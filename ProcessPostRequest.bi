#ifndef PROCESSPOSTREQUEST_BI
#define PROCESSPOSTREQUEST_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\winsock2.bi"
#include "win\ws2tcpip.bi"
#include "WebSite.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"

Declare Function ProcessPostRequest( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal ClientSocket As SOCKET, _
	ByVal pWebSite As SimpleWebSite Ptr, _
	ByVal pClientReader As StreamSocketReader Ptr, _
	ByVal pRequestedFile As RequestedFile Ptr _
)As Boolean

#endif
