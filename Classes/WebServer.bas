#include "WebServer.bi"
#include "win\shlwapi.bi"
#include "ClientContext.bi"
#include "ClientRequest.bi"
#include "Configuration.bi"
#include "ContainerOf.bi"
#include "CreateInstance.bi"
#include "PrintDebugInfo.bi"
#include "IniConst.bi"
#include "Network.bi"
#include "NetworkServer.bi"
#include "NetworkStream.bi"
#include "ServerResponse.bi"
#include "WebSiteContainer.bi"
#include "WorkerThread.bi"
#include "WriteHttpError.bi"

Extern GlobalWebServerVirtualTable As Const IRunnableVirtualTable

Const ListenAddressLengthMaximum As Integer = 255
Const ListenPortLengthMaximum As Integer = 15

Const THREAD_STACK_SIZE As SIZE_T_ = 0
Const THREAD_SLEEPING_TIME As DWORD = 60 * 1000

Type ClientMemoryContext
	Dim pIMemoryAllocator As IMalloc Ptr
	Dim pIContext As IClientContext Ptr
	Dim hrMemoryAllocator As HRESULT
	Dim hrClientContex As HRESULT
End Type

/'
1. Создать хранилище для контекстов клиента
2. На клиентское соединение контекст брать из хранилища
3. Хранилище пустое — удалить старое хранилище, создать новое
'/

Type _WebServer
	Dim lpVtbl As Const IRunnableVirtualTable Ptr
	Dim ReferenceCounter As Integer
	Dim pIMemoryAllocator As IMalloc Ptr
	
	Dim hIOCompletionPort As HANDLE
	Dim hIOCompletionClosePort As HANDLE
	Dim WorkerThreadsCount As Integer
	Dim pIWebSites As IWebSiteContainer Ptr
	Dim pINetworkStream As INetworkStream Ptr
	Dim pIRequest As IClientRequest Ptr
	Dim pIResponse As IServerResponse Ptr
	
	Dim pCachedClientMemoryContext As ClientMemoryContext Ptr
	Dim CachedClientMemoryContextMaximum As Integer
	Dim CachedClientMemoryContextIndex As Integer
	
	Dim Context As Any Ptr
	Dim StatusHandler As RunnableStatusHandler
	
	' Dim pExeDir As WString Ptr
	' Dim LogDir As WString * (MAX_PATH + 1)
	Dim SettingsFileName As WString * (MAX_PATH + 1)
	
	Dim ListenAddress As WString * (ListenAddressLengthMaximum + 1)
	Dim ListenPort As WString * (ListenPortLengthMaximum + 1)
	
	Dim ListenSocket As SOCKET
	Dim CurrentStatus As HRESULT
	
	#ifdef PERFORMANCE_TESTING
		Dim Frequency As LARGE_INTEGER
	#endif
	
End Type

Declare Function AcceptConnection( _
	ByVal this As WebServer Ptr, _
	ByVal pCachedContext As ClientMemoryContext Ptr _
)As HRESULT

Declare Function ReadConfiguration( _
	ByVal this As WebServer Ptr _
)As HRESULT

Declare Function CreateServerSocket( _
	ByVal this As WebServer Ptr _
)As HRESULT

Declare Function InitializeIOCP( _
	ByVal this As WebServer Ptr _
)As HRESULT

Declare Function ProcessErrorAssociateWithIOCP( _
	ByVal this As WebServer Ptr, _
	ByVal ClientSocket As SOCKET, _
	ByVal pCachedContext As ClientMemoryContext Ptr, _
	ByVal dwErrorAccept As Long _
)As HRESULT

Declare Sub SetCurrentStatus( _
	ByVal this As WebServer Ptr, _
	ByVal Status As HRESULT _
)

Declare Function AssociateWithIOCP( _
	ByVal this As WebServer Ptr, _
	ByVal ClientSocket As SOCKET, _
	ByVal CompletionKey As ULONG_PTR _
)As HRESULT

Declare Function GetProcessorsCount( _
)As Integer

Declare Function ServerThread( _
	ByVal lpParam As LPVOID _
)As DWORD

Declare Sub CreateCachedClientMemoryContext( _
	ByVal this As WebServer Ptr _
)

Declare Sub DestroyCachedClientMemoryContext( _
	ByVal this As WebServer Ptr _
)

Dim Shared ExecutableDirectory As WString * (MAX_PATH + 1)

Sub InitializeWebServer( _
		ByVal this As WebServer Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr, _
		ByVal pIWebSites As IWebSiteContainer Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal pIResponse As IServerResponse Ptr _
	)
	
	this->lpVtbl = @GlobalWebServerVirtualTable
	this->ReferenceCounter = 0
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->hIOCompletionPort = NULL
	this->hIOCompletionClosePort = NULL
	this->WorkerThreadsCount = 0
	this->pIWebSites = pIWebSites
	this->pINetworkStream = pINetworkStream
	this->pIRequest = pIRequest
	this->pIResponse = pIResponse
	this->pCachedClientMemoryContext = NULL
	this->CachedClientMemoryContextIndex  = 0
	
	Dim ExeFileName As WString * (MAX_PATH + 1) = Any
	Dim ExeFileNameLength As DWORD = GetModuleFileName(0, @ExeFileName, MAX_PATH)
	If ExeFileNameLength = 0 Then
		' Return 4
	End If
	
	lstrcpy(@ExecutableDirectory, @ExeFileName)
	PathRemoveFileSpec(@ExecutableDirectory)
	
	this->Context = NULL
	this->StatusHandler = NULL
	
	PathCombine(@this->SettingsFileName, @ExecutableDirectory, @WebServerIniFileString)
	
	this->ListenSocket = INVALID_SOCKET
	this->CurrentStatus = RUNNABLE_S_STOPPED
	
	#ifdef PERFORMANCE_TESTING
		QueryPerformanceFrequency(@this->Frequency)
	#endif
	
End Sub

Sub UnInitializeWebServer( _
		ByVal this As WebServer Ptr _
	)
	
	If this->pIWebSites <> NULL Then
		IWebSiteContainer_Release(this->pIWebSites)
	End If
	
	If this->pINetworkStream <> NULL Then
		INetworkStream_Release(this->pINetworkStream)
	End If
	
	If this->pIRequest <> NULL Then
		IClientRequest_Release(this->pIRequest)
	End If
	
	If this->pIResponse <> NULL Then
		IServerResponse_Release(this->pIResponse)
	End If
	
	If this->ListenSocket <> INVALID_SOCKET Then
		closesocket(this->ListenSocket)
	End If
	
	If this->hIOCompletionPort <> NULL Then
		CloseHandle(this->hIOCompletionPort)
	End If
	
	If this->hIOCompletionClosePort <> NULL Then
		CloseHandle(this->hIOCompletionClosePort)
	End If
	
	DestroyCachedClientMemoryContext(this)
	
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateWebServer( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As WebServer Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"WebServer create\t")
	#endif
	
	Dim pIWebSites As IWebSiteContainer Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		pIMemoryAllocator, _
		@CLSID_WEBSITECONTAINER, _
		@IID_IWebSiteContainer, _
		@pIWebSites _
	)
	If SUCCEEDED(hr) Then
		Dim pIRequest As IClientRequest Ptr = Any
		hr = CreateInstance( _
			pIMemoryAllocator, _
			@CLSID_CLIENTREQUEST, _
			@IID_IClientRequest, _
			@pIRequest _
		)
		If SUCCEEDED(hr) Then
			Dim pIResponse As IServerResponse Ptr = Any
			hr = CreateInstance( _
				pIMemoryAllocator, _
				@CLSID_SERVERRESPONSE, _
				@IID_IServerResponse, _
				@pIResponse _
			)
			If SUCCEEDED(hr) Then
				Dim pINetworkStream As INetworkStream Ptr = Any
				hr = CreateInstance( _
					pIMemoryAllocator, _
					@CLSID_NETWORKSTREAM, _
					@IID_INetworkStream, _
					@pINetworkStream _
				)
				If SUCCEEDED(hr) Then
					Dim this As WebServer Ptr = IMalloc_Alloc( _
						pIMemoryAllocator, _
						SizeOf(WebServer) _
					)
					If this <> NULL Then
						InitializeWebServer(this, pIMemoryAllocator, pIWebSites, pINetworkStream, pIRequest, pIResponse)
						Return this
					End If
					
					INetworkStream_Release(pINetworkStream)
					
				End If
				
				IServerResponse_Release(pIResponse)
				
			End If
			
			IClientRequest_Release(pIRequest)
			
		End If
		
		IWebSiteContainer_Release(pIWebSites)
		
	End If
	
	Return NULL
	
End Function

Sub DestroyWebServer( _
		ByVal this As WebServer Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeWebServer(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"WebServer destroyed\t")
	#endif
	
End Sub

Function WebServerQueryInterface( _
		ByVal this As WebServer Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IRunnable, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IUnknown, riid) Then
			*ppv = @this->lpVtbl
		Else
			*ppv = NULL
			Return E_NOINTERFACE
		End If
	End If
	
	WebServerAddRef(this)
	
	Return S_OK
	
End Function

Function WebServerAddRef( _
		ByVal this As WebServer Ptr _
	)As ULONG
	
	this->ReferenceCounter += 1
	
	Return 1
	
End Function

Function WebServerRelease( _
		ByVal this As WebServer Ptr _
	)As ULONG
	
	this->ReferenceCounter -= 1
	
	If this->ReferenceCounter = 0 Then
		
		DestroyWebServer(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function WebServerRun( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	If this->CurrentStatus <> RUNNABLE_S_STOPPED Then
		Return S_FALSE
	End If
	
	SetCurrentStatus(this, RUNNABLE_S_START_PENDING)
	
	Dim hr As HRESULT = ReadConfiguration(this)
	If FAILED(hr) Then
		' TODO Собственный код ошибки
		SetCurrentStatus(this, RUNNABLE_S_STOPPED)
		Return E_OUTOFMEMORY
	End If
	
	hr = IWebSiteContainer_LoadWebSites(this->pIWebSites, @ExecutableDirectory)
	If FAILED(hr) Then
		' TODO Собственный код ошибки
		SetCurrentStatus(this, RUNNABLE_S_STOPPED)
		Return E_OUTOFMEMORY
	End If
	
	hr = CreateServerSocket(this)
	If FAILED(hr) Then
		SetCurrentStatus(this, RUNNABLE_S_STOPPED)
		Return hr
	End If
	
	hr = InitializeIOCP(this)
	If FAILED(hr) Then
		SetCurrentStatus(this, RUNNABLE_S_STOPPED)
		Return hr
	End If
	
	CreateCachedClientMemoryContext(this)
	
	Const DefaultStackSize As SIZE_T_ = 0
	Dim dwThreadId As DWORD = Any
	Dim hThread As HANDLE = CreateThread( _
		NULL, _
		DefaultStackSize, _
		@ServerThread, _
		this, _
		0, _
		@dwThreadId _
	)
	If hThread = NULL Then
		Dim dwError As DWORD = GetLastError()
		SetCurrentStatus(this, RUNNABLE_S_STOPPED)
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	WebServerAddRef(this)
	
	CloseHandle(hThread)
	
	Return S_OK
	
End Function

Function WebServerStop( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	If this->CurrentStatus = RUNNABLE_S_STOPPED Then
		Return S_FALSE
	End If
	
	SetCurrentStatus(this, RUNNABLE_S_STOP_PENDING)
	
	If this->ListenSocket <> INVALID_SOCKET Then
		closesocket(this->ListenSocket)
		this->ListenSocket = INVALID_SOCKET
	End If
	
	If this->hIOCompletionPort <> NULL Then
		CloseHandle(this->hIOCompletionPort)
		this->hIOCompletionPort = NULL
	End If
	
	SetCurrentStatus(this, RUNNABLE_S_STOPPED)
	
	Return S_OK
	
End Function

Function WebServerIsRunning( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Return this->CurrentStatus
	
End Function

Function WebServerRegisterStatusHandler( _
		ByVal this As WebServer Ptr, _
		ByVal Context As Any Ptr, _
		ByVal StatusHandler As RunnableStatusHandler _
	)As HRESULT
	
	this->Context = Context
	this->StatusHandler = StatusHandler
	
	Return S_OK
	
End Function

Sub SetCurrentStatus( _
		ByVal this As WebServer Ptr, _
		ByVal Status As HRESULT _
	)
	
	this->CurrentStatus = Status
	
	If this->StatusHandler <> NULL Then
		this->StatusHandler(this->Context, Status)
	End If
	
End Sub

Function AcceptConnection( _
		ByVal this As WebServer Ptr, _
		ByVal pCachedContext As ClientMemoryContext Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Scope
		Dim RemoteAddress As SOCKADDR_IN = Any
		Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
		ClientSocket = accept( _
			this->ListenSocket, _
			CPtr(SOCKADDR Ptr, @RemoteAddress), _
			@RemoteAddressLength _
		)
		Dim dwErrorAccept As Long = WSAGetLastError()
		
		If FAILED(ProcessErrorAssociateWithIOCP(this, ClientSocket, pCachedContext, dwErrorAccept)) Then
			Return E_FAIL
		End If
		
		' TODO Использовать RemoteAddress и RemoteAddressLength
		' IClientContext_SetRemoteAddress(pCachedContext->pIContext, RemoteAddress)
		' IClientContext_SetRemoteAddressLength(pCachedContext->pIContext, RemoteAddressLength)
	End Scope
	
	Scope
		Dim pINetworkStream As INetworkStream Ptr = Any
		IClientContext_GetNetworkStream(pCachedContext->pIContext, @pINetworkStream)
		INetworkStream_SetSocket(pINetworkStream, ClientSocket)
		INetworkStream_Release(pINetworkStream)
	End Scope
	
	Dim pIRequest As IClientRequest Ptr = Any
	IClientContext_GetClientRequest(pCachedContext->pIContext, @pIRequest)
	
	#ifdef PERFORMANCE_TESTING
		IClientContext_SetFrequency(pCachedContext->pIContext, this->Frequency)
		
		Dim StartTicks As LARGE_INTEGER
		QueryPerformanceCounter(@StartTicks)
		
		IClientContext_SetStartTicks(pCachedContext->pIContext, StartTicks)
	#endif
	
	Dim pIAsyncResult As IAsyncResult Ptr = Any
	Dim hrBeginReadRequest As HRESULT = IClientRequest_BeginReadRequest( _
		pIRequest, _
		CPtr(IUnknown Ptr, pCachedContext->pIContext), _
		@pIAsyncResult _
	)
	IClientRequest_Release(pIRequest)
	IClientContext_Release(pCachedContext->pIContext)
	
	If FAILED(hrBeginReadRequest) Then
		#ifndef WINDOWS_SERVICE
			DebugPrint(!"Error IClientRequest_BeginReadRequest\t", hrBeginReadRequest)
		#endif
		' TODO Отправить клиенту Не могу начать асинхронное чтение
		' CloseSocketConnection(ClientSocket)
		Return S_FALSE
	End If
	
	' Ссылка на pIContext сохранена в pIAsyncResult
	' Указатель на pIAsyncResult сохранён в структуре OVERLAPPED
	
	Return S_OK
	
End Function

Function ProcessErrorAssociateWithIOCP( _
		ByVal this As WebServer Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pCachedContext As ClientMemoryContext Ptr, _
		ByVal dwErrorAccept As Long _
	)As HRESULT
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"\r\n\r\n\r\nClient connected\t", dwErrorAccept)
	#endif
	
	Scope
		If ClientSocket = INVALID_SOCKET Then
			If pCachedContext->pIContext <> NULL Then
				IClientContext_Release(pCachedContext->pIContext)
			End If
			Return HRESULT_FROM_WIN32(dwErrorAccept)
		End If
		
		If pCachedContext->pIMemoryAllocator = NULL Then
			' TODO Отправить клиенту Не могу создать кучу памяти
			INetworkStream_SetSocket(this->pINetworkStream, ClientSocket)
			WriteHttpNotEnoughMemory(this->pIRequest, this->pIResponse, CPtr(IBaseStream Ptr, this->pINetworkStream), NULL)
			' CloseSocketConnection(ClientSocket)
			Return pCachedContext->hrMemoryAllocator
		End If
		
		If FAILED(pCachedContext->hrClientContex) Then
			' TODO Отправить клиенту Не могу выделить память в куче
			INetworkStream_SetSocket(this->pINetworkStream, ClientSocket)
			WriteHttpNotEnoughMemory(this->pIRequest, this->pIResponse, CPtr(IBaseStream Ptr, this->pINetworkStream), NULL)
			' CloseSocketConnection(ClientSocket)
			Return pCachedContext->hrClientContex
		End If
		
		Dim hrAssociate As HRESULT = AssociateWithIOCP( _
			this, _
			ClientSocket, _
			0 _
		)
		If FAILED(hrAssociate) Then
			IClientContext_Release(pCachedContext->pIContext)
			' TODO Отправить клиенту Не могу ассоциировать с портом завершения
			INetworkStream_SetSocket(this->pINetworkStream, ClientSocket)
			WriteHttpNotEnoughMemory(this->pIRequest, this->pIResponse, CPtr(IBaseStream Ptr, this->pINetworkStream), NULL)
			' CloseSocketConnection(ClientSocket)
			Return hrAssociate
		End If
		
	End Scope
	
	Return S_OK
	
End Function

Sub CreateCachedClientMemoryContext( _
		ByVal this As WebServer Ptr _
	)
	' TODO Асинхронное создание списка контекстов
	this->pCachedClientMemoryContext = IMalloc_Alloc( _
		this->pIMemoryAllocator, _
		this->CachedClientMemoryContextMaximum * SizeOf(ClientMemoryContext) _
	)
	
	If this->pCachedClientMemoryContext <> NULL Then
		
		For i As Integer = 0 To this->CachedClientMemoryContextMaximum - 1
			
			Dim pCachedContext As ClientMemoryContext Ptr = @this->pCachedClientMemoryContext[i]
			pCachedContext->hrMemoryAllocator = CoGetPrivateHeapMalloc( _
				1, _
				@pCachedContext->pIMemoryAllocator _
			)
			
			If SUCCEEDED(pCachedContext->hrMemoryAllocator) Then
				pCachedContext->hrClientContex = CreateInstance( _
					pCachedContext->pIMemoryAllocator, _
					@CLSID_CLIENTCONTEXT, _
					@IID_IClientContext, _
					@pCachedContext->pIContext _
				)
				
				If SUCCEEDED(pCachedContext->hrClientContex) Then
					IClientContext_SetOperationCode(pCachedContext->pIContext, OperationCodes.ReadRequest)
					
					Dim pIReader As IHttpReader Ptr = Any
					IClientContext_GetHttpReader(pCachedContext->pIContext, @pIReader)
					
					Scope
						Dim pINetworkStream As INetworkStream Ptr = Any
						IClientContext_GetNetworkStream(pCachedContext->pIContext, @pINetworkStream)
						IHttpReader_SetBaseStream(pIReader, CPtr(IBaseStream Ptr, pINetworkStream))
						INetworkStream_Release(pINetworkStream)
					End Scope
					
					Scope
						Dim pIRequest As IClientRequest Ptr = Any
						IClientContext_GetClientRequest(pCachedContext->pIContext, @pIRequest)
						IClientRequest_SetTextReader(pIRequest, CPtr(ITextReader Ptr, pIReader))
						IClientRequest_Release(pIRequest)
					End Scope
					
					IHttpReader_Release(pIReader)
					
				End If
				
			End If
			
		Next
		
	End If
	
End Sub

Sub DestroyCachedClientMemoryContext( _
		ByVal this As WebServer Ptr _
	)
	
	For i As Integer = 0 To this->CachedClientMemoryContextMaximum - 1
		Dim pCachedContext As ClientMemoryContext Ptr = @this->pCachedClientMemoryContext[i]
		IMalloc_Release(pCachedContext->pIMemoryAllocator)
		' IClientContext_Release(pCachedContext->pIContext)
	Next
	
	If this->pCachedClientMemoryContext <> NULL Then
		IMalloc_Free(this->pIMemoryAllocator, this->pCachedClientMemoryContext)
	End If
	
End Sub

Function CreateServerSocket( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Dim hr As HRESULT = CreateSocketAndListen( _
		@this->ListenAddress, _
		@this->ListenPort, _
		@this->ListenSocket _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	Return S_OK
	
End Function

Function ReadConfiguration( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Dim pIConfig As IConfiguration Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		this->pIMemoryAllocator, _
		@CLSID_CONFIGURATION, _
		@IID_IConfiguration, _
		@pIConfig _
	)
	If FAILED(hr) Then
		Return E_OUTOFMEMORY
	End If
	
	IConfiguration_SetIniFilename(pIConfig, @this->SettingsFileName)
	
	Dim ValueLength As Integer = Any
	
	IConfiguration_GetStringValue(pIConfig, _
		@WebServerSectionString, _
		@ListenAddressKeyString, _
		@DefaultAddressString, _
		ListenAddressLengthMaximum, _
		@this->ListenAddress, _
		@ValueLength _
	)
	
	IConfiguration_GetStringValue(pIConfig, _
		@WebServerSectionString, _
		@PortKeyString, _
		@DefaultHttpPort, _
		ListenPortLengthMaximum, _
		@this->ListenPort, _
		@ValueLength _
	)
	
	Dim DefaultWorkerThreadsCount As Integer = 2 * GetProcessorsCount()
	
	IConfiguration_GetIntegerValue(pIConfig, _
		@WebServerSectionString, _
		@MaxWorkerThreadsKeyString, _
		DefaultWorkerThreadsCount, _
		@this->WorkerThreadsCount _
	)
	
	Const DefaultCachedClientMemoryContextMaximum As Integer = 1
	IConfiguration_GetIntegerValue(pIConfig, _
		@WebServerSectionString, _
		@MaxCachedClientMemoryContextKeyString, _
		DefaultCachedClientMemoryContextMaximum, _
		@this->CachedClientMemoryContextMaximum _
	)
	
	IConfiguration_Release(pIConfig)
	
	Return S_OK

End Function

Function GetProcessorsCount()As Integer
	
	Dim si As SYSTEM_INFO
	GetSystemInfo(@si)
	Return si.dwNumberOfProcessors
	
End Function

Function InitializeIOCP( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	this->hIOCompletionPort = CreateIoCompletionPort( _
		INVALID_HANDLE_VALUE, _
		NULL, _
		Cast(ULONG_PTR, 0), _
		this->WorkerThreadsCount _
	)
	If this->hIOCompletionPort = NULL Then
		Dim dwError As DWORD = GetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	this->hIOCompletionClosePort = CreateIoCompletionPort( _
		INVALID_HANDLE_VALUE, _
		NULL, _
		Cast(ULONG_PTR, 0), _
		this->WorkerThreadsCount _
	)
	If this->hIOCompletionClosePort = NULL Then
		Dim dwError As DWORD = GetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Const DefaultStackSize As SIZE_T_ = 0
	
	For i As Integer = 0 To this->WorkerThreadsCount - 1
		
		Dim pWorkerContext As WorkerThreadContext Ptr = CoTaskMemAlloc(SizeOf(WorkerThreadContext))
		If pWorkerContext = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		pWorkerContext->hIOCompletionPort = this->hIOCompletionPort
		pWorkerContext->hIOCompletionClosePort = this->hIOCompletionClosePort
		IWebSiteContainer_AddRef(this->pIWebSites)
		pWorkerContext->pIWebSites = this->pIWebSites
		
		pWorkerContext->hThread = CreateThread( _
			NULL, _
			DefaultStackSize, _
			@WorkerThread, _
			pWorkerContext, _
			0, _
			@pWorkerContext->ThreadId _
		)
		If pWorkerContext->hThread = NULL Then
			Dim dwError As DWORD = GetLastError()
			Return HRESULT_FROM_WIN32(dwError)
		End If
		
	Next
	
	For i As Integer = 0 To this->WorkerThreadsCount - 1
		
		Dim pCloserThreadContext As CloserThreadContext Ptr = CoTaskMemAlloc(SizeOf(CloserThreadContext))
		If pCloserThreadContext = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		pCloserThreadContext->hIOCompletionClosePort = this->hIOCompletionClosePort
		
		pCloserThreadContext->hThread = CreateThread( _
			NULL, _
			DefaultStackSize, _
			@CloserThread, _
			pCloserThreadContext, _
			0, _
			@pCloserThreadContext->ThreadId _
		)
		If pCloserThreadContext->hThread = NULL Then
			Dim dwError As DWORD = GetLastError()
			Return HRESULT_FROM_WIN32(dwError)
		End If
		
	Next
	
	Return S_OK
	
End Function

Function AssociateWithIOCP( _
		ByVal this As WebServer Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal CompletionKey As ULONG_PTR _
	)As HRESULT
	
	Dim hPort As HANDLE = CreateIoCompletionPort( _
		Cast(HANDLE, ClientSocket), _
		this->hIOCompletionPort, _
		CompletionKey, _
		0 _
	)
	If hPort = NULL Then
		Return HRESULT_FROM_WIN32(GetLastError())
	End If
	
	Return S_OK
	
End Function

Function ServerThread( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim this As WebServer Ptr = lpParam
	
	SetCurrentStatus(this, RUNNABLE_S_RUNNING)
	
	Do
		If this->CachedClientMemoryContextIndex >= this->CachedClientMemoryContextMaximum Then
			this->CachedClientMemoryContextIndex = 0
			DestroyCachedClientMemoryContext(this)
			CreateCachedClientMemoryContext(this)
		End If
		
		IClientRequest_Clear(this->pIRequest)
		IServerResponse_Clear(this->pIResponse)
		Dim hr As HRESULT = AcceptConnection( _
			this, _
			@this->pCachedClientMemoryContext[this->CachedClientMemoryContextIndex] _
		)
		INetworkStream_Close(this->pINetworkStream)
		
		this->CachedClientMemoryContextIndex += 1
		
		If FAILED(hr) Then
			If this->CurrentStatus = RUNNABLE_S_RUNNING Then
				Sleep_(THREAD_SLEEPING_TIME)
			Else
				Exit Do
			End If
		End If
		
	Loop While this->CurrentStatus = RUNNABLE_S_RUNNING
	
	WebServerStop(this)
	
	WebServerRelease(this)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"Останавливаю сервер\t")
	#endif
	
	Return 0
	
End Function


Function IWebServerQueryInterface( _
		ByVal this As IRunnable Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	Return WebServerQueryInterface(ContainerOf(this, WebServer, lpVtbl), riid, ppv)
End Function

Function IWebServerAddRef( _
		ByVal this As IRunnable Ptr _
	)As ULONG
	Return WebServerAddRef(ContainerOf(this, WebServer, lpVtbl))
End Function

Function IWebServerRelease( _
		ByVal this As IRunnable Ptr _
	)As ULONG
	Return WebServerRelease(ContainerOf(this, WebServer, lpVtbl))
End Function

Function IWebServerRun( _
		ByVal this As IRunnable Ptr _
	)As HRESULT
	Return WebServerRun(ContainerOf(this, WebServer, lpVtbl))
End Function

Function IWebServerStop( _
		ByVal this As IRunnable Ptr _
	)As HRESULT
	Return WebServerStop(ContainerOf(this, WebServer, lpVtbl))
End Function

Function IWebServerIsRunning( _
		ByVal this As IRunnable Ptr _
	)As HRESULT
	Return WebServerIsRunning(ContainerOf(this, WebServer, lpVtbl))
End Function

Function IWebServerRegisterStatusHandler( _
		ByVal this As IRunnable Ptr, _
		ByVal Context As Any Ptr, _
		ByVal StatusHandler As RunnableStatusHandler _
	)As HRESULT
	Return WebServerRegisterStatusHandler(ContainerOf(this, WebServer, lpVtbl), Context, StatusHandler)
End Function

' Function IWebServerSuspend( _
		' ByVal this As IRunnable Ptr _
	' )As HRESULT
	' Return WebServerSuspend(ContainerOf(this, WebServer, lpVtbl))
' End Function

' Function IWebServerResume( _
		' ByVal this As IRunnable Ptr _
	' )As HRESULT
	' Return WebServerResume(ContainerOf(this, WebServer, lpVtbl))
' End Function

Dim GlobalWebServerVirtualTable As Const IRunnableVirtualTable = Type( _
	@IWebServerQueryInterface, _
	@IWebServerAddRef, _
	@IWebServerRelease, _
	@IWebServerRun, _
	@IWebServerStop, _
	@IWebServerIsRunning, _
	@IWebServerRegisterStatusHandler _
)
