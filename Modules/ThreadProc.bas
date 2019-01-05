#include "ThreadProc.bi"
#include "ReadHeadersResult.bi"
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
#include "NetworkStream.bi"
#include "ConsoleColors.bi"

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	Dim param As ThreadParam Ptr = CPtr(ThreadParam Ptr, lpParam)
	
	Scope
		Dim ReceiveTimeOut As DWORD = 90 * 1000
		setsockopt(param->ClientSocket, SOL_SOCKET, SO_RCVTIMEO, CPtr(ZString Ptr, @ReceiveTimeOut), SizeOf(DWORD))
	End Scope
	
	Dim tcpStream As NetworkStream = Any
	Dim pINetworkStream As INetworkStream Ptr = CPtr(INetworkStream Ptr, New(@tcpStream) NetworkStream())
	
	pINetworkStream->pVirtualTable->SetSocket(pINetworkStream, param->ClientSocket)
	
	Dim ClientReader As StreamSocketReader = Any
	InitializeStreamSocketReader(@ClientReader)
	ClientReader.pStream = pINetworkStream
	
	Dim state As ReadHeadersResult = Any
	
	Do
		ClientReader.Flush()
		InitializeReadHeadersResult(@state)
		
		If state.ClientRequest.ReadClientHeaders(@ClientReader) = False Then
			Select Case GetLastError()
				
				Case ParseRequestLineResult.HTTPVersionNotSupported
					WriteHttpVersionNotSupported(@state, pINetworkStream, 0)
					
				Case ParseRequestLineResult.BadRequest
					WriteHttpBadRequest(@state, pINetworkStream, 0)
					
				Case ParseRequestLineResult.BadPath
					WriteHttpPathNotValid(@state, pINetworkStream, 0)
					
				Case ParseRequestLineResult.EmptyRequest
					' Пустой запрос, клиент закрыл соединение
					
				Case ParseRequestLineResult.SocketError
					' Ошибка сокета
					
				Case ParseRequestLineResult.RequestUrlTooLong
					WriteHttpRequestUrlTooLarge(@state, pINetworkStream, 0)
					
				Case ParseRequestLineResult.RequestHeaderFieldsTooLarge
					WriteHttpRequestHeaderFieldsTooLarge(@state, pINetworkStream, 0)
					
			End Select
			
			Exit Do
			
		End If
		
		' TODO Заголовок Host может не быть в версии 1.0
		If lstrlen(state.ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderHost)) = 0 Then
			If state.ClientRequest.HttpVersion = HttpVersions.Http10 Then
				state.ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderHost) = state.ClientRequest.ClientURI.Url
			Else
				WriteHttpHostNotFound(@state, pINetworkStream, 0)
				Exit Do
			End If
		End If
		
		#if __FB_DEBUG__ <> 0
			Color ConsoleColors.Green
			Print ClientReader.Buffer
		#endif
		
		' Найти сайт по его имени
		Dim www As SimpleWebSite = Any
		If param->pWebSitesArray->FindSimpleWebSite(@www, state.ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderHost)) = False Then
			If state.ClientRequest.HttpMethod = HttpMethods.HttpConnect Then
				www.PhysicalDirectory = param->ExeDir
			Else
				WriteHttpHostNotFound(@state, pINetworkStream, 0)
				Exit Do
			End If
		End If
		
		If www.IsMoved <> False Then
			' Сайт перемещён на другой ресурс
			' если запрошен документ /robots.txt то не перенаправлять
			If lstrcmpi(state.ClientRequest.ClientURI.Url, "/robots.txt") <> 0 Then
				WriteMovedPermanently(@state, pINetworkStream, @www)
				Exit Do
			End If
		End If
		
		' Обработка запроса
		
		Dim ProcessRequestVirtualTable As Function( _
			ByVal pState As ReadHeadersResult Ptr, _
			ByVal ClientSocket As SOCKET, _
			ByVal pWebSite As SimpleWebSite Ptr, _
			ByVal pClientReader As StreamSocketReader Ptr, _
			ByVal hRequestedFile As RequestedFile Ptr _
		)As Boolean = Any
		
		Dim hFile As RequestedFile = Any
		
		Select Case state.ClientRequest.HttpMethod
			
			Case HttpMethods.HttpGet
				www.GetRequestedFile(@hFile, @state.ClientRequest.ClientURI.Path, FileAccess.ForGetHead)
				ProcessRequestVirtualTable = @ProcessGetHeadRequest
				
			Case HttpMethods.HttpHead
				state.ServerResponse.SendOnlyHeaders = True
				www.GetRequestedFile(@hFile, @state.ClientRequest.ClientURI.Path, FileAccess.ForGetHead)
				ProcessRequestVirtualTable = @ProcessGetHeadRequest
				
			Case HttpMethods.HttpPost
				www.GetRequestedFile(@hFile, @state.ClientRequest.ClientURI.Path, FileAccess.ForGetHead)
				ProcessRequestVirtualTable = @ProcessPostRequest
				
			Case HttpMethods.HttpPut
				www.GetRequestedFile(@hFile, @state.ClientRequest.ClientURI.Path, FileAccess.ForPut)
				ProcessRequestVirtualTable = @ProcessPutRequest
				
			Case HttpMethods.HttpDelete
				ProcessRequestVirtualTable = @ProcessDeleteRequest
				
			Case HttpMethods.HttpOptions
				ProcessRequestVirtualTable = @ProcessOptionsRequest
				
			Case HttpMethods.HttpTrace
				ProcessRequestVirtualTable = @ProcessTraceRequest
				
			Case HttpMethods.HttpConnect
				ProcessRequestVirtualTable = @ProcessConnectRequest
				
			Case Else
				' TODO Выделить в отдельную функцию
				state.ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethods
				WriteHttpNotImplemented(@state, pINetworkStream, 0)
				Exit Do
				
		End Select
		
		If ProcessRequestVirtualTable( _
			@state, _
			param->ClientSocket, _
			@www, _
			@ClientReader, _
			@hFile _
		) = False Then
			Exit Do
		End If
		
	Loop While state.ClientRequest.KeepAlive
	
	CloseSocketConnection(param->ClientSocket)
	CloseHandle(param->hThread)
	VirtualFree(param, 0, MEM_RELEASE)
	
	Return 0
End Function
