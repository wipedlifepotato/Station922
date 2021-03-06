#ifndef ICLIENTREQUEST_BI
#define ICLIENTREQUEST_BI

#include "Http.bi"
#include "IHttpReader.bi"
#include "Station922Uri.bi"

Const MaxRequestBufferLength As Integer = 32 * 1024 - 1

' IClientRequest.ReadRequest:
' S_OK — запрос прочитан успешно
' S_FALSE — клиент закрыл соединение (получено 0 байт от клиента)
' E_FAIL — ошибка чтения

' IClientRequest.BeginReadRequest:
' S_OK — запрос прочитан успешно
' CLIENTREQUEST_S_IO_PENDING — запрос успешно поставлен в очередь на исполнение
' E_FAIL — ошибка добавления запроса в очередь
Const CLIENTREQUEST_S_IO_PENDING As HRESULT = MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_ITF, &h0201)

' IClientRequest.EndReadRequest:
' S_OK — запрос прочитан весь успешно
' S_FALSE — клиент закрыл соединение (получено 0 байт от клиента)
' CLIENTREQUEST_S_IO_PENDING — данные прочитаны не все, требуется ещё одна постановка запроса в очередь
' E_FAIL — запрос завершился ошибкой
Const CLIENTREQUEST_E_HEADERFIELDSTOOLARGE As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0208)
Const CLIENTREQUEST_E_SOCKETERROR As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0201)
Const CLIENTREQUEST_E_EMPTYREQUEST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0202)

' IClientRequest.Prepare:
' S_OK, E_FAIL, CLIENTREQUEST_E_...
Const CLIENTREQUEST_E_HTTPVERSIONNOTSUPPORTED As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0203)
Const CLIENTREQUEST_E_BADHOST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0204)
Const CLIENTREQUEST_E_BADREQUEST As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0205)
Const CLIENTREQUEST_E_BADPATH As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0206)
Const CLIENTREQUEST_E_URITOOLARGE As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0207)
Const CLIENTREQUEST_E_HTTPMETHODNOTSUPPORTED As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0209)

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

Type IClientRequest As IClientRequest_

Type LPICLIENTREQUEST As IClientRequest Ptr

Extern IID_IClientRequest Alias "IID_IClientRequest" As Const IID

Type IClientRequestVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IClientRequest Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IClientRequest Ptr _
	)As ULONG
	
	Dim ReadRequest As Function( _
		ByVal this As IClientRequest Ptr _
	)As HRESULT
	
	Dim BeginReadRequest As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	Dim EndReadRequest As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	Dim Prepare As Function( _
		ByVal this As IClientRequest Ptr _
	)As HRESULT
	
	Dim GetHttpMethod As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pHttpMethod As HttpMethods Ptr _
	)As HRESULT
	
	' TODO Возвращать интерфейс IClientUri
	Dim GetUri As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pUri As Station922Uri Ptr _
	)As HRESULT
	
	Dim GetHttpVersion As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pHttpVersions As HttpVersions Ptr _
	)As HRESULT
	
	Dim GetHttpHeader As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal HeaderIndex As HttpRequestHeaders, _
		ByVal ppHeader As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetKeepAlive As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pKeepAlive As Boolean Ptr _
	)As HRESULT
	
	Dim GetContentLength As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pContentLength As LongInt Ptr _
	)As HRESULT
	
	Dim GetByteRange As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pRange As ByteRange Ptr _
	)As HRESULT
	
	Dim GetZipMode As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal ZipIndex As ZipModes, _
		ByVal pSupported As Boolean Ptr _
	)As HRESULT
	
	Dim Clear As Function( _
		ByVal this As IClientRequest Ptr _
	)As HRESULT
	
	Dim GetTextReader As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal ppIReader As ITextReader Ptr Ptr _
	)As HRESULT
	
	Dim SetTextReader As Function( _
		ByVal this As IClientRequest Ptr, _
		ByVal pIReader As ITextReader Ptr _
	)As HRESULT
	
End Type

Type IClientRequest_
	Dim lpVtbl As IClientRequestVirtualTable Ptr
End Type

#define IClientRequest_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IClientRequest_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IClientRequest_Release(this) (this)->lpVtbl->Release(this)
' #define IClientRequest_ReadRequest(this) (this)->lpVtbl->ReadRequest(this)
#define IClientRequest_BeginReadRequest(this, StateObject, ppIAsyncResult) (this)->lpVtbl->BeginReadRequest(this, StateObject, ppIAsyncResult)
#define IClientRequest_EndReadRequest(this, pIAsyncResult) (this)->lpVtbl->EndReadRequest(this, pIAsyncResult)
#define IClientRequest_Prepare(this) (this)->lpVtbl->Prepare(this)
#define IClientRequest_GetHttpMethod(this, pHttpMethod) (this)->lpVtbl->GetHttpMethod(this, pHttpMethod)
#define IClientRequest_GetUri(this, pUri) (this)->lpVtbl->GetUri(this, pUri)
#define IClientRequest_GetHttpVersion(this, pHttpVersions) (this)->lpVtbl->GetHttpVersion(this, pHttpVersions)
#define IClientRequest_GetHttpHeader(this, HeaderIndex, ppHeader) (this)->lpVtbl->GetHttpHeader(this, HeaderIndex, ppHeader)
#define IClientRequest_GetKeepAlive(this, pKeepAlive) (this)->lpVtbl->GetKeepAlive(this, pKeepAlive)
#define IClientRequest_GetContentLength(this, pContentLength) (this)->lpVtbl->GetContentLength(this, pContentLength)
#define IClientRequest_GetByteRange(this, pRange) (this)->lpVtbl->GetByteRange(this, pRange)
#define IClientRequest_GetZipMode(this, ZipIndex, pSupported) (this)->lpVtbl->GetZipMode(this, ZipIndex, pSupported)
#define IClientRequest_Clear(this) (this)->lpVtbl->Clear(this)
#define IClientRequest_GetTextReader(this, ppIReader) (this)->lpVtbl->GetTextReader(this, ppIReader)
#define IClientRequest_SetTextReader(this, pIReader) (this)->lpVtbl->SetTextReader(this, pIReader)

#endif
