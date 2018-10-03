#include "NetworkStream.bi"

Common Shared GlobalNetworkStreamVirtualTable As INetworkStreamVirtualTable

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

Function NetworkStreamCloseStream( _
		ByVal this As NetworkStream Ptr _
	)As HRESULT
	
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
	Return S_OK
End Function

Function NetworkStreamOpenStream( _
		ByVal this As NetworkStream Ptr _
	)As HRESULT
	
	Return S_OK
End Function

Function NetworkStreamPosition( _
		ByVal this As NetworkStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	*pResult = 0
	Return S_OK
End Function

Function NetworkStreamRead( _
		ByVal this As NetworkStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As LongInt Ptr _
	)As HRESULT
	
	*pReadedBytes = recv(this->m_Socket, @buffer[offset], Count, 0)
	Return S_OK
End Function

Function NetworkStreamWrite( _
		ByVal this As NetworkStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	
	*pWritedBytes = send(this->m_Socket, buffer, Count - offset, 0)
	
	Return S_OK
End Function

Function NetworkStreamSeek( _
		ByVal this As NetworkStream Ptr, _
		ByVal offset As LongInt, _
		ByVal origin As SeekOrigin _
	)As HRESULT
	
	Return S_OK
End Function

Function NetworkStreamSetLength( _
		ByVal this As NetworkStream Ptr, _
		ByVal length As LongInt _
	)As HRESULT
	
	Return S_OK
End Function

Sub InitializeNetworkStream( _
		ByVal pNetworkStream As NetworkStream Ptr, _
		ByVal mSock As SOCKET _
	)
	pNetworkStream->pVirtualTable = @GlobalNetworkStreamVirtualTable
	pNetworkStream->ReferenceCounter = 1
	pNetworkStream->m_Socket = mSock
End Sub
