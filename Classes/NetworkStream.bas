#include "NetworkStream.bi"
#include "Network.bi"

Common Shared GlobalNetworkStreamVirtualTable As INetworkStreamVirtualTable

Sub InitializeNetworkStream( _
		ByVal pStream As NetworkStream Ptr _
	)
	
	pStream->pVirtualTable = @GlobalNetworkStreamVirtualTable
	pStream->ReferenceCounter = 0
	pStream->m_Socket = INVALID_SOCKET
	
End Sub

Function InitializeNetworkStreamOfINetworkStream( _
		ByVal pStream As NetworkStream Ptr _
	)As INetworkStream Ptr
	
	InitializeNetworkStream(pStream)
	pStream->ExistsInStack = True
	
	Dim pINetworkStream As INetworkStream Ptr = Any
	
	NetworkStreamQueryInterface( _
		pStream, @IID_INETWORKSTREAM, @pINetworkStream _
	)
	
	Return pINetworkStream
	
End Function

Function NetworkStreamQueryInterface( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, @pNetworkStream->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_IBASESTREAM, riid) Then
		*ppv = CPtr(IBaseStream Ptr, @pNetworkStream->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_INETWORKSTREAM, riid) Then
		*ppv = CPtr(INetworkStream Ptr, @pNetworkStream->pVirtualTable)
	End If
	
	If *ppv = 0 Then
		Return E_NOINTERFACE
	End If
	
	NetworkStreamAddRef(pNetworkStream)
	
	Return S_OK
	
End Function

Function NetworkStreamAddRef( _
		ByVal pNetworkStream As NetworkStream Ptr _
	)As ULONG
	
	Return InterlockedIncrement(@pNetworkStream->ReferenceCounter)
	
End Function

Function NetworkStreamRelease( _
		ByVal pNetworkStream As NetworkStream Ptr _
	)As ULONG
	
	InterlockedDecrement(@pNetworkStream->ReferenceCounter)
	
	If pNetworkStream->ReferenceCounter = 0 Then
		
		CloseSocketConnection(pNetworkStream->m_Socket)
		
		If pNetworkStream->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pNetworkStream->ReferenceCounter
	
End Function

Function NetworkStreamCanRead( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = True
	
	Return S_OK
	
End Function

Function NetworkStreamCanSeek( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = False
	
	Return S_OK
	
End Function

Function NetworkStreamCanWrite( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	*pResult = True
	
	Return S_OK
	
End Function

Function NetworkStreamCloseStream( _
		ByVal pNetworkStream As NetworkStream Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function

Function NetworkStreamFlush( _
		ByVal pNetworkStream As NetworkStream Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function

Function NetworkStreamGetLength( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	*pResult = 0
	
	Return S_FALSE
	
End Function

Function NetworkStreamOpenStream( _
		ByVal pNetworkStream As NetworkStream Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function

Function NetworkStreamPosition( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	*pResult = 0
	
	Return S_FALSE
	
End Function

Function NetworkStreamRead( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As LongInt Ptr _
	)As HRESULT
	
	Dim ReadedBytes As Integer = recv(pNetworkStream->m_Socket, @buffer[offset], Count, 0)
	
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
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal Buffer As UByte Ptr, _
		ByVal Offset As Integer, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	
	Dim WritedBytes As Integer = send(pNetworkStream->m_Socket, @Buffer[Offset], Count - Offset, 0)
	
	If WritedBytes = SOCKET_ERROR Then	
		Dim intError As Integer = WSAGetLastError()
		*pWritedBytes = 0
		Return HRESULT_FROM_WIN32(intError)
	End If
	
	*pWritedBytes = WritedBytes
	
	Return S_OK
	
End Function

Function NetworkStreamSeek( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal offset As LongInt, _
		ByVal origin As SeekOrigin _
	)As HRESULT
	
	Return S_FALSE
	
End Function

Function NetworkStreamSetLength( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal length As LongInt _
	)As HRESULT
	
	Return S_FALSE
	
End Function

Function NetworkStreamGetSocket( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal pResult As SOCKET Ptr _
	)As HRESULT
	
	*pResult = pNetworkStream->m_Socket
	
	Return S_OK
	
End Function
	
Function NetworkStreamSetSocket( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal sock As SOCKET _
	)As HRESULT
	
	pNetworkStream->m_Socket = sock
	
	Return S_OK
	
End Function
