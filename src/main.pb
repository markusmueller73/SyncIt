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
;-include header
XIncludeFile "header.pbi"

;-------------------------------------------------------------
;- define vars

Define.b do_loop = #True, check_for_copy
Define.i sys_evt, evt_wnd, evt_gdg, evt_mnu, evt_type
Define   cur_dir._PATHS
Define   cpy_settings._COPY_SETTINGS
Define   wnd_main._MAIN_WINDOW
Define   wnd_main_size._WINDOW_SIZES
Define   wnd_conf._CONFIG_WINDOW

NewList src_files._FILE_DESCRIPTOR()
NewList dst_files._FILE_DESCRIPTOR()
NewList result._FILE_DESCRIPTOR_EX()

;-------------------------------------------------------------
;- declare sub functions
Declare   check_button_states( *w._MAIN_WINDOW , list_content.l )
Declare.s get_selected_directory( str_gadget.i , dialog_title.s , initial_dir.s )
Declare   get_selected_settings( *s._COPY_SETTINGS , *w._CONFIG_WINDOW )
Declare.l show_comparsion( list_gadget.i , List res._FILE_DESCRIPTOR_EX() , *s._COPY_SETTINGS )

;-------------------------------------------------------------
;- load settings and setup program
start_logging()

If load_settings(@cur_dir, @cpy_settings, @wnd_main_size) = 0
    warn("Can't load settings, starting with default values.")
EndIf

If main_window_open(@wnd_main, @wnd_main_size)
    If cur_dir\src
        SetGadgetText(wnd_main\str_src_dir, cur_dir\src)
    EndIf
    If cur_dir\dst
        SetGadgetText(wnd_main\str_dst_dir, cur_dir\dst)
    EndIf
Else
    err("Can't open a window.")
EndIf

;-------------------------------------------------------------
;- start main loop

Repeat 
    
    sys_evt = WaitWindowEvent()
    evt_wnd = EventWindow()
    
    Select sys_evt
            
        Case #PB_Event_CloseWindow
            
            Select evt_wnd
                    
                Case wnd_main\id
                    do_loop = #False
                    
                Case wnd_conf\id
                    CloseWindow(wnd_conf\id)
                    
            EndSelect
            
        Case #PB_Event_SizeWindow
            
            If evt_wnd = wnd_main\id
                main_window_resize(@wnd_main)
            EndIf
            
        Case #PB_Event_Gadget
            ;---- check the gadgets of the MAIN window
            evt_gdg = EventGadget()
            
            Select evt_gdg
                    
                Case wnd_main\btn_src_dir
                    
                    cur_dir\src = get_selected_directory(wnd_main\str_src_dir, "source" , cur_dir\src)
                    
                Case wnd_main\btn_dst_dir
                    
                    cur_dir\dst = get_selected_directory(wnd_main\str_dst_dir, "destination", cur_dir\dst)
                    
                Case wnd_main\btn_compare
                    
                    get_directory_content(cur_dir\src, src_files())
                    get_directory_content(cur_dir\dst, dst_files())
                    
                    compare_directories(cur_dir\src, src_files(), cur_dir\dst, dst_files(), result())
                    
                    show_comparsion(wnd_main\lst_diff, result(), @cpy_settings)
                    
                Case wnd_main\btn_sync
                    
                    If MessageRequester(#APP_NAME, "Are you sure, to copy and delete the marked files?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
                        
                        sync_dirs(wnd_main\id, result())
                        
                        clear_list(src_files())
                        clear_list(dst_files())
                        clear_list(result())
                        
                        ClearGadgetItems(wnd_main\lst_diff)
                        
                    EndIf
                    
                Case wnd_main\btn_clear
                    
                    clear_list(src_files())
                    clear_list(dst_files())
                    clear_list(result())
                    
                    ClearGadgetItems(wnd_main\lst_diff)
                    
                ;----- from here the gadgets of the CONFIG window get processed
                Case wnd_conf\btn_ok
                    
                    get_selected_settings(@cpy_settings, @wnd_conf)
                    
                    CloseWindow(wnd_conf\id)
                    
                Case wnd_conf\btn_cancel
                    
                    CloseWindow(wnd_conf\id)
                    
                ;----- from here the gadgets of the ABOUT window get processed
                    
            EndSelect
            
        Case #PB_Event_Menu
            ;---- check the menu items of the MAIN window
            evt_mnu = EventMenu()
            
            Select evt_mnu
                    
                Case wnd_main\mnu\file_prefs
                    
                    config_window_open(wnd_main\id, @wnd_conf, @cpy_settings)
                
                Case wnd_main\mnu\file_quit
                    
                    do_loop = #False
                
                Case wnd_main\mnu\help_about
                    
                    about_window_open()
                
            EndSelect
            
    EndSelect
    
    check_button_states(@wnd_main, ListSize(result()))
    
Until do_loop = #False

;-------------------------------------------------------------
;-end

save_settings(wnd_main\id, wnd_main\str_src_dir, wnd_main\str_dst_dir, @cpy_settings)

delete_list(src_files())
delete_list(dst_files())
delete_list(result())

If IsWindow(wnd_main\id)
    CloseWindow(wnd_main\id)
EndIf

info("Program closed regulary by user.")

End 0

;-------------------------------------------------------------
;-functions

Procedure check_button_states( *w._MAIN_WINDOW , list_content.l )
    
    With *w
    
        If GetGadgetText(\str_src_dir) <> #Null$ And GetGadgetText(\str_dst_dir) <> #Null$
            DisableGadget(\btn_compare, #False)
        Else
            DisableGadget(\btn_compare, #True)
        EndIf
        
        If list_content > 0
            DisableGadget(\btn_sync, #False)
        Else
            DisableGadget(\btn_sync, #True)
        EndIf
        
        If CountGadgetItems(\lst_diff) > 0
            DisableGadget(\btn_clear, #False)
        Else
            DisableGadget(\btn_clear, #True)
        EndIf
    
    EndWith
    
EndProcedure

Procedure.s get_selected_directory( str_gadget.i , dialog_title.s , initial_dir.s )
    
    Protected.s dir
    
    If initial_dir = #Null$
        initial_dir = GetHomeDirectory()
    EndIf
    
    dir = PathRequester("Select " + dialog_title + " directory:", initial_dir)
    
    If dir = #Null$
        
        SetGadgetText(str_gadget, #Null$)
        GadgetToolTip(str_gadget, "No directory selected")
        
    Else
        
        SetGadgetText(str_gadget, dir)
        GadgetToolTip(str_gadget, dir)
        
    EndIf
    
    ProcedureReturn dir
    
EndProcedure

Procedure get_selected_settings( *s._COPY_SETTINGS , *w._CONFIG_WINDOW )
    
    check_ptr(*s)
    check_ptr(*w)
    
    Macro check_state( gadget , var , state )
        If GetGadgetState(gadget)
            var = state
        EndIf
    EndMacro
    
    check_state(*w\opt_src_ne_cpy_dst, *s\src_not_exist, #APP_COPY_DST_COPY)
    check_state(*w\opt_src_ne_del_dst, *s\src_not_exist, #APP_COPY_DST_DEL)
    check_state(*w\opt_src_ne_nothing, *s\src_not_exist, #APP_COPY_DO_NOTHING)
    
    check_state(*w\opt_dst_ne_cpy_src, *s\dst_not_exist, #APP_COPY_SRC_COPY)
    check_state(*w\opt_dst_ne_del_src, *s\dst_not_exist, #APP_COPY_SRC_DEL)
    check_state(*w\opt_dst_ne_nothing, *s\dst_not_exist, #APP_COPY_DO_NOTHING)
    
    check_state(*w\opt_src_dn_cpy_src, *s\src_is_newer, #APP_COPY_SRC_COPY)
    check_state(*w\opt_src_dn_nothing, *s\src_is_newer, #APP_COPY_DO_NOTHING)
    
    check_state(*w\opt_src_do_cpy_src, *s\src_is_older, #APP_COPY_SRC_COPY)
    check_state(*w\opt_src_do_cpy_dst, *s\src_is_older, #APP_COPY_DST_COPY)
    check_state(*w\opt_src_do_nothing, *s\src_is_older, #APP_COPY_DO_NOTHING)
    
EndProcedure

Procedure.l show_comparsion( list_gadget.i , List res._FILE_DESCRIPTOR_EX() , *s._COPY_SETTINGS )
    
    Protected.l line_color, i, j, k
    Protected   cell_content$
    
    If ListSize(res()) = 0
        warn("The result list is empty.")
        ProcedureReturn 0
    EndIf
    
    ClearGadgetItems(list_gadget)
    
    ForEach res()
        
        line_color     = GetSysColor_(#COLOR_BTNTEXT)
        cell_content$  = ""
        
        res()\sync_status = 0
        
        If res()\diff & #APP_FILEATTR_DST_NOT_EXIST
            cell_content$ + "X" + Chr(10)
            res()\sync_status = *s\dst_not_exist
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\diff & #APP_FILEATTR_SRC_IS_NEWER
            cell_content$ + "X" + Chr(10)
            res()\sync_status = *s\src_is_newer
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\diff & #APP_FILEATTR_SRC_IS_OLDER
            cell_content$ + "X" + Chr(10)
            res()\sync_status = *s\src_is_older
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\diff & #APP_FILEATTR_SRC_IS_BIGGER
            cell_content$ + "X" + Chr(10)
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\diff & #APP_FILEATTR_SRC_IS_SMALLER
            cell_content$ + "X" + Chr(10)
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\diff & #APP_FILEATTR_SRC_NOT_EXIST
            cell_content$ + "X" + Chr(10)
            res()\sync_status = *s\src_not_exist
        Else
            cell_content$ + "-" + Chr(10)
        EndIf
        
        If res()\sync_status = #APP_COPY_SRC_COPY Or res()\sync_status = #APP_COPY_DST_COPY
            line_color = #APP_COPY_COLOR_COPY
            j + 1
        ElseIf res()\sync_status = #APP_COPY_SRC_DEL Or res()\sync_status = #APP_COPY_DST_DEL
            line_color = #APP_COPY_COLOR_DELETE
            k + 1
        Else
            ;line_color = #APP_COPY_COLOR_NOTHING
        EndIf
        
        AddGadgetItem(list_gadget, i, "" + Chr(10) + res()\path\src + Chr(10) + res()\name + Chr(10) + cell_content$)
        
        SetGadgetItemColor(list_gadget, i, #PB_Gadget_FrontColor, line_color)
        SetGadgetItemData(list_gadget, i, res()\sync_status)
        
        If res()\sync_status
            SetGadgetItemState(list_gadget, i, #PB_ListIcon_Checked)
        EndIf
        
        i + 1
        
    Next
    
    ProcedureReturn i
    
EndProcedure


; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 121
; FirstLine = 102
; Folding = 5
; Optimizer
; EnableXP
; EnablePurifier
; EnableCompileCount = 39
; EnableBuildCount = 0
; EnableExeConstant