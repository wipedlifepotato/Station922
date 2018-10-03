#ifndef THREADPROC_BI
#define THREADPROC_BI

#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "Network.bi"
#include "WebSite.bi"

Type ThreadParam
	Dim ClientSocket As SOCKET
	Dim ServerSocket As SOCKET
	Dim RemoteAddress As SOCKADDR_IN
	Dim RemoteAddressLength As Integer
	Dim hOutput As Handle
	Dim ThreadId As DWORD
	Dim hThread As HANDLE
	Dim ExeDir As WString Ptr
	Dim pWebSitesArray As WebSitesArray Ptr
End Type

Declare Function ThreadProc( _
	ByVal lpParam As LPVOID _
)As DWORD

#endif
