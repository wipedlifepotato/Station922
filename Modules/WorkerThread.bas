#include "WorkerThread.bi"
#include "CreateInstance.bi"
#include "HttpGetProcessor.bi"
#include "IClientContext.bi"
#include "IRequestProcessor.bi"
#include "NetworkStreamAsyncResult.bi"
#include "PrintDebugInfo.bi"
#include "RequestedFile.bi"
#include "WriteHttpError.bi"

Enum DataError
	HostNotFound
	SiteNotFound
	MovedPermanently
	NotEnoughMemory
	HttpMethodNotSupported
End Enum

Sub ProcessBeginReadError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrBeginReadRequest As HRESULT _
	)
	' TODO Отправить клиенту Не могу начать асинхронное чтение
End Sub

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
			WriteHttpVersionNotSupported(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case CLIENTREQUEST_E_BADREQUEST
			WriteHttpBadRequest(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case CLIENTREQUEST_E_BADPATH
			WriteHttpPathNotValid(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case CLIENTREQUEST_E_EMPTYREQUEST
			' Пустой запрос, клиент закрыл соединение
			
		Case CLIENTREQUEST_E_SOCKETERROR
			' Ошибка сокета
			
		Case CLIENTREQUEST_E_URITOOLARGE
			WriteHttpRequestUrlTooLarge(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case CLIENTREQUEST_E_HEADERFIELDSTOOLARGE
			WriteHttpRequestHeaderFieldsTooLarge(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case CLIENTREQUEST_E_HTTPMETHODNOTSUPPORTED
			IServerResponse_AddKnownResponseHeader(pIResponse, HttpResponseHeaders.HeaderAllow, @AllSupportHttpMethods)
			WriteHttpNotImplemented(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case Else
			WriteHttpBadRequest(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
	End Select
	
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
	
End Sub

Sub ProcessDataError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrDataError As DataError _
	)
	
	Dim pIResponse As IServerResponse Ptr = Any
	IClientContext_GetServerResponse(pIContext, @pIResponse)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	
	Select Case hrDataError
		
		Case DataError.HostNotFound
			WriteHttpHostNotFound(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case DataError.SiteNotFound
			WriteHttpSiteNotFound(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
		Case DataError.MovedPermanently
			Dim pIWebSite As IWebSite Ptr = Any
			IClientContext_GetWebSite(pIContext, @pIWebSite)
			WriteMovedPermanently(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			IWebSite_Release(pIWebSite)
			
		Case DataError.NotEnoughMemory
			Dim pIWebSite As IWebSite Ptr = Any
			IClientContext_GetWebSite(pIContext, @pIWebSite)
			WriteHttpNotEnoughMemory(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			IWebSite_Release(pIWebSite)
			
		Case DataError.HttpMethodNotSupported
			WriteHttpNotImplemented(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
	End Select
	
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
	
End Sub

Sub ProcessBeginWriteError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrBeginProcess As HRESULT _
	)
	Dim pIResponse As IServerResponse Ptr = Any
	IClientContext_GetServerResponse(pIContext, @pIResponse)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	Dim pIWebSite As IWebSite Ptr = Any
	IClientContext_GetWebSite(pIContext, @pIWebSite)
	
	Select Case hrBeginProcess
		
		Case REQUESTPROCESSOR_E_FILENOTFOUND
			WriteHttpFileNotFound(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			
		Case REQUESTPROCESSOR_E_FILEGONE
			WriteHttpFileGone(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			
		Case REQUESTPROCESSOR_E_FORBIDDEN
			WriteHttpForbidden(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			
		Case Else
			WriteHttpInternalServerError(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
			
	End Select
	
	IWebSite_Release(pIWebSite)
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
	
End Sub

Sub ProcessEndWriteError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrEndProcess As HRESULT _
	)
End Sub

Function ProcessReadRequest( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	
	Dim hrEndReadRequest As HRESULT = IClientRequest_EndReadRequest(pIRequest, pIAsyncResult)
	If FAILED(hrEndReadRequest) Then
		ProcessEndReadError(pIContext, pIRequest, hrEndReadRequest)
		hrResult = hrEndReadRequest
	Else
		Select Case hrEndReadRequest
			
			Case CLIENTREQUEST_S_IO_PENDING
				IClientContext_SetOperationCode(pIContext, OperationCodes.ReadRequest)
				
				Const NullCallback As AsyncCallback = NULL
				Dim pINewAsyncResult As IAsyncResult Ptr = Any
				Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
					pIRequest, _
					NullCallback, _
					CPtr(IUnknown Ptr, pIContext), _
					@pINewAsyncResult _
				)
				If FAILED(hrBeginReadRequest) Then
					ProcessBeginReadError(pIContext, pIRequest, hrBeginReadRequest)
					hrResult = hrBeginReadRequest
				End If
				
			Case S_FALSE
				' Клиент закрыл соединение
				hrResult = E_FAIL
				
			Case S_OK
				#ifndef WINDOWS_SERVICE
					Dim pIHttpReader2 As IHttpReader Ptr = Any
					IClientContext_GetHttpReader(pIContext, @pIHttpReader2)
					PrintRequestedBytes(pIHttpReader2)
					IHttpReader_Release(pIHttpReader2)
				#endif
				
				Dim pIMemoryAllocator As IMalloc Ptr = Any
				IClientContext_GetMemoryAllocator(pIContext, @pIMemoryAllocator)
				
				Dim pINewAsyncResult As INetworkStreamAsyncResult Ptr = Any
				Dim hr As HRESULT = CreateInstance( _
					pIMemoryAllocator, _
					@CLSID_NETWORKSTREAMASYNCRESULT, _
					@IID_INetworkStreamAsyncResult, _
					@pINewAsyncResult _
				)
				If FAILED(hr) Then
					hrResult = hr
				Else
					IClientContext_SetOperationCode(pIContext, OperationCodes.PrepareResponse)
					
					Dim lpRecvOverlapped As ASYNCRESULTOVERLAPPED Ptr = Any
					INetworkStreamAsyncResult_GetWsaOverlapped(pINewAsyncResult, @lpRecvOverlapped)
					lpRecvOverlapped->pIAsync = CPtr(IAsyncResult Ptr, pINewAsyncResult)
					
					INetworkStreamAsyncResult_SetAsyncState(pINewAsyncResult, CPtr(IUnknown Ptr, pIContext))
					INetworkStreamAsyncResult_SetAsyncCallback(pINewAsyncResult, NULL)
					
					Const dwNumberOfBytesTransferred As DWORD = 265
					Const CompletionKey As ULONG_PTR = 0
					Dim res As Integer = PostQueuedCompletionStatus( _
						hIoCompletionPort, _
						dwNumberOfBytesTransferred, _
						CompletionKey, _
						CPtr(LPOVERLAPPED, lpRecvOverlapped) _
					)
					If res = 0 Then
						Dim dwError As DWORD = GetLastError()
						INetworkStreamAsyncResult_Release(pINewAsyncResult)
						hrResult = HRESULT_FROM_WIN32(dwError)
					End If
					
				End If
				
				IMalloc_Release(pIMemoryAllocator)
				
		End Select
	End If
	
	IClientRequest_Release(pIRequest)
	
	Return hrResult
	
End Function

Function ProcessPrepareResponse( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pIWebSites As IWebSiteContainer Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	
	Dim KeepAlive As Boolean = True
	
	Dim pIResponse As IServerResponse Ptr = Any
	IClientContext_GetServerResponse(pIContext, @pIResponse)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	
	' IHttpWriter_Clear(pIHttpWriter)
	IServerResponse_Clear(pIResponse)
	
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
		ProcessDataError(pIContext, pIRequest, DataError.HostNotFound)
		hrResult = E_FAIL
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
			ProcessDataError(pIContext, pIRequest, DataError.SiteNotFound)
			hrResult = E_FAIL
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
				ProcessDataError(pIContext, pIRequest, DataError.MovedPermanently)
				hrResult = E_FAIL
			Else
				
				Dim pIMemoryAllocator As IMalloc Ptr = Any
				IClientContext_GetMemoryAllocator(pIContext, @pIMemoryAllocator)
				
				Dim RequestedFileAccess As FileAccess = Any
				Dim pIProcessor As IRequestProcessor Ptr = Any
				Dim hrCreateRequestProcessor As HRESULT = Any
				
				Select Case HttpMethod
					
					Case HttpMethods.HttpGet
						RequestedFileAccess = FileAccess.ReadAccess
						hrCreateRequestProcessor = CreateInstance( _
							pIMemoryAllocator, _
							@CLSID_HTTPGETPROCESSOR, _
							@IID_IRequestProcessor, _
							@pIProcessor _
						)
						
					Case HttpMethods.HttpHead
						IServerResponse_SetSendOnlyHeaders(pIResponse, True)
						RequestedFileAccess = FileAccess.ReadAccess
						hrCreateRequestProcessor = CreateInstance( _
							pIMemoryAllocator, _
							@CLSID_HTTPGETPROCESSOR, _
							@IID_IRequestProcessor, _
							@pIProcessor _
						)
						
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
						
					Case Else
						RequestedFileAccess = FileAccess.ReadAccess
						pIProcessor = NULL
						hrCreateRequestProcessor = E_OUTOFMEMORY
						
				End Select
				
				If FAILED(hrCreateRequestProcessor) Then
					ProcessDataError(pIContext, pIRequest, DataError.HttpMethodNotSupported)
					hrResult = E_FAIL
				Else
					Dim pIFile As IRequestedFile Ptr = Any
					Dim hrCreateRequestedFile As HRESULT = CreateInstance( _
						pIMemoryAllocator, _
						@CLSID_REQUESTEDFILE, _
						@IID_IRequestedFile, _
						@pIFile _
					)
					If FAILED(hrCreateRequestedFile) Then
						ProcessDataError(pIContext, pIRequest, DataError.NotEnoughMemory)
						hrResult = E_FAIL
					Else
						Dim pIHttpReader As IHttpReader Ptr = Any
						IClientContext_GetHttpReader(pIContext, @pIHttpReader)
						
						Dim hrGetFile As HRESULT = IWebSite_OpenRequestedFile( _
							pIWebSite, _
							pIFile, _
							@ClientURI.Path, _
							RequestedFileAccess _
						)
						
						Dim pc As ProcessorContext = Any
						pc.pIRequest = pIRequest
						pc.pIResponse = pIResponse
						pc.pINetworkStream = pINetworkStream
						pc.pIWebSite = pIWebSite
						pc.pIClientReader = pIHttpReader
						pc.pIRequestedFile = pIFile
						pc.pIMemoryAllocator = pIMemoryAllocator
						
						Dim hrPrepare As HRESULT = IRequestProcessor_Prepare( _
							pIProcessor, _
							@pc _
						)
						If FAILED(hrPrepare) Then
							ProcessBeginWriteError(pIContext, pIRequest, hrPrepare)
						Else
							IClientContext_SetOperationCode(pIContext, OperationCodes.WriteResponse)
						
							Dim pINewAsyncResult As IAsyncResult Ptr = Any
							Dim hrBeginProcess As HRESULT = IRequestProcessor_BeginProcess( _
								pIProcessor, _
								@pc, _
								CPtr(IUnknown Ptr, pIContext), _
								@pINewAsyncResult _
							)
							If FAILED(hrBeginProcess) Then
								ProcessBeginWriteError(pIContext, pIRequest, hrBeginProcess)
								hrResult = E_FAIL
							Else
								IClientContext_SetRequestProcessor(pIContext, pIProcessor)
								IClientContext_SetRequestedFile(pIContext, pIFile)
							End If
						End If
						
						IHttpReader_Release(pIHttpReader)
						IRequestedFile_Release(pIFile)
					End If
					
					IRequestProcessor_Release(pIProcessor)
				End If
				
				IMalloc_Release(pIMemoryAllocator)
				
			End If
			
		End If
		
		IWebSite_Release(pIWebSite)
		
	End If
	
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
	IClientRequest_Release(pIRequest)
	
	Return hrResult
	
End Function

Function ProcessWriteOperation( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	Dim pIProcessor As IRequestProcessor Ptr = Any
	IClientContext_GetRequestProcessor(pIContext, @pIProcessor)
	
	Dim hrEndProcess As HRESULT = IRequestProcessor_EndProcess(pIProcessor, pIAsyncResult)
	If FAILED(hrEndProcess) Then
		ProcessEndWriteError(pIContext, pIRequest, hrEndProcess)
		hrResult = E_FAIL
	Else
		Select Case hrEndProcess
			
			Case REQUESTPROCESSOR_S_IO_PENDING
				IClientContext_SetOperationCode(pIContext, OperationCodes.WriteResponse)
				
				Dim pIFile As IRequestedFile Ptr = Any
				IClientContext_GetRequestedFile(pIContext, @pIFile)
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				Dim pIHttpReader As IHttpReader Ptr
				IClientContext_GetHttpReader(pIContext, @pIHttpReader)
				Dim pIWebSite As IWebSite Ptr = Any
				IClientContext_GetWebSite(pIContext, @pIWebSite)
				Dim pIMemoryAllocator As IMalloc Ptr = Any
				IClientContext_GetMemoryAllocator(pIContext, @pIMemoryAllocator)
				
				Dim pc As ProcessorContext = Any
				pc.pIRequest = pIRequest
				pc.pIResponse = pIResponse
				pc.pINetworkStream = pINetworkStream
				pc.pIWebSite = pIWebSite
				pc.pIClientReader = pIHttpReader
				pc.pIRequestedFile = pIFile
				pc.pIMemoryAllocator = pIMemoryAllocator
				
				Dim pINewAsyncResult As IAsyncResult Ptr = Any
				Dim hrBeginProcess As HRESULT = IRequestProcessor_BeginProcess( _
					pIProcessor, _
					@pc, _
					CPtr(IUnknown Ptr, pIContext), _
					@pINewAsyncResult _
				)
				If FAILED(hrBeginProcess) Then
					ProcessBeginWriteError(pIContext, pIRequest, hrBeginProcess)
					hrResult = E_FAIL
				End If
				
				IMalloc_Release(pIMemoryAllocator)
				IWebSite_Release(pIWebSite)
				IHttpReader_Release(pIHttpReader)
				IServerResponse_Release(pIResponse)
				IRequestedFile_Release(pIFile)
				
			Case S_FALSE
				hrEndProcess = E_FAIL
				
			Case Else
				' Запустить чтение заново
				IClientContext_SetRequestProcessor(pIContext, NULL)
				IClientContext_SetRequestedFile(pIContext, NULL)
				
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				
				Dim KeepAlive As Boolean = True
				IServerResponse_GetKeepAlive(pIResponse, @KeepAlive)
				
				If KeepAlive Then
					
					Dim pIHttpReader As IHttpReader Ptr
					IClientContext_GetHttpReader(pIContext, @pIHttpReader)
					
					IHttpReader_Clear(pIHttpReader)
					IClientRequest_Clear(pIRequest)
					IClientContext_SetOperationCode(pIContext, OperationCodes.ReadRequest)
					
					Const NullCallback As AsyncCallback = NULL
					Dim pINewAsyncResult As IAsyncResult Ptr = Any
					Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
						pIRequest, _
						NullCallback, _
						CPtr(IUnknown Ptr, pIContext), _
						@pINewAsyncResult _
					)
					If FAILED(hrBeginReadRequest) Then
						ProcessBeginReadError(pIContext, pIRequest, hrBeginReadRequest)
						hrResult = E_FAIL
					End If
					
					IHttpReader_Release(pIHttpReader)
					
				Else
					hrResult = E_FAIL
				End If
				
				IServerResponse_Release(pIResponse)
				
		End Select
		
	End If
	
	IRequestProcessor_Release(pIProcessor)
	INetworkStream_Release(pINetworkStream)
	IClientRequest_Release(pIRequest)
	
	Return hrResult
	
End Function

Function ProcessCloseOperation( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	' Dim hClientContextHeap As HANDLE = Any
	' IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
	
	IClientContext_Release(pIContext)
	IAsyncResult_Release(pIAsyncResult)
	
	' HeapDestroy(hClientContextHeap)
	
	Return S_FALSE
	
End Function

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
			#ifndef WINDOWS_SERVICE
				PrintErrorCode(!"GetQueuedCompletionStatus\t", dwError)
			#endif
			' If dwError = ERROR_ABANDONED_WAIT_0 Then
				' Exit Do
			' End If
			If pOverlapped = NULL Then
				Exit Do
			End If
			
			' If dwNumberOfBytesTransferred = 0 Then
			' End If
			Dim pIContext As IClientContext Ptr = Any
			IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
			
			' Dim hClientContextHeap As HANDLE = Any
			' IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
			
			IClientContext_Release(pIContext)
			IAsyncResult_Release(pOverlapped->pIAsync)
			
			' HeapDestroy(hClientContextHeap)
			
		Else
			Dim pIContext As IClientContext Ptr = Any
			IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
			
			Dim hrProcess As HRESULT = E_FAIL
			
	#ifndef WINDOWS_SERVICE
		PrintErrorCode(!"dwNumberOfBytesTransferred\t", dwNumberOfBytesTransferred)
	#endif
			If dwNumberOfBytesTransferred <> 0 Then
				Dim OpCode As OperationCodes = Any
				IClientContext_GetOperationCode(pIContext, @OpCode)
				
				Select Case OpCode
					
					Case OperationCodes.ReadRequest
						hrProcess = ProcessReadRequest( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync _
						)
						
					Case OperationCodes.PrepareResponse
						hrProcess = ProcessPrepareResponse( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync, _
							pWorkerContext->pIWebSites _
						)
						
					Case OperationCodes.WriteResponse
						hrProcess = ProcessWriteOperation( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync _
						)
						
					Case OperationCodes.OpClose
						hrProcess = ProcessCloseOperation( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync _
						)
						
				End Select
				
			End If
			
			' Dim hClientContextHeap As HANDLE = Any
			' IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
			
			IClientContext_Release(pIContext)
			IAsyncResult_Release(pOverlapped->pIAsync)
			
			If FAILED(hrProcess) Then
				' HeapDestroy(hClientContextHeap)
				
				' IClientContext_SetOperationCode(pIContext, OperationCodes.OpClose)
				' IClientContext_Release(pIContext)
				
				' Dim res As Integer = PostQueuedCompletionStatus( _
					' pWorkerContext->hIOCompletionPort, _
					' 1, _
					' Cast(ULONG_PTR, 0), _
					' CPtr(LPOVERLAPPED, pOverlapped) _
				' )
				' If res = 0 Then
					' Dim dwError As DWORD = GetLastError()
					' #ifndef WINDOWS_SERVICE
						' PrintErrorCode(!"Ошибка добавления пакета в очередь порта завершения\t", dwError)
					' #endif
				' End If
			Else
				' If hrProcess <> S_FALSE Then
				' End If
			End If
			
		End If
		
	Loop
	
	CloseHandle(pWorkerContext->hThread)
	IWebSiteContainer_Release(pWorkerContext->pIWebSites)
	
	' IMalloc_AddRef(pWorkerContext->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = pWorkerContext->pIMemoryAllocator
	
	IMalloc_Free(pWorkerContext->pIMemoryAllocator, pWorkerContext)
	IMalloc_Release(pIMemoryAllocator)
	
	' IMalloc_Release(pIMemoryAllocator)
	
	Return 0
	
End Function
