#include "NetworkStream.bi"
#include "AsyncResult.bi"
#include "ContainerOf.bi"
#include "CreateInstance.bi"
#include "PrintDebugInfo.bi"
#include "Network.bi"

Extern GlobalNetworkStreamVirtualTable As Const INetworkStreamVirtualTable

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Type _NetworkStream
	Dim lpVtbl As Const INetworkStreamVirtualTable Ptr
	Dim ReferenceCounter As Integer
	#ifndef WITHOUT_CRITICAL_SECTIONS
		Dim crSection As CRITICAL_SECTION
	#endif
	Dim pIMemoryAllocator As IMalloc Ptr
	Dim ClientSocket As SOCKET
End Type

Sub InitializeNetworkStream( _
		ByVal this As NetworkStream Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalNetworkStreamVirtualTable
	this->ReferenceCounter = 0
	#ifndef WITHOUT_CRITICAL_SECTIONS
		InitializeCriticalSectionAndSpinCount( _
			@this->crSection, _
			MAX_CRITICAL_SECTION_SPIN_COUNT _
		)
	#endif
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->ClientSocket = INVALID_SOCKET
	
End Sub

Sub UnInitializeNetworkStream( _
		ByVal this As NetworkStream Ptr _
	)
	
	If this->ClientSocket <> INVALID_SOCKET Then
		CloseSocketConnection(this->ClientSocket)
	End If
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		DeleteCriticalSection(@this->crSection)
	#endif
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateNetworkStream( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As NetworkStream Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"NetworkStream create\t")
	#endif
	
	Dim this As NetworkStream Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(NetworkStream) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeNetworkStream(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyNetworkStream( _
		ByVal this As NetworkStream Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeNetworkStream(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"NetworkStream destroyed\t")
	#endif
	
End Sub

Function NetworkStreamQueryInterface( _
		ByVal this As NetworkStream Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_INetworkStream, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IBaseStream, riid) Then
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
	
	NetworkStreamAddRef(this)
	
	Return S_OK
	
End Function

Function NetworkStreamAddRef( _
		ByVal this As NetworkStream Ptr _
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

Function NetworkStreamRelease( _
		ByVal this As NetworkStream Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter -= 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	If this->ReferenceCounter = 0 Then
		
		DestroyNetworkStream(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function NetworkStreamCanRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = True
	
	Return S_OK
	
End Function

Function NetworkStreamCanSeek( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = False
	
	Return S_OK
	
End Function

Function NetworkStreamCanWrite( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = True
	
	Return S_OK
	
End Function

Function NetworkStreamFlush( _
		ByVal this As NetworkStream Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function

Function NetworkStreamGetLength( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	*pResult = 0
	
	Return S_FALSE
	
End Function

Function NetworkStreamPosition( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	*pResult = 0
	
	Return S_FALSE
	
End Function

Function NetworkStreamRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As LongInt Ptr _
	)As HRESULT
	
	Dim ReadedBytes As Integer = recv(this->ClientSocket, buffer, Count, 0)
	
	Select Case ReadedBytes
		
		Case SOCKET_ERROR
			Dim intError As Integer = WSAGetLastError()
			*pReadedBytes = 0
			Return HRESULT_FROM_WIN32(intError)
			
		Case 0
			*pReadedBytes = 0
			Return S_FALSE
			
		Case Else
			*pReadedBytes = ReadedBytes
			Return S_OK
			
	End Select
	
End Function

Function NetworkStreamWrite( _
		ByVal this As NetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	
	Dim WritedBytes As Integer = send(this->ClientSocket, Buffer, Count, 0)
	
	If WritedBytes = SOCKET_ERROR Then	
		Dim intError As Integer = WSAGetLastError()
		*pWritedBytes = 0
		Return HRESULT_FROM_WIN32(intError)
	End If
	
	*pWritedBytes = WritedBytes
	
	Return S_OK
	
End Function

Function NetworkStreamSeek( _
		ByVal this As NetworkStream Ptr, _
		ByVal offset As LongInt, _
		ByVal origin As SeekOrigin _
	)As HRESULT
	
	Return S_FALSE
	
End Function

Function NetworkStreamSetLength( _
		ByVal this As NetworkStream Ptr, _
		ByVal length As LongInt _
	)As HRESULT
	
	Return S_FALSE
	
End Function

Function NetworkStreamBeginRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	*ppIAsyncResult = NULL
	
	Dim pINewAsyncResult As IMutableAsyncResult Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		this->pIMemoryAllocator, _
		@CLSID_ASYNCRESULT, _
		@IID_IMutableAsyncResult, _
		@pINewAsyncResult _
	)
	If FAILED(hr) Then
		Return E_OUTOFMEMORY
	End If
	
	Dim lpReceiveCompletionROUTINE As LPWSAOVERLAPPED_COMPLETION_ROUTINE = Any
	
	Dim lpRecvOverlapped As ASYNCRESULTOVERLAPPED Ptr = Any
	IMutableAsyncResult_GetWsaOverlapped(pINewAsyncResult, @lpRecvOverlapped)
	lpRecvOverlapped->pIAsync = CPtr(IAsyncResult Ptr, pINewAsyncResult)
	
	If callback = NULL Then
		' Const ManualReset As Boolean = True
		' Const NonsignaledState As Boolean = False
		
		' hEvent = NULL
		'hEvent = CreateEvent(NULL, ManualReset, NonsignaledState, NULL)
		'
		'If hEvent = NULL Then
		'	Dim dwError As DWORD = GetLastError()
		'	INetworkStreamAsyncResult_Release(pINewAsyncResult)
		'	
		'	Return HRESULT_FROM_WIN32(dwError)
		'End If
		
		' lpRecvOverlapped->hEvent = pINewAsyncResult ' WSACreateEvent()  WSACloseEvent()
		' INetworkStreamAsyncResult_SetWaitHandle(pINewAsyncResult, hEvent)
		lpReceiveCompletionROUTINE = NULL
	Else
		' TODO Реализовать для функции завершения ввода‐вывода
		' lpRecvOverlapped->hEvent = pINewAsyncResult
		lpReceiveCompletionROUTINE = NULL
	End If
	
	Dim ReceiveBuffer As WSABUF = Any
	ReceiveBuffer.len = Cast(ULONG, Count)
	ReceiveBuffer.buf = Buffer
	
	IMutableAsyncResult_SetAsyncState(pINewAsyncResult, StateObject)
	IMutableAsyncResult_SetAsyncCallback(pINewAsyncResult, callback)
	
	Const MaxReceiveBuffersCount As Integer = 1
	Const lpNumberOfBytesRecvd As LPDWORD = NULL
	Dim Flags As DWORD = 0
	
	Dim WSARecvResult As Long = WSARecv( _
		this->ClientSocket, _
		@ReceiveBuffer, _
		MaxReceiveBuffersCount, _
		lpNumberOfBytesRecvd, _
		@Flags, _
		CPtr(WSAOVERLAPPED Ptr, lpRecvOverlapped), _
		lpReceiveCompletionROUTINE _
	)
	If WSARecvResult <> 0 Then
		
		Dim intError As Long = WSAGetLastError()
		If intError <> WSA_IO_PENDING Then
			IMutableAsyncResult_Release(pINewAsyncResult)
			Return HRESULT_FROM_WIN32(intError)
		End If
		
		IMutableAsyncResult_SetCompletedSynchronously(pINewAsyncResult, False)
		*ppIAsyncResult = CPtr(IAsyncResult Ptr, pINewAsyncResult)
		
		Return BASESTREAM_S_IO_PENDING
	End If
	
	IMutableAsyncResult_SetCompletedSynchronously(pINewAsyncResult, True)
	*ppIAsyncResult = CPtr(IAsyncResult Ptr, pINewAsyncResult)
	
	Return S_OK
	
End Function

Function NetworkStreamEndRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pReadedBytes As Integer Ptr _
	)As HRESULT
	
	*pReadedBytes = 0
	
	Dim pINewAsyncResult As IMutableAsyncResult Ptr = CPtr(IMutableAsyncResult Ptr, pIAsyncResult)
	
	Dim lpRecvOverlapped As ASYNCRESULTOVERLAPPED Ptr = Any
	IMutableAsyncResult_GetWsaOverlapped(pINewAsyncResult, @lpRecvOverlapped)
	
	Const fNoWait As Boolean = False
	Dim cbTransfer As DWORD = Any
	Dim dwFlags As DWORD = Any
	
	Dim OverlappedResult As Integer = WSAGetOverlappedResult( _
		this->ClientSocket, _
		CPtr(WSAOVERLAPPED Ptr, lpRecvOverlapped), _
		@cbTransfer, _
		fNoWait, _
		@dwFlags _
	)
	If OverlappedResult = 0 Then
		
		Dim intError As Long = WSAGetLastError()
		
		If intError = WSA_IO_INCOMPLETE OrElse intError = WSA_IO_PENDING Then
			Return BASESTREAM_S_IO_PENDING
		End If
		
		Return HRESULT_FROM_WIN32(intError)
	End If
	
	*pReadedBytes = cbTransfer
	
	If cbTransfer = 0 Then
		Return S_FALSE
	End If
	
	Return S_OK
	
End Function

Function NetworkStreamGetSocket( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As SOCKET Ptr _
	)As HRESULT
	
	*pResult = this->ClientSocket
	
	Return S_OK
	
End Function
	
Function NetworkStreamSetSocket( _
		ByVal this As NetworkStream Ptr, _
		ByVal ClientSocket As SOCKET _
	)As HRESULT
	
	If this->ClientSocket <> INVALID_SOCKET Then
		CloseSocketConnection(this->ClientSocket)
	End If
	
	this->ClientSocket = ClientSocket
	
	Return S_OK
	
End Function

Function NetworkStreamClose( _
		ByVal this As NetworkStream Ptr _
	)As HRESULT
	
	If this->ClientSocket <> INVALID_SOCKET Then
		CloseSocketConnection(this->ClientSocket)
		this->ClientSocket = INVALID_SOCKET
	End If
	
	Return S_OK
	
End Function

' Function StartRecvOverlapped( _
		' ByVal this As NetworkStream Ptr _
	' )As HRESULT
	
	' memset(@pIrcClient->RecvOverlapped, 0, SizeOf(WSAOVERLAPPED))
	' pIrcClient->RecvOverlapped.hEvent = pIrcClient
	' pIrcClient->RecvBuf(0).len = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - pIrcClient->ClientRawBufferLength
	' pIrcClient->RecvBuf(0).buf = @pIrcClient->ClientRawBuffer[pIrcClient->ClientRawBufferLength]
	
	' Const lpNumberOfBytesRecvd As LPDWORD = NULL
	' Dim Flags As DWORD = 0
	
	' Dim WSARecvResult As Integer = WSARecv( _
		' pIrcClient->ClientSocket, _
		' @pIrcClient->RecvBuf(0), _
		' IrcClient.MaxReceivedBuffersCount, _
		' lpNumberOfBytesRecvd, _
		' @Flags, _
		' @pIrcClient->RecvOverlapped, _
		' @ReceiveCompletionROUTINE _
	' )
	
	' If WSARecvResult <> 0 Then
		
		' If WSAGetLastError() <> WSA_IO_PENDING Then
			' CloseIrcClient(pIrcClient)
			' Return E_FAIL
		' End If
		
	' End If
	
	' Return S_OK
	
' End Function


Function INetworkStreamQueryInterface( _
		ByVal this As INetworkStream Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return NetworkStreamQueryInterface(ContainerOf(this, NetworkStream, lpVtbl), riid, ppvObject)
End Function

Function INetworkStreamAddRef( _
		ByVal this As INetworkStream Ptr _
	)As ULONG
	Return NetworkStreamAddRef(ContainerOf(this, NetworkStream, lpVtbl))
End Function

Function INetworkStreamRelease( _
		ByVal this As INetworkStream Ptr _
	)As ULONG
	Return NetworkStreamRelease(ContainerOf(this, NetworkStream, lpVtbl))
End Function

Function INetworkStreamCanRead( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	Return NetworkStreamCanRead(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamCanSeek( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	Return NetworkStreamCanSeek(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamCanWrite( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	Return NetworkStreamCanWrite(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamFlush( _
		ByVal this As INetworkStream Ptr _
	)As HRESULT
	Return NetworkStreamFlush(ContainerOf(this, NetworkStream, lpVtbl))
End Function

Function INetworkStreamGetLength( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	Return NetworkStreamGetLength(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamPosition( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	Return NetworkStreamPosition(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamRead( _
		ByVal this As INetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As Integer Ptr _
	)As HRESULT
	Return NetworkStreamRead(ContainerOf(this, NetworkStream, lpVtbl), Buffer, Count, pReadedBytes)
End Function

Function INetworkStreamSeek( _
		ByVal this As INetworkStream Ptr, _
		ByVal Offset As LongInt, _
		ByVal Origin As SeekOrigin _
	)As HRESULT
	Return NetworkStreamSeek(ContainerOf(this, NetworkStream, lpVtbl), Offset, Origin)
End Function

Function INetworkStreamSetLength( _
		ByVal this As INetworkStream Ptr, _
		ByVal Length As LongInt _
	)As HRESULT
	Return NetworkStreamSetLength(ContainerOf(this, NetworkStream, lpVtbl), Length)
End Function

Function INetworkStreamWrite( _
		ByVal this As INetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	Return NetworkStreamWrite(ContainerOf(this, NetworkStream, lpVtbl), Buffer, Count, pWritedBytes)
End Function

Function INetworkStreamBeginRead( _
		ByVal this As INetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Count As Integer, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	Return NetworkStreamBeginRead(ContainerOf(this, NetworkStream, lpVtbl), Buffer, Count, callback, StateObject, ppIAsyncResult)
End Function

' Function INetworkStreamBeginWrite( _
		' ByVal this As INetworkStream Ptr, _
		' ByVal Buffer As UByte Ptr, _
		' ByVal Count As Integer, _
		' ByVal callback As AsyncCallback, _
		' ByVal StateObject As IUnknown Ptr, _
		' ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	' )As HRESULT
' End Function

Function INetworkStreamEndRead( _
		ByVal this As INetworkStream Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pReadedBytes As Integer Ptr _
	)As HRESULT
	Return NetworkStreamEndRead(ContainerOf(this, NetworkStream, lpVtbl), pIAsyncResult, pReadedBytes)
End Function

' Function INetworkStreamEndWrite( _
		' ByVal this As INetworkStream Ptr, _
		' ByVal pIAsyncResult As IAsyncResult Ptr, _
		' ByVal pWritedBytes As Integer Ptr _
	' )As HRESULT
' End Function

Function INetworkStreamGetSocket( _
		ByVal this As INetworkStream Ptr, _
		ByVal pResult As SOCKET Ptr _
	)As HRESULT
	Return NetworkStreamGetSocket(ContainerOf(this, NetworkStream, lpVtbl), pResult)
End Function

Function INetworkStreamSetSocket( _
		ByVal this As INetworkStream Ptr, _
		ByVal sock As SOCKET _
	)As HRESULT
	Return NetworkStreamSetSocket(ContainerOf(this, NetworkStream, lpVtbl), sock)
End Function

Function INetworkStreamClose( _
		ByVal this As INetworkStream Ptr _
	)As HRESULT
	Return NetworkStreamClose(ContainerOf(this, NetworkStream, lpVtbl))
End Function

Dim GlobalNetworkStreamVirtualTable As Const INetworkStreamVirtualTable = Type( _
	@INetworkStreamQueryInterface, _
	@INetworkStreamAddRef, _
	@INetworkStreamRelease, _
	@INetworkStreamCanRead, _
	@INetworkStreamCanSeek, _
	@INetworkStreamCanWrite, _
	@INetworkStreamFlush, _
	@INetworkStreamGetLength, _
	@INetworkStreamPosition, _
	@INetworkStreamRead, _
	@INetworkStreamSeek, _
	@INetworkStreamSetLength, _
	@INetworkStreamWrite, _
	@INetworkStreamBeginRead, _
	NULL, _ /' INetworkStreamBeginWrite '/
	@INetworkStreamEndRead, _
	NULL, _ /' INetworkStreamEndWrite '/
	@INetworkStreamGetSocket, _
	@INetworkStreamSetSocket, _
	@INetworkStreamClose _
)
