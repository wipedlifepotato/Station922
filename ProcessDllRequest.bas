#include "ProcessDllRequest.bi"
#include "Http.bi"
#include "ServerState.bi"
#include "WebUtils.bi"
#include "WriteHttpError.bi"

Function ProcessDllCgiRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As Boolean
	
	' Создать клиентский буфер
	Dim hMapFile As HANDLE = CreateFileMapping( _
		INVALID_HANDLE_VALUE, _
		0, _
		PAGE_READWRITE, _
		0, _
		MaxClientBufferLength, _
		NULL _
	)
	
	If hMapFile = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка CreateFileMapping", intError
		#endif
		WriteHttpNotEnoughMemory(pRequest, pResponse, pINetworkStream, pIWebSite)
		Return False
	End If
	
	Dim ClientBuffer As Any Ptr = MapViewOfFile( _
		hMapFile, _
		FILE_MAP_ALL_ACCESS, _
		0, _
		0, _
		MaxClientBufferLength _
	)
	
	If ClientBuffer = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка MapViewOfFile", intError
		#endif
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pINetworkStream, pIWebSite)
		Return False
	End If
	
	Dim PathTranslated As WString Ptr = Any
	IRequestedFile_GetPathTranslated(pIRequestedFile, @PathTranslated)
	
	Dim hModule As HINSTANCE = LoadLibrary(PathTranslated)
	If hModule = NULL Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка загрузки DLL", intError
		#endif
		UnmapViewOfFile(ClientBuffer)
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pINetworkStream, pIWebSite)
		Return False
	End If
	
	Dim lpfnProcessDllRequest As Function(ByVal pServerState As IServerState Ptr)As Boolean = GetProcAddress(hModule, "ProcessDllRequest")
	
	If CInt(lpfnProcessDllRequest) = 0 Then
		#if __FB_DEBUG__ <> 0
			Dim intError As DWORD = GetLastError()
			Print "Ошибка поиска функции lpfnProcessDllRequest", intError
		#endif
		UnmapViewOfFile(ClientBuffer)
		CloseHandle(hMapFile)
		FreeLibrary(hModule)
		WriteHttpBadGateway(pRequest, pResponse, pINetworkStream, pIWebSite)
		Return False
	End If
	
	Dim objServerState As ServerState = Any
	InitializeServerState(@objServerState, pINetworkStream, pRequest, pResponse, pIWebSite, hMapFile, ClientBuffer)
	
	Dim pServerState As IServerState Ptr = CPtr(IServerState Ptr, @objServerState)
	
	Dim Result As Boolean = lpfnProcessDllRequest(pServerState)
	If Result = False Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Функция lpfnProcessDllRequest завершилась ошибкой", intError
		#endif
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pINetworkStream, pIWebSite)
		Return False
	End If
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	' If send(ClientSocket, @SendBuffer, AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, objServerState.BufferLength), 0) = SOCKET_ERROR Then
		' UnmapViewOfFile(objServerState.ClientBuffer)
		' CloseHandle(hMapFile)
		' Return False
	' End If
	Dim WritedBytes As Integer = Any
	Dim hr As HRESULT = INetworkStream_Write(pINetworkStream, _
		@SendBuffer, 0, AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, objServerState.BufferLength), @WritedBytes _
	)
	If FAILED(hr) Then
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		Return False
	End If
	
	' Тело
	If pResponse->SendOnlyHeaders = False Then
		' If send(ClientSocket, objServerState.ClientBuffer, objServerState.BufferLength, 0) = SOCKET_ERROR Then
			' UnmapViewOfFile(objServerState.ClientBuffer)
			' CloseHandle(hMapFile)
			' Return False
		' End If
		hr = INetworkStream_Write(pINetworkStream, _
			objServerState.ClientBuffer, 0, objServerState.BufferLength, @WritedBytes _
		)
		
		If FAILED(hr) Then
			UnmapViewOfFile(objServerState.ClientBuffer)
			CloseHandle(hMapFile)
			Return False
		End If
	End If
	
	UnmapViewOfFile(objServerState.ClientBuffer)
	CloseHandle(hMapFile)
	FreeLibrary(hModule)
	
	Return True
	
End Function
