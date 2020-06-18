#include "WorkerThread.bi"
#include "IClientContext.bi"
#include "IRequestProcessor.bi"
#include "WriteHttpError.bi"

Sub ProcessEndReadError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrEndReadRequest As HRESULT _
	)
	Dim pIResponse As IServerResponse Ptr = Any
	IClientContext_GetServerResponse(pIContext, @pIResponse)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	
	Select Case hrEndReadRequest
		
		Case CLIENTREQUEST_E_HTTPVERSIONNOTSUPPORTED
			WriteHttpVersionNotSupported(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
		Case CLIENTREQUEST_E_BADREQUEST
			WriteHttpBadRequest(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
		Case CLIENTREQUEST_E_BADPATH
			WriteHttpPathNotValid(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
		Case CLIENTREQUEST_E_EMPTYREQUEST
			' Пустой запрос, клиент закрыл соединение
			
		Case CLIENTREQUEST_E_SOCKETERROR
			' Ошибка сокета
			
		Case CLIENTREQUEST_E_URITOOLARGE
			WriteHttpRequestUrlTooLarge(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
		Case CLIENTREQUEST_E_HEADERFIELDSTOOLARGE
			WriteHttpRequestHeaderFieldsTooLarge(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
		Case CLIENTREQUEST_E_HTTPMETHODNOTSUPPORTED
			' TODO Выделить в отдельную функцию
			IServerResponse_SetHttpHeader(pIResponse, HttpResponseHeaders.HeaderAllow, @AllSupportHttpMethods)
			WriteHttpNotImplemented(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case Else
			WriteHttpBadRequest(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
			
	End Select
	
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
	
End Sub

Sub ProcessReadOperation( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pIWebSites As IWebSiteContainer Ptr _
	)
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	
	Dim hrEndReadRequest As HRESULT = IClientRequest_EndReadRequest(pIRequest, pIAsyncResult)
	Print !"IClientRequest_EndReadRequest\t" & WStr(Hex(hrEndReadRequest))
	
	If FAILED(hrEndReadRequest) Then
		ProcessEndReadError(pIContext, pIRequest, hrEndReadRequest)
	Else
		Select Case hrEndReadRequest
			
			Case CLIENTREQUEST_S_IO_PENDING
				' Запустить чтение заново
				IClientContext_SetOperationCode(pIContext, OperationCodes.OpRead)
				
				Const NullCallback As AsyncCallback = NULL
				Dim pINewAsyncResult As IAsyncResult Ptr = Any
				Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
					pIRequest, _
					NullCallback, _
					CPtr(IUnknown Ptr, pIContext), _
					@pINewAsyncResult _
				)
				Print !"IClientRequest_BeginReadRequest\t" & WStr(Hex(hrBeginReadRequest))
				If FAILED(hrBeginReadRequest) Then
					If pINewAsyncResult <> NULL Then
						IAsyncResult_Release(pINewAsyncResult)
					End If
					' TODO Отправить клиенту Не могу начать асинхронное чтение
				End If
				
			Case Else
				' Прочитано, обработать запрос
				Dim KeepAlive As Boolean = True
				
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				Dim pINetworkStream As INetworkStream Ptr = Any
				IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
				
				IClientRequest_GetKeepAlive(pIRequest, @KeepAlive)
				IServerResponse_SetKeepAlive(pIResponse, KeepAlive)
				
				Dim HttpMethod As HttpMethods = Any
				IClientRequest_GetHttpMethod(pIRequest, @HttpMethod)
				
				Dim ClientURI As Station922Uri = Any
				IClientRequest_GetUri(pIRequest, @ClientURI)
				
				' TODO Найти правильный заголовок Host в зависимости от версии 1.0 или 1.1
				Dim pHeaderHost As WString Ptr = Any
				If HttpMethod = HttpMethods.HttpConnect Then
					pHeaderHost = ClientURI.pUrl
				Else
					IClientRequest_GetHttpHeader(pIRequest, HttpRequestHeaders.HeaderHost, @pHeaderHost)
				End If
				
				Dim HttpVersion As HttpVersions = Any
				IClientRequest_GetHttpVersion(pIRequest, @HttpVersion)
				
				If lstrlen(pHeaderHost) = 0 AndAlso HttpVersion = HttpVersions.Http11 Then
					WriteHttpHostNotFound(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
				Else
					
					Dim pIWebSite As IWebSite Ptr = Any
					IClientContext_GetWebSite(pIContext, @pIWebSite)
					
					Dim hrFindSite As HRESULT = Any
					If HttpMethod = HttpMethods.HttpConnect Then
						hrFindSite = IWebSiteContainer_GetDefaultWebSite(pIWebSites, pIWebSite)
					Else
						hrFindSite = IWebSiteContainer_FindWebSite(pIWebSites, pHeaderHost, pIWebSite)
					End If
					
					If FAILED(hrFindSite) Then
						WriteHttpSiteNotFound(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), 0)
					Else
						
						Dim IsSiteMoved As Boolean = Any
						' TODO Грязный хак с robots.txt
						If lstrcmpi(ClientURI.pUrl, "/robots.txt") = 0 Then
							IsSiteMoved = False
						Else
							IWebSite_GetIsMoved(pIWebSite, @IsSiteMoved)
						End If
						
						If IsSiteMoved Then
							' Сайт перемещён на другой ресурс
							' если запрошен документ /robots.txt то не перенаправлять
							WriteMovedPermanently(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
						Else
							
							Dim pIProcessor As IRequestProcessor Ptr = NULL
							Dim RequestedFileAccess As FileAccess = FileAccess.ReadAccess
							
							' Select Case HttpMethod
								
								' Case HttpMethods.HttpGet
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessGetHeadRequest
									
								' Case HttpMethods.HttpHead
									' IServerResponse_SetSendOnlyHeaders(pIResponse, True)
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessGetHeadRequest
									
								' Case HttpMethods.HttpPost
									' RequestedFileAccess = FileAccess.UpdateAccess
									' ProcessRequestVirtualTable = @ProcessPostRequest
									
								' Case HttpMethods.HttpPut
									' RequestedFileAccess = FileAccess.CreateAccess
									' ProcessRequestVirtualTable = @ProcessPutRequest
									
								' Case HttpMethods.HttpDelete
									' RequestedFileAccess = FileAccess.DeleteAccess
									' ProcessRequestVirtualTable = @ProcessDeleteRequest
									
								' Case HttpMethods.HttpOptions
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessOptionsRequest
									
								' Case HttpMethods.HttpTrace
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessTraceRequest
									
								' Case HttpMethods.HttpConnect
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessConnectRequest
									
								' Case Else
									' RequestedFileAccess = FileAccess.ReadAccess
									' ProcessRequestVirtualTable = @ProcessGetHeadRequest
									
							' End Select
							
							Dim pIFile As IRequestedFile Ptr = Any
							IClientContext_GetRequestedFile(pIContext, @pIFile)
							Dim pIHttpReader As IHttpReader Ptr
							IClientContext_GetHttpReader(pIContext, @pIHttpReader)
							Dim hClientContextHeap As HANDLE = Any
							IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
							
							Dim hrGetFile As HRESULT = IWebSite_OpenRequestedFile( _
								pIWebSite, _
								pIFile, _
								@ClientURI.Path, _
								RequestedFileAccess _
							)
							
							' IHttpWriter_Clear(pIHttpWriter)
							IServerResponse_Clear(pIResponse)
							IClientContext_SetOperationCode(pIContext, OperationCodes.OpWrite)
							
							Dim pc As ProcessorContext = Any
							pc.pIRequest = pIRequest
							pc.pIResponse = pIResponse
							pc.pINetworkStream = pINetworkStream
							pc.pIWebSite = pIWebSite
							pc.pIClientReader = pIHttpReader
							pc.pIRequestedFile = pIFile
							pc.hClientContextHeap = hClientContextHeap
							
							Dim pINewAsyncResult As IAsyncResult Ptr = Any
							Dim hrProcessRequest As HRESULT = IRequestProcessor_BeginProcess( _
								pIProcessor, _
								@pc, _
								CPtr(IUnknown Ptr, pIContext), _
								@pINewAsyncResult _
							)
							Print !"IRequestProcessor_BeginProcess\t" & WStr(Hex(hrProcessRequest))
							If FAILED(hrProcessRequest) Then
								If pINewAsyncResult <> NULL Then
									IAsyncResult_Release(pINewAsyncResult)
								End If
							Else
								
							End If
							
							IHttpReader_Release(pIHttpReader)
							IRequestedFile_Release(pIFile)
							
						End If
						
					End If
					
					IWebSite_Release(pIWebSite)
					
				End If
				
				INetworkStream_Release(pINetworkStream)
				IServerResponse_Release(pIResponse)
				
		End Select
	End If
	
	IClientRequest_Release(pIRequest)
	
End Sub

Sub ProcessWriteOperation( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	Dim pIProcessor As IRequestProcessor Ptr = Any
	IClientContext_GetRequestProcessor(pIContext, @pIProcessor)
	
	Dim hrEndProcess As HRESULT = IRequestProcessor_EndProcess(pIProcessor, pIAsyncResult)
	Print !"IRequestProcessor_EndProcess\t" & WStr(Hex(hrEndProcess))
	
	If FAILED(hrEndProcess) Then
		' Закрываем соединение
	Else
		Select Case hrEndProcess
			
			Case REQUESTPROCESSOR_S_IO_PENDING
				IClientContext_SetOperationCode(pIContext, OperationCodes.OpWrite)
				
				Dim pIFile As IRequestedFile Ptr = Any
				IClientContext_GetRequestedFile(pIContext, @pIFile)
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				Dim pIHttpReader As IHttpReader Ptr
				IClientContext_GetHttpReader(pIContext, @pIHttpReader)
				Dim hClientContextHeap As HANDLE = Any
				IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
				Dim pIWebSite As IWebSite Ptr = Any
				IClientContext_GetWebSite(pIContext, @pIWebSite)
				
				Dim pc As ProcessorContext = Any
				pc.pIRequest = pIRequest
				pc.pIResponse = pIResponse
				pc.pINetworkStream = pINetworkStream
				pc.pIWebSite = pIWebSite
				pc.pIClientReader = pIHttpReader
				pc.pIRequestedFile = pIFile
				pc.hClientContextHeap = hClientContextHeap
				
				Dim pINewAsyncResult As IAsyncResult Ptr = Any
				Dim hrProcessRequest As HRESULT = IRequestProcessor_BeginProcess( _
					pIProcessor, _
					@pc, _
					CPtr(IUnknown Ptr, pIContext), _
					@pINewAsyncResult _
				)
				Print !"IRequestProcessor_BeginProcess\t" & WStr(Hex(hrProcessRequest))
				If FAILED(hrProcessRequest) Then
					If pINewAsyncResult <> NULL Then
						IAsyncResult_Release(pINewAsyncResult)
					End If
				End If
				
				IWebSite_Release(pIWebSite)
				IHttpReader_Release(pIHttpReader)
				IServerResponse_Release(pIResponse)
				IRequestedFile_Release(pIFile)
				
			Case Else
				' Запустить чтение заново
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				
				Dim KeepAlive As Boolean = True
				IServerResponse_GetKeepAlive(pIResponse, @KeepAlive)
				
				If KeepAlive Then
					
					Dim pIHttpReader As IHttpReader Ptr
					IClientContext_GetHttpReader(pIContext, @pIHttpReader)
					
					IHttpReader_Clear(pIHttpReader)
					IClientRequest_Clear(pIRequest)
					IClientContext_SetOperationCode(pIContext, OperationCodes.OpRead)
					
					Const NullCallback As AsyncCallback = NULL
					Dim pINewAsyncResult As IAsyncResult Ptr = Any
					Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
						pIRequest, _
						NullCallback, _
						CPtr(IUnknown Ptr, pIContext), _
						@pINewAsyncResult _
					)
					Print !"IClientRequest_BeginReadRequest\t" & WStr(Hex(hrBeginReadRequest))
					If FAILED(hrBeginReadRequest) Then
						If pINewAsyncResult <> NULL Then
							IAsyncResult_Release(pINewAsyncResult)
						End If
						' TODO Отправить клиенту Не могу начать асинхронное чтение
					End If
					
					IHttpReader_Release(pIHttpReader)
				End If
				
				IServerResponse_Release(pIResponse)
				
		End Select
		
	End If
	
	IRequestProcessor_Release(pIProcessor)
	INetworkStream_Release(pINetworkStream)
	IClientRequest_Release(pIRequest)
	
End Sub

Function WorkerThread( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim pWorkerContext As WorkerThreadContext Ptr = CPtr(WorkerThreadContext Ptr, lpParam)
	
	Do
		
		Dim dwNumberOfBytesTransferred As DWORD = Any
		Dim CompletionKey As ULONG_PTR = Any
		Dim pOverlapped As LPASYNCRESULTOVERLAPPED = Any
		
		Dim res As Integer = GetQueuedCompletionStatus( _
			pWorkerContext->hIOCompletionPort, _
			@dwNumberOfBytesTransferred, _
			@CompletionKey, _
			CPtr(LPOVERLAPPED Ptr, @pOverlapped), _
			INFINITE _
		)
		If res = 0 Then
			' TODO Обработать ошибку
			Dim dwError As DWORD = GetLastError()
			Print !"Ошибка ожидания очереди порта завершения\t" & WStr(CInt(dwError))
			If dwError = ERROR_ABANDONED_WAIT_0 Then
				Exit Do
			End If
			If pOverlapped = NULL Then
				Print "pOverlapped = NULL"
				Exit Do
			End If
			If dwNumberOfBytesTransferred = 0 Then
				Print "Клиент отсоединился"
				' TODO Закрыть соединения
				Dim pIAsyncResult As IAsyncResult Ptr = pOverlapped->pIAsync
				
				Dim pIContext As IClientContext Ptr = Any
				IAsyncResult_GetAsyncState(pIAsyncResult, CPtr(IUnknown Ptr Ptr, @pIContext))
				
				IClientContext_Release(pIContext)
				IAsyncResult_Release(pIAsyncResult)
			End If
		Else
			
			Dim pIAsyncResult As IAsyncResult Ptr = pOverlapped->pIAsync
			
			Dim pIContext As IClientContext Ptr = Any
			IAsyncResult_GetAsyncState(pIAsyncResult, CPtr(IUnknown Ptr Ptr, @pIContext))
			
			Dim OpCode As OperationCodes = Any
			IClientContext_GetOperationCode(pIContext, @OpCode)
			
			Print "Получен пакет из очереди порта завершения"
			Print !"dwNumberOfBytesTransferred\t" & WStr(dwNumberOfBytesTransferred)
			Print !"CompletionKey\t" & WStr(CompletionKey)
			Print !"pOverlapped\t" & WStr(CUInt(pOverlapped))
			Print !"pIAsyncResult\t" & WStr(CUInt(pIAsyncResult))
			Print !"pIContext\t" & WStr(CUInt(pIContext))
			Print !"OpCode\t" & WStr(OpCode)
			
			Select Case OpCode
				
				Case OperationCodes.OpRead
					ProcessReadOperation(pIContext, pIAsyncResult, pWorkerContext->pIWebSites)
					
				Case OperationCodes.OpWrite
					ProcessWriteOperation(pIContext, pIAsyncResult)
					
				Case Else
					
					
			End Select
			
			IClientContext_Release(pIContext)
			IAsyncResult_Release(pIAsyncResult)
			
		End If
		
	Loop
	
	CloseHandle(pWorkerContext->hThread)
	IWebSiteContainer_Release(pWorkerContext->pIWebSites)
	HeapFree(GetProcessHeap(), 0, pWorkerContext)
	
	Return 0
	
End Function
