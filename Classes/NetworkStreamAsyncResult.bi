#ifndef NETWORKSTREAMASYNCRESULT_BI
#define NETWORKSTREAMASYNCRESULT_BI

#include "INetworkStreamAsyncResult.bi"

Extern CLSID_NETWORKSTREAMASYNCRESULT Alias "CLSID_NETWORKSTREAMASYNCRESULT" As Const CLSID

Type NetworkStreamAsyncResult As _NetworkStreamAsyncResult

Type LPNetworkStreamAsyncResult As _NetworkStreamAsyncResult Ptr

Declare Function CreateNetworkStreamAsyncResult( _
	ByVal pIMemoryAllocator As IMalloc Ptr _
)As NetworkStreamAsyncResult Ptr

Declare Sub DestroyNetworkStreamAsyncResult( _
	ByVal this As NetworkStreamAsyncResult Ptr _
)

Declare Function NetworkStreamAsyncResultQueryInterface( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal riid As REFIID, _
	ByVal ppvObject As Any Ptr Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultAddRef( _
	ByVal this As NetworkStreamAsyncResult Ptr _
)As ULONG

Declare Function NetworkStreamAsyncResultRelease( _
	ByVal this As NetworkStreamAsyncResult Ptr _
)As ULONG

Declare Function NetworkStreamAsyncResultGetAsyncState( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal ppState As IUnknown Ptr Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultGetWaitHandle( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal pWaitHandle As HANDLE Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultGetCompletedSynchronously( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal pCompletedSynchronously As Boolean Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultSetAsyncState( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal pState As IUnknown Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultSetWaitHandle( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal WaitHandle As HANDLE _
)As HRESULT

Declare Function NetworkStreamAsyncResultSetCompletedSynchronously( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal CompletedSynchronously As Boolean _
)As HRESULT

Declare Function NetworkStreamAsyncResultGetAsyncCallback( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal pcallback As AsyncCallback Ptr _
)As HRESULT

Declare Function NetworkStreamAsyncResultSetAsyncCallback( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal callback As AsyncCallback _
)As HRESULT

Declare Function NetworkStreamAsyncResultGetWsaOverlapped( _
	ByVal this As NetworkStreamAsyncResult Ptr, _
	ByVal ppRecvOverlapped As LPASYNCRESULTOVERLAPPED Ptr _
)As HRESULT

#endif
