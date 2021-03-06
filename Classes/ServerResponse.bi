#ifndef SERVERRESPONSE_BI
#define SERVERRESPONSE_BI

#include "IServerResponse.bi"

Extern CLSID_SERVERRESPONSE Alias "CLSID_SERVERRESPONSE" As Const CLSID

Type ServerResponse As _ServerResponse

Type LPServerResponse As _ServerResponse Ptr

Declare Function CreateServerResponse( _
	ByVal pIMemoryAllocator As IMalloc Ptr _
)As ServerResponse Ptr

Declare Sub DestroyServerResponse( _
	ByVal this As ServerResponse Ptr _
)

Declare Function ServerResponseQueryInterface( _
	ByVal this As ServerResponse Ptr, _
	ByVal riid As REFIID, _
	ByVal ppv As Any Ptr Ptr _
)As HRESULT

Declare Function ServerResponseAddRef( _
	ByVal this As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseRelease( _
	ByVal this As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseGetHttpVersion( _
	ByVal this As ServerResponse Ptr, _
	ByVal pHttpVersion As HttpVersions Ptr _
)As HRESULT

Declare Function ServerResponseSetHttpVersion( _
	ByVal this As ServerResponse Ptr, _
	ByVal HttpVersion As HttpVersions _
)As HRESULT

Declare Function ServerResponseGetStatusCode( _
	ByVal this As ServerResponse Ptr, _
	ByVal pStatusCode As HttpStatusCodes Ptr _
)As HRESULT

Declare Function ServerResponseSetStatusCode( _
	ByVal this As ServerResponse Ptr, _
	ByVal StatusCode As HttpStatusCodes _
)As HRESULT

Declare Function ServerResponseGetStatusDescription( _
	ByVal this As ServerResponse Ptr, _
	ByVal ppStatusDescription As WString Ptr Ptr _
)As HRESULT

Declare Function ServerResponseSetStatusDescription( _
	ByVal this As ServerResponse Ptr, _
	ByVal pStatusDescription As WString Ptr _
)As HRESULT

Declare Function ServerResponseGetKeepAlive( _
	ByVal this As ServerResponse Ptr, _
	ByVal pKeepAlive As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetKeepAlive( _
	ByVal this As ServerResponse Ptr, _
	ByVal KeepAlive As Boolean _
)As HRESULT

Declare Function ServerResponseGetSendOnlyHeaders( _
	ByVal this As ServerResponse Ptr, _
	ByVal pSendOnlyHeaders As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetSendOnlyHeaders( _
	ByVal this As ServerResponse Ptr, _
	ByVal SendOnlyHeaders As Boolean _
)As HRESULT

Declare Function ServerResponseGetMimeType( _
	ByVal this As ServerResponse Ptr, _
	ByVal pMimeType As MimeType Ptr _
)As HRESULT

Declare Function ServerResponseSetMimeType( _
	ByVal this As ServerResponse Ptr, _
	ByVal pMimeType As MimeType Ptr _
)As HRESULT

Declare Function ServerResponseGetHttpHeader( _
	ByVal this As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal ppHeader As WString Ptr Ptr _
)As HRESULT

Declare Function ServerResponseSetHttpHeader( _
	ByVal this As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal pHeader As WString Ptr _
)As HRESULT

Declare Function ServerResponseGetZipEnabled( _
	ByVal this As ServerResponse Ptr, _
	ByVal pZipEnabled As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetZipEnabled( _
	ByVal this As ServerResponse Ptr, _
	ByVal ZipEnabled As Boolean _
)As HRESULT

Declare Function ServerResponseGetZipMode( _
	ByVal this As ServerResponse Ptr, _
	ByVal pZipMode As ZipModes Ptr _
)As HRESULT

Declare Function ServerResponseSetZipMode( _
	ByVal this As ServerResponse Ptr, _
	ByVal ZipMode As ZipModes _
)As HRESULT

Declare Function ServerResponseAddResponseHeader( _
	ByVal this As ServerResponse Ptr, _
	ByVal HeaderName As WString Ptr, _
	ByVal Value As WString Ptr _
)As HRESULT

Declare Function ServerResponseAddKnownResponseHeader( _
	ByVal this As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal Value As WString Ptr _
)As HRESULT

Declare Function ServerResponseClear( _
	ByVal this As ServerResponse Ptr _
)As HRESULT

Declare Function ServerResponseStringableQueryInterface( _
	ByVal this As ServerResponse Ptr, _
	ByVal riid As REFIID, _
	ByVal ppv As Any Ptr Ptr _
)As HRESULT

Declare Function ServerResponseStringableAddRef( _
	ByVal this As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseStringableRelease( _
	ByVal this As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseStringableToString( _
	ByVal this As ServerResponse Ptr, _
	ByVal pLength As Integer Ptr, _
	ByVal ppResult As WString Ptr Ptr _
)As HRESULT

#endif
