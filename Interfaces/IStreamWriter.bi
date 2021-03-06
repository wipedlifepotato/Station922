#ifndef ISTREAMWRITER_BI
#define ISTREAMWRITER_BI

#include "ITextWriter.bi"

Type IStreamWriter As IStreamWriter_

Type LPISTREAMWRITER As IStreamWriter Ptr

Extern IID_IStreamWriter Alias "IID_IStreamWriter" As Const IID

Type IStreamWriterVirtualTable
	Dim InheritedTable As ITextWriterVirtualTable
	
End Type

Type IStreamWriter_
	Dim lpVtbl As IStreamWriterVirtualTable Ptr
End Type

#endif
