#include once "ProcessConnectRequest.bi"
#include once "WebUtils.bi"
#include once "IniConst.bi"
#include once "CharConstants.bi"
#include once "Network.bi"
#include once "WriteHttpError.bi"

' Инкапсуляция клиентского и серверного сокетов как параметр для процедуры потока
Type ClientServerSocket
	Dim InSock As SOCKET
	Dim OutSock As SOCKET
	Dim ThreadId As DWord
	Dim hThread As HANDLE
End Type

' Получение данных от входящего сокета и отправка на исходящий
Declare Sub SendReceiveData( _
	ByVal OutSock As SOCKET, _
	ByVal InSock As SOCKET _
)

Declare Function SendReceiveDataThreadProc( _
	ByVal lpParam As LPVOID _
)As DWORD

Function ProcessConnectRequest( _
		ByVal This As IProcessRequest Ptr, _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr, _
		ByVal fileExtention As WString Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal hRequestedFile As Handle _
	)As Boolean
	' Проверка заголовка Authorization
	If HttpAuthUtil(pState, ClientSocket, pWebSite, True) = False Then
		Return False
	End If
	
	' Файл с настройками
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, @pWebSite->PhysicalDirectory, @WebServerIniFileString)
	
	Dim ConnectBindAddress As WString * 256 = Any
	Dim ConnectBindPort As WString * 16 = Any
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindAddressSectionString, @DefaultAddressString, @ConnectBindAddress, 255, @IniFileName)
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindPortSectionString, @ConnectBindDefaultPort, @ConnectBindPort, 15, @IniFileName)
	
	' Соединиться с сервером
	Dim ServiceName As WString Ptr = Any
	Dim wColon As WString Ptr = StrChr(pState->ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderHost), ColonChar)
	If wColon = 0 Then
		ServiceName = @DefaultHttpPort
	Else
		wColon[0] = 0
		If lstrlen(wColon + 1) = 0 Then
			ServiceName = @DefaultHttpPort
		Else
			ServiceName = wColon + 1
		End If
	End If
	
	Dim ServerSocket2 As SOCKET = INVALID_SOCKET
	For i As Integer = 0 To 9
		ServerSocket2 = ConnectToServer(pState->ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderHost), ServiceName, @ConnectBindAddress, @ConnectBindPort)
		If ServerSocket2 <> INVALID_SOCKET Then
			Exit For
		End If
	Next
	
	If ServerSocket2 = INVALID_SOCKET Then
		WriteHttpGatewayTimeout(pState, ClientSocket, pWebSite)
		Return False
	End If

	' Отправить ответ о статусе соединения
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, pState->AllResponseHeadersToBytes(@SendBuffer, 0), 0)
	
	' Читать данные от клиента, отправлять на сервер
	' TODO Исправить ошибку с отправкой локальной переменной в поток
	Dim CSS As ClientServerSocket = Any
	CSS.OutSock = ServerSocket2
	CSS.InSock = ClientSocket
	CSS.hThread = CreateThread(NULL, 0, @SendReceiveDataThreadProc, @CSS, 0, @CSS.ThreadId)
	
	' Читать данные от сервера, отправлять клиенту
	SendReceiveData(ClientSocket, ServerSocket2)
	
	Return True
	
End Function

Sub SendReceiveData(ByVal OutSock As SOCKET, ByVal InSock As SOCKET)
	' Читать данные из входящего сокета, отправлять на исходящий
	Const MaxBytesCount As Integer = 20 * 4096
	Dim ReceiveBuffer As ZString * (MaxBytesCount) = Any
	
	' Получаем данные
	Dim intReceivedBytesCount As Integer = recv(InSock, ReceiveBuffer, MaxBytesCount, 0)
	Do
		Select Case intReceivedBytesCount
			Case SOCKET_ERROR
				' Недействительное ответное сообщение от сервера
				' pState->StatusCode = 502
				' WriteHttpError(pState, ClientSocket, @HttpError504GatewayTimeout, @pWebSite->VirtualPath)
				Exit Sub
			Case 0
				Exit Sub
			Case Else
				' Отправить данные
				If send(OutSock, ReceiveBuffer, intReceivedBytesCount, 0) = SOCKET_ERROR Then
					Exit Sub
				End If
				intReceivedBytesCount = recv(InSock, ReceiveBuffer, MaxBytesCount, 0)
		End Select
	Loop
End Sub

Function SendReceiveDataThreadProc(ByVal lpParam As LPVOID)As DWORD
	Dim CSS As ClientServerSocket Ptr = CPtr(ClientServerSocket Ptr, lpParam)
	SendReceiveData(CSS->OutSock, CSS->InSock)
	
	CloseSocketConnection(CSS->OutSock)
	CloseHandle(CSS->hThread)
	Return 0
End Function
