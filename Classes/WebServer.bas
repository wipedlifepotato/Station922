#include "WebServer.bi"
#include "win\shlwapi.bi"
#include "ThreadProc.bi"
#include "Network.bi"
#include "WebUtils.bi"
#include "IniConst.bi"
#include "WriteHttpError.bi"
#include "WebSite.bi"
#include "NetworkStream.bi"
#include "Configuration.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"

Common Shared GlobalWebServerVirtualTable As IRunnableVirtualTable

Sub InitializeWebServer( _
		ByVal pWebServer As WebServer Ptr _
	)
	
	pWebServer->pVirtualTable = @GlobalWebServerVirtualTable
	pWebServer->ReferenceCounter = 0
	
	Dim ExeFileName As WString * (MAX_PATH + 1) = Any
	Dim ExeFileNameLength As DWORD = GetModuleFileName(0, @ExeFileName, MAX_PATH)
	If ExeFileNameLength = 0 Then
		' Return 4
	End If
	
	lstrcpy(@pWebServer->ExeDir, @ExeFileName)
	PathRemoveFileSpec(@pWebServer->ExeDir)
	
	PathCombine(@pWebServer->SettingsFileName, @pWebServer->ExeDir, @WebServerIniFileString)
	
	Scope
		Dim objWsaData As WSAData = Any
		If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> NO_ERROR Then
			' Return 1
		End If
	End Scope
	
	pWebServer->ReListenSocket = True
	
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
		
		If pWebServer->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pWebServer->ReferenceCounter
	
End Function

Function WebServerRun( _
		ByVal pWebServer As WebServer Ptr _
	)As HRESULT
	
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
	
	Dim WebSitesLength As Integer = GetWebSitesArray(@pWebServer->pWebSitesArray, @pWebServer->ExeDir)
	
	pWebServer->ListenSocket = CreateSocketAndListen(@pWebServer->ListenAddress, @pWebServer->ListenPort)
	If pWebServer->ListenSocket = INVALID_SOCKET Then
		WSACleanup()
		Return E_FAIL
	End If
	
	Dim param As ThreadParam Ptr = VirtualAlloc( _
		0, _
		SizeOf(ThreadParam), _
		MEM_COMMIT Or MEM_RESERVE, _
		PAGE_READWRITE _
	)
	
	If param <> 0 Then
		param->hThread = CreateThread( _
			NULL, _
			0, _
			@ThreadProc, _
			param, _
			CREATE_SUSPENDED, _
			@param->ThreadId _
		)
	End If
	
	Dim RemoteAddress As SOCKADDR_IN = Any
	Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
	
	Dim ClientSocket As SOCKET = accept( _
		pWebServer->ListenSocket, _
		CPtr(SOCKADDR Ptr, @RemoteAddress), _
		@RemoteAddressLength _
	)
	
	Do While pWebServer->ReListenSocket
		
		If ClientSocket = INVALID_SOCKET Then
			SleepEx(60 * 1000, True)
			
			Goto TDLoop
		End If
		
		If param = 0 Then
			Dim tcpStream As NetworkStream = Any
			Dim pINetworkStream As INetworkStream Ptr = InitializeNetworkStreamOfINetworkStream(@tcpStream)
			
			NetworkStream_NonVirtualSetSocket(pINetworkStream, ClientSocket)
			
			Dim request As WebRequest = Any
			InitializeWebRequest(@request)
			
			Dim response As WebResponse = Any
			InitializeWebResponse(@response)
			
			WriteHttpNotEnoughMemory(@request, @response, pINetworkStream, 0)
			
			NetworkStream_NonVirtualRelease(pINetworkStream)
			
			Goto TDLoop
		End If
		
#if __FB_DEBUG__ <> 0
		
		QueryPerformanceFrequency(@param->m_frequency)
		QueryPerformanceCounter(@param->m_startTicks)
		
#endif
		
		param->pINetworkStream = InitializeNetworkStreamOfINetworkStream(@param->tcpStream)
		NetworkStream_NonVirtualSetSocket(param->pINetworkStream, ClientSocket)
		
		If param->hThread = NULL Then
			' TODO Узнать ошибку и обработать
			Dim request As WebRequest = Any
			InitializeWebRequest(@request)
			
			Dim response As WebResponse = Any
			InitializeWebResponse(@response)
			
			WriteHttpCannotCreateThread(@request, @response, param->pINetworkStream, 0)
			
			NetworkStream_NonVirtualRelease(param->pINetworkStream)
			VirtualFree(param, 0, MEM_RELEASE)
			
			Goto TDLoop
		End If
		
		param->ClientSocket = ClientSocket
		param->RemoteAddress = RemoteAddress
		param->RemoteAddressLength = RemoteAddressLength
		param->ServerSocket = pWebServer->ListenSocket
		param->pExeDir = @pWebServer->ExeDir
		param->pWebSitesArray = pWebServer->pWebSitesArray
		
		ResumeThread(param->hThread)
		
TDLoop:
		param = VirtualAlloc( _
			0, _
			SizeOf(ThreadParam), _
			MEM_COMMIT Or MEM_RESERVE, _
			PAGE_READWRITE _
		)
		
		If param <> 0 Then
			param->hThread = CreateThread( _
				NULL, _
				0, _
				@ThreadProc, _
				param, _
				CREATE_SUSPENDED, _
				@param->ThreadId _
			)
		End If
		
		ClientSocket = accept( _
			pWebServer->ListenSocket, _
			CPtr(SOCKADDR Ptr, @RemoteAddress), _
			@RemoteAddressLength _
		)
	Loop
	
	Return S_OK
	
End Function

Function WebServerStop( _
		ByVal pWebServer As WebServer Ptr _
	)As HRESULT
	
	pWebServer->ReListenSocket = False
	CloseSocketConnection(pWebServer->ListenSocket)
	WSACleanup()
	
	Return S_OK
	
End Function
