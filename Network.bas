#ifndef unicode
	#define unicode
#endif
#include once "Network.bi"

Sub CloseSocketConnection(ByVal mSock As SOCKET)
	Shutdown(mSock, 2)
	closesocket(mSock)
End Sub

Function ResolveHost(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr)As addrinfoW Ptr
	Dim hints As addrinfoW
	With hints
		' Если стоит AF_UNSPEC, то неважно, IPv4 или IPv6
		.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	' Связанный список результата
	Dim pResult As addrinfoW Ptr = 0
	
	If GetAddrInfoW(sServer, ServiceName, @hints, @pResult) = 0 Then
		Return pResult
	End If
	Return 0
End Function

Function CreateSocketAndBind(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr)As SOCKET
	' Открыть сокет
	Dim iSocket As SOCKET = socket_(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP)
	If iSocket <> INVALID_SOCKET Then
		' Привязать адрес к сокету
		Dim localIp As addrinfoW Ptr = ResolveHost(sServer, ServiceName)
		If localIp <> 0 Then
			' Обойти список адресов и сделать привязку
			Dim pPtr As addrinfoW Ptr = localIp
			Dim BindResult As Integer = Any
			Do
				BindResult = bind(iSocket, Cast(LPSOCKADDR, pPtr->ai_addr), pPtr->ai_addrlen)
				If BindResult = 0 Then
					' Привязано
					Exit Do
				End If
				pPtr = pPtr->ai_next
			Loop Until pPtr = 0
			' Очистка
			FreeAddrInfoW(localIp)
			' Привязались к адресу
			If BindResult = 0 Then
				Return iSocket
			End If
		End If
	End If
	CloseSocketConnection(iSocket)
	Return INVALID_SOCKET
End Function

Function CreateSocketAndListen(ByVal localServer As WString Ptr, ByVal ServiceName As WString Ptr)As SOCKET
	' Открыть сокет
	Dim iSocket As SOCKET = CreateSocketAndBind(localServer, ServiceName)
	If iSocket <> INVALID_SOCKET Then
		' Начать прослушивание
		If listen(iSocket, 1) <> SOCKET_ERROR Then
			Return iSocket
		End If
	End If
	CloseSocketConnection(iSocket)
	Return INVALID_SOCKET
End Function

Function ConnectToServer(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr, ByVal localServer As WString Ptr, ByVal LocalServiceName As WString Ptr)As SOCKET
	' Открыть сокет
	Dim iSocket As SOCKET = CreateSocketAndBind(localServer, LocalServiceName)
	If iSocket <> INVALID_SOCKET Then
		' Привязать адрес к сокету
		Dim localIp As addrinfoW Ptr = ResolveHost(sServer, ServiceName)
		If localIp <> 0 Then
			' Обойти список адресов и сделать привязку
			Dim pPtr As addrinfoW Ptr = localIp
			Dim ConnectResult As Integer = Any
			Do
				ConnectResult = connect(iSocket, Cast(LPSOCKADDR, pPtr->ai_addr), pPtr->ai_addrlen)
				If ConnectResult = 0 Then
					' Соединено
					Exit Do
				End If
				pPtr = pPtr->ai_next
			Loop Until pPtr = 0
			' Очистка
			FreeAddrInfoW(localIp)
			' Соединение установлено
			If ConnectResult = 0 Then
				Return iSocket
			End If
		End If
	End If
	CloseSocketConnection(iSocket)
	Return INVALID_SOCKET
End Function
