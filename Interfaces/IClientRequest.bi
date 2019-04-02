#ifndef ICLIENTREQUEST_BI
#define ICLIENTREQUEST_BI

#include "Http.bi"
#include "IHttpReader.bi"
#include "Uri.bi"

Const MaxRequestBufferLength As Integer = 32 * 1024 - 1

Const CLIENTREQUEST_E_SOCKETERROR As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 1)
Const CLIENTREQUEST_E_EMPTYREQUEST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 2)
Const CLIENTREQUEST_E_HTTPVERSIONNOTSUPPORTED As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 3)
Const CLIENTREQUEST_E_BADHOST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 4)
Const CLIENTREQUEST_E_BADREQUEST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 5)
Const CLIENTREQUEST_E_BADPATH As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 6)
Const CLIENTREQUEST_E_URITOOLARGE As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 7)
Const CLIENTREQUEST_E_HEADERFIELDSTOOLARGE As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 8)
Const CLIENTREQUEST_E_HTTPMETHODNOTSUPPORTED As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 9)

' {E998CAB4-5559-409C-93BC-97AFDF6A3921}
Dim Shared IID_ICLIENTREQUEST As IID = Type(&he998cab4, &h5559, &h409c, _
	{&h93, &hbc, &h97, &haf, &hdf, &h6a, &h39, &h21} _
)

Enum ByteRangeIsSet
	NotSet
	FirstBytePositionIsSet
	LastBytePositionIsSet
	FirstAndLastPositionIsSet
End Enum

Type ByteRange
	Dim IsSet As ByteRangeIsSet
	Dim FirstBytePosition As LongInt
	Dim LastBytePosition As LongInt
End Type

Type LPICLIENTREQUEST As IClientRequest Ptr

Type IClientRequest As IClientRequest_

Type IClientRequestVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim ReadRequest As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pIReader As IHttpReader Ptr _
	)As HRESULT
	
	Dim GetHttpMethod As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pHttpMethod As HttpMethods Ptr _
	)As HRESULT
	
	Dim GetUri As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pUri As Uri Ptr _
	)As HRESULT
	
	Dim GetHttpVersion As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pHttpVersions As HttpVersions Ptr _
	)As HRESULT
	
	Dim GetHttpHeader As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal HeaderIndex As HttpRequestHeaders, _
		ByVal ppHeader As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetKeepAlive As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pKeepAlive As Boolean Ptr _
	)As HRESULT
	
	Dim GetContentLength As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pContentLength As LongInt Ptr _
	)As HRESULT
	
	Dim GetByteRange As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal pRange As ByteRange Ptr _
	)As HRESULT
	
	Dim GetZipMode As Function( _
		ByVal pIClientRequest As IClientRequest Ptr, _
		ByVal ZipIndex As ZipModes, _
		ByVal pSupported As Boolean Ptr _
	)As HRESULT
	
End Type

Type IClientRequest_
	Dim pVirtualTable As IClientRequestVirtualTable Ptr
End Type

#define IClientRequest_QueryInterface(pIClientRequest, riid, ppv) (pIClientRequest)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIClientRequest), riid, ppv)
#define IClientRequest_AddRef(pIClientRequest) (pIClientRequest)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIClientRequest))
#define IClientRequest_Release(pIClientRequest) (pIClientRequest)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIClientRequest))
#define IClientRequest_ReadRequest(pIClientRequest, pIReader) (pIClientRequest)->pVirtualTable->ReadRequest(pIClientRequest, pIReader)
#define IClientRequest_GetHttpMethod(pIClientRequest, pHttpMethod) (pIClientRequest)->pVirtualTable->GetHttpMethod(pIClientRequest, pHttpMethod)
#define IClientRequest_GetUri(pIClientRequest, pUri) (pIClientRequest)->pVirtualTable->GetUri(pIClientRequest, pUri)
#define IClientRequest_GetHttpVersion(pIClientRequest, pHttpVersions) (pIClientRequest)->pVirtualTable->GetHttpVersion(pIClientRequest, pHttpVersions)
#define IClientRequest_GetHttpHeader(pIClientRequest, HeaderIndex, ppHeader) (pIClientRequest)->pVirtualTable->GetHttpHeader(pIClientRequest, HeaderIndex, ppHeader)
#define IClientRequest_GetKeepAlive(pIClientRequest, pKeepAlive) (pIClientRequest)->pVirtualTable->GetKeepAlive(pIClientRequest, pKeepAlive)
#define IClientRequest_GetContentLength(pIClientRequest, pContentLength) (pIClientRequest)->pVirtualTable->GetContentLength(pIClientRequest, pContentLength)
#define IClientRequest_GetByteRange(pIClientRequest, pRange) (pIClientRequest)->pVirtualTable->GetByteRange(pIClientRequest, pRange)
#define IClientRequest_GetZipMode(pIClientRequest, ZipIndex, pSupported) (pIClientRequest)->pVirtualTable->GetZipMode(pIClientRequest, ZipIndex, pSupported)

#endif
