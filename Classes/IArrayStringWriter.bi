#ifndef IARRAYSTRINGWRITER_BI
#define IARRAYSTRINGWRITER_BI

#include "ITextWriter.bi"

' {2EB72D36-E6DC-4250-A9F0-7302EF840681}
Dim Shared IID_IARRAYSTRINGWRITER As IID = Type(&h2eb72d36, &he6dc, &h4250, _
	{&ha9, &hf0, &h73, &h2, &hef, &h84, &h6, &h81})

Type LPIARRAYSTRINGWRITER As IArrayStringWriter Ptr

Type IArrayStringWriter As IArrayStringWriter_

Type IArrayStringWriterVirtualTable
	Dim VirtualTable As ITextWriterVirtualTable
End Type

Type IArrayStringWriter_
	Dim pVirtualTable As IArrayStringWriterVirtualTable Ptr
End Type

#endif
