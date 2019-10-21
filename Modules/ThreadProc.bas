#include "ThreadProc.bi"
#include "ClientRequest.bi"
#include "ConsoleColors.bi"
#include "HttpReader.bi"
#include "IntegerToWString.bi"
#include "ProcessConnectRequest.bi"
#include "ProcessDeleteRequest.bi"
#include "ProcessGetHeadRequest.bi"
#include "ProcessOptionsRequest.bi"
#include "ProcessPostRequest.bi"
#include "ProcessPutRequest.bi"
#include "ProcessTraceRequest.bi"
#include "ServerResponse.bi"
#include "WebUtils.bi"
#include "WriteHttpError.bi"

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	
	Dim pContext As ThreadContext Ptr = CPtr(ThreadContext Ptr, lpParam)
	
#ifndef WINDOWS_SERVICE
	
	Dim m_startTicks As LARGE_INTEGER
	QueryPerformanceCounter(@m_startTicks)
	
#endif
	
	Dim reader As HttpReader = Any
	Dim pIHttpReader As IHttpReader Ptr = InitializeHttpReaderOfIHttpReader(@reader)
	
	HttpReader_NonVirtualSetBaseStream(pIHttpReader, CPtr(IBaseStream Ptr, pContext->pINetworkStream))
	
	Dim request As ClientRequest = Any
	Dim response As ServerResponse = Any
	
	Dim KeepAlive As Boolean = True
	Dim ProcessRequestResult As Boolean = True
	
	Do
		HttpReader_NonVirtualClear(pIHttpReader)
		
		Dim pIClientRequest As IClientRequest Ptr = InitializeClientRequestOfIClientRequest(@request)
		Dim pIResponse As IServerResponse Ptr = InitializeServerResponseOfIServerResponse(@response)
		
		Dim hrReadRequest As HRESULT = IClientRequest_ReadRequest(pIClientRequest, pIHttpReader)
		
		If FAILED(hrReadRequest) Then
			
			KeepAlive = False
			
			Select Case hrReadRequest
				
				Case CLIENTREQUEST_E_HTTPVERSIONNOTSUPPORTED
					WriteHttpVersionNotSupported(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
					
				Case CLIENTREQUEST_E_BADREQUEST
					WriteHttpBadRequest(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
					
				Case CLIENTREQUEST_E_BADPATH
					WriteHttpPathNotValid(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
					
				Case CLIENTREQUEST_E_EMPTYREQUEST
					' Пустой запрос, клиент закрыл соединение
					
				Case CLIENTREQUEST_E_SOCKETERROR
					' Ошибка сокета
					
				Case CLIENTREQUEST_E_URITOOLARGE
					WriteHttpRequestUrlTooLarge(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
					
				Case CLIENTREQUEST_E_HEADERFIELDSTOOLARGE
					WriteHttpRequestHeaderFieldsTooLarge(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
					
				Case CLIENTREQUEST_E_HTTPMETHODNOTSUPPORTED
					' TODO Выделить в отдельную функцию
					IServerResponse_SetHttpHeader(pIResponse, HttpResponseHeaders.HeaderAllow, @AllSupportHttpMethods)
					WriteHttpNotImplemented(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), NULL)
					
			End Select
			
		Else
			
			IClientRequest_GetKeepAlive(pIClientRequest, @KeepAlive)
			IServerResponse_SetKeepAlive(pIResponse, KeepAlive)
			
			Dim HttpMethod As HttpMethods = Any
			IClientRequest_GetHttpMethod(pIClientRequest, @HttpMethod)
			
			Dim ClientURI As URI = Any
			IClientRequest_GetUri(pIClientRequest, @ClientURI)
			
			Dim pHeaderHost As WString Ptr = Any
			
			If HttpMethod = HttpMethods.HttpConnect Then
				pHeaderHost = ClientURI.Url
			Else
				IClientRequest_GetHttpHeader(pIClientRequest, HttpRequestHeaders.HeaderHost, @pHeaderHost)
			End If
			
			Dim HttpVersion As HttpVersions = Any
			IClientRequest_GetHttpVersion(pIClientRequest, @HttpVersion)
			
			' TODO Заголовок Host может не быть в версии 1.0
			If lstrlen(pHeaderHost) = 0 AndAlso HttpVersion = HttpVersions.Http11 Then
				WriteHttpHostNotFound(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), 0)
			Else
				
#ifndef WINDOWS_SERVICE
				Dim pRequestedBytes As UByte Ptr = Any
				Dim RequestedBytesLength As Integer = Any
				IHttpReader_GetRequestedBytes(pIHttpReader, @RequestedBytesLength, @pRequestedBytes)
				
				Dim CharsWritten As Integer = Any
				ConsoleWriteColorLineA(pRequestedBytes, @CharsWritten, ConsoleColors.Green, ConsoleColors.Black)
#endif
				
				Dim pIWebSite As IWebSite Ptr = Any
				
				Dim hrFindSite As HRESULT = Any
				
				If HttpMethod = HttpMethods.HttpConnect Then
					hrFindSite = IWebSiteContainer_GetDefaultWebSite(pContext->pIWebSites, @pIWebSite)
				Else
					hrFindSite = IWebSiteContainer_FindWebSite(pContext->pIWebSites, pHeaderHost, @pIWebSite)
				End If
				
				If FAILED(hrFindSite) Then
					WriteHttpSiteNotFound(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), NULL)
				Else
					
					Dim IsSiteMoved As Boolean = Any
					
					If lstrcmpi(ClientURI.Url, "/robots.txt") = 0 Then
						IsSiteMoved = False
					Else
						IWebSite_GetIsMoved(pIWebSite, @IsSiteMoved)
					End If
					
					If IsSiteMoved Then
						' Сайт перемещён на другой ресурс
						' если запрошен документ /robots.txt то не перенаправлять
						WriteMovedPermanently(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), pIWebSite)
					Else
						
						' Обработка запроса
						
						Dim ProcessRequestVirtualTable As Function( _
							ByVal pIClientRequest As IClientRequest Ptr, _
							ByVal pIResponse As IServerResponse Ptr, _
							ByVal pINetworkStream As INetworkStream Ptr, _
							ByVal pIWebSite As IWebSite Ptr, _
							ByVal pIClientReader As IHttpReader Ptr, _
							ByVal pIFile As IRequestedFile Ptr _
						)As Boolean = Any
						
						Dim pIFile As IRequestedFile Ptr = Any
						Dim RequestedFileAccess As FileAccess = Any
						
						Select Case HttpMethod
							
							Case HttpMethods.HttpGet
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessGetHeadRequest
								
							Case HttpMethods.HttpHead
								IServerResponse_SetSendOnlyHeaders(pIResponse, True)
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessGetHeadRequest
								
							Case HttpMethods.HttpPost
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessPostRequest
								
							Case HttpMethods.HttpPut
								RequestedFileAccess = FileAccess.ForPut
								ProcessRequestVirtualTable = @ProcessPutRequest
								
							Case HttpMethods.HttpDelete
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessDeleteRequest
								
							Case HttpMethods.HttpOptions
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessOptionsRequest
								
							Case HttpMethods.HttpTrace
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessTraceRequest
								
							Case HttpMethods.HttpConnect
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessConnectRequest
								
							Case Else
								RequestedFileAccess = FileAccess.ForGetHead
								ProcessRequestVirtualTable = @ProcessGetHeadRequest
								
						End Select
						
						Dim hrGetFile As HRESULT = IWebSite_GetRequestedFile(pIWebSite, @ClientURI.Path, RequestedFileAccess, @pIFile)
						
						If FAILED(hrGetFile) Then
							WriteHttpNotEnoughMemory(pIClientRequest, pIResponse, CPtr(IBaseStream Ptr, pContext->pINetworkStream), pIWebSite)
						Else
							
							ProcessRequestResult = ProcessRequestVirtualTable( _
								pIClientRequest, _
								pIResponse, _
								pContext->pINetworkStream, _
								pIWebSite, _
								pIHttpReader, _
								pIFile _
							)
							
							IRequestedFile_Release(pIFile)
							
#ifndef WINDOWS_SERVICE
							
							Dim m_endTicks As LARGE_INTEGER
							QueryPerformanceCounter(@m_endTicks)
							
							Dim wstrTemp As WString * (255 + 1) = Any
							
							i64tow( _
								((m_startTicks.QuadPart - pContext->m_startTicks.QuadPart) * 1000 * 1000) \ pContext->Frequency.QuadPart, _
								@wstrTemp, _
								10 _
							)
							
							ConsoleWriteColorStringW( _
								@!"Количество микросекунд запуска потока\t", _
								@CharsWritten, _
								ConsoleColors.Green, _
								ConsoleColors.Black _
							)
							ConsoleWriteColorLineW( _
								@wstrTemp, @CharsWritten, _
								ConsoleColors.Green, _
								ConsoleColors.Black _
							)
							
							i64tow( _
								((m_endTicks.QuadPart - pContext->m_startTicks.QuadPart) * 1000 * 1000) \ pContext->Frequency.QuadPart, _
								@wstrTemp, _
								10 _
							)
							
							ConsoleWriteColorStringW( _
								@!"Количество микросекунд обработки запроса\t", _
								@CharsWritten, _
								ConsoleColors.Green, _
								ConsoleColors.Black _
							)
							ConsoleWriteColorLineW( _
								@wstrTemp, @CharsWritten, _
								ConsoleColors.Green, _
								ConsoleColors.Black _
							)
							
							pContext->m_startTicks.QuadPart = m_endTicks.QuadPart
							
#endif
						End If
						
					End If
					
					IWebSite_Release(pIWebSite)
					
				End If
				
			End If
			
			IServerResponse_GetKeepAlive(pIResponse, @KeepAlive)
			
		End If
		
		IServerResponse_Release(pIResponse)
		IClientRequest_Release(pIClientRequest)
		
	Loop While KeepAlive AndAlso ProcessRequestResult
	
	HttpReader_NonVirtualRelease(pIHttpReader)
	
	NetworkStream_NonVirtualRelease(pContext->pINetworkStream)
	IWebSiteContainer_Release(pContext->pIWebSites)
	
	CloseHandle(pContext->hThread)
	
	HeapFree(pContext->hThreadContextHeap, 0, pContext)
	
	Return 0
	
End Function
