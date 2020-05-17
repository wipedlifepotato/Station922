#include "NetworkStream.bi"
#include "ContainerOf.bi"
#include "Network.bi"

Extern GlobalNetworkStreamVirtualTable As Const INetworkStreamVirtualTable

Type _NetworkStream
	Dim lpVtbl As Const INetworkStreamVirtualTable Ptr
	Dim ReferenceCounter As Integer
	Dim hHeap As HANDLE
	
	Dim m_Socket As SOCKET
	
End Type

Sub InitializeNetworkStream( _
		ByVal this As NetworkStream Ptr, _
		ByVal hHeap As HANDLE _
	)
	
	this->lpVtbl = @GlobalNetworkStreamVirtualTable
	this->ReferenceCounter = 0
	this->m_Socket = INVALID_SOCKET
	this->hHeap = hHeap
	
End Sub

Sub UnInitializeNetworkStream( _
		ByVal this As NetworkStream Ptr _
	)
	
	If this->m_Socket <> INVALID_SOCKET Then
		CloseSocketConnection(this->m_Socket)
	End If
	
End Sub

Function CreateNetworkStream( _
		ByVal hHeap As HANDLE _
	)As NetworkStream Ptr
	
	Dim this As NetworkStream Ptr = HeapAlloc( _
		hHeap, _
		HEAP_NO_SERIALIZE, _
		SizeOf(NetworkStream) _
	)
	
	If this = NULL Then
		Return NULL
	End If
	
	InitializeNetworkStream(this, hHeap)
	
	Return this
	
End Function

Sub DestroyNetworkStream( _
		ByVal this As NetworkStream Ptr _
	)
	
	UnInitializeNetworkStream(this)
	
	HeapFree(this->hHeap, HEAP_NO_SERIALIZE, this)
	
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
	
	this->ReferenceCounter += 1
	
	Return 1
	
End Function

Function NetworkStreamRelease( _
		ByVal this As NetworkStream Ptr _
	)As ULONG
	
	this->ReferenceCounter -= 1
	
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

Function StartRecvOverlapped( _
		ByVal this As NetworkStream Ptr _
	)As HRESULT
	
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
	
	Return S_OK
	
End Function

Function NetworkStreamRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As LongInt Ptr _
	)As HRESULT
	
	Dim ReadedBytes As Integer = recv(this->m_Socket, @buffer[offset], Count, 0)
	
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
		ByVal Offset As Integer, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	
	Dim WritedBytes As Integer = send(this->m_Socket, @Buffer[Offset], Count - Offset, 0)
	
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

Function NetworkStreamGetSocket( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As SOCKET Ptr _
	)As HRESULT
	
	*pResult = this->m_Socket
	
	Return S_OK
	
End Function
	
Function NetworkStreamSetSocket( _
		ByVal this As NetworkStream Ptr, _
		ByVal sock As SOCKET _
	)As HRESULT
	
	If this->m_Socket <> INVALID_SOCKET Then
		CloseSocketConnection(this->m_Socket)
	End If
	
	this->m_Socket = sock
	
	Return S_OK
	
End Function

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
		ByVal Offset As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As Integer Ptr _
	)As HRESULT
	Return NetworkStreamRead(ContainerOf(this, NetworkStream, lpVtbl), Buffer, Offset, Count, pReadedBytes)
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
		ByVal Offset As Integer, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	Return NetworkStreamWrite(ContainerOf(this, NetworkStream, lpVtbl), Buffer, Offset, Count, pWritedBytes)
End Function

' Function INetworkStreamBeginRead( _
		' ByVal this As INetworkStream Ptr, _
		' ByVal Buffer As UByte Ptr, _
		' ByVal Offset As Integer, _
		' ByVal Count As Integer, _
		' ByVal callback As AsyncCallback, _
		' ByVal StateObject As IUnknown Ptr, _
		' ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	' )As HRESULT
' End Function

' Function INetworkStreamBeginWrite( _
		' ByVal this As INetworkStream Ptr, _
		' ByVal Buffer As UByte Ptr, _
		' ByVal Offset As Integer, _
		' ByVal Count As Integer, _
		' ByVal callback As AsyncCallback, _
		' ByVal StateObject As IUnknown Ptr, _
		' ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	' )As HRESULT
' End Function

' Function INetworkStreamEndRead( _
		' ByVal this As INetworkStream Ptr, _
		' ByVal pIAsyncResult As IAsyncResult Ptr, _
		' ByVal pReadedBytes As Integer Ptr _
	' )As HRESULT
' End Function

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
	NULL, _ /' BeginRead '/
	NULL, _ /' BeginWrite '/
	NULL, _ /' EndRead '/
	NULL, _ /' EndWrite '/
	@INetworkStreamGetSocket, _
	@INetworkStreamSetSocket _
)
