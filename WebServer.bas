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

Function InitializeWebServer( _
		ByVal pWebServer As WebServer Ptr _
	)As Integer
	
	' Имя исполняемого файла
	Dim ExeFileName As WString * (MAX_PATH + 1) = Any
	Dim ExeFileNameLength As DWORD = GetModuleFileName(0, @ExeFileName, MAX_PATH)
	If ExeFileNameLength = 0 Then
		Return 4
	End If
	
	lstrcpy(@pWebServer->ExeDir, @ExeFileName)
	PathRemoveFileSpec(@pWebServer->ExeDir)
	
	Dim SettingsFileName As WString * (MAX_PATH + 1)
	PathCombine(@SettingsFileName, @pWebServer->ExeDir, @WebServerIniFileString)
	
	Dim ListenAddress As WString * 256 = Any
	Dim ListenPort As WString * 16 = Any
	
	Dim Config As Configuration = Any
	Dim pConfig As IConfiguration Ptr = CPtr(IConfiguration Ptr, New(@Config) Configuration())
	
	pConfig->pVirtualTable->SetIniFilename(pConfig, @SettingsFileName)
	
	Dim ValueLength As Integer = Any
	
	pConfig->pVirtualTable->GetStringValue(pConfig, @WebServerSectionString, @ListenAddressKeyString, @DefaultAddressString, 255, @ListenAddress, @ValueLength)
	pConfig->pVirtualTable->GetStringValue(pConfig, @WebServerSectionString, @PortKeyString, @DefaultHttpPort, 15, @ListenPort, @ValueLength)
	
	Dim WebSitesLength As Integer = GetWebSitesArray(@pWebServer->pWebSitesArray, @pWebServer->ExeDir)
	
	Scope
		Dim objWsaData As WSAData = Any
		If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> NO_ERROR Then
			Return 1
		End If
	End Scope
	
	pWebServer->ListenSocket = CreateSocketAndListen(@ListenAddress, @ListenPort)
	If pWebServer->ListenSocket = INVALID_SOCKET Then
		WSACleanup()
		Return 2
	End If
	
	Return 0
End Function

Sub UninitializeWebServer( _
		ByVal pWebServer As WebServer Ptr _
	)
	
	CloseSocketConnection(pWebServer->ListenSocket)
	WSACleanup()
End Sub

Function WebServerMainLoop( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim pWebServer As WebServer Ptr = lpParam
	
	Dim RemoteAddress As SOCKADDR_IN = Any
	Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
	Dim ClientSocket As SOCKET = accept(pWebServer->ListenSocket, CPtr(SOCKADDR Ptr, @RemoteAddress), @RemoteAddressLength)
	
	Do
		If ClientSocket = INVALID_SOCKET Then
			SleepEx(60 * 1000, True)
		Else
			Dim tcpStream As NetworkStream = Any
			
			Dim pINetworkStream As INetworkStream Ptr = CPtr(INetworkStream Ptr, New(@tcpStream) NetworkStream())
			
			pINetworkStream->pVirtualTable->SetSocket(pINetworkStream, ClientSocket)
			
			Dim param As ThreadParam Ptr = VirtualAlloc(0, SizeOf(ThreadParam), MEM_COMMIT Or MEM_RESERVE, PAGE_READWRITE)
			If param = 0 Then
				' Dim ClientReader As StreamSocketReader = Any
				' InitializeStreamSocketReader(@ClientReader)
				' ClientReader.pStream = pINetworkStream
				
				Dim request As WebRequest = Any
				InitializeWebRequest(@request)
				Dim response As WebResponse = Any
				InitializeWebResponse(@response)
				
				WriteHttpNotEnoughMemory(@request, @response, pINetworkStream, 0)
				
				CloseSocketConnection(ClientSocket)
			Else
				param->ClientSocket = ClientSocket
				param->RemoteAddress = RemoteAddress
				param->RemoteAddressLength = RemoteAddressLength
				param->ServerSocket = pWebServer->ListenSocket
				param->ExeDir = @pWebServer->ExeDir
				param->pWebSitesArray = pWebServer->pWebSitesArray
				
				param->hThread = CreateThread(NULL, 0, @ThreadProc, param, 0, @param->ThreadId)
				
				If param->hThread = NULL Then
					' TODO Узнать ошибку и обработать
					Dim request As WebRequest = Any
					InitializeWebRequest(@request)
					Dim response As WebResponse = Any
					InitializeWebResponse(@response)
					
					WriteHttpCannotCreateThread(@request, @response, pINetworkStream, 0)
					
					CloseSocketConnection(ClientSocket)
					VirtualFree(param, 0, MEM_RELEASE)
				End If
			End If
		End If
		
		ClientSocket = accept(pWebServer->ListenSocket, CPtr(SOCKADDR Ptr, @RemoteAddress), @RemoteAddressLength)
	Loop
	
	Return 0
End Function
