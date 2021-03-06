#include "Network.bi"

#ifndef unicode

Function ResolveHostA( _
		ByVal Host As PCSTR, _
		ByVal Port As PCSTR, _
		ByVal ppAddressList As addrinfo Ptr Ptr _
	)As HRESULT
	
	Dim hints As addrinfo
	With hints
		.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	If getaddrinfoA(Host, Port, @hints, ppAddressList) = 0 Then
		
		Return S_OK
		
	End If
	
	Return HRESULT_FROM_WIN32(WSAGetLastError())
	
End Function

#endif

#ifdef unicode

Function ResolveHostW( _
		ByVal Host As PCWSTR, _
		ByVal Port As PCWSTR, _
		ByVal ppAddressList As addrinfoW Ptr Ptr _
	)As HRESULT
	
	Dim hints As addrinfoW
	With hints
		.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	If GetAddrInfoW(Host, Port, @hints, ppAddressList) = 0 Then
		
		Return S_OK
		
	End If
	
	Return HRESULT_FROM_WIN32(WSAGetLastError())
	
End Function

#endif

#ifndef unicode

Function CreateSocketAndBindA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = WSASocket(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)
	
	If ClientSocket = INVALID_SOCKET Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	Dim hr As HRESULT = ResolveHostA(LocalAddress, LocalPort, @pAddressList)
	
	If FAILED(hr) Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim BindResult As Integer = Any
	
	Dim e As Long = 0
	Do
		BindResult = bind(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If BindResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoA(pAddressList)
	
	If BindResult <> 0 Then
		
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

#endif

#ifdef unicode

Function CreateSocketAndBindW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = WSASocket(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)
	
	If ClientSocket = INVALID_SOCKET Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddressList As addrinfoW Ptr = NULL
	Dim hr As HRESULT = ResolveHostW(LocalAddress, LocalPort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return hr
		
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim BindResult As Long = Any
	
	Dim e As Long = 0
	Do
		BindResult = bind(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If BindResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoW(pAddressList)
	
	If BindResult <> 0 Then
		
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

#endif

Function CloseSocketConnection( _
		ByVal ClientSocket As SOCKET _
	)As HRESULT
	
	Dim res As Integer = shutdown(ClientSocket, SD_BOTH)
	
	If res <> 0 Then
		
		Dim e As ULONG = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	res = closesocket(ClientSocket)
	
	If res <> 0 Then
		
		Dim e As ULONG = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	Return S_OK
	
End Function

Function SetReceiveTimeout( _
		ByVal ClientSocket As SOCKET, _
		ByVal dwMilliseconds As DWORD _
	)As HRESULT
	
	Dim res As Integer = setsockopt( _
		ClientSocket, _
		SOL_SOCKET, _
		SO_RCVTIMEO, _
		CPtr(ZString Ptr, @dwMilliseconds), _
		SizeOf(DWORD) _
	)
	
	If res <> 0 Then
		
		Dim e As Integer = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	Return S_OK
	
End Function
