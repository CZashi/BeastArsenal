INT HideProcInvertPtr(VOID)
{
    PLDR_DATA_TABLE_ENTRY pLdm;
    PPEB_LDR_DATA         pLdr;
    PLIST_ENTRY           pBack;   
    PLIST_ENTRY           pNext;
  
    HMODULE hMod = GetModuleHandleA("ntdll.dll");
  
#ifdef CODE_ASM_X64
    _asm
    {
        mov eax, gs: [0x60] ;　　　　　　　　　
        mov eax, [eax + 0x18];
        mov pLdr, eax;
    }
#endif
    PPEB pLdr = NtCurrentTeb()->Peb->Ldr;

    pBack = &(pLdr->InLoadOrderModuleList);         
    pNext = pBack->Flink;
  
    do
    {
        pLdm = CONTAINING_RECORD(pNext, LDR_DATA_TABLE_ENTRY, InLoadOrderModuleList); 

        if (hMod == pLdm->BaseAddress)                                    
        {                                             
            pLdm->InLoadOrderModuleList.Blink->Flink = pLdm->InLoadOrderModuleList.Flink;
            pLdm->InLoadOrderModuleList.Flink->Blink = pLdm->InLoadOrderModuleList.Blink;

            pLdm->InInitializationOrderModuleList.Blink->Flink = pLdm->InInitializationOrderModuleList.Flink;
            pLdm->InInitializationOrderModuleList.Flink->Blink = pLdm->InInitializationOrderModuleList.Blink;

            pLdm->InMemoryOrderModuleList.Blink->Flink = pLdm->InMemoryOrderModuleList.Flink;
            pLdm->InMemoryOrderModuleList.Flink->Blink = pLdm->InMemoryOrderModuleList.Blink;
            break;
        }
      
        pNext = pNext->Flink;
      
    } while (pBack != pNext);

    return 0;
}
