#ifndef WRITEHTTPERROR_BI
#define WRITEHTTPERROR_BI

#include "IBaseStream.bi"
#include "IClientRequest.bi"
#include "IServerResponse.bi"
#include "IWebSite.bi"

Declare Sub WriteHttpCreated( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpUpdated( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteMovedPermanently( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpBadRequest( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpPathNotValid( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpHostNotFound( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpSiteNotFound( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpNeedAuthenticate( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpBadAuthenticateParam( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpNeedBasicAuthenticate( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpEmptyPassword( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpBadUserNamePassword( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpForbidden( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpFileNotFound( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpMethodNotAllowed( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpFileGone( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpLengthRequired( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpRequestEntityTooLarge( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpRequestUrlTooLarge( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpRequestHeaderFieldsTooLarge( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpInternalServerError( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpFileNotAvailable( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateChildProcess( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpCannotCreatePipe( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpNotImplemented( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpContentTypeEmpty( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpContentEncodingNotEmpty( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpBadGateway( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpNotEnoughMemory( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateThread( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpGatewayTimeout( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

Declare Sub WriteHttpVersionNotSupported( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIStream As IBaseStream Ptr, _
	ByVal pIWebSite As IWebSite Ptr _
)

#endif
