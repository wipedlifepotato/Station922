#include "WebServer.bi"
#include "win\shlwapi.bi"
#include "ClientContext.bi"
#include "Configuration.bi"
#include "ContainerOf.bi"
#include "CreateInstance.bi"
#include "IniConst.bi"
#include "Network.bi"
#include "NetworkServer.bi"
#include "NetworkStream.bi"
#include "ServerResponse.bi"
#include "ThreadProc.bi"
#include "WebSiteContainer.bi"
#include "WriteHttpError.bi"

Extern GlobalWebServerVirtualTable As Const IRunnableVirtualTable

#define CreateSuspendedThread(lpThreadProc, pIContext, lpThreadId) CreateThread(NULL, THREAD_STACK_SIZE, (lpThreadProc), (pIContext), CREATE_SUSPENDED, (lpThreadId))
#define CreateClientContextHeap HeapCreate(HEAP_NO_SERIALIZE, THREADCONTEXT_HEAPINITIALSIZE, THREADCONTEXT_HEAPMAXIMUMSIZE)

Const ListenAddressLengthMaximum As Integer = 255
Const ListenPortLengthMaximum As Integer = 15

Const CLIENTSOCKET_RECEIVE_TIMEOUT As DWORD = 90 * 1000
Const THREAD_STACK_SIZE As SIZE_T_ = 0
Const THREAD_SLEEPING_TIME As DWORD = 60 * 1000
Const THREADCONTEXT_HEAPINITIALSIZE As DWORD = 256000
Const THREADCONTEXT_HEAPMAXIMUMSIZE As DWORD = 256000

Type _WebServer
	Dim lpVtbl As Const IRunnableVirtualTable Ptr
	Dim ReferenceCounter As Integer
	
	' Dim pExeDir As WString Ptr
	Dim LogDir As WString * (MAX_PATH + 1)
	Dim SettingsFileName As WString * (MAX_PATH + 1)
	
	Dim ListenAddress As WString * (ListenAddressLengthMaximum + 1)
	Dim ListenPort As WString * (ListenPortLengthMaximum + 1)
	
	Dim ListenSocket As SOCKET
	Dim ReListenSocket As Boolean
	
	#ifdef PERFORMANCE_TESTING
		Dim Frequency As LARGE_INTEGER
	#endif
	
End Type

Declare Function WebServerReadConfiguration( _
	ByVal this As WebServer Ptr _
)As HRESULT

Dim Shared ExecutableDirectory As WString * (MAX_PATH + 1)

Sub InitializeWebServer( _
		ByVal this As WebServer Ptr _
	)
	
	this->lpVtbl = @GlobalWebServerVirtualTable
	this->ReferenceCounter = 0
	
	Dim ExeFileName As WString * (MAX_PATH + 1) = Any
	Dim ExeFileNameLength As DWORD = GetModuleFileName(0, @ExeFileName, MAX_PATH)
	If ExeFileNameLength = 0 Then
		' Return 4
	End If
	
	lstrcpy(@ExecutableDirectory, @ExeFileName)
	PathRemoveFileSpec(@ExecutableDirectory)
	
	PathCombine(@this->SettingsFileName, @ExecutableDirectory, @WebServerIniFileString)
	
	this->ListenSocket = INVALID_SOCKET
	this->ReListenSocket = True
	
	#ifdef PERFORMANCE_TESTING
		QueryPerformanceFrequency(@this->Frequency)
	#endif
	
End Sub

Sub UnInitializeWebServer( _
		ByVal this As WebServer Ptr _
	)
	
	If this->ListenSocket <> INVALID_SOCKET Then
		closesocket(this->ListenSocket)
	End If
	
End Sub

Function CreateWebServer( _
	)As WebServer Ptr
	
	Dim this As WebServer Ptr = HeapAlloc( _
		GetProcessHeap(), _
		0, _
		SizeOf(WebServer) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeWebServer(this)
	
	Return this
	
End Function

Sub DestroyWebServer( _
		ByVal this As WebServer Ptr _
	)
	
	UnInitializeWebServer(this)
	HeapFree(GetProcessHeap(), 0, this)
	
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

Function WebServerCreateListenSocket( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Dim hr As HRESULT = Any
	Do
		hr = WebServerReadConfiguration(this)
		If FAILED(hr) Then
			Return hr
		End If
		
		Dim hr As HRESULT = CreateSocketAndListen( _
			@this->ListenAddress, _
			@this->ListenPort, _
			@this->ListenSocket _
		)
		
		If FAILED(hr) Then
			' TODO Обработать ошибку
			If this->ReListenSocket Then
				SleepEx(THREAD_SLEEPING_TIME, True)
			Else
				hr = S_FALSE
			End If
		End If
		
	Loop While FAILED(hr)
	
	Return S_OK
	
End Function

Sub CleanUpContext( _
		ByVal hClientContextHeap As HANDLE, _
		ByVal pIContext As IClientContext Ptr, _
		ByVal hThread As HANDLE, _
		ByVal ClientSocket As SOCKET _
	)
	
	If ClientSocket <> INVALID_SOCKET Then
		CloseSocketConnection(ClientSocket)
	End If
	
	If hThread <> NULL Then
		CloseHandle(hThread)
	End If
	
	If pIContext <> NULL Then
		IClientContext_Release(pIContext)
	End If
	
	If hClientContextHeap <> NULL Then
		HeapDestroy(hClientContextHeap)
	End If
	
End Sub

Function WebServerRun( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Dim pIWebSites As IWebSiteContainer Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		GetProcessHeap(), _
		@CLSID_WEBSITECONTAINER, _
		@IID_IWebSiteContainer, _
		@pIWebSites _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	hr = IWebSiteContainer_LoadWebSites(pIWebSites, @ExecutableDirectory)
	If FAILED(hr) Then
		Return hr
	End If
	
	hr = WebServerCreateListenSocket(this)
	If FAILED(hr) OrElse hr = S_FALSE Then
		IWebSiteContainer_Release(pIWebSites)
		Return hr
	End If
	
	' Куча
	Dim hClientContextHeap As HANDLE = CreateClientContextHeap
	Dim dwCreateClientContextHeapErrorCode As DWORD = GetLastError()
	
	' Контекст запроса
	Dim pIContext As IClientContext Ptr = NULL
	Dim hrCreateClientContext As HRESULT = E_FAIL
	If hClientContextHeap <> NULL Then
		hrCreateClientContext = CreateInstance( _
			hClientContextHeap, _
			@CLSID_CLIENTCONTEXT, _
			@IID_IClientContext, _
			@pIContext _
		)
	End If
	
	' Поток клиента
	Dim dwThreadId As DWORD = Any
	Dim hThread As HANDLE = CreateSuspendedThread(@ThreadProc, pIContext, @dwThreadId)
	Dim dwCreateThreadErrorCode As DWORD = GetLastError()
	
	' Сокет клиента
	Dim RemoteAddress As SOCKADDR_IN = Any
	Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
	Dim ClientSocket As SOCKET = accept( _
		this->ListenSocket, _
		CPtr(SOCKADDR Ptr, @RemoteAddress), _
		@RemoteAddressLength _
	)
	Dim SocketErrorCode As Integer = WSAGetLastError()
	
	Do
		If hClientContextHeap <> NULL AndAlso _
				SUCCEEDED(hrCreateClientContext) AndAlso _
				hThread <> NULL AndAlso _
				ClientSocket <> INVALID_SOCKET Then
			
			SetReceiveTimeout(ClientSocket, CLIENTSOCKET_RECEIVE_TIMEOUT)
			
			' Dim pIClientRequest As IClientRequest Ptr = Any
			' IClientContext_GetClientRequest(pIContext, @pIClientRequest)
			
			Dim pINetworkStream As INetworkStream Ptr = Any
			IClientContext_GetNetworkStream(pIContext, @pINetworkStream)
			INetworkStream_SetSocket(pINetworkStream, ClientSocket)
			
			IClientContext_SetRemoteAddress(pIContext, RemoteAddress)
			IClientContext_SetRemoteAddressLength(pIContext, RemoteAddressLength)
			IClientContext_SetThreadId(pIContext, dwThreadId)
			IClientContext_SetThreadHandle(pIContext, hThread)
			IClientContext_SetClientContextHeap(pIContext, hClientContextHeap)
			IClientContext_SetExecutableDirectory(pIContext, @ExecutableDirectory)
			IClientContext_SetWebSiteContainer(pIContext, pIWebSites)
			
			INetworkStream_Release(pINetworkStream)
			' IClientRequest_Release(pIClientRequest)
			
			#ifdef PERFORMANCE_TESTING
				IClientContext_SetFrequency(pIContext, this->Frequency)
				
				Dim StartTicks As LARGE_INTEGER
				QueryPerformanceCounter(@StartTicks)
				
				IClientContext_SetStartTicks(pIContext, StartTicks)
			#endif
			
			Dim dwResume As DWORD = ResumeThread(hThread)
			If dwResume = -1 Then
				' TODO Отправить клиенту сообщение об ошибке сервера
				Dim dwResumeThreadError As DWORD = GetLastError()
				
				CleanUpContext(hClientContextHeap, pIContext, hThread, ClientSocket)
			End If
			
		Else
			' TODO Отправить клиенту сообщение об ошибке сервера
			CleanUpContext(hClientContextHeap, pIContext, hThread, ClientSocket)
			
			If this->ReListenSocket = False Then
				Exit Do
			End If
			
			SleepEx(THREAD_SLEEPING_TIME, True)
			
		End If
		
		hClientContextHeap = CreateClientContextHeap
		dwCreateClientContextHeapErrorCode = GetLastError()
		
		pIContext = NULL
		hrCreateClientContext = E_FAIL
		If hClientContextHeap <> NULL Then
			hrCreateClientContext = CreateInstance( _
				hClientContextHeap, _
				@CLSID_CLIENTCONTEXT, _
				@IID_IClientContext, _
				@pIContext _
			)
		End If
		
		hThread = CreateSuspendedThread(@ThreadProc, pIContext, @dwThreadId)
		dwCreateThreadErrorCode = GetLastError()
		
		ClientSocket = accept( _
			this->ListenSocket, _
			CPtr(SOCKADDR Ptr, @RemoteAddress), _
			@RemoteAddressLength _
		)
		SocketErrorCode = WSAGetLastError()
		
	Loop While this->ReListenSocket
	
	CleanUpContext(hClientContextHeap, pIContext, hThread, ClientSocket)
	
	IWebSiteContainer_Release(pIWebSites)
	
	' IServerResponse_Release(pIResponseDefault)
	' INetworkStream_Release(pINetworkStreamDefault)
	
	Return S_OK
	
End Function

Function WebServerStop( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	this->ReListenSocket = False
	
	If this->ListenSocket <> INVALID_SOCKET Then
		closesocket(this->ListenSocket)
		this->ListenSocket = INVALID_SOCKET
	End If
	
	Return S_OK
	
End Function

Function WebServerReadConfiguration( _
		ByVal this As WebServer Ptr _
	)As HRESULT
	
	Dim pIConfig As IConfiguration Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		GetProcessHeap(), _
		@CLSID_CONFIGURATION, _
		@IID_IConfiguration, _
		@pIConfig _
	)
	
	If FAILED(hr) Then
		Return hr
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
	
	IConfiguration_Release(pIConfig)
	
	Return S_OK
	
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

Dim GlobalWebServerVirtualTable As Const IRunnableVirtualTable = Type( _
	@IWebServerQueryInterface, _
	@IWebServerAddRef, _
	@IWebServerRelease, _
	@IWebServerRun, _
	@IWebServerStop _
)
