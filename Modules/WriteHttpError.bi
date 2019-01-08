#ifndef WRITEHTTPERROR_BI
#define WRITEHTTPERROR_BI

#include "IBaseStream.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"
#include "WebSite.bi"

Declare Sub WriteHttpCreated( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpUpdated( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteMovedPermanently( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal www As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadRequest( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpPathNotValid( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpHostNotFound( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNeedAuthenticate( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadAuthenticateParam( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNeedBasicAuthenticate( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpEmptyPassword( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadUserNamePassword( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpForbidden( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileNotFound( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpMethodNotAllowed( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileGone( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpLengthRequired( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestEntityTooLarge( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestUrlTooLarge( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpRequestHeaderFieldsTooLarge( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpInternalServerError( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpFileNotAvailable( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateChildProcess( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreatePipe( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNotImplemented( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpContentTypeEmpty( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpContentEncodingNotEmpty( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpBadGateway( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpNotEnoughMemory( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpCannotCreateThread( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpGatewayTimeout( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

Declare Sub WriteHttpVersionNotSupported( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal pWebSite As SimpleWebSite Ptr _
)

#endif
