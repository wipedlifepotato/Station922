#ifndef WRITEHTTPERROR_BI
#define WRITEHTTPERROR_BI

#include "ReadHeadersResult.bi"
#include "Classes\IBaseStream.bi"

Declare Sub WriteHttpCreated( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpUpdated( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteMovedPermanently( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal www As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadRequest( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpPathNotValid( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpHostNotFound( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNeedAuthenticate( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadAuthenticateParam( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNeedBasicAuthenticate( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpEmptyPassword( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadUserNamePassword( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpForbidden( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileNotFound( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpMethodNotAllowed( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileGone( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpLengthRequired( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestEntityTooLarge( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestUrlTooLarge( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestHeaderFieldsTooLarge( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpInternalServerError( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileNotAvailable( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateChildProcess( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreatePipe( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNotImplemented( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpContentTypeEmpty( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpContentEncodingNotEmpty( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadGateway( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNotEnoughMemory( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateThread( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpGatewayTimeout( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpVersionNotSupported( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

#endif
