#ifndef NETWORKSTREAM_BI
#define NETWORKSTREAM_BI

#include "INetworkStream.bi"
#include once "win\winsock2.bi"

Type NetworkStream
	Dim pVirtualTable As INetworkStreamVirtualTable Ptr
	Dim ReferenceCounter As ULONG
	Dim m_Socket As SOCKET
End Type

Declare Function NetworkStreamCanRead( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As Boolean Ptr _
)As HRESULT

Declare Function NetworkStreamCanSeek( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As Boolean Ptr _
)As HRESULT

Declare Function NetworkStreamCanWrite( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As Boolean Ptr _
)As HRESULT

Declare Function NetworkStreamCloseStream( _
	ByVal this As NetworkStream Ptr _
)As HRESULT

Declare Function NetworkStreamFlush( _
	ByVal this As NetworkStream Ptr _
)As HRESULT

Declare Function NetworkStreamGetLength( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As LongInt Ptr _
)As HRESULT

Declare Function NetworkStreamOpenStream( _
	ByVal this As NetworkStream Ptr _
)As HRESULT

Declare Function NetworkStreamPosition( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As LongInt Ptr _
)As HRESULT

Declare Function NetworkStreamRead( _
	ByVal this As NetworkStream Ptr, _
	ByVal buffer As UByte Ptr, _
	ByVal offset As Integer, _
	ByVal Count As Integer, _
	ByVal pReadedBytes As LongInt Ptr _
)As HRESULT

Declare Function NetworkStreamSeek( _
	ByVal this As NetworkStream Ptr, _
	ByVal offset As LongInt, _
	ByVal origin As SeekOrigin _
)As HRESULT

Declare Function NetworkStreamSetLength( _
	ByVal this As NetworkStream Ptr, _
	ByVal length As LongInt _
)As HRESULT

Declare Function NetworkStreamWrite( _
	ByVal this As NetworkStream Ptr, _
	ByVal buffer As UByte Ptr, _
	ByVal offset As Integer, _
	ByVal Count As Integer, _
	ByVal pWritedBytes As Integer Ptr _
)As HRESULT

Declare Function NetworkStreamGetSocket( _
	ByVal this As NetworkStream Ptr, _
	ByVal pResult As SOCKET Ptr _
)As HRESULT

Declare Function NetworkStreamSetSocket( _
	ByVal this As NetworkStream Ptr, _
	ByVal sock As SOCKET _
)As HRESULT

Declare Sub InitializeNetworkStream( _
	ByVal pNetworkStream As NetworkStream Ptr, _
	ByVal mSock As SOCKET _
)

#endif
