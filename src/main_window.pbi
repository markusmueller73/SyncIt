;-------------------------------------------------------------
;- SyncIt!
;- small tool to synchronize two directories
;- include file: main_window.pbi
;- Copyright 2020 by Markus Mueller <markus.mueller.73 at hotmail dot de>
;- This program is free software
;-------------------------------------------------------------

;-------------------------------------------------------------
;-window constants
#APP_COLOR_SRC = $FF901E
#APP_COLOR_DST = $228B22

#MAIN_WINDOW_DEFAULT_WIDTH  = 700
#MAIN_WINDOW_DEFAULT_HEIGHT = 800

#PATHSELECT_CONTAINER_HEIGHT = 100
#BUTTON_CONTAINER_HEIGHT = 50
#DEFAULT_BUTTON_WIDTH  = 200

;-------------------------------------------------------------
;-main window gadget structure


Structure _MAIN_WINDOW_MENU
  id.i          ; handle of the menu
  file_prefs.i
  file_quit.i
  help_about.i
EndStructure

Structure _MAIN_WINDOW_ICONS
  app.i
  folder_open.i
  folder_open_small.i
EndStructure

Structure _MAIN_WINDOW
  id.i                    ; handle of the window
  mnu._MAIN_WINDOW_MENU   ; menu structure
  cnt_dir.i               ; container for the select directory part
  cnt_lst.i               ; container for the list 
  cnt_btn.i               ; container for the buttons
  txt_src_dir.i
  str_src_dir.i
  btn_src_dir.i
  txt_dst_dir.i
  str_dst_dir.i
  btn_dst_dir.i
  lst_diff.i
  btn_clear.i
  btn_compare.i
  btn_sync.i
  btn_exit.i
  ico._MAIN_WINDOW_ICONS  ; icon structure
EndStructure

;-------------------------------------------------------------
;-macro declarations
Macro _get_image_from_mem( var , mem_addr )
  var = CatchImage(#PB_Any, mem_addr)
  If IsImage(var)
    info("Image from executeable got successfully at address (" + str_addr(mem_addr) + ").")
  Else
    warn("Can't get image from executeable.")
  EndIf
EndMacro

;-------------------------------------------------------------
;-function declarations
Declare.b main_window_get_icons( *i._MAIN_WINDOW_ICONS )
Declare.b main_window_create_menu( window_id.i , *wm._MAIN_WINDOW_MENU )
Declare.i add_tooltip ( gadget.i, tooltip_text$, max_width.l = 300) 
Declare.b set_tooltip_text(gadget.i, tooltip.i, tooltip_text$)
;Declare   main_window_resize_cb ( void )

;-------------------------------------------------------------
;-main window function

Procedure.i main_window_open (*w._MAIN_WINDOW, *s._WINDOW_SIZES)
    
    check_ptr(*s)
    check_ptr(*w)
    
    If IsWindow(*w\id)
        warn("Main window is already created.")
        ProcedureReturn 0
    EndIf
  
    ;--set window and list flags
    Protected.l wnd_flags, lst_flags, ww, wh
    Protected.i tt_h
    Protected.s tt_text
    
    wnd_flags = #PB_Window_SystemMenu|#PB_Window_SizeGadget
    lst_flags = #PB_ListIcon_GridLines|#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection
    
    ;--create window
    *w\id = OpenWindow(#PB_Any, *s\x, *s\y, *s\w, *s\h, #APP_NAME, wnd_flags|#PB_Window_Invisible)
    
    If IsWindow(*w\id)
        
        main_window_get_icons(*w\ico)
        
        main_window_create_menu(WindowID(*w\id), *w\mnu)
        
        With *w
            
            ww = WindowWidth(\id)
            wh = WindowHeight(\id) - MenuHeight()
            
            ;----create dir select container
            \cnt_dir = ContainerGadget(#PB_Any, 0, 0, ww, #PATHSELECT_CONTAINER_HEIGHT)
            If IsGadget(\cnt_dir)
                
                \txt_src_dir = TextGadget(#PB_Any, 10, 15, 120, 25, "Source Directory:")
                \str_src_dir = StringGadget(#PB_Any, GadgetX(\txt_src_dir)+GadgetWidth(\txt_src_dir)+10, GadgetY(\txt_src_dir), ww-GadgetWidth(\txt_src_dir)-70, 25, "")
                tt_h = add_tooltip(\str_src_dir, "The source directory.")
                SetGadgetColor(\txt_src_dir, #PB_Gadget_FrontColor, #APP_COLOR_SRC)
                SetGadgetColor(\str_src_dir, #PB_Gadget_FrontColor, #APP_COLOR_SRC)
                
                \btn_src_dir = ButtonImageGadget(#PB_Any, GadgetWidth(\cnt_dir)-40, GadgetY(\txt_src_dir)-2, 30, 30, ImageID(\ico\folder_open_small))
                add_tooltip(\btn_src_dir, "Select a directory, the files in the directory will be inspected and checked for copying.")
                
                \txt_dst_dir = TextGadget(#PB_Any, GadgetX(\txt_src_dir), GadgetY(\txt_src_dir)+40, 120, 25, "Destination Directory:")
                \str_dst_dir = StringGadget(#PB_Any, GadgetX(\str_src_dir), GadgetY(\txt_dst_dir), ww-GadgetWidth(\txt_dst_dir)-70, 25, "")
                tt_h = add_tooltip(\str_dst_dir, "The destination directory.")
                SetGadgetColor(\txt_dst_dir, #PB_Gadget_FrontColor, #APP_COLOR_DST)
                SetGadgetColor(\str_dst_dir, #PB_Gadget_FrontColor, #APP_COLOR_DST)
                
                \btn_dst_dir = ButtonImageGadget(#PB_Any, GadgetX(\btn_src_dir), GadgetY(\txt_dst_dir)-2, 30, 30, ImageID(\ico\folder_open_small))
                add_tooltip(\btn_dst_dir, "Select a directory, to copy the source files to.")
                
                CloseGadgetList()
                
            EndIf
            
            ;----create button container
            \cnt_btn = ContainerGadget(#PB_Any, 0, wh - #BUTTON_CONTAINER_HEIGHT, ww, #BUTTON_CONTAINER_HEIGHT)
            If IsGadget(\cnt_btn)
                
                \btn_compare = ButtonGadget(#PB_Any, 10,                          10, #DEFAULT_BUTTON_WIDTH, 30, "Compare Directories")
                \btn_sync    = ButtonGadget(#PB_Any, #DEFAULT_BUTTON_WIDTH + 20,  10, #DEFAULT_BUTTON_WIDTH, 30, "Synchronize Directories")
                \btn_clear   = ButtonGadget(#PB_Any, ww-#DEFAULT_BUTTON_WIDTH-10, 10, #DEFAULT_BUTTON_WIDTH, 30, "Clear List")
                
                CloseGadgetList()
                
            EndIf

            ;----create list container
            \cnt_lst = ContainerGadget(#PB_Any, 0, GadgetY(\cnt_dir) + GadgetHeight(\cnt_dir), ww, GadgetY(\cnt_btn) - (GadgetY(\cnt_dir) + GadgetHeight(\cnt_dir)))
            If IsGadget(\cnt_lst)
                
                \lst_diff = ListIconGadget(#PB_Any, 10, 10, GadgetWidth(\cnt_lst)-20, GadgetHeight(\cnt_lst)-20, "", 40, lst_flags|#PB_ListIcon_CheckBoxes)
                
                AddGadgetColumn(\lst_diff, 1, "Directory", 250)
                AddGadgetColumn(\lst_diff, 2, "Filename", 200)
                AddGadgetColumn(\lst_diff, 3, "E", 25)
                AddGadgetColumn(\lst_diff, 4, "N", 25)
                AddGadgetColumn(\lst_diff, 5, "O", 25)
                AddGadgetColumn(\lst_diff, 6, "B", 25)
                AddGadgetColumn(\lst_diff, 7, "S", 25)
                AddGadgetColumn(\lst_diff, 8, "?", 25)
                
                tt_text = "Legend:"+#CRLF$+"E = file did not exist in destinations dir"+#CRLF$+"N = source file is newer"+#CRLF$+"O = source file is older"+#CRLF$+"B = source file is bigger"+#CRLF$+"S = source file is smaller"+#CRLF$+"? = there is a destination file, but no source file"
                add_tooltip(\lst_diff, tt_text)
                
                CloseGadgetList()
                
            EndIf
            
            ;----set window visibility
            ResizeWindow(\id, #PB_Ignore, #PB_Ignore,  GadgetX(\cnt_lst) + GadgetWidth(\cnt_lst), GadgetY(\cnt_btn) + GadgetHeight(\cnt_btn))
            HideWindow(\id, #False)
            
        EndWith
        
        ;---setting window bounds
        WindowBounds(*w\id, #DEFAULT_BUTTON_WIDTH * 3 + 40, #PATHSELECT_CONTAINER_HEIGHT + #BUTTON_CONTAINER_HEIGHT + 200, #PB_Ignore, #PB_Ignore)
        
        info("Main window successfully with handle {"+str_addr(*w\id)+"} created.")
        
    Else
        err("Can't create a window.")
        ProcedureReturn 0
    EndIf
    
    ProcedureReturn *w\id
    
EndProcedure

;-------------------------------------------------------------
;-main window help functions
;-------------------------------------------------------------
Procedure.b main_window_get_icons( *i._MAIN_WINDOW_ICONS )
    
    Protected.a d
    Protected.w w, h, x, y
    Protected.l col
    
    Restore FOLDER_OPEN_16
    Read.w w : Read.w h : Read.a d
    
    *i\folder_open_small = CreateImage(#PB_Any, w, h, d, #PB_Image_Transparent)
    If IsImage(*i\folder_open_small)
        
        StartDrawing(ImageOutput(*i\folder_open_small))
        
        DrawingMode(#PB_2DDrawing_AllChannels)
        
        For y = 0 To h-1
            For x = 0 To w-1
                Read.l col
                Plot(x, y, col)
            Next
        Next

        StopDrawing()
        
    Else
        err("Can't create image 'FOLDER_OPEN_16'.")
    EndIf
    
    Restore SYNCIT_64
    Read.w w : Read.w h : Read.a d
    
    *i\app = CreateImage(#PB_Any, w, h, d)
    If IsImage(*i\app)
        
        StartDrawing(ImageOutput(*i\app))
        
        DrawingMode(#PB_2DDrawing_AllChannels)
        
        For y = 0 To h-1
            For x = 0 To w-1
                Read.l col
                Plot(x, y, col)
            Next
        Next

        StopDrawing()
        
    Else
        err("Can't create image 'SYNCIT_64'.")
    EndIf
    
    ProcedureReturn  1
        
EndProcedure

; Procedure.b main_window_load_icons ( *ptr._MAIN_WINDOW_ICONS )
;   
;   _get_image_from_mem(*ptr\app, ?ICON_APP)
;   _get_image_from_mem(*ptr\folder_open, ?ICON_FOLDER_OPEN)
;   _get_image_from_mem(*ptr\folder_open_small, ?ICON_FOLDER_OPEN_SMALL)
;   
; EndProcedure
;-------------------------------------------------------------
Procedure.b main_window_create_menu( window_id.i , *wm._MAIN_WINDOW_MENU )
    
    *wm\id = CreateMenu(#PB_Any, window_id)
    
    If IsMenu(*wm\id)
    
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        
            *wm\file_prefs  = #PB_Menu_Preferences
            *wm\file_quit   = #PB_Menu_Quit
            *wm\help_about  = #PB_Menu_About
            
            MenuItem(*wm\file_prefs, "Preferences")
            MenuItem(*wm\file_quit, "Quit" + Space(1) + #APP_NAME)
            MenuItem(*wm\help_about, "About" + Space(1) + #APP_NAME)
            
        CompilerElse
        
            *wm\file_quit   = 1
            *wm\file_prefs  = 2
            *wm\help_about  = 3
            
            MenuTitle("File")
            MenuItem(*wm\file_prefs, "Preferences")
            MenuBar()
            MenuItem(*wm\file_quit, "Quit" + Space(1) + #APP_NAME)
            
            MenuTitle("Help")
            MenuItem(*wm\help_about, "About" + Space(1) + #APP_NAME)
            
        CompilerEndIf
        
    Else
        ProcedureReturn 0
    EndIf
    
    ProcedureReturn 1
    
EndProcedure
;-------------------------------------------------------------
Procedure.i add_tooltip ( gadget.i, tooltip_text$, max_width.l = 300) 
    
    Protected.i tooltip
    Protected   tti.TOOLINFO
    
    If Not IsGadget(gadget)
        warn("gadget " + Hex(gadget) + " did not exist.")
        ProcedureReturn 0
    EndIf
        
    ; remove #TTS_BALLOON flag for default tooltip
    tooltip = CreateWindowEx_(0, "ToolTips_Class32", "", #TTS_NOPREFIX | #TTS_BALLOON, 0, 0, 0, 0, 0, 0, GetModuleHandle_(0), 0)
    
    SendMessage_(tooltip, #TTM_SETTIPTEXTCOLOR, GetSysColor_(#COLOR_INFOTEXT), 0) 
    SendMessage_(tooltip, #TTM_SETTIPBKCOLOR, GetSysColor_(#COLOR_INFOBK), 0) 
    
    tti\cbSize = SizeOf(TOOLINFO) 
    tti\uFlags = #TTF_SUBCLASS | #TTF_IDISHWND 

    SendMessage_(tooltip, #TTM_SETMAXTIPWIDTH, 0, max_width) 
    tti\hWnd     = GadgetID(gadget)
    tti\uId      = GadgetID(gadget)
    tti\hinst    = 0
    tti\lpszText = @tooltip_text$
    
    SendMessage_(tooltip, #TTM_ADDTOOL, 0, tti) 
    SendMessage_(tooltip, #TTM_SETDELAYTIME, #TTDT_AUTOPOP, 15000) 
    SendMessage_(tooltip, #TTM_UPDATE , 0, 0)
    
    If GetGadgetData(gadget) = 0
        SetGadgetData(gadget, tooltip)
    EndIf
    
    ProcedureReturn tooltip
    
EndProcedure 
Procedure.b set_tooltip_text(gadget.i, tooltip.i, tooltip_text$)
    
    Protected tti.TOOLINFO
    
    tti\cbSize   = SizeOf(TOOLINFO)
    tti\hWnd     = GadgetID(gadget)
    tti\uId      = GadgetID(gadget)
    tti\lpszText = @tooltip_text$

    SendMessage_(tooltip, #TTM_UPDATETIPTEXT, 0, @tti)
    
    ProcedureReturn 1
    
EndProcedure
;-------------------------------------------------------------
Procedure.b main_window_resize ( *w._MAIN_WINDOW )
  
  Protected.l ww, wh, cnt_lst_h
  
  ;--check for window
  If IsWindow(*w\id)
    
    ww = WindowWidth(*w\id)
    wh = WindowHeight(*w\id) - MenuHeight()
    
    ;---resize the dir select container
    ResizeGadget(*w\cnt_dir, #PB_Ignore, #PB_Ignore, ww, #PB_Ignore)
    ResizeGadget(*w\str_src_dir, #PB_Ignore, #PB_Ignore, ww-GadgetWidth(*w\txt_src_dir)-70, #PB_Ignore)
    ResizeGadget(*w\btn_src_dir, ww-35, #PB_Ignore, #PB_Ignore, #PB_Ignore)
    ResizeGadget(*w\str_dst_dir, #PB_Ignore, #PB_Ignore, ww-GadgetWidth(*w\txt_dst_dir)-70, #PB_Ignore)
    ResizeGadget(*w\btn_dst_dir, ww-35, #PB_Ignore, #PB_Ignore, #PB_Ignore)
    
    ;---resize the buttons container
    ResizeGadget(*w\cnt_btn, #PB_Ignore, wh - #BUTTON_CONTAINER_HEIGHT, ww, #PB_Ignore)
    ResizeGadget(*w\btn_clear, ww-#DEFAULT_BUTTON_WIDTH-10, #PB_Ignore, #PB_Ignore, #PB_Ignore)
    
    ;---resize the list container
    ResizeGadget(*w\cnt_lst, #PB_Ignore, #PB_Ignore, ww, GadgetY(*w\cnt_btn) - (GadgetY(*w\cnt_dir) + GadgetHeight(*w\cnt_dir)))
    ResizeGadget(*w\lst_diff, #PB_Ignore, #PB_Ignore, GadgetWidth(*w\cnt_lst)-20, GadgetHeight(*w\cnt_lst)-20)
    
  Else
    warn("Window wasn't created.")
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
EndProcedure
;-------------------------------------------------------------
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 217
; FirstLine = 192
; Folding = --
; Optimizer
; EnableXP
; UseMainFile = main.pb
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant