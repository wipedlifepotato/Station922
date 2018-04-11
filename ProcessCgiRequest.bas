#include once "ProcessCgiRequest.bi"
#include once "HttpConst.bi"
#include once "WriteHttpError.bi"
#include once "Http.bi"

Const MaxEnvironmentBlockBufferLength As Integer = 8 * WebResponse.MaxResponseHeaderBuffer

Function ProcessCgiRequest( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr, _
		ByVal fileExtention As WString Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal hOutput As Handle _
	)As Boolean
	Const MaxBufferLength As Integer = 4096 - 1
	
	Dim Buffer As ZString * (MaxBufferLength + 1) = Any
	
	' Длина содержимого по заголовку Content-Length слишком большая
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	If StrToInt64Ex(pState->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength), STIF_DEFAULT, @RequestBodyContentLength.QuadPart) = 0 Then
		RequestBodyContentLength.QuadPart = 0
	Else
		If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
			pState->ServerResponse.StatusCode = 413
			WriteHttpError(pState, ClientSocket, HttpErrors.HttpError413RequestEntityTooLarge, @pWebSite->VirtualPath, hOutput)
			Return False
		End If
	End If
	
	' Создать блок переменных окружения
	Dim hMapFile As HANDLE = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, MaxEnvironmentBlockBufferLength, NULL)
	If hMapFile = 0 Then
		pState->ServerResponse.StatusCode = 503
		pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderRetryAfter) = @"Retry-After: 300"
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError503Memory, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	Dim EnvironmentBlock As WString Ptr = CPtr(WString Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, MaxEnvironmentBlockBufferLength))
	If EnvironmentBlock = 0 Then
		CloseHandle(hMapFile)
		pState->ServerResponse.StatusCode = 503
		pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderRetryAfter) = @"Retry-After: 300"
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError503Memory, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	EnvironmentBlock[0] = 0
	EnvironmentBlock[1] = 0
	EnvironmentBlock[2] = 0
	EnvironmentBlock[3] = 0
	'
	Scope
		Dim wStart As WString Ptr = EnvironmentBlock
		
		lstrcpy(wStart, "SCRIPT_FILENAME=")
		lstrcat(wStart, @pWebSite->PathTranslated)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "PATH_INFO=")
		lstrcat(wStart, @"")
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "SCRIPT_NAME=")
		lstrcat(wStart, @"")
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "REQUEST_LINE=")
		lstrcat(wStart, pState->ClientRequest.ClientURI.Url)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "QUERY_STRING=")
		lstrcat(wStart, pState->ClientRequest.ClientURI.QueryString)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "SERVER_SOFTWARE=")
		lstrcat(wStart, @HttpServerNameString)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "SERVER_NAME=")
		lstrcat(wStart, @pWebSite->HostName)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "SERVER_PROTOCOL=")
		' TODO Указать правильную версию
		lstrcat(wStart, @HttpVersion11)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "SERVER_PORT=80")
		REM lstrcat(wStart, @pWebSite->HostName)
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "GATEWAY_INTERFACE=")
		lstrcat(wStart, @"CGI/1.1")
		wStart += lstrlen(wStart) + 1
		
		
		lstrcpy(wStart, "REMOTE_ADDR=")
		lstrcat(wStart, @"")
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "REMOTE_HOST=")
		lstrcat(wStart, @"")
		wStart += lstrlen(wStart) + 1
		
		lstrcpy(wStart, "REQUEST_METHOD=")
		Scope
			Dim HttpMethod As WString Ptr = HttpMethodToString(pState->ClientRequest.HttpMethod, 0)
			lstrcat(wStart, HttpMethod)
		End Scope
		wStart += lstrlen(wStart) + 1
		
		For i As Integer = 0 To WebRequest.RequestHeaderMaximum - 1
			lstrcpy(wStart, KnownRequestCgiHeaderToString(i, 0))
			lstrcat(wStart, "=")
			If pState->ClientRequest.RequestHeaders(i) <> 0 Then
				lstrcat(wStart, pState->ClientRequest.RequestHeaders(i))
			End If
			wStart += lstrlen(wStart) + 1
		Next
		
		' Завершить брок переменных окружения
		wStart[0] = 0
	End Scope
	
	' Текущая директория дочернего процесса
	Dim CurrentChildProcessDirectory As WString * (MAX_PATH + 1) = Any
	lstrcpy(@CurrentChildProcessDirectory, @pWebSite->PathTranslated)
	PathRemoveFileSpec(@CurrentChildProcessDirectory)
	
	' Скопировать в буфер имя исполняемого файла
	Dim ApplicationNameBuffer As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(@ApplicationNameBuffer, @pWebSite->PathTranslated)
	
	' Атрибуты защиты
	Dim saAttr As SECURITY_ATTRIBUTES = Any
	saAttr.nLength = SizeOf(SECURITY_ATTRIBUTES)
	saAttr.bInheritHandle = TRUE
	saAttr.lpSecurityDescriptor = NULL
	
	Dim hRead As Handle = NULL
	Dim hWrite As Handle = NULL
	
	' Каналы чтения‐записи
	If CreatePipe(@hRead, @hWrite, @saAttr, 0) = 0 Then
		Dim intError As DWORD = GetLastError()
		UnmapViewOfFile(EnvironmentBlock)
		CloseHandle(hMapFile)
		pState->ServerResponse.StatusCode = 503
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError503Memory, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	' Информация о процессе
	Dim siStartInfo As STARTUPINFO
	siStartInfo.cb = SizeOf(STARTUPINFO)
	siStartInfo.hStdOutput = hWrite
	siStartInfo.hStdInput = hRead
	siStartInfo.dwFlags = STARTF_USESTDHANDLES
	
	Dim piProcInfo As PROCESS_INFORMATION
	
	If CreateProcess(@ApplicationNameBuffer, NULL, NULL, NULL, True, CREATE_UNICODE_ENVIRONMENT, EnvironmentBlock, @CurrentChildProcessDirectory, @siStartInfo, @piProcInfo) = 0 Then
		Dim intError As DWORD = GetLastError()
		UnmapViewOfFile(EnvironmentBlock)
		CloseHandle(hMapFile)
		CloseHandle(hRead)
		CloseHandle(hWrite)
		pState->ServerResponse.StatusCode = 504
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError504GatewayTimeout, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	#if __FB_DEBUG__ <> 0
		Print "Создал процесс, ошибок вроде не было"
	#endif
	
	If pState->ClientRequest.HttpMethod = HttpMethods.HttpPost Then
		
		Dim WriteBytesCount As DWORD = Any
		
		' Записать предварительно загруженные данные
		Dim PreloadedContentLength As Integer = pClientReader->BufferLength - pClientReader->Start
		If PreloadedContentLength > 0 Then
			WriteFile(hWrite, @pClientReader->Buffer[pClientReader->Start], PreloadedContentLength, @WriteBytesCount, NULL)
			' TODO Проверить на ошибки записи
			pClientReader->Flush()
		End If
		
		' Записать всё остальное
		Do While PreloadedContentLength < RequestBodyContentLength.QuadPart
			Dim numReceived As Integer = recv(ClientSocket, @Buffer, MaxBufferLength, 0)
			
			' TODO Проверить на ошибки записи
			Select Case numReceived
				
				Case SOCKET_ERROR
					Exit Do
					
				Case 0
					Exit Do
					
				Case Else
					' Сколько байт получили, на столько и увеличили буфер
					PreloadedContentLength += numReceived
					WriteFile(hWrite, @Buffer, numReceived, @WriteBytesCount, NULL)
					
			End Select
			
		Loop
	End If
	
	Dim CloseHandleResult As Integer = CloseHandle(hWrite)
	Dim CloseHandleResultError As DWORD = GetLastError()
	#if __FB_DEBUG__ <> 0
		Print "Закрыл трубу для записи", CloseHandleResult
		Print "Ошибка", CloseHandleResultError
	#endif
	
	Do
		Dim ReadBytesCount As DWORD = Any
		Dim ReadFileResult As Integer = ReadFile(hRead, @Buffer, MaxBufferLength, @ReadBytesCount, NULL)
		Dim ReadFileResultError As DWORD = GetLastError()
		If ReadFileResult = 0 Then
			#if __FB_DEBUG__ <> 0
				Print "Чтение трубы", ReadFileResult
				Print "Ошибка", ReadFileResultError
			#endif
			Exit Do
		End If
		
		If ReadBytesCount = 0 Then
			Exit Do
		End If
		
		Buffer[ReadBytesCount] = 0
		If send(ClientSocket, @Buffer, ReadBytesCount, 0) = SOCKET_ERROR Then
			Exit Do
		End If
	Loop
	
	#if __FB_DEBUG__ <> 0
		Print "Завершаю работу скрипта"
	#endif
	UnmapViewOfFile(EnvironmentBlock)
	CloseHandle(hMapFile)
	CloseHandle(piProcInfo.hProcess)
	CloseHandle(piProcInfo.hThread)
	CloseHandle(hRead)
	
	Return True
End Function
