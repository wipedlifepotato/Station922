#include "WebServer.bi"
#include "win\shlwapi.bi"
#include "ClientRequest.bi"
#include "Configuration.bi"
#include "IniConst.bi"
#include "Network.bi"
#include "NetworkServer.bi"
#include "NetworkStream.bi"
#include "ServerResponse.bi"
#include "ThreadProc.bi"
#include "WebUtils.bi"
#include "WriteHttpError.bi"

Const ClientSocketReceiveTimeout As DWORD = 90 * 1000
Const DefaultStackSize As SIZE_T_ = 0
Const SleepTimeout As DWORD = 60 * 1000

Common Shared GlobalWebServerVirtualTable As IRunnableVirtualTable

Sub InitializeWebServerVirtualTable()
	GlobalWebServerVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @WebServerQueryInterface)
	GlobalWebServerVirtualTable.InheritedTable.Addref = Cast(Any Ptr, @WebServerAddRef)
	GlobalWebServerVirtualTable.InheritedTable.Release = Cast(Any Ptr, @WebServerRelease)
	GlobalWebServerVirtualTable.Run = Cast(Any Ptr, @WebServerRun)
	GlobalWebServerVirtualTable.Stop = Cast(Any Ptr, @WebServerStop)
End Sub

Sub InitializeWebServer( _
		ByVal pWebServer As WebServer Ptr _
	)
	
	pWebServer->pVirtualTable = @GlobalWebServerVirtualTable
	pWebServer->ReferenceCounter = 0
	
	pWebServer->hHeap = GetProcessHeap()
	
	Dim ExeFileName As WString * (MAX_PATH + 1) = Any
	Dim ExeFileNameLength As DWORD = GetModuleFileName(0, @ExeFileName, MAX_PATH)
	If ExeFileNameLength = 0 Then
		' Return 4
	End If
	
	' TODO Придумать как очистить память
	pWebServer->pExeDir = HeapAlloc( _
		pWebServer->hHeap, _
		0, _
		(MAX_PATH + 1) * SizeOf(WString) _
	)
	
	lstrcpy(pWebServer->pExeDir, @ExeFileName)
	PathRemoveFileSpec(pWebServer->pExeDir)
	
	PathCombine(@pWebServer->SettingsFileName, pWebServer->pExeDir, @WebServerIniFileString)
	
	Scope
		Dim objWsaData As WSAData = Any
		If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> NO_ERROR Then
			' Return 1
		End If
	End Scope
	
	pWebServer->ReListenSocket = True
	QueryPerformanceFrequency(@pWebServer->Frequency)
	
End Sub

Sub UnInitializeWebServer( _
		ByVal pWebServer As WebServer Ptr _
	)
	
	WSACleanup()
	
End Sub

Function InitializeWebServerOfIRunnable( _
		ByVal pWebServer As WebServer Ptr _
	)As IRunnable Ptr
	
	InitializeWebServer(pWebServer)
	pWebServer->ExistsInStack = True
	
	Dim pIWebServer As IRunnable Ptr = Any
	
	WebServerQueryInterface( _
		pWebServer, @IID_IRUNNABLE, @pIWebServer _
	)
	
	Return pIWebServer
	
End Function

Function WebServerQueryInterface( _
		ByVal pWebServer As WebServer Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, @pWebServer->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_IRUNNABLE, riid) Then
		*ppv = CPtr(IRunnable Ptr, @pWebServer->pVirtualTable)
	End If
	
	If *ppv = 0 Then
		Return E_NOINTERFACE
	End If
	
	WebServerAddRef(pWebServer)
	
	Return S_OK
	
End Function

Function WebServerAddRef( _
		ByVal pWebServer As WebServer Ptr _
	)As ULONG
	
	Return InterlockedIncrement(@pWebServer->ReferenceCounter)
	
End Function

Function WebServerRelease( _
		ByVal pWebServer As WebServer Ptr _
	)As ULONG
	
	InterlockedDecrement(@pWebServer->ReferenceCounter)
	
	If pWebServer->ReferenceCounter = 0 Then
		
		UnInitializeWebServer(pWebServer)
		
		If pWebServer->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pWebServer->ReferenceCounter
	
End Function

Function WebServerRun( _
		ByVal pWebServer As WebServer Ptr _
	)As HRESULT
	
	Scope
		
		Dim Config As Configuration = Any
		Dim pIConfig As IConfiguration Ptr = InitializeConfigurationOfIConfiguration(@Config)
		
		Configuration_NonVirtualSetIniFilename(pIConfig, @pWebServer->SettingsFileName)
		
		Dim ValueLength As Integer = Any
		
		Configuration_NonVirtualGetStringValue(pIConfig, _
			@WebServerSectionString, _
			@ListenAddressKeyString, _
			@DefaultAddressString, _
			WebServer.ListenAddressLengthMaximum, _
			@pWebServer->ListenAddress, _
			@ValueLength _
		)
		
		Configuration_NonVirtualGetStringValue(pIConfig, _
			@WebServerSectionString, _
			@PortKeyString, _
			@DefaultHttpPort, _
			WebServer.ListenPortLengthMaximum, _
			@pWebServer->ListenPort, _
			@ValueLength _
		)
		
		Configuration_NonVirtualRelease(pIConfig)
		
	End Scope
	
	Dim pIWebSites As IWebSiteContainer Ptr = CreateWebSiteContainerOfIWebSiteContainer()
	
	If pIWebSites = NULL Then
		Return E_OUTOFMEMORY
	End If
	
	WebSiteContainer_NonVirtualLoadWebSites(pIWebSites, pWebServer->pExeDir)
	
	Dim hrCreateSocket As HRESULT = CreateSocketAndListen( _
		@pWebServer->ListenAddress, _
		@pWebServer->ListenPort, _
		@pWebServer->ListenSocket _
	)
	
	If FAILED(hrCreateSocket) Then
		Return hrCreateSocket
	End If
	
	Do
		
		Dim pContext As ThreadContext Ptr = HeapAlloc( _
			pWebServer->hHeap, _
			0, _
			SizeOf(ThreadContext) _
		)
		
		Dim dwThreadId As DWORD = Any
		Dim hThread As HANDLE = CreateThread( _
			NULL, _
			DefaultStackSize, _
			@ThreadProc, _
			pContext, _
			CREATE_SUSPENDED, _
			@dwThreadId _
		)
		Dim dwCreateThreadErrorCode As DWORD = GetLastError()
		
		Dim RemoteAddress As SOCKADDR_IN = Any
		Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
		
		Dim ClientSocket As SOCKET = accept( _
			pWebServer->ListenSocket, _
			CPtr(SOCKADDR Ptr, @RemoteAddress), _
			@RemoteAddressLength _
		)
		
		If ClientSocket = INVALID_SOCKET Then
			
			' TODO Узнать ошибку и обработать
			Dim ErrorCode As Integer = GetLastError()
			SleepEx(SleepTimeout, True)
			
		Else
			
			If pContext = NULL OrElse hThread = NULL Then
				Dim tcpStream As NetworkStream = Any
				Dim pINetworkStream As INetworkStream Ptr = InitializeNetworkStreamOfINetworkStream(@tcpStream)
				
				NetworkStream_NonVirtualSetSocket(pINetworkStream, ClientSocket)
				
				Dim request As ClientRequest = Any
				Dim pIClientRequest As IClientRequest Ptr = InitializeClientRequestOfIClientRequest(@request)
				
				Dim response As ServerResponse = Any
				Dim pIResponse As IServerResponse Ptr = InitializeServerResponseOfIServerResponse(@response)
				
				If pContext = NULL Then
					WriteHttpNotEnoughMemory( _
						pIClientRequest, _
						pIResponse, _
						CPtr(IBaseStream Ptr, pINetworkStream), _
						NULL _
					)
				Else
					WriteHttpCannotCreateThread( _
						pIClientRequest, _
						pIResponse, _
						CPtr(IBaseStream Ptr, pINetworkStream), _
						NULL _
					)
				End If
				
				IServerResponse_Release(pIResponse)
				IClientRequest_Release(pIClientRequest)
				
				NetworkStream_NonVirtualRelease(pINetworkStream)
				
				If pWebServer->hHeap <> NULL Then
					HeapFree(pWebServer->hHeap, 0, pContext)
				End If
				
				If hThread <> NULL Then
					CloseHandle(hThread)
				End If
				
			Else
				
				SetReceiveTimeout(ClientSocket, ClientSocketReceiveTimeout)
				
				pContext->ClientSocket = ClientSocket
				pContext->ServerSocket = pWebServer->ListenSocket
				
				pContext->pINetworkStream = InitializeNetworkStreamOfINetworkStream(@pContext->tcpStream)
				NetworkStream_NonVirtualSetSocket(pContext->pINetworkStream, ClientSocket)
				
				pContext->RemoteAddress = RemoteAddress
				pContext->RemoteAddressLength = RemoteAddressLength
				
				pContext->ThreadId = dwThreadId
				pContext->hThread = hThread
				pContext->pExeDir = pWebServer->pExeDir
				
				WebSiteContainer_NonVirtualAddRef(pIWebSites)
				pContext->pIWebSites = pIWebSites
				
				pContext->Frequency.QuadPart = pWebServer->Frequency.QuadPart
				QueryPerformanceCounter(@pContext->m_startTicks)
				
				ResumeThread(hThread)
				
			End If
			
		End If
		
	Loop While pWebServer->ReListenSocket
	
	WebSiteContainer_NonVirtualRelease(pIWebSites)
	
	Return S_OK
	
End Function

Function WebServerStop( _
		ByVal pWebServer As WebServer Ptr _
	)As HRESULT
	
	pWebServer->ReListenSocket = False
	closesocket(pWebServer->ListenSocket)
	
	Return S_OK
	
End Function
