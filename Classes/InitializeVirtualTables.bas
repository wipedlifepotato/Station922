#include "InitializeVirtualTables.bi"
#include "ArrayStringWriter.bi"
#include "ServerState.bi"
#include "NetworkStream.bi"

Common Shared GlobalArrayStringWriterVirtualTable As ITextWriterVirtualTable
Common Shared GlobalServerStateVirtualTable As IServerStateVirtualTable
Common Shared GlobalNetworkStreamVirtualTable As INetworkStreamVirtualTable

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
	
	' NetworkStream
	GlobalNetworkStreamVirtualTable.VirtualTable.VirtualTable.QueryInterface = 0
	GlobalNetworkStreamVirtualTable.VirtualTable.VirtualTable.Addref = 0
	GlobalNetworkStreamVirtualTable.VirtualTable.VirtualTable.Release = 0
	GlobalNetworkStreamVirtualTable.VirtualTable.CanRead = @NetworkStreamCanRead
	GlobalNetworkStreamVirtualTable.VirtualTable.CanSeek = @NetworkStreamCanSeek
	GlobalNetworkStreamVirtualTable.VirtualTable.CanWrite = @NetworkStreamCanWrite
	GlobalNetworkStreamVirtualTable.VirtualTable.CloseStream = @NetworkStreamCloseStream
	GlobalNetworkStreamVirtualTable.VirtualTable.Flush = @NetworkStreamFlush
	GlobalNetworkStreamVirtualTable.VirtualTable.GetLength = @NetworkStreamGetLength
	GlobalNetworkStreamVirtualTable.VirtualTable.OpenStream = @NetworkStreamOpenStream
	GlobalNetworkStreamVirtualTable.VirtualTable.Position = @NetworkStreamPosition
	GlobalNetworkStreamVirtualTable.VirtualTable.Read = @NetworkStreamRead
	GlobalNetworkStreamVirtualTable.VirtualTable.Seek = @NetworkStreamSeek
	GlobalNetworkStreamVirtualTable.VirtualTable.SetLength = @NetworkStreamSetLength
	GlobalNetworkStreamVirtualTable.VirtualTable.Write = @NetworkStreamWrite
	
End Sub
