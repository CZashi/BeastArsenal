Private Function LdrAddress()
    Dim ret As Long
    Dim size As LongPtr
    Dim pbi As PROCESS_BASIC_INFORMATION
    Dim cPEB As PEB
       
    ret = NtQueryInformationProcess(-1, 0, pbi, LenB(pbi), size)
    Call CopyMemory(VarPtr(cPEB), pbi.PEBBaseAddress, LenB(cPEB))
    LdrAddress = cPEB.Ldr
  
End Function

Private Function FindNtdll()
    Dim InLoadOrderModuleList As LongPtr
    Dim currentEntry As LongPtr
    Dim nextEntry As LongPtr
    Dim dllbase As LongPtr
    Dim DllNamePtr As LongPtr
    Dim DllName As String
    Dim currentDllBase As LongPtr
    Dim Ldr As LongPtr
    Dim row As Integer

    Ldr = LdrAddress
    Call CopyMemory(VarPtr(InLoadOrderModuleList), LdrAddress + &H18, LenB(InLoadOrderModuleList))
    Call CopyMemory(VarPtr(dllbase), InLoadOrderModuleList + &H30, LenB(dllbase))
    
    currentEntry = InLoadOrderModuleList
    Do Until nextEntry = InLoadOrderModuleList
        Call CopyMemory(VarPtr(nextEntry), currentEntry, LenB(nextEntry))
        Call CopyMemory(VarPtr(dllbase), currentEntry + &H30, LenB(dllbase))
        Call CopyMemory(VarPtr(DllNamePtr), currentEntry + &H58 + 8, LenB(DllNamePtr)) 'UNICODE_STRING USHORT + USHORT = 8
        DllName = StringFromPointerW(DllNamePtr)
        
        If StrComp("ntdll.dll", DllName, 0) = 0 Then
            Exit Do
        End If
        currentEntry = nextEntry
    Loop
    FindNtdll = dllbase
    
End Function

Sub VBCall()
    Dim dllbase As LongPtr
    Dim DosHeader As IMAGE_DOS_HEADER
    Dim pNtHeaders As LongPtr
    Dim ntHeader As IMAGE_NT_HEADERS
    Dim DataDirectory As IMAGE_DATA_DIRECTORY
    Dim IMAGE_EXPORT_DIRECTORY As LongPtr 
    Dim NumberOfFunctions As Long
    Dim NumberOfNames As Long
    Dim FunctionsPtr As LongPtr
    Dim NamesPtr As LongPtr
    Dim OrdinalsPtr As LongPtr
    Dim FunctionsOffset As Long
    Dim NamesOffset As Long
    Dim OrdinalsOffset As Long
    Dim OrdinalBase As Long
    

    dllbase = FindNtdll
    Call CopyMemory(VarPtr(DosHeader), dllbase, LenB(DosHeader))
    
    pNtHeaders = dllbase + DosHeader.e_lfanew
    Call CopyMemory(VarPtr(ntHeader), pNtHeaders, LenB(ntHeader))
    
    IMAGE_EXPORT_DIRECTORY = ntHeader.OptionalHeader.DataDirectory(0).VirtualAddress + dllbase
    
    Call CopyMemory(VarPtr(NumberOfFunctions), IMAGE_EXPORT_DIRECTORY + &H14, LenB(NumberOfFunctions))
    Call CopyMemory(VarPtr(NumberOfNames), IMAGE_EXPORT_DIRECTORY + &H18, LenB(NumberOfNames))
    Call CopyMemory(VarPtr(FunctionsOffset), IMAGE_EXPORT_DIRECTORY + &H1C, LenB(FunctionsOffset))
    FunctionsPtr = dllbase + FunctionsOffset

    Call CopyMemory(VarPtr(NamesOffset), IMAGE_EXPORT_DIRECTORY + &H20, LenB(NamesOffset))
    NamesPtr = dllbase + NamesOffset
    
    Call CopyMemory(VarPtr(OrdinalsOffset), IMAGE_EXPORT_DIRECTORY + &H24, LenB(OrdinalsOffset))
    OrdinalsPtr = dllbase + OrdinalsOffset
    
    Call CopyMemory(VarPtr(OrdinalBase), IMAGE_EXPORT_DIRECTORY + &H10, LenB(OrdinalBase))
    
    Dim j As Long
    Dim i As Long
    j = 0
    For i = 0 To NumberOfNames - 1
        Dim tmpOffset As Long
        Dim tmpName As String
        Dim tmpOrd As Integer

        Call CopyMemory(VarPtr(tmpOffset), NamesPtr + (LenB(tmpOffset) * i), LenB(tmpOffset))
        tmpName = StringFromPointerA(tmpOffset + dllbase)
        If InStr(1, tmpName, "Zw") = 1 Then
            Cells(j + 1, 1) = Replace(tmpName, "Zw", "Nt")

            Call CopyMemory(VarPtr(tmpOrd), OrdinalsPtr + (LenB(tmpOrd) * i), LenB(tmpOrd))
            Cells(j + 1, 2) = tmpOrd + OrdinalBase

            tmpOffset = 0
            Call CopyMemory(VarPtr(tmpOffset), FunctionsPtr + (LenB(tmpOffset) * tmpOrd), LenB(tmpOffset))
            Cells(j + 1, 3) = tmpOffset
            j = j + 1
        End If
    Next i

    Range("A1:C" & j).Sort , Key1:=Range("C1"), Order1:=xlAscending

    For k = 0 To j - 1
        Cells(k + 1, 2) = k
        Cells(k + 1, 3) = ""
    Next k
    
End Sub
