#include "InitializeVirtualTables.bi"
#include "ArrayStringWriter.bi"
#include "HttpReader.bi"
#include "NetworkStream.bi"

Sub InitializeVirtualTables()
	
	InitializeArrayStringWriterVirtualTable()
	InitializeHttpReaderVirtualTable()
	InitializeNetworkStreamVirtualTable()
	
End Sub
