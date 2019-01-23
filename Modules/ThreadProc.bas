#include "ThreadProc.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"
#include "WebUtils.bi"
#include "ProcessConnectRequest.bi"
#include "ProcessDeleteRequest.bi"
#include "ProcessGetHeadRequest.bi"
#include "ProcessOptionsRequest.bi"
#include "ProcessPostRequest.bi"
#include "ProcessPutRequest.bi"
#include "ProcessTraceRequest.bi"
#include "Http.bi"
#include "WriteHttpError.bi"
#include "ConsoleColors.bi"

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	
	Dim param As ThreadParam Ptr = CPtr(ThreadParam Ptr, lpParam)
	
#if __FB_DEBUG__ <> 0
	
	Dim m_startTicks As LARGE_INTEGER
	QueryPerformanceCounter(@m_startTicks)
	
	Print "Количество тиков", m_startTicks.QuadPart - param->m_startTicks.QuadPart
	
#endif
	
	Dim ClientReader As StreamSocketReader = Any
	InitializeStreamSocketReader(@ClientReader)
	
	NetworkStream_NonVirtualAddRef(param->pINetworkStream)
	ClientReader.pStream = CPtr(IBaseStream Ptr, param->pINetworkStream)
	
	Dim request As WebRequest = Any
	Dim response As WebResponse = Any
	
	Do
		ClientReader.Flush()
		InitializeWebRequest(@request)
		InitializeWebResponse(@response)
		
		If request.ReadClientHeaders(@ClientReader) = False Then
			Select Case GetLastError()
				
				Case ParseRequestLineResult.HTTPVersionNotSupported
					WriteHttpVersionNotSupported(@request, @response, param->pINetworkStream, 0)
					
				Case ParseRequestLineResult.BadRequest
					WriteHttpBadRequest(@request, @response, param->pINetworkStream, 0)
					
				Case ParseRequestLineResult.BadPath
					WriteHttpPathNotValid(@request, @response, param->pINetworkStream, 0)
					
				Case ParseRequestLineResult.EmptyRequest
					' Пустой запрос, клиент закрыл соединение
					
				Case ParseRequestLineResult.SocketError
					' Ошибка сокета
					
				Case ParseRequestLineResult.RequestUrlTooLong
					WriteHttpRequestUrlTooLarge(@request, @response, param->pINetworkStream, 0)
					
				Case ParseRequestLineResult.RequestHeaderFieldsTooLarge
					WriteHttpRequestHeaderFieldsTooLarge(@request, @response, param->pINetworkStream, 0)
					
			End Select
			
			Exit Do
			
		End If
		
		' TODO Заголовок Host может не быть в версии 1.0
		If lstrlen(request.RequestHeaders(HttpRequestHeaders.HeaderHost)) = 0 Then
			If request.HttpVersion = HttpVersions.Http10 Then
				request.RequestHeaders(HttpRequestHeaders.HeaderHost) = request.ClientURI.Url
			Else
				WriteHttpHostNotFound(@request, @response, param->pINetworkStream, 0)
				Exit Do
			End If
		End If
		
		#ifndef service
			Dim CharsWritten As Integer = Any
			ConsoleWriteColorLineA(ClientReader.Buffer, @CharsWritten,ConsoleColors.Green, ConsoleColors.Black)
		#endif
		
		' Найти сайт по его имени
		Dim www As SimpleWebSite = Any
		If param->pWebSitesArray->FindSimpleWebSite(@www, request.RequestHeaders(HttpRequestHeaders.HeaderHost)) = False Then
			If request.HttpMethod = HttpMethods.HttpConnect Then
				www.PhysicalDirectory = param->pExeDir
			Else
				WriteHttpHostNotFound(@request, @response, param->pINetworkStream, 0)
				Exit Do
			End If
		End If
		
		If www.IsMoved <> False Then
			' Сайт перемещён на другой ресурс
			' если запрошен документ /robots.txt то не перенаправлять
			If lstrcmpi(request.ClientURI.Url, "/robots.txt") <> 0 Then
				WriteMovedPermanently(@request, @response, param->pINetworkStream, @www)
				Exit Do
			End If
		End If
		
		' Обработка запроса
		
		Dim ProcessRequestVirtualTable As Function( _
			ByVal pRequest As WebRequest Ptr, _
			ByVal pResponse As WebResponse Ptr, _
			ByVal pINetworkStream As INetworkStream Ptr, _
			ByVal pWebSite As SimpleWebSite Ptr, _
			ByVal pClientReader As StreamSocketReader Ptr, _
			ByVal pIFile As IRequestedFile Ptr _
		)As Boolean = Any
		
		Dim pIFile As IRequestedFile Ptr = Any
		
		Select Case request.HttpMethod
			
			Case HttpMethods.HttpGet
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessGetHeadRequest
				
			Case HttpMethods.HttpHead
				response.SendOnlyHeaders = True
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessGetHeadRequest
				
			Case HttpMethods.HttpPost
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessPostRequest
				
			Case HttpMethods.HttpPut
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForPut, @pIFile)
				ProcessRequestVirtualTable = @ProcessPutRequest
				
			Case HttpMethods.HttpDelete
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessDeleteRequest
				
			Case HttpMethods.HttpOptions
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessOptionsRequest
				
			Case HttpMethods.HttpTrace
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessTraceRequest
				
			Case HttpMethods.HttpConnect
				www.GetRequestedFile(@request.ClientURI.Path, FileAccess.ForGetHead, @pIFile)
				ProcessRequestVirtualTable = @ProcessConnectRequest
				
			Case Else
				' TODO Выделить в отдельную функцию
				response.ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethods
				WriteHttpNotImplemented(@request, @response, param->pINetworkStream, 0)
				Exit Do
				
		End Select
		
		ProcessRequestVirtualTable( _
			@request, _
			@response, _
			param->pINetworkStream, _
			@www, _
			@ClientReader, _
			pIFile _
		)
		
		IRequestedFile_Release(pIFile)
		
	Loop While request.KeepAlive
	
	NetworkStream_NonVirtualRelease(param->pINetworkStream)
	NetworkStream_NonVirtualRelease(param->pINetworkStream)
	
	CloseHandle(param->hThread)
	
	HeapFree(GetProcessHeap(), 0, param)
	
	Return 0
End Function
