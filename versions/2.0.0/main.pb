;  * SyncIt!
;  * small tool to synchronize two directories
;  *
;  * main.pb
;  *
;  * Copyright 2020 by Markus Mueller <markus.mueller.73 at hotmail dot de>
;  *
;  * This program is free software; you can redistribute it and/or modify
;  * it under the terms of the GNU General Public License As published by
;  * the Free Software Foundation; either version 2 of the License, or
;  * (at your option) any later version.
;  *
;  * This program is distributed in the hope that it will be useful,
;  * but WITHOUT ANY WARRANTY; without even the implied warranty of
;  * MERCHANTABILITY or FITNESS for A PARTICULAR PURPOSE.  See the
;  * GNU General Public License for more details.
;  *
;  * You should have received a copy of the GNU General Public License
;  * along with this program; if not, write to the Free Software
;  * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;  * MA 02110-1301, USA.
;  *
;-------------------------------------------------------------
;-header
XIncludeFile "header.pbi"
;-------------------------------------------------------------
;-start
Declare.i main ( void )
Define.b RESULT = main( )
;-end
End RESULT
;-------------------------------------------------------------
;-helper macros
Macro _select_directory( var , gadget , type=#Null$)
  If var = #Null$
    var = PathRequester("Select " + type + " directory:", GetHomeDirectory())
  Else
    var = PathRequester("Select " + type + " directory:", var)
  EndIf
  If var = #Null$
    SetGadgetText(gadget, #Null$)
    GadgetToolTip(gadget, "No directory selected")
  Else
    SetGadgetText(gadget, var)
    GadgetToolTip(gadget, var)
  EndIf
EndMacro
;-------------------------------------------------------------
;-main function
Procedure.i main ( void )
  
  Protected.b do_loop = #True, check_for_copy
  Protected.i n, line_color, evt, evt_wnd, evt_gdg, evt_mnu, evt_type
  Protected   cur_src_dir$, cur_dst_dir$
  Protected   wnd._MAIN_WINDOW
  
  NewList src_files._FILE_DESCRIPTOR()
  NewList dst_files._FILE_DESCRIPTOR()
  NewList result._FILE_DESCRIPTOR_EX()
  
  ;--open main window
  If main_window_open(@wnd) = 0
    ProcedureReturn 1
  EndIf
  
  ;--debug vars, only for testing
  CompilerIf #PB_Compiler_Debugger
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      cur_src_dir$ = "E:\Temp\_ORG\"
      cur_dst_dir$ = "E:\Temp\_BAK\"
    CompilerElse
      cur_src_dir$ = "/Users/markus/_TEST/ORG/"
      cur_dst_dir$ = "/Users/markus/_TEST/BAK/"
    CompilerEndIf
    SetGadgetText(wnd\str_src_dir, cur_src_dir$)
    GadgetToolTip(wnd\str_src_dir, cur_src_dir$)
    SetGadgetText(wnd\str_dst_dir, cur_dst_dir$)
    GadgetToolTip(wnd\str_dst_dir, cur_dst_dir$)
  CompilerEndIf
  
  ;--loop
  Repeat 
    
    evt = WaitWindowEvent()
    
    Select evt
        
      Case #PB_Event_CloseWindow
        do_loop = #False
        
      Case #PB_Event_SizeWindow
        main_window_resize(@wnd)
        
      ;---check gadgets
      Case #PB_Event_Gadget
        evt_gdg = EventGadget()
        Select evt_gdg
            
          Case wnd\btn_src_dir
            _select_directory(cur_src_dir$, wnd\str_src_dir, "source")
            
          Case wnd\btn_dst_dir
            _select_directory(cur_dst_dir$, wnd\str_dst_dir, "destination")
            
          Case wnd\btn_compare
            get_directory_content(cur_src_dir$, src_files())
            get_directory_content(cur_dst_dir$, dst_files())
            
            n = compare_directories(cur_src_dir$, src_files(), cur_dst_dir$, dst_files(), result())
            If ListSize(result()) > 0
              
              ClearGadgetItems(wnd\lst_diff)
              
              n = 0
              
              ForEach result()
                
                If result()\diff = #APP_FILEATTR_SRC_NOT_EXIST Or result()\diff = #APP_FILEATTR_SRC_IS_OLDER Or result()\diff = #APP_FILEATTR_DST_IS_BIGGER
                  line_color = #APP_COLOR_DST
                  check_for_copy = 0
                Else
                  line_color = #APP_COLOR_SRC
                  If result()\diff = #APP_FILEATTR_DST_NOT_EXIST
                    check_for_copy = 1
                  Else
                    check_for_copy = 0
                  EndIf
                EndIf
                
                result()\to_copy = check_for_copy
                
                AddGadgetItem(wnd\lst_diff, n, "" + Chr(10) + result()\path\src + Chr(10) + result()\name + Chr(10) + result()\text)
                SetGadgetItemColor(wnd\lst_diff, n, #PB_Gadget_FrontColor, line_color)
                SetGadgetItemData(wnd\lst_diff, n, check_for_copy)
                If check_for_copy
                    SetGadgetItemState(wnd\lst_diff, n, #PB_ListIcon_Checked)
                EndIf
                
                n + 1
                
              Next
              
            EndIf
            
          Case wnd\btn_sync
            sync_dirs(result())
            
          Case wnd\btn_clear
            del_list(src_files()) : del_list(dst_files()) : del_list(result())
            ClearGadgetItems(wnd\lst_diff)
            
        EndSelect
        
      ;---check menus
      Case #PB_Event_Menu
        
        evt_mnu = EventMenu()
        Select evt_mnu
            
          Case wnd\mnu\file_prefs
            config_window_open()
            
          Case wnd\mnu\file_quit
            do_loop = #False
            
          Case wnd\mnu\help_about
            about_window_open()
            
        EndSelect
        
    EndSelect
    
    ;--check button states
    If GetGadgetText(wnd\str_src_dir) <> #Null$ And GetGadgetText(wnd\str_dst_dir) <> #Null$
      DisableGadget(wnd\btn_compare, #False)
    Else
      DisableGadget(wnd\btn_compare, #True)
    EndIf
    
    If ListSize(result()) > 0
      DisableGadget(wnd\btn_sync, #False)
    Else
      DisableGadget(wnd\btn_sync, #True)
    EndIf
    
    If CountGadgetItems(wnd\lst_diff) > 0
      DisableGadget(wnd\btn_clear, #False)
    Else
      DisableGadget(wnd\btn_clear, #True)
    EndIf
    
  Until do_loop = #False
  
  info(#APP_NAME + " closed by user.")
  
  ProcedureReturn 0
  
EndProcedure
; IDE Options = PureBasic 6.02 LTS (Windows - x64)
; CursorPosition = 68
; FirstLine = 62
; Folding = -
; Optimizer
; EnableXP
; EnablePurifier
; EnableCompileCount = 39
; EnableBuildCount = 0
; EnableExeConstant