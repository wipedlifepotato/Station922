#ifndef ITEXTWRITER_BI
#define ITEXTWRITER_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

' {8F177D4A-A214-49D2-A752-0BF4CC000C1C}
Dim Shared IID_ITEXTWRITER As IID = Type(&h8f177d4a, &ha214, &h49d2, _
	{&ha7, &h52, &hb, &hf4, &hcc, &h0, &hc, &h1c} _
)

Type ITextWriter As ITextWriter_

Type LPITEXTWRITER As ITextWriter Ptr

Type ITextWriterVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim CloseTextWriter As Function( _
		ByVal pITextWriter As ITextWriter Ptr _
	)As HRESULT
	
	Dim OpenTextWriter As Function( _
		ByVal pITextWriter As ITextWriter Ptr _
	)As HRESULT
	
	Dim Flush As Function( _
		ByVal pITextWriter As ITextWriter Ptr _
	)As HRESULT
	
	Dim GetCodePage As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal pCodePage As Integer Ptr _
	)As HRESULT
	
	Dim SetCodePage As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal CodePage As Integer _
	)As HRESULT
	
	Dim WriteNewLine As Function( _
		ByVal pITextWriter As ITextWriter Ptr _
	)As HRESULT
	
	Dim WriteStringLine As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Dim WriteLengthStringLine As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	Dim WriteString As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Dim WriteLengthString As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	Dim WriteChar As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal wc As Integer _
	)As HRESULT
	
	Dim WriteInt32 As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal Value As Long _
	)As HRESULT
	
	Dim WriteInt64 As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal Value As LongInt _
	)As HRESULT
	
	Dim WriteUInt64 As Function( _
		ByVal pITextWriter As ITextWriter Ptr, _
		ByVal Value As ULongInt _
	)As HRESULT
	
End Type

Type ITextWriter_
	Dim pVirtualTable As ITextWriterVirtualTable Ptr
End Type

#define ITextWriter_QueryInterface(pITextWriter, riid, ppv) (pITextWriter)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pITextWriter), riid, ppv)
#define ITextWriter_AddRef(pITextWriter) (pITextWriter)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pITextWriter))
#define ITextWriter_Release(pITextWriter) (pITextWriter)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pITextWriter))
#define ITextWriter_CloseTextWriter(pITextWriter) (pITextWriter)->pVirtualTable->CloseTextWriter(pITextWriter)
#define ITextWriter_OpenTextWriter(pITextWriter) (pITextWriter)->pVirtualTable->OpenTextWriter(pITextWriter)
#define ITextWriter_Flush(pITextWriter) (pITextWriter)->pVirtualTable->Flush(pITextWriter)
#define ITextWriter_GetCodePage(pITextWriter, pCodePage) (pITextWriter)->pVirtualTable->GetCodePage(pITextWriter, pCodePage)
#define ITextWriter_SetCodePage(pITextWriter, CodePage) (pITextWriter)->pVirtualTable->GetCodePage(pITextWriter, CodePage)
#define ITextWriter_WriteNewLine(pITextWriter) (pITextWriter)->pVirtualTable->WriteNewLine(pITextWriter)
#define ITextWriter_WriteStringLine(pITextWriter, w) (pITextWriter)->pVirtualTable->WriteStringLine(pITextWriter, w)
#define ITextWriter_WriteLengthStringLine(pITextWriter, w, Length) (pITextWriter)->pVirtualTable->WriteLengthStringLine(pITextWriter, w, Length)
#define ITextWriter_WriteString(pITextWriter, w) (pITextWriter)->pVirtualTable->WriteString(pITextWriter, w)
#define ITextWriter_WriteLengthString(pITextWriter, w, Length) (pITextWriter)->pVirtualTable->WriteLengthString(pITextWriter, w, Length)
#define ITextWriter_WriteChar(pITextWriter, wc) (pITextWriter)->pVirtualTable->WriteChar(pITextWriter, wc)
#define ITextWriter_WriteInt32(pITextWriter, Value) (pITextWriter)->pVirtualTable->WriteInt32(pITextWriter, Value)
#define ITextWriter_WriteInt64(pITextWriter, Value) (pITextWriter)->pVirtualTable->WriteInt64(pITextWriter, Value)
#define ITextWriter_WriteUInt64(pITextWriter, Value) (pITextWriter)->pVirtualTable->WriteUInt64(pITextWriter, Value)

#endif
