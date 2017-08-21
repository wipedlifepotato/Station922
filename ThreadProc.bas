#include once "ThreadProc.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"
#include once "Network.bi"

#include once "ReadHeadersResult.bi"
#include once "WebUtils.bi"
#include once "ProcessRequests.bi"
#include once "Http.bi"
#include once "HeapOnArray.bi"
#include once "WriteHttpError.bi"

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	Dim param As ThreadParam Ptr = CPtr(ThreadParam Ptr, lpParam)
	
	#if __FB_DEBUG__ <> 0
		Print "Поток стартовал", param->ThreadId
	#endif
	
	' TODO Реализовать CGI
	' TODO Реализовать DLL-GI
	' TODO К директориям /cgi-bin/ /dll-bin/ /app-data/ нужно запретить доступ?
	
	' Ожидать чтения данных с клиента 5 минут
	Scope
		Dim ReceiveTimeOut As DWORD = 5 * 60 * 1000
		setsockopt(param->ClientSocket, SOL_SOCKET, SO_RCVTIMEO, CPtr(ZString Ptr, @ReceiveTimeOut), SizeOf(DWORD))
	End Scope
	
	Dim state As ReadHeadersResult = Any
	state.ClientReader.Initialize()
	state.ClientReader.ClientSocket = param->ClientSocket
	
	Do
		state.Initialize()
		
		' Читать запрос клиента
		If state.ClientRequest.ReadAllHeaders(@state.ClientReader) = False Then
			Select Case GetLastError()
				
				Case ParseRequestLineResult.HTTPVersionNotSupported
					' Версия не поддерживается
					state.StatusCode = 505
					WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError505VersionNotSupported, @SlashString, param->hOutput)
					
				Case ParseRequestLineResult.BadRequest
					' Плохой запрос
					state.StatusCode = 400
					WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError400BadRequest, @SlashString, param->hOutput)
					
				Case ParseRequestLineResult.BadPath
					' Плохой путь
					state.StatusCode = 400
					WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError400BadPath, @SlashString, param->hOutput)
					
				Case ParseRequestLineResult.EmptyRequest
					' Пустой запрос, клиент закрыл соединение
					
				Case ParseRequestLineResult.SocketError
					' Ошибка сокета
					
				Case ParseRequestLineResult.RequestUrlTooLong
					' Запрошенный Url слишкой длинный
					state.StatusCode = 414
					WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError414RequestUrlTooLarge, @SlashString, param->hOutput)
					
				Case ParseRequestLineResult.RequestHeaderFieldsTooLarge
					' Превышена допустимая длина заголовков
					state.StatusCode = 431
					WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError431RequestRequestHeaderFieldsTooLarge, @SlashString, param->hOutput)
					
			End Select
			
			Exit Do
			
		End If
		
		' TODO Заголовок Host может не быть в версии 1.0
		If lstrlen(state.ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderHost)) = 0 Then
			state.StatusCode = 400
			WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError400Host, @SlashString, param->hOutput)
			Exit Do
		End If
		
		#if __FB_DEBUG__ <> 0
			' Распечатать весь запрос
			Print "Распечатываю весь запрос"
			Print state.ClientReader.Buffer
		#endif
		
		' Найти сайт по его имени
		Dim www As WebSite = Any
		If GetWebSite(@www, state.ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderHost)) = False Then
			If state.ClientRequest.HttpMethod <> HttpMethods.HttpConnect Then
				state.StatusCode = 400
				WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError400Host, @SlashString, param->hOutput)
				Exit Do
			End If
		End If
		
		If www.IsMoved <> False Then
			' Сайт перемещён на другой ресурс
			' если запрошен документ /robots.txt то не перенаправлять
			If lstrcmpi(state.ClientRequest.ClientURI.Url, "/robots.txt") <> 0 Then
				WriteHttp301Error(param->ClientSocket, @state, @www, param->hOutput)
				Exit Do
			End If
		End If
		
		/'
			Кеширование
			Dim MapFileName As WString * (MAX_PATH + 1) = Any
			lstrcpy(@MapFileName, "FreeBASICWebServer")
			lstrcat(@MapFileName, @www.VirtualPath)
			
			Dim hMapFile As HANDLE = OpenFileMapping(GENERIC_READ + GENERIC_WRITE, False, @MapFileName)
			If hMapFile = 0 Then
				#if __FB_DEBUG__ <> 0
					Print "Создаю отображение файла"
				#endif
				hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, 1024 * 1024, @MapFileName)
				If hMapFile <> 0 Then
					Dim b As WString Ptr = CPtr(WString Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, 1024 * 1024))
					' Записать данные в память
					lstrcpy(b, "Сообщение из первого процесса")
					' Выгрузить
					If b <> 0 Then
						UnmapViewOfFile(b)
					End If
				End If
				' Не закрывать hMapFile, чтобы отображение существовало
			Else
				#if __FB_DEBUG__ <> 0
					Print "Открыл отображённый файл"
				#endif
				Dim b As WString Ptr = CPtr(WString Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, 1024 * 1024))
				' Прочитать данные из памяти
				Print *b
				' Выгрузить
				If b <> 0 Then
					UnmapViewOfFile(b)
				End If
				CloseHandle(hMapFile)
			End If
		'/
		
		' Обработка запроса
		
		Select Case state.ClientRequest.HttpMethod
			
			Case HttpMethods.HttpGet, HttpMethods.HttpHead
				' Отправлять только заголовки
				If state.ClientRequest.HttpMethod = HttpMethods.HttpHead Then
					state.SendOnlyHeaders = True
				End If
				If ProcessGetHeadRequest( _
						param->ClientSocket, _
						@state, _
						@www, _
						PathFindExtension(@www.PathTranslated), _
						param->hOutput, _
						www.GetFilePath(@state.ClientRequest.ClientURI.Path, FileAccess.ForGetHead) _
				) = False Then
					Exit Do
				End If
				
			Case HttpMethods.HttpPut
				www.GetFilePath(@state.ClientRequest.ClientURI.Path, FileAccess.ForPut)
				If ProcessPutRequest( _
						param->ClientSocket, _
						@state, _
						@www, _
						param->hOutput _
				) = False Then
					Exit Do
				End If
				
			Case HttpMethods.HttpDelete
				If ProcessDeleteRequest( _
						param->ClientSocket, _
						@state, _
						@www, _
						param->hOutput, _
						www.GetFilePath(@state.ClientRequest.ClientURI.Path, FileAccess.ForDelete) _
				) = False Then
					Exit Do
				End If
				
			Case HttpMethods.HttpOptions
				If ProcessOptionsRequest( _
						param->ClientSocket, _
						@state, _
						param->hOutput _
				) = False Then
					Exit Do
				End If
				
			Case HttpMethods.HttpTrace
				If ProcessTraceRequest( _
						param->ClientSocket, _
						@state, _
						param->hOutput _
				) = False Then
					Exit Do
				End If
				
			Case HttpMethods.HttpConnect
				' TODO Устранить грязный хак с конфигурацией метода CONNECT
				lstrcpy(www.PhysicalDirectory, param->ExeDir)
				lstrcpy(www.VirtualPath, @SlashString)
				www.IsMoved = False
				If ProcessConnectRequest( _
						param->ClientSocket, _
						@state, _
						@www, _
						param->hOutput _
				) = False Then
					Exit Do
				End If
				
			Case Else
				' Метод не поддерживается сервером
				state.StatusCode = 501
				state.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethods
				WriteHttpError(@state, param->ClientSocket, HttpErrors.HttpError501MethodNotAllowed, @SlashString, param->hOutput)
				Exit Do
				
		End Select
		
	Loop While state.ClientRequest.KeepAlive
	
	#if __FB_DEBUG__ <> 0
		Print "Закрываю поток:", param->hThread, state.ClientRequest.KeepAlive
	#endif
	CloseSocketConnection(param->ClientSocket)
	CloseHandle(param->hThread)
	MyHeapFree(param)
	
	Return 0
End Function
