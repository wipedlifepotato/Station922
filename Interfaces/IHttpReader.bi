#ifndef IHTTPREADER_BI
#define IHTTPREADER_BI

#include "IBaseStream.bi"

' S_OK
Const HTTPREADER_E_INTERNALBUFFEROVERFLOW As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 1)
Const HTTPREADER_E_SOCKETERROR As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 2)
Const HTTPREADER_E_CLIENTCLOSEDCONNECTION As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 3)
Const HTTPREADER_E_BUFFERTOOSMALL As HRESULT = MAKE_HRESULT(SEVERITY_ERROR, FACILITY_ITF, 4)

' {D34D026F-D057-422F-9B32-C6D9424336F2}
Dim Shared IID_IHTTPREADER As IID = Type(&hd34d026f, &hd057, &h422f, _
	{&h9b, &h32, &hc6, &hd9, &h42, &h43, &h36, &hf2} _
)

Type LPIHTTPREADER As IHttpReader Ptr

Type IHttpReader As IHttpReader_

Type IHttpReaderVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim ReadLine As Function( _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pLineLength As Integer Ptr _
	)As HRESULT
	
	Dim Clear As Function( _
		ByVal pIHttpReader As IHttpReader Ptr _
	)As HRESULT
	
	Dim GetBaseStream As Function( _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal ppResult As IBaseStream Ptr Ptr _
	)As HRESULT
	
	Dim SetBaseStream As Function( _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal pIStream As IBaseStream Ptr _
	)As HRESULT
	
	Dim GetPreloadedBytes As Function( _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal pPreloadedBytesLength As Integer Ptr, _
		ByVal ppPreloadedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	Dim GetRequestedBytes As Function( _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal pRequestedBytesLength As Integer Ptr, _
		ByVal ppRequestedBytes As UByte Ptr Ptr _
	)As HRESULT
	
End Type

Type IHttpReader_
	Dim pVirtualTable As IHttpReaderVirtualTable Ptr
End Type

#define IHttpReader_QueryInterface(pIHttpReader, riid, ppv) (pIHttpReader)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIHttpReader), riid, ppv)
#define IHttpReader_AddRef(pIHttpReader) (pIHttpReader)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIHttpReader))
#define IHttpReader_Release(pIHttpReader) (pIHttpReader)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIHttpReader))
#define IHttpReader_ReadLine(pIHttpReader, Buffer, BufferLength, pLineLength) (pIHttpReader)->pVirtualTable->ReadLine(pIHttpReader, Buffer, BufferLength, pLineLength)
#define IHttpReader_Clear(IHttpReader) (IHttpReader)->pVirtualTable->Clear(IHttpReader)
#define IHttpReader_GetBaseStream(IHttpReader, ppResult) (IHttpReader)->pVirtualTable->GetBaseStream(IHttpReader, ppResult)
#define IHttpReader_SetBaseStream(IHttpReader, pIStream) (IHttpReader)->pVirtualTable->SetBaseStream(IHttpReader, pIStream)
#define IHttpReader_GetPreloadedBytes(IHttpReader, pPreloadedBytesLength, ppPreloadedBytes) (IHttpReader)->pVirtualTable->GetPreloadedBytes(IHttpReader, pPreloadedBytesLength, ppPreloadedBytes)
#define IHttpReader_GetRequestedBytes(IHttpReader, pRequestedBytesLength, ppRequestedBytes) (IHttpReader)->pVirtualTable->GetRequestedBytes(IHttpReader, pRequestedBytesLength, ppRequestedBytes)

#endif
