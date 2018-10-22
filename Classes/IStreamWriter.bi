#ifndef ISTREAMWRITER_BI
#define ISTREAMWRITER_BI

#include "ITextWriter.bi"

' {2B67DF5D-D44E-4D1E-87BE-9609B1E2E10A}
Dim Shared IID_ISTREAMWRITER As IID = Type(&h2b67df5d, &hd44e, &h4d1e, _
	{&h87, &hbe, &h96, &h9, &hb1, &he2, &he1, &ha})

Type IStreamWriter As IStreamWriter_

Type LPISTREAMWRITER As IStreamWriter Ptr

Type IStreamWriterVirtualTable
	Dim VirtualTable As ITextWriterVirtualTable
End Type

Type IStreamWriter_
	Dim pVirtualTable As IStreamWriterVirtualTable Ptr
End Type

#endif
