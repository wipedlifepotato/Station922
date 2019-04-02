#ifndef ISERVERRESPONSE_BI
#define ISERVERRESPONSE_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

#include "Http.bi"
#include "Mime.bi"

Const MaxResponseBufferLength As Integer = 32 * 1024 - 1

' {C1BFB23D-79B3-4AE9-BEF9-5BF9D3073B84}
Dim Shared IID_IServerResponse As IID = Type(&hc1bfb23d, &h79b3, &h4ae9, _
	{&hbe, &hf9, &h5b, &hf9, &hd3, &h7, &h3b, &h84} _
)

Type LPISERVERRESPONSE As IServerResponse Ptr

Type IServerResponse As IServerResponse_

Type IServerResponseVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim GetHttpVersion As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pHttpVersion As HttpVersions Ptr _
	)As HRESULT
	
	Dim SetHttpVersion As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal HttpVersion As HttpVersions _
	)As HRESULT
	
	Dim GetStatusCode As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pStatusCode As HttpStatusCodes Ptr _
	)As HRESULT
	
	Dim SetStatusCode As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal StatusCode As HttpStatusCodes _
	)As HRESULT
	
	Dim GetStatusDescription As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal ppStatusDescription As WString Ptr Ptr _
	)As HRESULT
	
	Dim SetStatusDescription As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pStatusDescription As WString Ptr _
	)As HRESULT
	
	Dim GetKeepAlive As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pKeepAlive As Boolean Ptr _
	)As HRESULT
	
	Dim SetKeepAlive As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal KeepAlive As Boolean _
	)As HRESULT
	
	Dim GetSendOnlyHeaders As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pSendOnlyHeaders As Boolean Ptr _
	)As HRESULT
	
	Dim SetSendOnlyHeaders As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal SendOnlyHeaders As Boolean _
	)As HRESULT
	
	Dim GetMimeType As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pMimeType As MimeType Ptr _
	)As HRESULT
	
	Dim SetMimeType As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pMimeType As MimeType Ptr _
	)As HRESULT
	
	Dim GetHttpHeader As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal HeaderIndex As HttpResponseHeaders, _
		ByVal ppHeader As WString Ptr Ptr _
	)As HRESULT
	
	Dim SetHttpHeader As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal HeaderIndex As HttpResponseHeaders, _
		ByVal pHeader As WString Ptr _
	)As HRESULT
	
	Dim GetZipEnabled As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pZipEnabled As Boolean Ptr _
	)As HRESULT
	
	Dim SetZipEnabled As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal ZipEnabled As Boolean _
	)As HRESULT
	
	Dim GetZipMode As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal pZipMode As ZipModes Ptr _
	)As HRESULT
	
	Dim SetZipMode As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal ZipMode As ZipModes _
	)As HRESULT
	
	Dim AddResponseHeader As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal HeaderName As WString Ptr, _
		ByVal Value As WString Ptr _
	)As HRESULT
	
	Dim AddKnownResponseHeader As Function( _
		ByVal pIServerResponse As IServerResponse Ptr, _
		ByVal HeaderIndex As HttpResponseHeaders, _
		ByVal Value As WString Ptr _
	)As HRESULT
	
End Type

Type IServerResponse_
	Dim pVirtualTable As IServerResponseVirtualTable Ptr
End Type

#define IServerResponse_QueryInterface(pIServerResponse, riid, ppv) (pIServerResponse)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIServerResponse), riid, ppv)
#define IServerResponse_AddRef(pIServerResponse) (pIServerResponse)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIServerResponse))
#define IServerResponse_Release(pIServerResponse) (pIServerResponse)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIServerResponse))
#define IServerResponse_GetHttpVersion(pIServerResponse, pHttpVersion) (pIServerResponse)->pVirtualTable->GetHttpVersion(pIServerResponse, pHttpVersion)
#define IServerResponse_SetHttpVersion(pIServerResponse, HttpVersion) (pIServerResponse)->pVirtualTable->SetHttpVersion(pIServerResponse, HttpVersion)
#define IServerResponse_GetStatusCode(pIServerResponse, pStatusCode) (pIServerResponse)->pVirtualTable->GetStatusCode(pIServerResponse, pStatusCode)
#define IServerResponse_SetStatusCode(pIServerResponse, StatusCode) (pIServerResponse)->pVirtualTable->SetStatusCode(pIServerResponse, StatusCode)
#define IServerResponse_GetStatusDescription(pIServerResponse, ppStatusDescription) (pIServerResponse)->pVirtualTable->GetStatusDescription(pIServerResponse, ppStatusDescription)
#define IServerResponse_SetStatusDescription(pIServerResponse, pStatusDescription) (pIServerResponse)->pVirtualTable->SetStatusDescription(pIServerResponse, pStatusDescription)
#define IServerResponse_GetKeepAlive(pIServerResponse, pKeepAlive) (pIServerResponse)->pVirtualTable->GetKeepAlive(pIServerResponse, pKeepAlive)
#define IServerResponse_SetKeepAlive(pIServerResponse, KeepAlive) (pIServerResponse)->pVirtualTable->SetKeepAlive(pIServerResponse, KeepAlive)
#define IServerResponse_GetSendOnlyHeaders(pIServerResponse, pSendOnlyHeaders) (pIServerResponse)->pVirtualTable->GetSendOnlyHeaders(pIServerResponse, pSendOnlyHeaders)
#define IServerResponse_SetSendOnlyHeaders(pIServerResponse, SendOnlyHeaders) (pIServerResponse)->pVirtualTable->SetSendOnlyHeaders(pIServerResponse, SendOnlyHeaders)
#define IServerResponse_GetMimeType(pIServerResponse, pMimeType) (pIServerResponse)->pVirtualTable->GetMimeType(pIServerResponse, pMimeType)
#define IServerResponse_SetMimeType(pIServerResponse, pMimeType) (pIServerResponse)->pVirtualTable->SetMimeType(pIServerResponse, pMimeType)
#define IServerResponse_GetHttpHeader(pIServerResponse, HeaderIndex, ppHeader) (pIServerResponse)->pVirtualTable->GetHttpHeader(pIServerResponse, HeaderIndex, ppHeader)
#define IServerResponse_SetHttpHeader(pIServerResponse, HeaderIndex, pHeader) (pIServerResponse)->pVirtualTable->SetHttpHeader(pIServerResponse, HeaderIndex, pHeader)
#define IServerResponse_GetZipEnabled(pIServerResponse, pZipEnabled) (pIServerResponse)->pVirtualTable->GetZipEnabled(pIServerResponse, pZipEnabled)
#define IServerResponse_SetZipEnabled(pIServerResponse, ZipEnabled) (pIServerResponse)->pVirtualTable->SetZipEnabled(pIServerResponse, ZipEnabled)
#define IServerResponse_GetZipMode(pIServerResponse, pZipMode) (pIServerResponse)->pVirtualTable->GetZipMode(pIServerResponse, pZipMode)
#define IServerResponse_SetZipMode(pIServerResponse, ZipMode) (pIServerResponse)->pVirtualTable->SetZipMode(pIServerResponse, ZipMode)
#define IServerResponse_AddResponseHeader(pIServerResponse, HeaderName, Value) (pIServerResponse)->pVirtualTable->AddResponseHeader(pIServerResponse, HeaderName, Value)
#define IServerResponse_AddKnownResponseHeader(pIServerResponse, HeaderIndex, Value) (pIServerResponse)->pVirtualTable->AddKnownResponseHeader(pIServerResponse, HeaderIndex, Value)

#endif
