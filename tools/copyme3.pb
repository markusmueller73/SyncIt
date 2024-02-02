EnableExplicit

UseCRC32Fingerprint()

#CopyFile_BufferSize = 131072

Enumeration -1 Step -1
  #CopyFile_Error_SameFiles
  #CopyFile_Error_SrcNotExist
  #CopyFile_Error_AllocateMem
  #CopyFile_Error_SrcCrcFailed
  #CopyFile_Error_CantReadSrc
  #CopyFile_Error_CantCreateDst
  #CopyFile_Error_DstCrcFailed
  #CopyFile_Error_CrcCheckFailed
EndEnumeration

Structure structCopyJob
  sourceFile.s
  destFile.s
  duration.i
  progress.l
  copied.q
EndStructure


Procedure.q myCopyFile( *job.structCopyJob )
  
  Protected   *copy_buffer
  Protected.i src_h, dst_h, start
  Protected.s src_crc, dst_crc
  Protected.q src_size, src_left
  Protected.d percent
  
  If FileSize(*job\sourceFile) < 0
    Debug "CopyFile ERROR: source file did not exist"
    ProcedureReturn #CopyFile_Error_SrcNotExist
  EndIf

  If GetFilePart(*job\destFile) = #Null$
    If Right(*job\destFile, 1) <> #PS$
      *job\destFile + #PS$
    EndIf
    *job\destFile + GetFilePart(*job\sourceFile)
  EndIf
  
  If CompareMemoryString(@*job\sourceFile, @*job\destFile) = #PB_String_Equal
    Debug "CopyFile ERROR: source and destination file are the same"
    ProcedureReturn #CopyFile_Error_SameFiles
  EndIf
      
  *copy_buffer = AllocateMemory(#CopyFile_BufferSize)
  If *copy_buffer = 0
    Debug "CopyFile ERROR: can't allocate memory"
    ProcedureReturn #CopyFile_Error_AllocateMem
  EndIf
  
  src_crc = FileFingerprint(*job\sourceFile, #PB_Cipher_CRC32)
  If src_crc = #Null$
    Debug "CopyFile ERROR: can't get valid CRC32 fingerprint from source file"
    ProcedureReturn #CopyFile_Error_SrcCrcFailed
  EndIf
  
  src_h = ReadFile(#PB_Any, *job\sourceFile)
  If Not IsFile(src_h)
    Debug "CopyFile ERROR: can't open source file"
    ProcedureReturn #CopyFile_Error_CantReadSrc
  EndIf
  
  src_size = Lof(src_h)
  src_left = Lof(src_h) - Loc(src_h)
  percent  = src_size / 100
  
  dst_h = CreateFile(#PB_Any, *job\destFile)
  If Not IsFile(dst_h)
    CloseFile(src_h)
    Debug "CopyFile ERROR: can't create destination file"
    ProcedureReturn #CopyFile_Error_CantCreateDst
  EndIf
  
  start = ElapsedMilliseconds()
  
  While src_left
    
    If src_left >= #CopyFile_BufferSize
      
      ReadData(src_h, *copy_buffer, #CopyFile_BufferSize)
      WriteData(dst_h, *copy_buffer, #CopyFile_BufferSize)
      
    Else
      
      ReadData(src_h, *copy_buffer, src_left)
      WriteData(dst_h, *copy_buffer, src_left)
      
    EndIf
    
    src_left = Lof(src_h) - Loc(src_h)
    
    *job\progress = IntQ(Loc(src_h)/percent)
    *job\copied   = Loc(src_h)
    
  Wend
  
  CloseFile(src_h)
  FlushFileBuffers(dst_h)
  CloseFile(dst_h)
  
  FreeMemory(*copy_buffer)
  
  *job\duration = ElapsedMilliseconds() - start
  
  dst_crc = FileFingerprint(*job\destFile, #PB_Cipher_CRC32)
  If dst_crc = #Null$
    DeleteFile(*job\destFile)
    Debug "CopyFile ERROR: can't get valid CRC32 fingerprint from destination file"
    ProcedureReturn #CopyFile_Error_DstCrcFailed
  EndIf
    
  If CompareMemoryString(@src_crc, @dst_crc) <> #PB_String_Equal
    DeleteFile(*job\destFile)
    Debug "CopyFile ERROR: CRC32 fingerprint is not equal"
    ProcedureReturn #CopyFile_Error_CrcCheckFailed
  EndIf
    
  ProcedureReturn src_size
  
EndProcedure

Define.structCopyJob cj
Define.i copy_thread

cj\sourceFile = "testfile2.tif"
cj\destFile   = "copy_of_testfile2.tif"

copy_thread = CreateThread(@myCopyFile(), cj)

Repeat
  
  Debug Str(cj\progress) + " %"
  Delay(1)
  
Until IsThread(copy_thread) = 0

Debug "Job finished in "+StrF(cj\duration/1000,3)+" seconds."

; IDE Options = PureBasic 6.00 LTS (Windows - x64)
; CursorPosition = 100
; FirstLine = 71
; Folding = -
; EnableThread
; EnableXP
; EnableCompileCount = 4
; EnableBuildCount = 0
; EnableExeConstant