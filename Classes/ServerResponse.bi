#ifndef SERVERRESPONSE_BI
#define SERVERRESPONSE_BI

#include "IServerResponse.bi"
#include "IStringable.bi"

Type ServerResponse
	Dim pServerResponseVirtualTable As IServerResponseVirtualTable Ptr
	Dim pStringableVirtualTable As IStringableVirtualTable Ptr
	Dim ReferenceCounter As ULONG
	Dim ExistsInStack As Boolean
	
	' Буфер заголовков ответа
	Dim ResponseHeaderBuffer As WString * (MaxResponseBufferLength + 1)
	' Указатель на свободное место в буфере заголовков ответа
	Dim StartResponseHeadersPtr As WString Ptr
	' Заголовки ответа
	Dim ResponseHeaders(HttpResponseHeadersMaximum - 1) As WString Ptr
	
	Dim HttpVersion As HttpVersions
	Dim StatusCode As HttpStatusCodes
	Dim StatusDescription As WString Ptr
	
	Dim SendOnlyHeaders As Boolean
	Dim KeepAlive As Boolean
	
	' Сжатие данных, поддерживаемое сервером
	Dim ResponseZipEnable As Boolean
	Dim ResponseZipMode As ZipModes
	
	Dim Mime As MimeType
	
End Type

Declare Function InitializeServerResponseOfIServerResponse( _
	ByVal pServerResponse As ServerResponse Ptr _
)As IServerResponse Ptr

Declare Function ServerResponseQueryInterface( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal riid As REFIID, _
	ByVal ppv As Any Ptr Ptr _
)As HRESULT

Declare Function ServerResponseAddRef( _
	ByVal pServerResponse As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseRelease( _
	ByVal pServerResponse As ServerResponse Ptr _
)As ULONG

Declare Function ServerResponseGetHttpVersion( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pHttpVersion As HttpVersions Ptr _
)As HRESULT

Declare Function ServerResponseSetHttpVersion( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal HttpVersion As HttpVersions _
)As HRESULT

Declare Function ServerResponseGetStatusCode( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pStatusCode As HttpStatusCodes Ptr _
)As HRESULT

Declare Function ServerResponseSetStatusCode( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal StatusCode As HttpStatusCodes _
)As HRESULT

Declare Function ServerResponseGetStatusDescription( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal ppStatusDescription As WString Ptr Ptr _
)As HRESULT

Declare Function ServerResponseSetStatusDescription( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pStatusDescription As WString Ptr _
)As HRESULT

Declare Function ServerResponseGetKeepAlive( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pKeepAlive As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetKeepAlive( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal KeepAlive As Boolean _
)As HRESULT

Declare Function ServerResponseGetSendOnlyHeaders( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pSendOnlyHeaders As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetSendOnlyHeaders( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal SendOnlyHeaders As Boolean _
)As HRESULT

Declare Function ServerResponseGetMimeType( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pMimeType As MimeType Ptr _
)As HRESULT

Declare Function ServerResponseSetMimeType( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pMimeType As MimeType Ptr _
)As HRESULT

Declare Function ServerResponseGetHttpHeader( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal ppHeader As WString Ptr Ptr _
)As HRESULT

Declare Function ServerResponseSetHttpHeader( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal pHeader As WString Ptr _
)As HRESULT

Declare Function ServerResponseGetZipEnabled( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pZipEnabled As Boolean Ptr _
)As HRESULT

Declare Function ServerResponseSetZipEnabled( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal ZipEnabled As Boolean _
)As HRESULT

Declare Function ServerResponseGetZipMode( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal pZipMode As ZipModes Ptr _
)As HRESULT

Declare Function ServerResponseSetZipMode( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal ZipMode As ZipModes _
)As HRESULT

Declare Function ServerResponseAddResponseHeader( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal HeaderName As WString Ptr, _
	ByVal Value As WString Ptr _
)As HRESULT

Declare Function ServerResponseAddKnownResponseHeader( _
	ByVal pServerResponse As ServerResponse Ptr, _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal Value As WString Ptr _
)As HRESULT

#endif
