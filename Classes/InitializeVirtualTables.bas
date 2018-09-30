#include "InitializeVirtualTables.bi"
#include "ArrayStringWriter.bi"
#include "ServerState.bi"

Common Shared GlobalArrayStringWriterVirtualTable As ITextWriterVirtualTable
Common Shared GlobalServerStateVirtualTable As IServerStateVirtualTable

Sub InitializeVirtualTables()
	
	' ArrayStringWriter
	GlobalArrayStringWriterVirtualTable.VirtualTable.QueryInterface = 0
	GlobalArrayStringWriterVirtualTable.VirtualTable.Addref = 0
	GlobalArrayStringWriterVirtualTable.VirtualTable.Release = 0
	GlobalArrayStringWriterVirtualTable.CloseTextWriter = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.OpenTextWriter = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.Flush = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.GetCodePage = @ArrayStringWriterGetCodePage
	GlobalArrayStringWriterVirtualTable.SetCodePage = @ArrayStringWriterSetCodePage
	GlobalArrayStringWriterVirtualTable.WriteNewLine = @ArrayStringWriterWriteNewLine
	GlobalArrayStringWriterVirtualTable.WriteStringLine = @ArrayStringWriterWriteStringLine
	GlobalArrayStringWriterVirtualTable.WriteLengthStringLine = @ArrayStringWriterWriteLengthStringLine
	GlobalArrayStringWriterVirtualTable.WriteString = @ArrayStringWriterWriteString
	GlobalArrayStringWriterVirtualTable.WriteLengthString = @ArrayStringWriterWriteLengthString
	GlobalArrayStringWriterVirtualTable.WriteChar = @ArrayStringWriterWriteChar
	GlobalArrayStringWriterVirtualTable.WriteInt32 = @ArrayStringWriterWriteInt32
	GlobalArrayStringWriterVirtualTable.WriteInt64 = @ArrayStringWriterWriteInt64
	GlobalArrayStringWriterVirtualTable.WriteUInt64 = @ArrayStringWriterWriteUInt64
	
	' ServerState
	GlobalServerStateVirtualTable.VirtualTable.QueryInterface = 0
	GlobalServerStateVirtualTable.VirtualTable.Addref = 0
	GlobalServerStateVirtualTable.VirtualTable.Release = 0
	GlobalServerStateVirtualTable.GetRequestHeader = @ServerStateDllCgiGetRequestHeader
	GlobalServerStateVirtualTable.GetHttpMethod = @ServerStateDllCgiGetHttpMethod
	GlobalServerStateVirtualTable.GetHttpVersion = @ServerStateDllCgiGetHttpVersion
	GlobalServerStateVirtualTable.SetStatusCode = @ServerStateDllCgiSetStatusCode
	GlobalServerStateVirtualTable.SetStatusDescription = @ServerStateDllCgiSetStatusDescription
	GlobalServerStateVirtualTable.SetResponseHeader = @ServerStateDllCgiSetResponseHeader
	GlobalServerStateVirtualTable.WriteData = @ServerStateDllCgiWriteData
	GlobalServerStateVirtualTable.ReadData = @ServerStateDllCgiReadData
	GlobalServerStateVirtualTable.GetHtmlSafeString = @ServerStateDllCgiGetHtmlSafeString
	
End Sub
