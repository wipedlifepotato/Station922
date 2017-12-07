#ifndef NETWORK_BI
#define NETWORK_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

' Соединиться с сервером и вернуть сокет
Declare Function ConnectToServer(ByVal sServer As WString Ptr, ByVal Port As WString Ptr, ByVal LocalAddress As WString Ptr, ByVal LocalPort As WString Ptr)As SOCKET

' Создать прослушивающий сокет, привязанный к адресу
Declare Function CreateSocketAndListen(ByVal LocalAddress As WString Ptr, ByVal LocalPort As WString Ptr)As SOCKET

' Закрывает сокет
Declare Sub CloseSocketConnection(ByVal mSock As SOCKET)

' Создать сокет, привязанный к адресу
Declare Function CreateSocketAndBind(ByVal sServer As WString Ptr, ByVal Port As WString Ptr)As SOCKET

' Разрешение доменного имени
Declare Function ResolveHost(ByVal sServer As WString Ptr, ByVal Port As WString Ptr)As addrinfoW Ptr

#endif
