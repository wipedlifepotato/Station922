#include "InitializeVirtualTables.bi"
#include "ArrayStringWriter.bi"
#include "ClientRequest.bi"
#include "Configuration.bi"
#include "HttpReader.bi"
#include "NetworkStream.bi"
#include "RequestedFile.bi"
#include "ServerResponse.bi"
#include "ServerState.bi"
#include "WebServer.bi"
#include "WebSite.bi"
#include "WebSiteContainer.bi"

Common Shared GlobalArrayStringWriterVirtualTable As IArrayStringWriterVirtualTable
Common Shared GlobalClientRequestVirtualTable As IClientRequestVirtualTable
Common Shared GlobalClientRequestStringableVirtualTable As IStringableVirtualTable
Common Shared GlobalConfigurationVirtualTable As IConfigurationVirtualTable
Common Shared GlobalHttpReaderVirtualTable As IHttpReaderVirtualTable
Common Shared GlobalNetworkStreamVirtualTable As INetworkStreamVirtualTable
Common Shared GlobalRequestedFileVirtualTable As IRequestedFileVirtualTable
Common Shared GlobalRequestedFileSendableVirtualTable As ISendableVirtualTable
Common Shared GlobalServerResponseVirtualTable As IServerResponseVirtualTable
Common Shared GlobalServerResponseStringableVirtualTable As IStringableVirtualTable
Common Shared GlobalServerStateVirtualTable As IServerStateVirtualTable
Common Shared GlobalWebServerVirtualTable As IRunnableVirtualTable
Common Shared GlobalWebSiteVirtualTable As IWebSiteVirtualTable
Common Shared GlobalWebSiteContainerVirtualTable As IWebSiteContainerVirtualTable

Sub InitializeVirtualTables()
	
	' ArrayStringWriter
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.QueryInterface = CPtr(Any Ptr, @ArrayStringWriterQueryInterface)
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.AddRef = Cast(Any Ptr, @ArrayStringWriterAddRef)
	GlobalArrayStringWriterVirtualTable.InheritedTable.InheritedTable.Release = Cast(Any Ptr, @ArrayStringWriterRelease)
	GlobalArrayStringWriterVirtualTable.InheritedTable.CloseTextWriter = Cast(Any Ptr, @ArrayStringWriterCloseTextWriter)
	GlobalArrayStringWriterVirtualTable.InheritedTable.OpenTextWriter = Cast(Any Ptr, @ArrayStringWriterCloseTextWriter)
	GlobalArrayStringWriterVirtualTable.InheritedTable.Flush = Cast(Any Ptr, @ArrayStringWriterCloseTextWriter)
	GlobalArrayStringWriterVirtualTable.InheritedTable.GetCodePage = Cast(Any Ptr, @ArrayStringWriterGetCodePage)
	GlobalArrayStringWriterVirtualTable.InheritedTable.SetCodePage = Cast(Any Ptr, @ArrayStringWriterSetCodePage)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteNewLine = Cast(Any Ptr, @ArrayStringWriterWriteNewLine)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteStringLine = Cast(Any Ptr, @ArrayStringWriterWriteStringLine)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteLengthStringLine = Cast(Any Ptr, @ArrayStringWriterWriteLengthStringLine)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteString = Cast(Any Ptr, @ArrayStringWriterWriteString)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteLengthString = Cast(Any Ptr, @ArrayStringWriterWriteLengthString)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteChar = Cast(Any Ptr, @ArrayStringWriterWriteChar)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteInt32 = Cast(Any Ptr, @ArrayStringWriterWriteInt32)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteInt64 = Cast(Any Ptr, @ArrayStringWriterWriteInt64)
	GlobalArrayStringWriterVirtualTable.InheritedTable.WriteUInt64 = Cast(Any Ptr, @ArrayStringWriterWriteUInt64)
	GlobalArrayStringWriterVirtualTable.SetBuffer = Cast(Any Ptr, @ArrayStringWriterSetBuffer)
	
	' TODO ClientRequest
	GlobalClientRequestVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ClientRequestQueryInterface)
	GlobalClientRequestVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @ClientRequestAddRef)
	GlobalClientRequestVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ClientRequestRelease)
	GlobalClientRequestVirtualTable.ReadRequest = Cast(Any Ptr, @ClientRequestReadRequest)
	GlobalClientRequestVirtualTable.GetHttpMethod = Cast(Any Ptr, @ClientRequestGetHttpMethod)
	GlobalClientRequestVirtualTable.GetUri = Cast(Any Ptr, @ClientRequestGetUri)
	GlobalClientRequestVirtualTable.GetHttpVersion = Cast(Any Ptr, @ClientRequestGetHttpVersion)
	GlobalClientRequestVirtualTable.GetHttpHeader = Cast(Any Ptr, @ClientRequestGetHttpHeader)
	GlobalClientRequestVirtualTable.GetKeepAlive = Cast(Any Ptr, @ClientRequestGetKeepAlive)
	GlobalClientRequestVirtualTable.GetContentLength = Cast(Any Ptr, @ClientRequestGetContentLength)
	GlobalClientRequestVirtualTable.GetByteRange = Cast(Any Ptr, @ClientRequestGetByteRange)
	GlobalClientRequestVirtualTable.GetZipMode = Cast(Any Ptr, @ClientRequestGetZipMode)
	
	' GlobalClientRequestStringableVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ClientRequestStringableQueryInterface)
	' GlobalClientRequestStringableVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @ClientRequestStringableAddRef)
	' GlobalClientRequestStringableVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ClientRequestStringableRelease)
	' GlobalClientRequestStringableVirtualTable.ToString = Cast(Any Ptr, @ClientRequestToString)
	
	' Configuration
	GlobalConfigurationVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ConfigurationQueryInterface)
	GlobalConfigurationVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @ConfigurationAddRef)
	GlobalConfigurationVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ConfigurationRelease)
	GlobalConfigurationVirtualTable.SetIniFilename = Cast(Any Ptr, @ConfigurationSetIniFilename)
	GlobalConfigurationVirtualTable.GetStringValue = Cast(Any Ptr, @ConfigurationGetStringValue)
	GlobalConfigurationVirtualTable.GetIntegerValue = Cast(Any Ptr, @ConfigurationGetIntegerValue)
	GlobalConfigurationVirtualTable.GetAllSections = Cast(Any Ptr, @ConfigurationGetAllSections)
	GlobalConfigurationVirtualTable.GetAllKeys = Cast(Any Ptr, @ConfigurationGetAllKeys)
	GlobalConfigurationVirtualTable.SetStringValue = Cast(Any Ptr, @ConfigurationSetStringValue)
	
	' HttpReader
	GlobalHttpReaderVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @HttpReaderQueryInterface)
	GlobalHttpReaderVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @HttpReaderAddRef)
	GlobalHttpReaderVirtualTable.InheritedTable.Release = Cast(Any Ptr, @HttpReaderRelease)
	GlobalHttpReaderVirtualTable.ReadLine = Cast(Any Ptr, @HttpReaderReadLine)
	GlobalHttpReaderVirtualTable.Clear = Cast(Any Ptr, @HttpReaderClear)
	GlobalHttpReaderVirtualTable.GetBaseStream = Cast(Any Ptr, @HttpReaderGetBaseStream)
	GlobalHttpReaderVirtualTable.SetBaseStream = Cast(Any Ptr, @HttpReaderSetBaseStream)
	GlobalHttpReaderVirtualTable.GetPreloadedBytes = Cast(Any Ptr, @HttpReaderGetPreloadedBytes)
	GlobalHttpReaderVirtualTable.GetRequestedBytes = Cast(Any Ptr, @HttpReaderGetRequestedBytes)
	
	' NetworkStream
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.QueryInterface = Cast(Any Ptr, @NetworkStreamQueryInterface)
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.AddRef = Cast(Any Ptr, @NetworkStreamAddRef)
	GlobalNetworkStreamVirtualTable.InheritedTable.InheritedTable.Release = Cast(Any Ptr, @NetworkStreamRelease)
	GlobalNetworkStreamVirtualTable.InheritedTable.CanRead = Cast(Any Ptr, @NetworkStreamCanRead)
	GlobalNetworkStreamVirtualTable.InheritedTable.CanSeek = Cast(Any Ptr, @NetworkStreamCanSeek)
	GlobalNetworkStreamVirtualTable.InheritedTable.CanWrite = Cast(Any Ptr, @NetworkStreamCanWrite)
	GlobalNetworkStreamVirtualTable.InheritedTable.CloseStream = Cast(Any Ptr, @NetworkStreamCloseStream)
	GlobalNetworkStreamVirtualTable.InheritedTable.Flush = Cast(Any Ptr, @NetworkStreamFlush)
	GlobalNetworkStreamVirtualTable.InheritedTable.GetLength = Cast(Any Ptr, @NetworkStreamGetLength)
	GlobalNetworkStreamVirtualTable.InheritedTable.OpenStream = Cast(Any Ptr, @NetworkStreamOpenStream)
	GlobalNetworkStreamVirtualTable.InheritedTable.Position = Cast(Any Ptr, @NetworkStreamPosition)
	GlobalNetworkStreamVirtualTable.InheritedTable.Read = Cast(Any Ptr, @NetworkStreamRead)
	GlobalNetworkStreamVirtualTable.InheritedTable.Seek = Cast(Any Ptr, @NetworkStreamSeek)
	GlobalNetworkStreamVirtualTable.InheritedTable.SetLength = Cast(Any Ptr, @NetworkStreamSetLength)
	GlobalNetworkStreamVirtualTable.InheritedTable.Write = Cast(Any Ptr, @NetworkStreamWrite)
	GlobalNetworkStreamVirtualTable.GetSocket = Cast(Any Ptr, @NetworkStreamGetSocket)
	GlobalNetworkStreamVirtualTable.SetSocket = Cast(Any Ptr, @NetworkStreamSetSocket)
	
	' TODO RequestedFile
	GlobalRequestedFileVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @RequestedFileQueryInterface)
	GlobalRequestedFileVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @RequestedFileAddRef)
	GlobalRequestedFileVirtualTable.InheritedTable.Release = Cast(Any Ptr, @RequestedFileRelease)
	GlobalRequestedFileVirtualTable.ChoiseFile = Cast(Any Ptr, 0)
	GlobalRequestedFileVirtualTable.GetFilePath = Cast(Any Ptr, @RequestedFileGetFilePath)
	GlobalRequestedFileVirtualTable.SetFilePath = Cast(Any Ptr, 0)
	GlobalRequestedFileVirtualTable.GetPathTranslated = Cast(Any Ptr, @RequestedFileGetPathTranslated)
	GlobalRequestedFileVirtualTable.SetPathTranslated = Cast(Any Ptr, 0)
	GlobalRequestedFileVirtualTable.FileExists = Cast(Any Ptr, @RequestedFileFileExists)
	GlobalRequestedFileVirtualTable.GetFileHandle = Cast(Any Ptr, @RequestedFileGetFileHandle)
	GlobalRequestedFileVirtualTable.GetLastFileModifiedDate = Cast(Any Ptr, @RequestedFileGetLastFileModifiedDate)
	GlobalRequestedFileVirtualTable.GetFileLength = Cast(Any Ptr, 0)
	GlobalRequestedFileVirtualTable.GetVaryHeaders = Cast(Any Ptr, 0)
	
	' GlobalRequestedFileSendableVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, 0)
	' GlobalRequestedFileSendableVirtualTable.InheritedTable.Addref = Cast(Any Ptr, 0)
	' GlobalRequestedFileSendableVirtualTable.InheritedTable.Release = Cast(Any Ptr, 0)
	' GlobalRequestedFileSendableVirtualTable.Send = Cast(Any Ptr, 0)
	
	' ServerResponse
	GlobalServerResponseVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ServerResponseQueryInterface)
	GlobalServerResponseVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @ServerResponseAddRef)
	GlobalServerResponseVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ServerResponseRelease)
	GlobalServerResponseVirtualTable.GetHttpVersion = Cast(Any Ptr, @ServerResponseGetHttpVersion)
	GlobalServerResponseVirtualTable.SetHttpVersion = Cast(Any Ptr, @ServerResponseSetHttpVersion)
	GlobalServerResponseVirtualTable.GetStatusCode = Cast(Any Ptr, @ServerResponseGetStatusCode)
	GlobalServerResponseVirtualTable.SetStatusCode = Cast(Any Ptr, @ServerResponseSetStatusCode)
	GlobalServerResponseVirtualTable.GetStatusDescription = Cast(Any Ptr, @ServerResponseGetStatusDescription)
	GlobalServerResponseVirtualTable.SetStatusDescription = Cast(Any Ptr, @ServerResponseSetStatusDescription)
	GlobalServerResponseVirtualTable.GetKeepAlive = Cast(Any Ptr, @ServerResponseGetKeepAlive)
	GlobalServerResponseVirtualTable.SetKeepAlive = Cast(Any Ptr, @ServerResponseSetKeepAlive)
	GlobalServerResponseVirtualTable.GetSendOnlyHeaders = Cast(Any Ptr, @ServerResponseGetSendOnlyHeaders)
	GlobalServerResponseVirtualTable.SetSendOnlyHeaders = Cast(Any Ptr, @ServerResponseSetSendOnlyHeaders)
	GlobalServerResponseVirtualTable.GetMimeType = Cast(Any Ptr, @ServerResponseGetMimeType)
	GlobalServerResponseVirtualTable.SetMimeType = Cast(Any Ptr, @ServerResponseSetMimeType)
	GlobalServerResponseVirtualTable.GetHttpHeader = Cast(Any Ptr, @ServerResponseGetHttpHeader)
	GlobalServerResponseVirtualTable.SetHttpHeader = Cast(Any Ptr, @ServerResponseSetHttpHeader)
	GlobalServerResponseVirtualTable.GetZipEnabled = Cast(Any Ptr, @ServerResponseGetZipEnabled)
	GlobalServerResponseVirtualTable.SetZipEnabled = Cast(Any Ptr, @ServerResponseSetZipEnabled)
	GlobalServerResponseVirtualTable.GetZipMode = Cast(Any Ptr, @ServerResponseGetZipMode)
	GlobalServerResponseVirtualTable.SetZipMode = Cast(Any Ptr, @ServerResponseSetZipMode)
	GlobalServerResponseVirtualTable.AddResponseHeader = Cast(Any Ptr, @ServerResponseAddResponseHeader)
	GlobalServerResponseVirtualTable.AddKnownResponseHeader = Cast(Any Ptr, @ServerResponseAddKnownResponseHeader)
	
	GlobalServerResponseStringableVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ServerResponseStringableQueryInterface)
	GlobalServerResponseStringableVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @ServerResponseStringableAddRef)
	GlobalServerResponseStringableVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ServerResponseStringableRelease)
	GlobalServerResponseStringableVirtualTable.ToString = Cast(Any Ptr, @ServerResponseStringableToString)
	
	
	' TODO ServerState
	GlobalServerStateVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, 0)
	GlobalServerStateVirtualTable.InheritedTable.Addref = Cast(Any Ptr, 0)
	GlobalServerStateVirtualTable.InheritedTable.Release = Cast(Any Ptr, 0)
	GlobalServerStateVirtualTable.GetRequestHeader = Cast(Any Ptr, @ServerStateDllCgiGetRequestHeader)
	GlobalServerStateVirtualTable.GetHttpMethod = Cast(Any Ptr, @ServerStateDllCgiGetHttpMethod)
	GlobalServerStateVirtualTable.GetHttpVersion = Cast(Any Ptr, @ServerStateDllCgiGetHttpVersion)
	GlobalServerStateVirtualTable.SetStatusCode = Cast(Any Ptr, @ServerStateDllCgiSetStatusCode)
	GlobalServerStateVirtualTable.SetStatusDescription = Cast(Any Ptr, @ServerStateDllCgiSetStatusDescription)
	GlobalServerStateVirtualTable.SetResponseHeader = Cast(Any Ptr, @ServerStateDllCgiSetResponseHeader)
	GlobalServerStateVirtualTable.WriteData = Cast(Any Ptr, @ServerStateDllCgiWriteData)
	GlobalServerStateVirtualTable.ReadData = Cast(Any Ptr, @ServerStateDllCgiReadData)
	GlobalServerStateVirtualTable.GetHtmlSafeString = Cast(Any Ptr, @ServerStateDllCgiGetHtmlSafeString)
	
	' WebServer
	GlobalWebServerVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @WebServerQueryInterface)
	GlobalWebServerVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @WebServerAddRef)
	GlobalWebServerVirtualTable.InheritedTable.Release = Cast(Any Ptr, @WebServerRelease)
	GlobalWebServerVirtualTable.Run = Cast(Any Ptr, @WebServerRun)
	GlobalWebServerVirtualTable.Stop = Cast(Any Ptr, @WebServerStop)
	
	' WebSite
	GlobalWebSiteVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @WebSiteQueryInterface)
	GlobalWebSiteVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @WebSiteAddRef)
	GlobalWebSiteVirtualTable.InheritedTable.Release = Cast(Any Ptr, @WebSiteRelease)
	GlobalWebSiteVirtualTable.GetHostName = Cast(Any Ptr, @WebSiteGetHostName)
	GlobalWebSiteVirtualTable.GetExecutableDirectory = Cast(Any Ptr, @WebSiteGetExecutableDirectory)
	GlobalWebSiteVirtualTable.GetSitePhysicalDirectory = Cast(Any Ptr, @WebSiteGetSitePhysicalDirectory)
	GlobalWebSiteVirtualTable.GetVirtualPath = Cast(Any Ptr, @WebSiteGetVirtualPath)
	GlobalWebSiteVirtualTable.GetIsMoved = Cast(Any Ptr, @WebSiteGetIsMoved)
	GlobalWebSiteVirtualTable.GetMovedUrl = Cast(Any Ptr, @WebSiteGetMovedUrl)
	GlobalWebSiteVirtualTable.MapPath = Cast(Any Ptr, @WebSiteMapPath)
	GlobalWebSiteVirtualTable.GetRequestedFile = Cast(Any Ptr, @WebSiteGetRequestedFile)
	GlobalWebSiteVirtualTable.NeedCgiProcessing = Cast(Any Ptr, @WebSiteNeedCgiProcessing)
	GlobalWebSiteVirtualTable.NeedDllProcessing = Cast(Any Ptr, @WebSiteNeedDllProcessing)
	
	' WebSiteContainer
	GlobalWebSiteContainerVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @WebSiteContainerQueryInterface)
	GlobalWebSiteContainerVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @WebSiteContainerAddRef)
	GlobalWebSiteContainerVirtualTable.InheritedTable.Release = Cast(Any Ptr, @WebSiteContainerRelease)
	GlobalWebSiteContainerVirtualTable.GetDefaultWebSite = Cast(Any Ptr, @WebSiteContainerGetDefaultWebSite)
	GlobalWebSiteContainerVirtualTable.FindWebSite = Cast(Any Ptr, @WebSiteContainerFindWebSite)
	GlobalWebSiteContainerVirtualTable.LoadWebSites = Cast(Any Ptr, @WebSiteContainerLoadWebSites)
	
End Sub
