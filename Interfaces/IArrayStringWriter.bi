#ifndef IARRAYATRINGWRITER_BI
#define IARRAYATRINGWRITER_BI

#include "ITextWriter.bi"

' {BC192A6D-7ACC-4219-A7AB-2900107366A4}
Dim Shared IID_IARRAYSTRINGWRITER As IID = Type(&hbc192a6d, &h7acc, &h4219, _
	{&ha7, &hab, &h29, &h0, &h10, &h73, &h66, &ha4} _
)

Type LPIARRAYSTRINGWRITER As IArrayStringWriter Ptr

Type IArrayStringWriter As IArrayStringWriter_

Type IArrayStringWriterVirtualTable
	Dim InheritedTable As ITextWriterVirtualTable
	
	Dim SetBuffer As Function( _
		ByVal pIArrayStringWriter As IArrayStringWriter Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal MaxBufferLength As Integer _
	)As HRESULT
	
End Type

Type IArrayStringWriter_
	Dim pVirtualTable As IArrayStringWriterVirtualTable Ptr
End Type

#define IArrayStringWriter_QueryInterface(pIArrayStringWriter, riid, ppv) (pIArrayStringWriter)->pVirtualTable->InheritedTable.InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIArrayStringWriter), riid, ppv)
#define IArrayStringWriter_AddRef(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.InheritedTable.AddRef(CPtr(IUnknown Ptr, pIArrayStringWriter))
#define IArrayStringWriter_Release(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.InheritedTable.Release(CPtr(IUnknown Ptr, pIArrayStringWriter))
#define IArrayStringWriter_CloseTextWriter(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.CloseTextWriter(CPtr(ITextWriter Ptr, pIArrayStringWriter))
#define IArrayStringWriter_OpenTextWriter(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.OpenTextWriter(CPtr(ITextWriter Ptr, pIArrayStringWriter))
#define IArrayStringWriter_Flush(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.Flush(CPtr(ITextWriter Ptr, pIArrayStringWriter))
#define IArrayStringWriter_GetCodePage(pIArrayStringWriter, pCodePage) (pIArrayStringWriter)->pVirtualTable->InheritedTable.GetCodePage(CPtr(ITextWriter Ptr, pIArrayStringWriter), pCodePage)
#define IArrayStringWriter_SetCodePage(pIArrayStringWriter, CodePage) (pIArrayStringWriter)->pVirtualTable->InheritedTable.GetCodePage(CPtr(ITextWriter Ptr, pIArrayStringWriter), CodePage)
#define IArrayStringWriter_WriteNewLine(pIArrayStringWriter) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteNewLine(CPtr(ITextWriter Ptr, pIArrayStringWriter))
#define IArrayStringWriter_WriteStringLine(pIArrayStringWriter, w) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteStringLine(CPtr(ITextWriter Ptr, pIArrayStringWriter), w)
#define IArrayStringWriter_WriteLengthStringLine(pIArrayStringWriter, w, Length) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteLengthStringLine(CPtr(ITextWriter Ptr, pIArrayStringWriter), w, Length)
#define IArrayStringWriter_WriteString(pIArrayStringWriter, w) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteString(CPtr(ITextWriter Ptr, pIArrayStringWriter), w)
#define IArrayStringWriter_WriteLengthString(pIArrayStringWriter, w, Length) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteLengthString(CPtr(ITextWriter Ptr, pIArrayStringWriter), w, Length)
#define IArrayStringWriter_WriteChar(pIArrayStringWriter, wc) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteChar(CPtr(ITextWriter Ptr, pIArrayStringWriter), wc)
#define IArrayStringWriter_WriteInt32(pIArrayStringWriter, Value) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteInt32(CPtr(ITextWriter Ptr, pIArrayStringWriter), Value)
#define IArrayStringWriter_WriteInt64(pIArrayStringWriter, Value) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteInt64(CPtr(ITextWriter Ptr, pIArrayStringWriter), Value)
#define IArrayStringWriter_WriteUInt64(pIArrayStringWriter, Value) (pIArrayStringWriter)->pVirtualTable->InheritedTable.WriteUInt64(CPtr(ITextWriter Ptr, pIArrayStringWriter), Value)
#define IArrayStringWriter_SetBuffer(pIArrayStringWriter, Buffer, MaxBufferLength) (pIArrayStringWriter)->pVirtualTable->SetBuffer(pIArrayStringWriter, Buffer, MaxBufferLength)

#endif
