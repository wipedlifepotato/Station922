#include "ProcessDllRequest.bi"
#include "Http.bi"
#include "WriteHttpError.bi"
#include "ServerState.bi"
#include "WebUtils.bi"

Function ProcessDllCgiRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal www As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pRequestedFile As RequestedFile Ptr _
	)As Boolean
	
	' Создать клиентский буфер
	Dim hMapFile As HANDLE = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, MaxClientBufferLength, NULL)
	If hMapFile = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка CreateFileMapping", intError
		#endif
		WriteHttpNotEnoughMemory(pRequest, pResponse, pClientReader->pStream, www)
		Return False
	End If
	
	Dim ClientBuffer As Any Ptr = MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, MaxClientBufferLength)
	If ClientBuffer = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка MapViewOfFile", intError
		#endif
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pClientReader->pStream, www)
		Return False
	End If
	
	Dim hModule As HINSTANCE = LoadLibrary(pRequestedFile->PathTranslated)
	If hModule = NULL Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка загрузки DLL", intError
		#endif
		UnmapViewOfFile(ClientBuffer)
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pClientReader->pStream, www)
		Return False
	End If
	
	Dim ProcessDllRequest As Function(ByVal pServerState As IServerState Ptr)As Boolean = GetProcAddress(hModule, "ProcessDllRequest")
	
	If CInt(ProcessDllRequest) = 0 Then
		#if __FB_DEBUG__ <> 0
			Dim intError As DWORD = GetLastError()
			Print "Ошибка поиска функции ProcessDllRequest", intError
		#endif
		UnmapViewOfFile(ClientBuffer)
		CloseHandle(hMapFile)
		FreeLibrary(hModule)
		WriteHttpBadGateway(pRequest, pResponse, pClientReader->pStream, www)
		Return False
	End If
	
	Dim objServerState As ServerState = Any
	InitializeServerState(@objServerState, pClientReader->pStream, pRequest, pResponse, www, hMapFile, ClientBuffer)
	
	Dim pServerState As IServerState Ptr = CPtr(IServerState Ptr, @objServerState)
	
	Dim Result As Boolean = ProcessDllRequest(pServerState)
	If Result = False Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Функция ProcessDllRequest завершилась ошибкой", intError
		#endif
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		WriteHttpNotEnoughMemory(pRequest, pResponse, pClientReader->pStream, www)
		Return False
	End If
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, objServerState.BufferLength), 0) = SOCKET_ERROR Then
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		Return False
	End If
	
	' Тело
	If pResponse->SendOnlyHeaders = False Then
		If send(ClientSocket, objServerState.ClientBuffer, objServerState.BufferLength, 0) = SOCKET_ERROR Then
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
