EnableExplicit

#DOT$ = "."

#APP_SEARCH_PATTERN$ = "*"
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #APP_STRING_CASE = #PB_String_NoCase
  #APP_MAX_PATH = #MAX_PATH
CompilerElseIf #PB_Compiler_OS = #PB_OS_MacOS
  #APP_STRING_CASE = #PB_String_CaseSensitive
  #APP_MAX_PATH = 1016
CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
  #APP_STRING_CASE = #PB_String_CaseSensitive
  #APP_MAX_PATH = #PATH_MAX
CompilerEndIf

Enumeration 0
  #APP_ATTR_FILES_ARE_EQUAL
  #APP_ATTR_FILE_IS_HIDDEN
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    #APP_ATTR_FILE_IS_SYSTEM
    #APP_ATTR_FILE_IS_READ_ONLY
  CompilerElse
    #APP_ATTR_FILE_IS_SYM_LINK
  CompilerEndIf
  #APP_ATTR_SRC_FILE_NOT_EXIST
  #APP_ATTR_DST_FILE_NOT_EXIST
  #APP_ATTR_SRC_IS_SMALLER
  #APP_ATTR_DST_IS_SMALLER
  #APP_ATTR_SRC_IS_OLDER
  #APP_ATTR_DST_IS_OLDER
EndEnumeration

Structure _file_dates
  ;created.l
  modified.l
  accessed.l
EndStructure

Structure _file_descriptor
  attr.l            ; = file system attributes
  date._file_dates  
  diff.l            ; = internal attributes (differences)
  size.q            ; = file size in bytes
  name.s
  path.s            ; with trailing path separator
EndStructure

Declare.b get_bit ( var.l , bit.l )
Declare.l set_bit ( bit.l )

Macro info( text ) : Debug "[INFO] " + text : EndMacro
Macro warn( text ) : Debug "[WARNING] " + text : EndMacro
Macro _add_ps( path )
  If Right(path, 1) <> #PS$ : path + #PS$ : EndIf
EndMacro
Macro _set_bit ( var , bit )
  ( var | ( 1 << bit ) )
EndMacro
Macro _is_bit_set ( var , bit )
  ( get_bit(var, bit) )
EndMacro
Macro _is_special_file ( filename , attr , ptr )
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If attr & #PB_FileSystem_Hidden
      ptr | ( 1 << #APP_ATTR_FILE_IS_HIDDEN )
    EndIf
    If attr &  #PB_FileSystem_System
      ptr | ( 1 << #APP_ATTR_FILE_IS_SYSTEM )
    EndIf
    If attr &  #PB_FileSystem_ReadOnly
      ptr | ( 1 << #APP_ATTR_FILE_IS_READ_ONLY )
    EndIf
  CompilerElse
    If Left(filename, 1) = #DOT$
      ptr | ( 1 << #APP_ATTR_FILE_IS_HIDDEN )
    EndIf
    If attr &  #PB_FileSystem_Link
      ptr | ( 1 << #APP_ATTR_FILE_IS_SYM_LINK )
    EndIf
  CompilerEndIf
EndMacro

Procedure.l check_dir ( root_dir$ , List files._file_descriptor() ) ; get the number of checked dirs, without . and ..
  
  If root_dir$ = ""
    warn("Missing argument, no root dir name.")
    ProcedureReturn 0
  EndIf
  
  If FileSize(root_dir$) = -1 Or FileSize(root_dir$) >= 0
    warn("Root dir '" + root_dir$ + "' doesn't exist or isn't a directory.")
    ProcedureReturn 0
  EndIf
  
  _add_ps(root_dir$)
  
  Protected.l nb_of_dirs = 0
  Protected.i h_dir = ExamineDirectory(#PB_Any, root_dir$, #APP_SEARCH_PATTERN$)
  Protected.s next_dir
  
  If IsDirectory(h_dir)
    
    info("Checking directory '" + root_dir$ + "' now.")
    
    While NextDirectoryEntry(h_dir)
      
      If DirectoryEntryType(h_dir) = #PB_DirectoryEntry_File
        
        AddElement(files())
        
        With files()
          
          \date\modified = DirectoryEntryDate(h_dir, #PB_Date_Modified)  ; last time of change
          \date\accessed = DirectoryEntryDate(h_dir, #PB_Date_Accessed) ; last time of access
          \attr = DirectoryEntryAttributes(h_dir)
          \diff = 0
          \size = DirectoryEntrySize(h_dir)
          \name = DirectoryEntryName(h_dir)
          \path = root_dir$
          
          _is_special_file(\name, \attr, \diff)
          
        EndWith
        
      Else ; == DirectoryEntryType(h_dir) = #PB_DirectoryEntry_Directory
        
        next_dir = DirectoryEntryName(h_dir)
        
        If next_dir <> "." And next_dir <> ".."
          nb_of_dirs + (check_dir(root_dir$ + next_dir, files())) + 1
        EndIf
        
      EndIf
      
    Wend
    
    FinishDirectory(h_dir)
    
  Else
    warn("Can't open directory '" + root_dir$ + "' for reading.")
    ProcedureReturn 0
  EndIf
  
  ProcedureReturn nb_of_dirs
  
EndProcedure

Procedure.l compare_dirs ( src_dir$ , List src_files._file_descriptor() , dst_dir$ , List dst_files._file_descriptor() )
  
  If ListSize(src_files()) = 0
    warn("Source list is empty.")
    ProcedureReturn 0
  EndIf
  
  If ListSize(dst_files()) = 0
    info("Destination list is empty.")
    ProcedureReturn ListSize(src_files())
  EndIf
  
  Protected.s src_rel_path, dst_rel_path, src_file, dst_file
  
  ForEach src_files()
    
    src_rel_path = RemoveString(src_files()\path, src_dir$, #APP_STRING_CASE, 1, 1)
    src_file     = src_rel_path + src_files()\name
    
    ForEach dst_files()
      
      dst_rel_path = RemoveString(dst_files()\path, dst_dir$, #APP_STRING_CASE, 1, 1)
      dst_file     = dst_rel_path + dst_files()\name
      
      If CompareMemoryString(@src_file, @dst_file, #APP_STRING_CASE) = #PB_String_Equal
        
        
        
        DeleteElement(dst_files(), 1)
        Break
        
      EndIf
      
    Next
    
  Next
  
  If ListSize(dst_files()) > 0
    ForEach dst_files()
      
    Next
  EndIf
  
  ProcedureReturn ListSize(src_files())
  
EndProcedure

Procedure.l set_bit ( bit.l )
  Protected.l var
  var | ( 1 << bit )
  ProcedureReturn var
EndProcedure

Procedure.b get_bit ( var.l , bit.l )
  If ( var & ( 1 << bit ) )
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

NewList files._file_descriptor()

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Debug check_dir("E:\Daten\Projekte\SyncIt", files())
CompilerElse
  Debug check_dir("/Users/markus/Projekte/examples", files())
CompilerEndIf

ForEach files()
  Debug files()\path + files()\name + " = " + Bin(files()\diff, #PB_Long)
Next

End
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 59
; FirstLine = 86
; Folding = PI-
; EnableXP
; EnablePurifier
; EnableCompileCount = 15
; EnableBuildCount = 0
; EnableExeConstant