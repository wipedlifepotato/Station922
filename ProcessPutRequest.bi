#ifndef PROCESSPUTREQUEST_BI
#define PROCESSPUTREQUEST_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"
#include once "WebSite.bi"
#include once "ReadHeadersResult.bi"

Declare Function ProcessPutRequest( _
	ByVal state As ReadHeadersResult Ptr, _
	ByVal ClientSocket As SOCKET, _
	ByVal www As WebSite Ptr, _
	ByVal pClientReader As StreamSocketReader Ptr, _
	ByVal hOutput As Handle _
)As Boolean

#endif
