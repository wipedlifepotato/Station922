#include "AsyncResult.bi"
#include "ContainerOf.bi"
#include "PrintDebugInfo.bi"

Extern GlobalMutableAsyncResultVirtualTable As Const IMutableAsyncResultVirtualTable

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Type _AsyncResult
	Dim lpVtbl As Const IMutableAsyncResultVirtualTable Ptr
	Dim ReferenceCounter As Integer
	#ifndef WITHOUT_CRITICAL_SECTIONS
		Dim crSection As CRITICAL_SECTION
	#endif
	Dim pIMemoryAllocator As IMalloc Ptr
	Dim pState As IUnknown Ptr
	Dim callback As AsyncCallback
	Dim WaitHandle As HANDLE
	Dim OverLap As ASYNCRESULTOVERLAPPED
	Dim CompletedSynchronously As Boolean
End Type

Sub InitializeAsyncResult( _
		ByVal this As AsyncResult Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalMutableAsyncResultVirtualTable
	this->ReferenceCounter = 0
	#ifndef WITHOUT_CRITICAL_SECTIONS
		InitializeCriticalSectionAndSpinCount( _
			@this->crSection, _
			MAX_CRITICAL_SECTION_SPIN_COUNT _
		)
	#endif
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->pState = NULL
	this->callback = NULL
	this->WaitHandle = NULL
	ZeroMemory(@this->OverLap, SizeOf(WSAOVERLAPPED))
	this->CompletedSynchronously = False
	
End Sub

Sub UnInitializeAsyncResult( _
		ByVal this As AsyncResult Ptr _
	)
	
	If this->pState <> NULL Then
		IUnknown_Release(this->pState)
	End If
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		DeleteCriticalSection(@this->crSection)
	#endif
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateAsyncResult( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As AsyncResult Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"AsyncResult create\t")
	#endif
	
	Dim this As AsyncResult Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(AsyncResult) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeAsyncResult(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyAsyncResult( _
		ByVal this As AsyncResult Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeAsyncResult(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"AsyncResult destroyed\t")
	#endif
	
End Sub


Function AsyncResultQueryInterface( _
		ByVal this As AsyncResult Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IMutableAsyncResult, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IAsyncResult, riid) Then
			*ppv = @this->lpVtbl
		Else
			If IsEqualIID(@IID_IUnknown, riid) Then
				*ppv = @this->lpVtbl
			Else
				*ppv = NULL
				Return E_NOINTERFACE
			End If
		End If
	End If
	
	AsyncResultAddRef(this)
	
	Return S_OK
	
End Function

Function AsyncResultAddRef( _
		ByVal this As AsyncResult Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter += 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	Return 1
	
End Function

Function AsyncResultRelease( _
		ByVal this As AsyncResult Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter -= 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	If this->ReferenceCounter = 0 Then
		
		DestroyAsyncResult(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function AsyncResultGetAsyncState( _
		ByVal this As AsyncResult Ptr, _
		ByVal ppState As IUnknown Ptr Ptr _
	)As HRESULT
	
	If this->pState <> NULL Then
		IUnknown_AddRef(this->pState)
	End If
	
	*ppState = this->pState
	
	Return S_OK
	
End Function

Function AsyncResultGetWaitHandle( _
		ByVal this As AsyncResult Ptr, _
		ByVal pWaitHandle As HANDLE Ptr _
	)As HRESULT
	
	*pWaitHandle = this->WaitHandle
	
	Return S_OK
	
End Function

Function AsyncResultGetCompletedSynchronously( _
		ByVal this As AsyncResult Ptr, _
		ByVal pCompletedSynchronously As Boolean Ptr _
	)As HRESULT
	
	*pCompletedSynchronously = this->CompletedSynchronously
	
	Return S_OK
	
End Function

Function AsyncResultSetAsyncState( _
		ByVal this As AsyncResult Ptr, _
		ByVal pState As IUnknown Ptr _
	)As HRESULT
	
	If this->pState <> NULL Then
		IUnknown_Release(this->pState)
	End If
	
	If pState <> NULL Then
		IUnknown_AddRef(pState)
	End If
	
	this->pState = pState
	
	Return S_OK
	
End Function

Function AsyncResultSetWaitHandle( _
		ByVal this As AsyncResult Ptr, _
		ByVal WaitHandle As HANDLE _
	)As HRESULT
	
	this->WaitHandle = WaitHandle
	
	Return S_OK
	
End Function

Function AsyncResultSetCompletedSynchronously( _
		ByVal this As AsyncResult Ptr, _
		ByVal CompletedSynchronously As Boolean _
	)As HRESULT
	
	this->CompletedSynchronously = CompletedSynchronously
	
	Return S_OK
	
End Function

Function AsyncResultGetAsyncCallback( _
		ByVal this As AsyncResult Ptr, _
		ByVal pcallback As AsyncCallback Ptr _
	)As HRESULT
	
	*pcallback = this->callback
	
	Return S_OK
	
End Function

Function AsyncResultSetAsyncCallback( _
		ByVal this As AsyncResult Ptr, _
		ByVal callback As AsyncCallback _
	)As HRESULT
	
	this->callback = callback
	
	Return S_OK
	
End Function

Function AsyncResultGetWsaOverlapped( _
		ByVal this As AsyncResult Ptr, _
		ByVal ppRecvOverlapped As LPASYNCRESULTOVERLAPPED Ptr _
	)As HRESULT
	
	*ppRecvOverlapped = @this->OverLap
	
	Return S_OK
	
End Function


Function IMutableAsyncResultQueryInterface( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return AsyncResultQueryInterface(ContainerOf(this, AsyncResult, lpVtbl), riid, ppvObject)
End Function

Function IMutableAsyncResultAddRef( _
		ByVal this As IMutableAsyncResult Ptr _
	)As HRESULT
	Return AsyncResultAddRef(ContainerOf(this, AsyncResult, lpVtbl))
End Function

Function IMutableAsyncResultRelease( _
		ByVal this As IMutableAsyncResult Ptr _
	)As HRESULT
	Return AsyncResultRelease(ContainerOf(this, AsyncResult, lpVtbl))
End Function

Function IMutableAsyncResultGetAsyncState( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal ppState As IUnknown Ptr Ptr _
	)As HRESULT
	Return AsyncResultGetAsyncState(ContainerOf(this, AsyncResult, lpVtbl), ppState)
End Function

Function IMutableAsyncResultGetWaitHandle( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal pWaitHandle As HANDLE Ptr _
	)As HRESULT
	Return AsyncResultGetWaitHandle(ContainerOf(this, AsyncResult, lpVtbl), pWaitHandle)
End Function

Function IMutableAsyncResultGetCompletedSynchronously( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal pCompletedSynchronously As Boolean Ptr _
	)As HRESULT
	Return AsyncResultGetCompletedSynchronously(ContainerOf(this, AsyncResult, lpVtbl), pCompletedSynchronously)
End Function

Function IMutableAsyncResultSetAsyncState( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal pState As IUnknown Ptr _
	)As HRESULT
	Return AsyncResultSetAsyncState(ContainerOf(this, AsyncResult, lpVtbl), pState)
End Function

Function IMutableAsyncResultSetWaitHandle( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal WaitHandle As HANDLE _
	)As HRESULT
	Return AsyncResultSetWaitHandle(ContainerOf(this, AsyncResult, lpVtbl), WaitHandle)
End Function

Function IMutableAsyncResultSetCompletedSynchronously( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal CompletedSynchronously As Boolean _
	)As HRESULT
	Return AsyncResultSetCompletedSynchronously(ContainerOf(this, AsyncResult, lpVtbl), CompletedSynchronously)
End Function

Function IMutableAsyncResultGetAsyncCallback( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal pcallback As AsyncCallback Ptr _
	)As HRESULT
	Return AsyncResultGetAsyncCallback(ContainerOf(this, AsyncResult, lpVtbl), pcallback)
End Function

Function IMutableAsyncResultSetAsyncCallback( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal callback As AsyncCallback _
	)As HRESULT
	Return AsyncResultSetAsyncCallback(ContainerOf(this, AsyncResult, lpVtbl), callback)
End Function

Function IMutableAsyncResultGetWsaOverlapped( _
		ByVal this As IMutableAsyncResult Ptr, _
		ByVal ppRecvOverlapped As LPASYNCRESULTOVERLAPPED Ptr _
	)As HRESULT
	Return AsyncResultGetWsaOverlapped(ContainerOf(this, AsyncResult, lpVtbl), ppRecvOverlapped)
End Function

Dim GlobalMutableAsyncResultVirtualTable As Const IMutableAsyncResultVirtualTable = Type( _
	@IMutableAsyncResultQueryInterface, _
	@IMutableAsyncResultAddRef, _
	@IMutableAsyncResultRelease, _
	@IMutableAsyncResultGetAsyncState, _
	@IMutableAsyncResultGetWaitHandle, _
	@IMutableAsyncResultGetCompletedSynchronously, _
	@IMutableAsyncResultSetAsyncState, _
	@IMutableAsyncResultSetWaitHandle, _
	@IMutableAsyncResultSetCompletedSynchronously, _
	@IMutableAsyncResultGetAsyncCallback, _
	@IMutableAsyncResultSetAsyncCallback, _
	@IMutableAsyncResultGetWsaOverlapped _
)
