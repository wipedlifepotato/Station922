#ifndef ISTREAMREADER_BI
#define ISTREAMREADER_BI

#include "ITextReader.bi"

Type LPISTREAMREADER As IStreamReader Ptr

Type IStreamReader As IStreamReader_

Extern IID_IStreamReader Alias "IID_IStreamReader" As Const IID

Type IStreamReaderVirtualTable
	Dim InheritedTable As ITextReaderVirtualTable
	
End Type

Type IStreamReader_
	Dim lpVtbl As IStreamReaderVirtualTable Ptr
End Type

#endif
