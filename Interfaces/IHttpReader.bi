#ifndef IHTTPREADER_BI
#define IHTTPREADER_BI

#include "IBaseStream.bi"
#include "ITextReader.bi"

Const HTTPREADER_E_INTERNALBUFFEROVERFLOW As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0201)
Const HTTPREADER_E_SOCKETERROR As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0202)
Const HTTPREADER_E_CLIENTCLOSEDCONNECTION As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0203)
Const HTTPREADER_E_BUFFERTOOSMALL As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, &h0204)

Type IHttpReader As IHttpReader_

Type LPIHTTPREADER As IHttpReader Ptr

Extern IID_IHttpReader Alias "IID_IHttpReader" As Const IID

Type IHttpReaderVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IHttpReader Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IHttpReader Ptr _
	)As ULONG
	
	Dim Peek As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pChar As wchar_t Ptr _
	)As HRESULT
	
	Dim ReadChar As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pChar As wchar_t Ptr _
	)As HRESULT
	
	Dim ReadCharArray As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal Index As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedChars As Integer Ptr _
	)As HRESULT
	
	Dim ReadLine As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal pLine As WString Ptr Ptr _
	)As HRESULT
	
	Dim ReadToEnd As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal ppLine As WString Ptr Ptr _
	)As HRESULT
	
	Dim BeginReadLine As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	Dim EndReadLine As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal ppLine As WString Ptr Ptr _
	)As HRESULT
	
	Dim BeginReadToEnd As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	Dim EndReadToEnd As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pLinesLength As Integer Ptr, _
		ByVal pLines As WString Ptr Ptr _
	)As HRESULT
	
	Dim Clear As Function( _
		ByVal this As IHttpReader Ptr _
	)As HRESULT
	
	Dim GetBaseStream As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal ppResult As IBaseStream Ptr Ptr _
	)As HRESULT
	
	Dim SetBaseStream As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pIStream As IBaseStream Ptr _
	)As HRESULT
	
	Dim GetPreloadedBytes As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pPreloadedBytesLength As Integer Ptr, _
		ByVal ppPreloadedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	Dim GetRequestedBytes As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pRequestedBytesLength As Integer Ptr, _
		ByVal ppRequestedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	Dim IsCompleted As Function( _
		ByVal this As IHttpReader Ptr, _
		ByVal pCompleted As Boolean Ptr _
	)As HRESULT
	
End Type

Type IHttpReader_
	Dim lpVtbl As IHttpReaderVirtualTable Ptr
End Type

#define IHttpReader_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IHttpReader_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IHttpReader_Release(this) (this)->lpVtbl->Release(this)
#define IHttpReader_ReadLine(this, pLineLength, pLine) (this)->lpVtbl->ReadLine(this, pLineLength, pLine)
#define IHttpReader_BeginReadLine(this, callback, StateObject, ppIAsyncResult) (this)->lpVtbl->BeginReadLine(this, callback, StateObject, ppIAsyncResult)
#define IHttpReader_EndReadLine(this, pIAsyncResult, pLineLength, pLine) (this)->lpVtbl->EndReadLine(this, pIAsyncResult, pLineLength, pLine)
#define IHttpReader_Clear(this) (this)->lpVtbl->Clear(this)
#define IHttpReader_GetBaseStream(this, ppResult) (this)->lpVtbl->GetBaseStream(this, ppResult)
#define IHttpReader_SetBaseStream(this, pIStream) (this)->lpVtbl->SetBaseStream(this, pIStream)
#define IHttpReader_GetPreloadedBytes(this, pPreloadedBytesLength, ppPreloadedBytes) (this)->lpVtbl->GetPreloadedBytes(this, pPreloadedBytesLength, ppPreloadedBytes)
#define IHttpReader_GetRequestedBytes(this, pRequestedBytesLength, ppRequestedBytes) (this)->lpVtbl->GetRequestedBytes(this, pRequestedBytesLength, ppRequestedBytes)
#define IHttpReader_IsCompleted(this, pCompleted) (this)->lpVtbl->IsCompleted(this, pCompleted)

#endif
