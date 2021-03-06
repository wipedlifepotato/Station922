#include "WorkerThread.bi"
#include "AsyncResult.bi"
#include "CreateInstance.bi"
#include "HttpGetProcessor.bi"
#include "IClientContext.bi"
#include "IRequestProcessor.bi"
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

/'
	Sub ReadRequest()
		Dim hrEndReadRequest As HRESULT = Any
		Do
			BeginReadRequest()
			hrEndReadRequest = EndReadRequest()
		Loop While hrEndReadRequest = IO_PENDING
		
		Sub PrepareRequestResponse()
			PrepareRequest()
			PrepareResponse()
			PrepareHttpProcessor()
		End Sub
		
	End Sub
	
	Sub WriteResponse()
		Do
			BeginWriteResponse()
			EndWriteResponse()
		Loop While hrEndWriteResponse = IO_PENDING
	End Sub
'/

Sub ProcessBeginReadError( _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal hrDataError As DataError _
	)
	Dim pIResponse As IServerResponse Ptr = Any
	IClientContext_GetServerResponse(pIContext, @pIResponse)
	Dim pINetworkStream As INetworkStream Ptr = Any
	IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
	
	Select Case hrDataError
		
		Case DataError.NotEnoughMemory
			WriteHttpNotEnoughMemory(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), NULL)
			
	End Select
	
	INetworkStream_Release(pINetworkStream)
	IServerResponse_Release(pIResponse)
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

Function PrepareRequestResponse( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pIWebSites As IWebSiteContainer Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	
	hrResult = IClientRequest_Prepare(pIRequest)
	If FAILED(hrResult) Then
		ProcessEndReadError(pIContext, pIRequest, hrResult)
		hrResult = E_FAIL
	Else
		
		' IHttpWriter_Clear(pIHttpWriter)
		
		Dim pIResponse As IServerResponse Ptr = Any
		IClientContext_GetServerResponse(pIContext, @pIResponse)
		IServerResponse_Clear(pIResponse)
		
		Scope
			Dim KeepAlive As Boolean = True
			IClientRequest_GetKeepAlive(pIRequest, @KeepAlive)
			IServerResponse_SetKeepAlive(pIResponse, KeepAlive)
		End Scope
		
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
		IServerResponse_SetHttpVersion(pIResponse, HttpVersion)
		
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
						IClientContext_SetRequestProcessor(pIContext, pIProcessor)
						
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
							IClientContext_SetRequestedFile(pIContext, pIFile)
							
							Dim hrGetFile As HRESULT = IWebSite_OpenRequestedFile( _
								pIWebSite, _
								pIFile, _
								@ClientURI.Path, _
								RequestedFileAccess _
							)
							If FAILED(hrGetFile) Then
								ProcessDataError(pIContext, pIRequest, DataError.NotEnoughMemory)
								hrResult = E_FAIL
							Else
								
								Dim pINetworkStream As INetworkStream Ptr = Any
								IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
								Dim pIHttpReader As IHttpReader Ptr = Any
								IClientContext_GetHttpReader(pIContext, @pIHttpReader)
								
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
									End If
									
								End If
								
								IHttpReader_Release(pIHttpReader)
								INetworkStream_Release(pINetworkStream)
							End If
							
							IRequestedFile_Release(pIFile)
						End If
						
						IRequestProcessor_Release(pIProcessor)
					End If
					
					IMalloc_Release(pIMemoryAllocator)
					
				End If
				
			End If
			
			IWebSite_Release(pIWebSite)
			
		End If
		
		IServerResponse_Release(pIResponse)
		
	End If
	
	IClientRequest_Release(pIRequest)
	
	Return hrResult
	
End Function

Function ReadRequest( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pIWebSites As IWebSiteContainer Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	Dim hrEndReadRequest As HRESULT = Any
	
	Scope
		Dim pIRequest As IClientRequest Ptr = Any
		IClientContext_GetClientRequest(pIContext, @pIRequest)
		
		hrEndReadRequest = IClientRequest_EndReadRequest(pIRequest, pIAsyncResult)
		If FAILED(hrEndReadRequest) Then
			#ifndef WINDOWS_SERVICE
				Dim pIHttpReader2 As IHttpReader Ptr = Any
				IClientContext_GetHttpReader(pIContext, @pIHttpReader2)
				DebugPrint(pIHttpReader2)
				IHttpReader_Release(pIHttpReader2)
			#endif
			ProcessEndReadError(pIContext, pIRequest, hrEndReadRequest)
			IClientRequest_Release(pIRequest)
			Return E_FAIL
		End If
		
		IClientRequest_Release(pIRequest)
	End Scope
	
	Select Case hrEndReadRequest
		
		Case CLIENTREQUEST_S_IO_PENDING
			IClientContext_SetOperationCode(pIContext, OperationCodes.ReadRequest)
			
			Dim pIRequest As IClientRequest Ptr = Any
			IClientContext_GetClientRequest(pIContext, @pIRequest)
			
			Dim pINewAsyncResult As IAsyncResult Ptr = Any
			Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
				pIRequest, _
				CPtr(IUnknown Ptr, pIContext), _
				@pINewAsyncResult _
			)
			If FAILED(hrBeginReadRequest) Then
				ProcessBeginReadError(pIContext, pIRequest, hrBeginReadRequest)
				hrResult = hrBeginReadRequest
			End If
			
			IClientRequest_Release(pIRequest)
			
		Case S_FALSE
			' Клиент закрыл соединение
			#ifndef WINDOWS_SERVICE
				Dim pIHttpReader2 As IHttpReader Ptr = Any
				IClientContext_GetHttpReader(pIContext, @pIHttpReader2)
				DebugPrint(pIHttpReader2)
				IHttpReader_Release(pIHttpReader2)
			#endif
			hrResult = E_FAIL
			
		Case S_OK
			#ifndef WINDOWS_SERVICE
				Dim pIHttpReader2 As IHttpReader Ptr = Any
				IClientContext_GetHttpReader(pIContext, @pIHttpReader2)
				DebugPrint(pIHttpReader2)
				IHttpReader_Release(pIHttpReader2)
			#endif
			
			' Dim pIMemoryAllocator As IMalloc Ptr = Any
			' IClientContext_GetMemoryAllocator(pIContext, @pIMemoryAllocator)
			
			' Dim pINewAsyncResult As IMutableAsyncResult Ptr = Any
			' Dim hr As HRESULT = CreateInstance( _
				' pIMemoryAllocator, _
				' @CLSID_ASYNCRESULT, _
				' @IID_IMutableAsyncResult, _
				' @pINewAsyncResult _
			' )
			' IMalloc_Release(pIMemoryAllocator)
			
			' If FAILED(hr) Then
				' ProcessBeginReadError(pIContext, pIRequest, DataError.NotEnoughMemory)
				' hrResult = hr
			' Else
				hrResult = PrepareRequestResponse( _
					hIoCompletionPort, _
					pIContext, _
					pIAsyncResult, _
					pIWebSites _
				)
				
			' End If
			
	End Select
	
	Return hrResult
	
End Function

Function WriteResponse( _
		ByVal hIoCompletionPort As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	Dim hrResult As HRESULT = S_OK
	Dim hrEndProcess As HRESULT = Any
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pIContext, @pIRequest)
	
	Scope
		Dim pIProcessor As IRequestProcessor Ptr = Any
		IClientContext_GetRequestProcessor(pIContext, @pIProcessor)
		
		hrEndProcess = IRequestProcessor_EndProcess(pIProcessor, pIAsyncResult)
		IRequestProcessor_Release(pIProcessor)
		
		If FAILED(hrEndProcess) Then
			ProcessEndWriteError(pIContext, pIRequest, hrEndProcess)
			hrResult = E_FAIL
		End If
	End Scope
	
	Select Case hrEndProcess
		
		Case REQUESTPROCESSOR_S_IO_PENDING
			IClientContext_SetOperationCode(pIContext, OperationCodes.WriteResponse)
			
			Dim pINetworkStream As INetworkStream Ptr = Any
			IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
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
			
			Dim pIProcessor As IRequestProcessor Ptr = Any
			IClientContext_GetRequestProcessor(pIContext, @pIProcessor)
			
			Dim pINewAsyncResult As IAsyncResult Ptr = Any
			Dim hrBeginProcess As HRESULT = IRequestProcessor_BeginProcess( _
				pIProcessor, _
				@pc, _
				CPtr(IUnknown Ptr, pIContext), _
				@pINewAsyncResult _
			)
			IRequestProcessor_Release(pIProcessor)
			
			If FAILED(hrBeginProcess) Then
				ProcessBeginWriteError(pIContext, pIRequest, hrBeginProcess)
				hrResult = E_FAIL
			End If
			
			IMalloc_Release(pIMemoryAllocator)
			IWebSite_Release(pIWebSite)
			IHttpReader_Release(pIHttpReader)
			IServerResponse_Release(pIResponse)
			IRequestedFile_Release(pIFile)
			INetworkStream_Release(pINetworkStream)
			
		Case S_FALSE
			hrEndProcess = E_FAIL
			
		Case Else
			' Запустить чтение заново
			Dim KeepAlive As Boolean = True
			Scope
				Dim pIResponse As IServerResponse Ptr = Any
				IClientContext_GetServerResponse(pIContext, @pIResponse)
				
				IServerResponse_GetKeepAlive(pIResponse, @KeepAlive)
				
				IServerResponse_Release(pIResponse)
			End Scope
			
			If KeepAlive Then
				' IClientContext_SetRequestProcessor(pIContext, NULL)
				' IClientContext_SetRequestedFile(pIContext, NULL)
				IClientContext_SetOperationCode(pIContext, OperationCodes.ReadRequest)
				
				Scope
					Dim pIHttpReader As IHttpReader Ptr
					IClientContext_GetHttpReader(pIContext, @pIHttpReader)
					IHttpReader_Clear(pIHttpReader)
					IHttpReader_Release(pIHttpReader)
				End Scope
				
				IClientRequest_Clear(pIRequest)
				
				Dim pINewAsyncResult As IAsyncResult Ptr = Any
				Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
					pIRequest, _
					CPtr(IUnknown Ptr, pIContext), _
					@pINewAsyncResult _
				)
				If FAILED(hrBeginReadRequest) Then
					ProcessBeginReadError(pIContext, pIRequest, hrBeginReadRequest)
					hrResult = E_FAIL
				End If
				
			Else
				hrResult = E_FAIL
			End If
			
	End Select
	
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
			#ifndef WINDOWS_SERVICE
				Dim dwError As DWORD = GetLastError()
				DebugPrint(!"GetQueuedCompletionStatus WorkerThread\t", dwError)
			#endif
			' If dwError = ERROR_ABANDONED_WAIT_0 Then
				' Exit Do
			' End If
			If pOverlapped = NULL Then
				Exit Do
			End If
			
			' If dwNumberOfBytesTransferred = 0 Then
			' End If
			' Dim pIContext As IClientContext Ptr = Any
			' IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
			
			' Dim hClientContextHeap As HANDLE = Any
			' IClientContext_GetClientContextHeap(pIContext, @hClientContextHeap)
			
			' IClientContext_Release(pIContext)
			' IAsyncResult_Release(pOverlapped->pIAsync)
			
			' HeapDestroy(hClientContextHeap)
			res = PostQueuedCompletionStatus( _
				pWorkerContext->hIOCompletionClosePort, _
				dwNumberOfBytesTransferred, _
				CompletionKey, _
				CPtr(LPOVERLAPPED, pOverlapped) _
			)
			If res = 0 Then
				#ifndef WINDOWS_SERVICE
					dwError = GetLastError()
					DebugPrint(!"Error to Post CloserCompletionPort\t", dwError)
				#endif
			End If
			
		Else
			#ifndef WINDOWS_SERVICE
				DebugPrint(!"\t\t\tdwNumberOfBytesTransferred\t", dwNumberOfBytesTransferred)
			#endif
			
			If dwNumberOfBytesTransferred <> 0 Then
				Dim pIContext As IClientContext Ptr = Any
				IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
				
				Dim OpCode As OperationCodes = Any
				IClientContext_GetOperationCode(pIContext, @OpCode)
				
				' Dim hrProcess As HRESULT = S_OK
				
				Select Case OpCode
					
					Case OperationCodes.ReadRequest
						' hrProcess = ReadRequest( _
						ReadRequest( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync, _
							pWorkerContext->pIWebSites _
						)
						
					' Case OperationCodes.PrepareResponse
						' hrProcess = PrepareRequestResponse( _
						' PrepareRequestResponse( _
							' pWorkerContext->hIOCompletionPort, _
							' pIContext, _
							' pOverlapped->pIAsync, _
							' pWorkerContext->pIWebSites _
						' )
						
					Case OperationCodes.WriteResponse
						' hrProcess = WriteResponse( _
						WriteResponse( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync _
						)
						
					Case OperationCodes.OpClose
						' hrProcess = ProcessCloseOperation( _
						ProcessCloseOperation( _
							pWorkerContext->hIOCompletionPort, _
							pIContext, _
							pOverlapped->pIAsync _
						)
						
				End Select
				
				IClientContext_Release(pIContext)
				IAsyncResult_Release(pOverlapped->pIAsync)
				
				' If FAILED(hrProcess) Then
					' res = PostQueuedCompletionStatus( _
						' pWorkerContext->hIOCompletionClosePort, _
						' dwNumberOfBytesTransferred, _
						' CompletionKey, _
						' CPtr(LPOVERLAPPED, pOverlapped) _
					' )
					' If res = 0 Then
						' Dim dwError As DWORD = GetLastError()
						' #ifndef WINDOWS_SERVICE
							' DebugPrint(!"Error to Post CloserCompletionPort\t", dwError)
						' #endif
					' End If
				' End If
				
			Else
				
				' Dim pIContext As IClientContext Ptr = Any
				' IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
				' Scope
					' Dim pINetworkStream As INetworkStream Ptr = Any
					' IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
					
					' INetworkStream_Close(pINetworkStream)
					' INetworkStream_Release(pINetworkStream)
				' End Scope
				' IClientContext_Release(pIContext)
				
				res = PostQueuedCompletionStatus( _
					pWorkerContext->hIOCompletionClosePort, _
					dwNumberOfBytesTransferred, _
					CompletionKey, _
					CPtr(LPOVERLAPPED, pOverlapped) _
				)
				If res = 0 Then
					#ifndef WINDOWS_SERVICE
						Dim dwError As DWORD = GetLastError()
						DebugPrint(!"Error to Post CloserCompletionPort\t", dwError)
					#endif
				End If
				
			End If
			
		End If
		
	Loop
	
	CloseHandle(pWorkerContext->hThread)
	IWebSiteContainer_Release(pWorkerContext->pIWebSites)
	CoTaskMemFree(pWorkerContext)
	
	Return 0
	
End Function

Function CloserThread( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim pCloserContext As CloserThreadContext Ptr = CPtr(CloserThreadContext Ptr, lpParam)
	
	' TODO Удалять контексты из списка все что старше трёх секунд пачками
	Do
		
		Dim dwNumberOfBytesTransferred As DWORD = Any
		Dim CompletionKey As ULONG_PTR = Any
		Dim pOverlapped As LPASYNCRESULTOVERLAPPED = Any
		
		Dim res As Integer = GetQueuedCompletionStatus( _
			pCloserContext->hIOCompletionClosePort, _
			@dwNumberOfBytesTransferred, _
			@CompletionKey, _
			CPtr(LPOVERLAPPED Ptr, @pOverlapped), _
			INFINITE _
		)
		If res = 0 Then
			' TODO Обработать ошибку
			#ifndef WINDOWS_SERVICE
				Dim dwError As DWORD = GetLastError()
				DebugPrint(!"GetQueuedCompletionStatus CloserThread\t", dwError)
			#endif
			If pOverlapped = NULL Then
				Exit Do
			End If
			
		Else
			
			' Dim pIContext As IClientContext Ptr = Any
			' IAsyncResult_GetAsyncState(pOverlapped->pIAsync, CPtr(IUnknown Ptr Ptr, @pIContext))
			' IClientContext_Release(pIContext)
			
			Const dwSleepTime As DWORD = 3000
			Sleep_(dwSleepTime)
			IAsyncResult_Release(pOverlapped->pIAsync)
		End If
		
	Loop
	
	CloseHandle(pCloserContext->hThread)
	CoTaskMemFree(pCloserContext)
	
	Return 0
	
End Function
