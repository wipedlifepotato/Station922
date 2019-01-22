#ifndef PROCESSPOSTREQUEST_BI
#define PROCESSPOSTREQUEST_BI

#include "INetworkStream.bi"
#include "WebSite.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"

Declare Function ProcessPostRequest( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pINetworkStream As INetworkStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr, _
	ByVal pClientReader As StreamSocketReader Ptr, _
	ByVal pIRequestedFile As IRequestedFile Ptr _
)As Boolean

#endif
