#ifndef STREAMWRITER_BI
#define STREAMWRITER_BI

#include "ITextWriter.bi"
#include "IBaseStream.bi"

Type StreamWriter
	Dim pVirtualTable As ITextWriterVirtualTable Ptr
	Dim ReferenceCounter As ULONG
	Dim Buffer As WString Ptr
	Dim BufferLength As Integer
	Dim MaxBufferLength As Integer
	Dim CodePage As Integer
End Type

Declare Sub InitializeStreamWriter( _
	ByVal pStreamWriter As StreamWriter Ptr, _
	ByVal pVirtualTable As ITextWriterVirtualTable Ptr, _
	ByVal Buffer As WString Ptr, _
	ByVal MaxBufferLength As Integer _
)

#endif
