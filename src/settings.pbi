;-------------------------------------------------------------
;- SyncIt!
;- small tool to synchronize two directories
;- include file: settings.pbi
;- Copyright 2020 by Markus Mueller <markus.mueller.73 at hotmail dot de>
;- This program is free software
;-------------------------------------------------------------


Procedure.l save_settings ( wnd_main.i , str_src_dir.i , str_dst_dir.i , *s._COPY_SETTINGS )
    
    Protected.i h_file
    
    check_ptr(*s)
    
    If FileSize(GetHomeDirectory() + #APP_SAVE_PATH) = #PB_FileSize_Not_Exist
        If CreateDirectory(GetHomeDirectory() + #APP_SAVE_PATH) = 0
            err("Can't create directory in HOMEDIR '"+GetHomeDirectory()+"'.")
        EndIf
    EndIf
    
    h_file = CreateFile(#PB_Any, GetHomeDirectory() + #APP_SAVE_PATH + #APP_CONF_FILE)
    If IsFile(h_file)
        
        WriteStringN(h_file, "# " + #APP_VERSION + " config file")
        WriteStringN(h_file, "# do NOT edit or modify this file, no warranty for lost files")
        WriteStringN(h_file, "")
        WriteStringN(h_file, "# main window depended settings")
        WriteStringN(h_file, "X-Pos" + " = " + Str(WindowX(wnd_main)))
        WriteStringN(h_file, "Y-Pos" + " = " + Str(WindowY(wnd_main)))
        WriteStringN(h_file, "Width" + " = " + Str(WindowWidth(wnd_main)))
        WriteStringN(h_file, "Height" + " = " + Str(WindowHeight(wnd_main)))
        WriteStringN(h_file, "")
        WriteStringN(h_file, "# this are the copy and delete rules for the file synchronisation, CAREFULLY!")
        WriteStringN(h_file, "Source file not exist" + " = " + Str(*s\src_not_exist))
        WriteStringN(h_file, "Source file is newer" + " = " + Str(*s\src_is_newer))
        WriteStringN(h_file, "Source file is older" + " = " + Str(*s\src_is_older))
        WriteStringN(h_file, "Destination file not exist" + " = " + Str(*s\dst_not_exist))
        WriteStringN(h_file, "")
        WriteStringN(h_file, "# the last used directories")
        WriteStringN(h_file, "Last used source directory" + " = " + GetGadgetText(str_src_dir))
        WriteStringN(h_file, "Last used destination directory" + " = " + GetGadgetText(str_dst_dir))
        WriteStringN(h_file, "")
        WriteStringN(h_file, "# eof")
        
        CloseFile(h_file)
        
        info("Settings successfully saved.")
        
    Else
        err("Can't create file '"+#APP_CONF_FILE+"' in directory '"+GetHomeDirectory() + #APP_SAVE_PATH+"'.")
    EndIf
    
    ProcedureReturn 1
    
EndProcedure

Procedure.l load_settings ( *p._PATHS , *s._COPY_SETTINGS , *w._WINDOW_SIZES )
    
    Protected.i h_file
    Protected   line$, key$, val$
    
    check_ptr(*p)
    check_ptr(*s)
    check_ptr(*w)
    
    h_file = ReadFile(#PB_Any, GetHomeDirectory() + #APP_SAVE_PATH + #APP_CONF_FILE)
    If IsFile(h_file)
        
        While Eof(h_file) = 0
            
            line$ = ReadString(h_file)
            
            If line$ = "" ; empty line
                Continue
            EndIf
            
            If Left(line$, 1) = "#" Or Left(line$, 1) = ";" ; comment in file
                Continue
            EndIf
            
            key$ = Trim(UCase(StringField(line$, 1, "=")))
            val$ = Trim(StringField(line$, 2, "="))
            
            Select key$
                Case "X-POS"    : *w\x = Val(val$)
                Case "Y-POS"    : *w\y = Val(val$)
                Case "WIDTH"    : *w\w = Val(val$)
                Case "HEIGHT"   : *w\h = Val(val$)
                Case "SOURCE FILE NOT EXIST"        : *s\src_not_exist = Val(val$)
                Case "SOURCE FILE IS NEWER"         : *s\src_is_newer = Val(val$)
                Case "SOURCE FILE IS OLDER"         : *s\src_is_older = Val(val$)
                Case "DESTINATION FILE NOT EXIST"   : *s\dst_not_exist = Val(val$)
                Case "LAST USED SOURCE DIRECTORY"       : *p\src = val$
                Case "LAST USED DESTINATION DIRECTORY"  : *p\dst = val$
                Default : warn("Unknown option in config file: " + key$)
            EndSelect
            
        Wend
        
        CloseFile(h_file)
        
    Else
        
        *w\x = #PB_Ignore
        *w\y = #PB_Ignore
        *w\w = 700
        *w\h = 800
        
        *s\src_not_exist    = #APP_COPY_DO_NOTHING
        *s\src_is_newer     = #APP_COPY_SRC_COPY
        *s\src_is_older     = #APP_COPY_DO_NOTHING
        *s\dst_not_exist    = #APP_COPY_SRC_COPY
        
        warn("No config file '"+#APP_CONF_FILE+"' found, set to default values.")
        
    EndIf
    
    ProcedureReturn 1
    
EndProcedure

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 40
; FirstLine = 21
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant