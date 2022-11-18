// use CSRSS to send msg

NTSTATUS WINAPI CSRSSCreateThreadRequest(IN HANDLE ThreadHandle, IN PCLIENT_ID ClientId)
{
    BASE_API_MESSAGE ApiMessage;
    PBASE_CREATE_THREAD CreateThreadRequest = &ApiMessage.Data.CreateThreadRequest;

    CreateThreadRequest->ClientId = *ClientId;
    CreateThreadRequest->ThreadHandle = ThreadHandle;

    CsrClientCallServer((PCSR_API_MESSAGE)&ApiMessage,
                        NULL,
                        CSR_CREATE_API_NUMBER(BASESRV_SERVERDLL_INDEX, BasepCreateThread),
                        sizeof(*CreateThreadRequest));
                        
    return STATUS_SUCCESS;
}
