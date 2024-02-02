;-------------------------------------------------------------
;- SyncIt!
;- small tool to synchronize two directories
;- include file: logging.pbi
;- Copyright 2020 by Markus Mueller <markus.mueller.73 at hotmail dot de>
;- This program is free software
;-------------------------------------------------------------

;-------------------------------------------------------------
;-specific constants

Enumeration 0
    #APP_LOGTYPE_NONE
    #APP_LOGTYPE_INFO
    #APP_LOGTYPE_WARNING
    #APP_LOGTYPE_ERROR
EndEnumeration


Procedure.s format_timer( time_in_ms.l )
  Protected.l h, m, s, ms
  Protected.s result
  If time_in_ms > 3600000
    h = Int(time_in_ms / 3600000)
    time_in_ms - (h * 3600000)
  EndIf
  If time_in_ms > 60000
    m = Int(time_in_ms / 60000)
    time_in_ms - (m * 60000)
  EndIf
  If time_in_ms > 1000
    s = Int(time_in_ms / 1000)
    time_in_ms - (s * 1000)
  EndIf
  ms = time_in_ms
  result = RSet(Str(h),2,"0") +":" + RSet(Str(m),2,"0") + ":" + RSet(Str(s),2,"0") + "." +RSet(Str(ms),3,"0")
  ProcedureReturn result
EndProcedure

Procedure.b logger( message.s , type.b , function.s, line.l = 0, start_logging.b = #False, create_new.b = #False )
    
    Static.b init = #False
    Static.l start_time
    
    Protected.i h_log
    Protected.s log_file, text
    
    log_file    = GetHomeDirectory() + #APP_SAVE_PATH + #APP_NAME_FS + ".log"
    
    If start_logging And init = #False
        
        start_time  = ElapsedMilliseconds()
        
        If FileSize(GetHomeDirectory() + #APP_SAVE_PATH) = #PB_FileSize_Not_Exist
            If CreateDirectory(GetHomeDirectory() + #APP_SAVE_PATH) = 0
                MessageRequester(#APP_NAME, "Error, can't create directory in the HOMEDIR: " + GetHomeDirectory(), #PB_MessageRequester_Error)
                End 1
            EndIf
        EndIf
        
        If create_new
            h_log = CreateFile(#PB_Any, log_file)
            If IsFile(h_log)
                WriteStringN(h_log, message + " log file, created at " + FormatDate("%yyyy-%mm-%dd %hh:%ii", Date()))
                CloseFile(h_log)
            Else
                MessageRequester(#APP_NAME, "Error, can't create file in directory " + GetHomeDirectory() + #APP_SAVE_PATH, #PB_MessageRequester_Error)
                End 1
            EndIf
        Else
            h_log = OpenFile(#PB_Any, log_file, #PB_File_Append | #PB_File_NoBuffering | #PB_File_SharedRead)
            If IsFile(h_log)
                WriteStringN(h_log, "------------------------------ fresh start at " + FormatDate("%yyyy-%mm-%dd %hh:%ii", Date()) + " ------------------------------")
                CloseFile(h_log)
            Else
                MessageRequester(#APP_NAME, "Error, can't open file " + log_file, #PB_MessageRequester_Error)
                End 1
            EndIf
        EndIf
        
        init = #True
        
        ProcedureReturn 1
        
    EndIf
    
    If init
        
        text = "[" + format_timer(ElapsedMilliseconds()-start_time) + "]" + " :: "
        
        Select type
            Case #APP_LOGTYPE_INFO    : text + "[INFO]" + "    :: "  
            Case #APP_LOGTYPE_WARNING : text + "[WARNING]" + " :: "
            Case #APP_LOGTYPE_ERROR   : text + "[ERROR]" + "   :: "
        EndSelect
        
        If function = "" : function = "main" : EndIf
        text + "<" + function + ">" + " => "
        
        h_log = OpenFile(#PB_Any, log_file, #PB_File_Append | #PB_File_NoBuffering | #PB_File_SharedRead)
        If IsFile(h_log)
            WriteStringN(h_log, text + message)
            CloseFile(h_log)
        EndIf
        
        CompilerIf #PB_Compiler_Debugger = 0
            If type = #APP_LOGTYPE_ERROR
                MessageRequester(#APP_NAME, "Error in function '" + function + "' near line " + Str(line) + #CRLF$ + #CRLF$ + message, #PB_MessageRequester_Error)
                End 1
            EndIf
        CompilerEndIf
        
        Debug text + message
        
        ProcedureReturn 2
        
    EndIf
    
    ProcedureReturn 0
    
EndProcedure:

Macro start_logging ( create_new_logfile = #False )
    logger(#APP_VERSION, #APP_LOGTYPE_INFO, "", 0, #True, create_new_logfile)
EndMacro

Macro info( msg )
    logger(msg, #APP_LOGTYPE_INFO, #PB_Compiler_Procedure, #PB_Compiler_Line)
EndMacro

Macro warn( msg )
    logger(msg, #APP_LOGTYPE_WARNING, #PB_Compiler_Procedure, #PB_Compiler_Line)
EndMacro

Macro err( msg )
    logger(msg, #APP_LOGTYPE_ERROR, #PB_Compiler_Procedure, #PB_Compiler_Line)
EndMacro


; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 138
; FirstLine = 81
; Folding = --
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant