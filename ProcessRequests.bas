#include once "WebServer.bi"

Function ProcessGetHeadRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean
	Dim hFile As HANDLE = CreateFile(@state->PathTranslated, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		' Файла не существет, записать ошибку клиенту
		WriteNotFoundError(ClientSocket, state, www, hOutput)
		Return True
	End If
	
	' Не обрабатываем файлы с неизвестным типом
	Dim mt As MimeType = Any
	GetMimeType(@mt, fileExtention)
	If mt.ContentType = ContentTypes.None Then
		Return False
	End If
	
	' TODO Проверить идентификацию для запароленных ресурсов
	
	' Строка с типом документа
	Dim wContentType As WString * (MaxContentTypeBuffer + 1) = Any
	ContentTypesToString(@wContentType, mt.ContentType)
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
	
	' Заголовки сжатия нужно устанавливать раньше заголовков кэширования
	' так как заголовки кэширования учитывают метод сжатия
	Dim hZipFile As Handle = state->AddResponseCompressionMethodHeader(@mt)
	
	state->AddResponseCacheHeaders(hFile)
	
	' Нельзя отображать файлы нулевого размера
	Dim FileSize As LARGE_INTEGER = Any
	If hZipFile = INVALID_HANDLE_VALUE Then
		GetFileSizeEx(hFile, @FileSize)
	Else
		GetFileSizeEx(hZipFile, @FileSize)
	End If
	If FileSize.QuadPart = 0 Then
		' Создать заголовки ответа
		Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
		send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, 0, hOutput), 0)
	Else
		' Отобразить файл
		Dim hFileMap As Handle = Any
		If hZipFile = INVALID_HANDLE_VALUE Then
			hFileMap = CreateFileMapping(hFile, 0, PAGE_READONLY, 0, 0, 0)
		Else
			hFileMap = CreateFileMapping(hZipFile, 0, PAGE_READONLY, 0, 0, 0)
		End If
		If hFileMap = 0 Then
			' TODO узнать причину неудачи через GetLastError() = ERROR_ALREADY_EXISTS
			' Чтение файла завершилось неудачей
			state->StatusCode = 500
			WriteHttpError(state, ClientSocket, @HttpError500NotAvailable, @www->VirtualPath, hOutput)
		Else
			' Всё хорошо
			' Создать представление файла
			Dim b As UByte Ptr = CPtr(UByte Ptr, MapViewOfFile(hFileMap, FILE_MAP_READ, 0, 0, 0))
			If b = 0 Then
				' Чтение файла завершилось неудачей
				state->StatusCode = 500
				WriteHttpError(state, ClientSocket, @HttpError500NotAvailable, @www->VirtualPath, hOutput)
			Else
				SendFileToClient(ClientSocket, hFile, hZipFile, b, state, mt.IsTextFormat, FileSize, @wContentType, hOutput)
				' Закрыть
				UnmapViewOfFile(b)
			End If
			CloseHandle(hFileMap)
		End If
	End If
	
	' Закрыть
	If hZipFile <> INVALID_HANDLE_VALUE Then
		CloseHandle(hZipFile)
	End If
	CloseHandle(hFile)
	Return True
End Function

Function ProcessDeleteRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean
	Dim hFile As HANDLE = CreateFile(state->PathTranslated, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		' Файла не существет, записать ошибку клиенту
		WriteNotFoundError(ClientSocket, state, www, hOutput)
		Return True
	End If
	CloseHandle(hFile)
	
	Dim mt As MimeType = Any
	GetMimeType(@mt, fileExtention)
	If mt.ContentType = ContentTypes.None Then
		' Не обрабатываем файлы с неизвестным типом
		Return False
	End If
	
	' Проверка заголовка Authorization
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return True
	End If
	
	' Необходимо удалить файл
	If DeleteFile(state->PathTranslated) <> 0 Then
		' Успешно
		' TODO Удалить возможные заголовочные файлы
		REM Dim sHeaderFile = state.PathTranslated & ".headers"
		REM If File.Exists(sHeaderFile) Then
			REM File.Delete(sHeaderFile)
		REM End If
		
		' Создать специальный файл, показывающий, что файл был удалён
		Dim PathTranslated410 As WString * (ReadHeadersResult.MaxFilePathTranslatedLength + 4 + 1) = Any
		lstrcpy(@PathTranslated410, state->PathTranslated)
		lstrcat(@PathTranslated410, @FileGoneExtension)
		Dim hFile As HANDLE = CreateFile(@PathTranslated410, GENERIC_READ + GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
		CloseHandle(hFile)
	Else
		' TODO Отправить ошибку клиенту если файл невозможно удалить
	End If
	' Отправить заголовки, что нет содержимого
	state->StatusCode = 204
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, 0, hOutput), 0)
	
	Return True
End Function

Function ProcessPutRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean
	' Проверка авторизации пользователя
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return True
	End If
	
	' Если какой-то из переданных серверу заголовков Content-* не опознан или не может быть использован в данной ситуации
	' сервер возвращает статус ошибки 501 (Not Implemented).
	' Если ресурс с указанным URI не может быть создан или модифицирован,
	' должно быть послано соответствующее сообщение об ошибке. 
	
	' Не указан тип содержимого
	If lstrlen(state->RequestHeaders(HttpRequestHeaderIndices.HeaderContentType)) = 0 Then
		state->StatusCode = 501
		WriteHttpError(state, ClientSocket, @HttpError501ContentTypeEmpty, @www->VirtualPath, hOutput)
		Return True
	End If
	' TODO Проверить тип содержимого
	
	' Сжатое содержимое не поддерживается
	If lstrlen(state->RequestHeaders(HttpRequestHeaderIndices.HeaderContentEncoding)) <> 0 Then
		state->StatusCode = 501
		WriteHttpError(state, ClientSocket, @HttpError501ContentEncoding, @www->VirtualPath, hOutput)
		Return True
	End If
	
	' Требуется указание длины
	If lstrlen(state->RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength)) = 0 Then
		state->StatusCode = 411
		WriteHttpError(state, ClientSocket, @HttpError411LengthRequired, @www->VirtualPath, hOutput)
		Return True
	End If
	
	' Длина содержимого по заголовку Content-Length слишком большая
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	RequestBodyContentLength.QuadPart = wtol(state->RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength))
	If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
		state->StatusCode = 413
		WriteHttpError(state, ClientSocket, @HttpError413RequestEntityTooLarge, @www->VirtualPath, hOutput)
		Return True
	End If
	
	' TODO Проверить на удовлетворение Content-Language: ru, ru-RU
	
	REM ' Может быть указана кодировка содержимого
	REM Dim contentType() As String = state.RequestHeaders(HttpRequestHeaderIndices.HeaderContentType).Split(";"c)
	REM Dim kvp = m_ContentTypes.Find(Function(x) x.ContentType = contentType(0))
	REM If kvp Is Nothing Then
		REM ' Такое содержимое нельзя загружать
		REM state.StatusCode = 501
		REM state.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = AllSupportHttpMethodsWithoutPut
		REM state.WriteError(objStream, String.Format(MethodNotAllowed, state.HttpMethod), www.VirtualPath)
		REM Exit Do
	REM End If
	
	' TODO Изменить расширение файла на правильное
	REM ' нельзя оставлять отправленное пользователем расширение
	REM ' указать (новое) имя файла в заголовке Location
	REM state.FilePath = Path.ChangeExtension(state.FilePath, kvp.Extension)
	REM state.PathTranslated = state.MapPath(www.VirtualPath, state.FilePath, www.PhysicalDirectory)
	
	Dim HeaderLocation As WString * (ReadHeadersResult.MaxFilePathLength + 1) = Any
	
	Dim hFile As HANDLE = CreateFile(state->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		' если ресурс присутствовал и был изменен в результате запроса PUT,
		' выдается код статуса 200 (Ok) или 204 (No Content). 
		hFile = CreateFile(state->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile = INVALID_HANDLE_VALUE Then
			' Ошибка, продолжать дальше нельзя
			state->StatusCode = 500
			WriteHttpError(state, ClientSocket, @HttpError500NotAvailable, @www->VirtualPath, hOutput)
			Return True
		Else
			state->StatusCode = 200
		End If
	Else
		' В случае отсутствия ресурса по указанному в заголовке URI,
		' сервер создает его и возвращает код статуса 201 (Created),
		state->StatusCode = 201
		lstrcpy(@HeaderLocation, "http://")
		lstrcat(@HeaderLocation, @www->HostName)
		lstrcat(@HeaderLocation, state->FilePath)
		state->ResponseHeaders(HttpResponseHeaderIndices.HeaderLocation) = @HeaderLocation
	End If
	
	Dim hFileMap As Handle = CreateFileMapping(hFile, 0, PAGE_READWRITE, RequestBodyContentLength.HighPart, RequestBodyContentLength.LowPart, 0)
	If hFileMap = 0 Then
		' Ошибка
		state->StatusCode = 500
		WriteHttpError(state, ClientSocket, @HttpError500NotAvailable, @www->VirtualPath, hOutput)
	Else
		Dim b As Byte Ptr = CPtr(Byte Ptr, MapViewOfFile(hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0))
		If b = 0 Then
			' Ошибка
			state->StatusCode = 500
			WriteHttpError(state, ClientSocket, @HttpError500NotAvailable, @www->VirtualPath, hOutput)
		Else
			' TODO Заголовки записать в специальный файл
			REM HeaderContentEncoding
			REM HeaderContentLanguage
			REM HeaderContentLocation
			REM HeaderContentMd5
			REM HeaderContentType
			
			' Записать предварительно загруженные данные
			Dim PreloadedContentLength As Long = state->HeaderBytesLength - state->EndHeadersOffset
			If PreloadedContentLength > 0 Then
				memcpy(b, @state->HeaderBytes[state->EndHeadersOffset], PreloadedContentLength)
			End If
			
			' Записать всё остальное
			Do While PreloadedContentLength < RequestBodyContentLength.QuadPart
				Dim numReceived As Integer = recv(ClientSocket, @b[PreloadedContentLength], RequestBodyContentLength.QuadPart - PreloadedContentLength, 0)
				If numReceived > 0 Then
					' Сколько байт получили, на столько и увеличили буфер
					PreloadedContentLength += numReceived
				Else
					Exit Do
				End If
			Loop
			
			' TODO Определить тип файла: текстовый или двоичный
			Dim wContentType As WString * 256 = Any
			state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
			lstrcpy(@wContentType, state->RequestHeaders(HttpRequestHeaderIndices.HeaderContentType))
			SendFileToClient(ClientSocket, hFile, INVALID_HANDLE_VALUE, b, state, False, RequestBodyContentLength, @wContentType, hOutput)
			
			' Удалить файл 410, если он был
			Dim PathTranslated410 As WString * (ReadHeadersResult.MaxFilePathTranslatedLength + 4 + 1) = Any
			lstrcpy(@PathTranslated410, state->PathTranslated)
			lstrcat(@PathTranslated410, @FileGoneExtension)
			DeleteFile(@PathTranslated410) ' не проверяем ошибку удаления
			
			UnmapViewOfFile(b)
		End If
		CloseHandle(hFileMap)
	End If
	CloseHandle(hFile)
	Return True
End Function

Function ProcessTraceRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Собрать все заголовки запроса и сформировать из них тело ответа
	
	' Строка с типом документа
	Dim wContentType As WString * (MaxContentTypeBuffer + 1) = Any
	ContentTypesToString(@wContentType, ContentTypes.MessageHttp)
	lstrcat(@wContentType, @ContentCharset8bit)
	
	With *state
		.StatusCode = 200
		.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
	End With
	
	' Заголовки
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, CLng(state->EndHeadersOffset), hOutput), 0)
	
	' Тело
	send(ClientSocket, @state->HeaderBytes, state->EndHeadersOffset, 0)
	Return True
End Function

Function ProcessOptionsRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean
	state->StatusCode = 204 ' нет содержимого
	REM ' Если звёздочка, то ко всему серверу
	REM If lstrcmp(@state->Path, "*") = 0 Then
		REM state->ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethods
	REM Else
		' К конкретному ресурсу
		REM If m_AspNetProcessingFiles.Contains(fileExtention) Then
			REM ' Файл обрабатывается процессором, значит может обработать разные методы
			REM state.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = AllSupportHttpMethods
		REM Else
			state->ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethodsServer
		REM End If
	REM End If
	
	' Заголовки
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, 0, hOutput), 0)
	Return True
End Function

Function ProcessConnectRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Проверка заголовка Authorization
	lstrcpy(www->PhysicalDirectory, state->ExeDir)
	lstrcpy(www->VirtualPath, @SlashString)
	www->IsMoved = False
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return True
	End If
	
	' Файл с настройками
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, state->ExeDir, @WebServerIniFileString)
	
	Dim ConnectBindAddress As WString * 256 = Any
	Dim ConnectBindPort As WString * 16 = Any
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindAddressSectionString, @DefaultAddressString, @ConnectBindAddress, 255, @IniFileName)
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindPortSectionString, @ConnectBindDefaultPort, @ConnectBindPort, 15, @IniFileName)
	
	' Соединиться с сервером
	Dim ServiceName As WString Ptr = Any
	Dim wColon As WString Ptr = StrStr(state->RequestHeaders(HttpRequestHeaderIndices.HeaderHost), @ColonString)
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
	
	Dim ServerSocket2 As SOCKET = ConnectToServer(state->RequestHeaders(HttpRequestHeaderIndices.HeaderHost), ServiceName, @ConnectBindAddress, @ConnectBindPort)
	If ServerSocket2 = INVALID_SOCKET Then
		' Не могу соединиться
		state->StatusCode = 504
		WriteHttpError(state, ClientSocket, @HttpError504GatewayTimeout, @www->VirtualPath, hOutput)
		Return True
	End If

	' Отправить ответ о статусе соединения
	state->StatusCode = 200
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, 0, hOutput), 0)
	
	' Читать данные от клиента, отправлять на сервер
	Dim CSS As ClientServerSocket = Any
	With CSS
		.OutSock = ServerSocket2
		.InSock = ClientSocket
	End With
	CSS.hThread = CreateThread(NULL, 0, @SendReceiveDataThreadProc, @CSS, 0, @CSS.ThreadId)
	
	' Читать данные от сервера, отправлять клиенту
	SendReceiveData(ClientSocket, ServerSocket2)
	
	Return True
	
End Function

Sub WriteHttpError(ByVal state As ReadHeadersResult Ptr, ByVal ClientSocket As SOCKET, ByVal strMessage As WString Ptr, ByVal VirtualPath As WString Ptr, ByVal hOutput As Handle)
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @HttpErrorContentType
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLanguage) = @DefaultContentLanguage
	state->KeepAlive = False
	
	Dim Body As ZString * (MaxHttpErrorBuffer * SizeOf(WString) + SizeOf(WString) + 1) = Any
	' Метка BOM (FFFE) для utf-16 LE
	Body[0] = 255
	Body[1] = 254
	Dim ContentLength As Long = FormatErrorMessageBody(CPtr(WString Ptr, @Body[2]), state->StatusCode, VirtualPath, strMessage) * SizeOf(WString) + 2
	
	' Заголовки
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, ContentLength, hOutput), 0)
	' Тело
	send(ClientSocket, @Body, ContentLength, 0)
End Sub

Sub WriteHttp301Error(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)
	state->StatusCode = 301
	Dim buf As WString * (ReadHeadersResult.MaxUrlLength * 2 + 1) = Any
	lstrcpy(@buf, www->MovedUrl)
	lstrcat(@buf, state->Url)
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderLocation) = @buf
	
	' Сделать экранирование символов <>'"&
	Dim strSafe As WString * (ReadHeadersResult.MaxUrlLength * 6 + 1) = Any
	GetSafeString(@strSafe, buf)
	
	Dim MovedMessage As WString * (ReadHeadersResult.MaxUrlLength * 7 + 1) = Any
	lstrcpy(@MovedMessage, @MovedPermanently1)
	lstrcat(@MovedMessage, @strSafe)
	lstrcat(@MovedMessage, @MovedPermanently2)
	lstrcat(@MovedMessage, @strSafe)
	lstrcat(@MovedMessage, @MovedPermanently3)
	
	WriteHttpError(state, ClientSocket, @MovedMessage, www->VirtualPath, hOutput)
End Sub

Sub WriteNotFoundError(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)
	Dim buf410 As WString * (ReadHeadersResult.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(buf410, state->PathTranslated)
	lstrcat(buf410, ".410")
	
	Dim strSafe As WString * (ReadHeadersResult.MaxFilePathTranslatedLength * 6 + 1) = Any
	GetSafeString(@strSafe, state->FilePath)
	
	Dim hFile410 As HANDLE = CreateFile(@buf410, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile410 = INVALID_HANDLE_VALUE Then
		' Файлы не существует, но она может появиться позже
		state->StatusCode = 404
		Dim bufFileNotFound As WString * (ReadHeadersResult.MaxFilePathTranslatedLength * 10 + 1) = Any
		lstrcpy(@bufFileNotFound, @HttpError404FileNotFound1)
		lstrcat(@bufFileNotFound, @strSafe)
		lstrcat(@bufFileNotFound, @HttpError404FileNotFound2)
		WriteHttpError(state, ClientSocket, @bufFileNotFound, www->VirtualPath, hOutput)
	Else
		' Файла раньше существовала, но теперь удалена навсегда
		CloseHandle(hFile410)
		state->StatusCode = 410
		Dim bufFileNotFound As WString * (ReadHeadersResult.MaxFilePathTranslatedLength * 10 + 1) = Any
		lstrcpy(@bufFileNotFound, @HttpError410Gone1)
		lstrcat(@bufFileNotFound, @strSafe)
		lstrcat(@bufFileNotFound, @HttpError410Gone2)
		WriteHttpError(state, ClientSocket, @bufFileNotFound, www->VirtualPath, hOutput)
	End If
End Sub
