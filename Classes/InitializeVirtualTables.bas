#include "InitializeVirtualTables.bi"
#include "ArrayStringWriter.bi"
#include "Configuration.bi"
#include "HttpReader.bi"
#include "NetworkStream.bi"
#include "RequestedFile.bi"
#include "ServerState.bi"
#include "WebServer.bi"

Common Shared GlobalArrayStringWriterVirtualTable As IArrayStringWriterVirtualTable
Common Shared GlobalConfigurationVirtualTable As IConfigurationVirtualTable
Common Shared GlobalHttpReaderVirtualTable As IHttpReaderVirtualTable
Common Shared GlobalNetworkStreamVirtualTable As INetworkStreamVirtualTable
Common Shared GlobalRequestedFileVirtualTable As IRequestedFileVirtualTable
Common Shared GlobalRequestedFileSendableVirtualTable As ISendableVirtualTable
Common Shared GlobalServerStateVirtualTable As IServerStateVirtualTable
Common Shared GlobalWebServerVirtualTable As IRunnableVirtualTable

Sub InitializeVirtualTables()
	
	' ArrayStringWriter
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.QueryInterface = @ArrayStringWriterQueryInterface
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.AddRef = @ArrayStringWriterAddRef
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.Release = @ArrayStringWriterRelease
	GlobalArrayStringWriterVirtualTable.InheritedTable.CloseTextWriter = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.InheritedTable.OpenTextWriter = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.InheritedTable.Flush = @ArrayStringWriterCloseTextWriter
	GlobalArrayStringWriterVirtualTable.InheritedTable.GetCodePage = @ArrayStringWriterGetCodePage
	GlobalArrayStringWriterVirtualTable.InheritedTable.SetCodePage = @ArrayStringWriterSetCodePage
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteNewLine = @ArrayStringWriterWriteNewLine
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteStringLine = @ArrayStringWriterWriteStringLine
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteLengthStringLine = @ArrayStringWriterWriteLengthStringLine
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteString = @ArrayStringWriterWriteString
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteLengthString = @ArrayStringWriterWriteLengthString
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteChar = @ArrayStringWriterWriteChar
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteInt32 = @ArrayStringWriterWriteInt32
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteInt64 = @ArrayStringWriterWriteInt64
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteUInt64 = @ArrayStringWriterWriteUInt64
	GlobalArrayStringWriterVirtualTable.SetBuffer = @ArrayStringWriterSetBuffer
	
	' Configuration
	GlobalConfigurationVirtualTable.InheritedTable.QueryInterface = @ConfigurationQueryInterface
	GlobalConfigurationVirtualTable.InheritedTable.AddRef = @ConfigurationAddRef
	GlobalConfigurationVirtualTable.InheritedTable.Release = @ConfigurationRelease
	GlobalConfigurationVirtualTable.SetIniFilename = @ConfigurationSetIniFilename
	GlobalConfigurationVirtualTable.GetStringValue = @ConfigurationGetStringValue
	GlobalConfigurationVirtualTable.GetIntegerValue = @ConfigurationGetIntegerValue
	GlobalConfigurationVirtualTable.GetAllSections = @ConfigurationGetAllSections
	GlobalConfigurationVirtualTable.GetAllKeys = @ConfigurationGetAllKeys
	GlobalConfigurationVirtualTable.SetStringValue = @ConfigurationSetStringValue
	
	' TODO HttpReader
	GlobalHttpReaderVirtualTable.InheritedTable.InheritedTable.QueryInterface = @HttpReaderQueryInterface
	GlobalHttpReaderVirtualTable.InheritedTable.InheritedTable.QueryInterface = @HttpReaderAddRef
	GlobalHttpReaderVirtualTable.InheritedTable.InheritedTable.QueryInterface = @HttpReaderRelease
	GlobalHttpReaderVirtualTable.InheritedTable.CloseTextReader = 0
	GlobalHttpReaderVirtualTable.InheritedTable.OpenTextReader = 0
	GlobalHttpReaderVirtualTable.InheritedTable.Peek = 0
	GlobalHttpReaderVirtualTable.InheritedTable.ReadChar = 0
	GlobalHttpReaderVirtualTable.InheritedTable.ReadCharArray = 0
	GlobalHttpReaderVirtualTable.InheritedTable.ReadLine = @HttpReaderReadLine
	GlobalHttpReaderVirtualTable.InheritedTable.ReadToEnd = 0
	GlobalHttpReaderVirtualTable.Clear = @HttpReaderClear
	GlobalHttpReaderVirtualTable.GetBaseStream = @HttpReaderGetBaseStream
	GlobalHttpReaderVirtualTable.SetBaseStream = @HttpReaderSetBaseStream
	GlobalHttpReaderVirtualTable.GetPreloadedContent = @HttpReaderGetPreloadedContent
	
	' NetworkStream
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.QueryInterface = @NetworkStreamQueryInterface
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.AddRef = @NetworkStreamAddRef
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.Release = @NetworkStreamRelease
	GlobalNetworkStreamVirtualTable.InheritedTable.CanRead = @NetworkStreamCanRead
	GlobalNetworkStreamVirtualTable.InheritedTable.CanSeek = @NetworkStreamCanSeek
	GlobalNetworkStreamVirtualTable.InheritedTable.CanWrite = @NetworkStreamCanWrite
	GlobalNetworkStreamVirtualTable.InheritedTable.CloseStream = @NetworkStreamCloseStream
	GlobalNetworkStreamVirtualTable.InheritedTable.Flush = @NetworkStreamFlush
	GlobalNetworkStreamVirtualTable.InheritedTable.GetLength = @NetworkStreamGetLength
	GlobalNetworkStreamVirtualTable.InheritedTable.OpenStream = @NetworkStreamOpenStream
	GlobalNetworkStreamVirtualTable.InheritedTable.Position = @NetworkStreamPosition
	GlobalNetworkStreamVirtualTable.InheritedTable.Read = @NetworkStreamRead
	GlobalNetworkStreamVirtualTable.InheritedTable.Seek = @NetworkStreamSeek
	GlobalNetworkStreamVirtualTable.InheritedTable.SetLength = @NetworkStreamSetLength
	GlobalNetworkStreamVirtualTable.InheritedTable.Write = @NetworkStreamWrite
	GlobalNetworkStreamVirtualTable.GetSocket = @NetworkStreamGetSocket
	GlobalNetworkStreamVirtualTable.SetSocket = @NetworkStreamSetSocket
	
	' TODO RequestedFile
	GlobalRequestedFileVirtualTable.InheritedTable.QueryInterface = @RequestedFileQueryInterface
	GlobalRequestedFileVirtualTable.InheritedTable.Addref = @RequestedFileAddRef
	GlobalRequestedFileVirtualTable.InheritedTable.Release = @RequestedFileRelease
	GlobalRequestedFileVirtualTable.ChoiseFile = 0
	GlobalRequestedFileVirtualTable.GetFilePath = @RequestedFileGetFilePath
	GlobalRequestedFileVirtualTable.SetFilePath = 0
	GlobalRequestedFileVirtualTable.GetPathTranslated = @RequestedFileGetPathTranslated
	GlobalRequestedFileVirtualTable.SetPathTranslated = 0
	GlobalRequestedFileVirtualTable.FileExists = @RequestedFileFileExists
	GlobalRequestedFileVirtualTable.GetFileHandle = @RequestedFileGetFileHandle
	GlobalRequestedFileVirtualTable.GetLastFileModifiedDate = @RequestedFileGetLastFileModifiedDate
	GlobalRequestedFileVirtualTable.GetFileLength = 0
	GlobalRequestedFileVirtualTable.GetVaryHeaders = 0
	
	GlobalRequestedFileSendableVirtualTable.InheritedTable.QueryInterface = 0
	GlobalRequestedFileSendableVirtualTable.InheritedTable.Addref = 0
	GlobalRequestedFileSendableVirtualTable.InheritedTable.Release = 0
	GlobalRequestedFileSendableVirtualTable.Send = 0
	
	' TODO ServerState
	GlobalServerStateVirtualTable.InheritedTable.QueryInterface = 0
	GlobalServerStateVirtualTable.InheritedTable.Addref = 0
	GlobalServerStateVirtualTable.InheritedTable.Release = 0
	GlobalServerStateVirtualTable.GetRequestHeader = @ServerStateDllCgiGetRequestHeader
	GlobalServerStateVirtualTable.GetHttpMethod = @ServerStateDllCgiGetHttpMethod
	GlobalServerStateVirtualTable.GetHttpVersion = @ServerStateDllCgiGetHttpVersion
	GlobalServerStateVirtualTable.SetStatusCode = @ServerStateDllCgiSetStatusCode
	GlobalServerStateVirtualTable.SetStatusDescription = @ServerStateDllCgiSetStatusDescription
	GlobalServerStateVirtualTable.SetResponseHeader = @ServerStateDllCgiSetResponseHeader
	GlobalServerStateVirtualTable.WriteData = @ServerStateDllCgiWriteData
	GlobalServerStateVirtualTable.ReadData = @ServerStateDllCgiReadData
	GlobalServerStateVirtualTable.GetHtmlSafeString = @ServerStateDllCgiGetHtmlSafeString
	
	' WebServer
	GlobalWebServerVirtualTable.InheritedTable.QueryInterface = @WebServerQueryInterface
	GlobalWebServerVirtualTable.InheritedTable.Addref = @WebServerAddRef
	GlobalWebServerVirtualTable.InheritedTable.Release = @WebServerRelease
	GlobalWebServerVirtualTable.Run = @WebServerRun
	GlobalWebServerVirtualTable.Stop = @WebServerStop
	
End Sub
