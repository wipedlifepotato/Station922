#include once "ProcessRequests.bi"
#include once "Mime.bi"
#include once "HttpConst.bi"
#include once "WebUtils.bi"
#include once "Network.bi"
#include once "IniConst.bi"
#include once "URI.bi"
#include once "CharConstants.bi"
#include once "WriteHttpError.bi"

' Инкапсуляция клиентского и серверного сокетов как параметр для процедуры потока
Type ClientServerSocket
	Dim OutSock As SOCKET
	Dim InSock As SOCKET
	Dim ThreadId As DWord
	Dim hThread As HANDLE
End Type

' Получение данных от входящего сокета и отправка на исходящий
Declare Sub SendReceiveData(ByVal OutSock As SOCKET, ByVal InSock As SOCKET)

' Процедура потока
Declare Function SendReceiveDataThreadProc(ByVal lpParam As LPVOID)As DWORD


Function ProcessGetHeadRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle, ByVal hFile As Handle)As Boolean
	If hFile = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		' Файла не существет, записать ошибку клиенту
		Dim buf410 As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, @www->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile410 = INVALID_HANDLE_VALUE Then
			' Файлы не существует, но она может появиться позже
			state->StatusCode = 404
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError404FileNotFound, www->VirtualPath, hOutput)
		Else
			' Файла раньше существовала, но теперь удалена навсегда
			CloseHandle(hFile410)
			state->StatusCode = 410
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError410Gone, www->VirtualPath, hOutput)
		End If
		Return True
	End If
	
	' Не обрабатываем файлы с неизвестным типом
	Dim mt As MimeType = GetMimeTypeOfExtension(fileExtention)
	If mt.ContentType = ContentTypes.None Then
		state->StatusCode = 403
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError403File, @www->VirtualPath, hOutput)
		Return False
	End If
	
	' TODO Проверить идентификацию для запароленных ресурсов
	
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = GetStringOfContentType(mt.ContentType)
	
	Dim hZipFile As Handle = Any
	If mt.IsTextFormat Then
		hZipFile = state->SetResponseCompression(@www->PathTranslated)
	Else
		hZipFile = INVALID_HANDLE_VALUE
	End If
	
	state->AddResponseCacheHeaders(hFile)
	
	' Нельзя отображать файлы нулевого размера
	Dim FileSize As LARGE_INTEGER = Any
	Dim GetFileSizeExResult As Integer = Any
	If hZipFile = INVALID_HANDLE_VALUE Then
		GetFileSizeExResult = GetFileSizeEx(hFile, @FileSize)
	Else
		GetFileSizeExResult = GetFileSizeEx(hZipFile, @FileSize)
	End If
	
	If GetFileSizeExResult = 0 Then
		' TODO узнать причину неудачи через GetLastError() = ERROR_ALREADY_EXISTS
		state->StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
	Else
		If FileSize.QuadPart = 0 Then
			' Создать заголовки ответа и отправить клиенту
			Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
			send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
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
				WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
			Else
				' Всё хорошо
				' Создать представление файла
				Dim b As UByte Ptr = CPtr(UByte Ptr, MapViewOfFile(hFileMap, FILE_MAP_READ, 0, 0, 0))
				If b = 0 Then
					' Чтение файла завершилось неудачей
					' TODO Узнать код ошибки и отправить его клиенту
					state->StatusCode = 500
					WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
				Else
					' Строка с типом документа
					Dim wContentType As WString * (2 * MaxContentTypeLength + 1) = Any
					
					' TODO Проверить частичный запрос
					REM If state->RequestHeaders(HttpRequestHeaderIndices.HeaderRange) = 0 Then
						REM ' Выдать всё содержимое от начала до конца
					REM Else
						REM ' Выдать только диапазон
						REM Range: bytes=0-255 — фрагмент от 0-го до 255-го байта включительно.
						REM Range: bytes=42-42 — запрос одного 42-го байта.
						REM Range: bytes=4000-7499,1000-2999 — два фрагмента. Так как первый выходит за пределы, то он интерпретируется как «4000-4999».
						REM Range: bytes=3000-,6000-8055 — первый интерпретируется как «3000-4999», а второй игнорируется.
						REM Range: bytes=-400,-9000 — последние 400 байт (от 4600 до 4999), а второй подгоняется под рамки содержимого (от 0 до 4999) обозначая как фрагмент весь объём.
						REM Range: bytes=500-799,600-1023,800-849 — при пересечениях диапазоны могут объединяться в один (от 500 до 1023).
						
						REM HTTP/1.1 206 Partial Content
						REM Обратите внимание на заголовок Content-Length — в нём указывается размер тела сообщения, то есть передаваемого фрагмента. Если сервер вернёт несколько фрагментов, то Content-Length будет содержать их суммарный объём.
						REM 'Content-Range: bytes 471104-2355520/2355521
						REM 'state.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentRange) = "bytes 471104-2355520/2355521"
					REM End If
					
					Dim Index As Integer = Any ' Смещение относительно начала файла, чтобы не отправлять BOM
					If mt.IsTextFormat Then
						If hZipFile = INVALID_HANDLE_VALUE Then
							' b указывает на настоящий файл
							If FileSize.QuadPart > 3 Then
								lstrcpy(@wContentType, state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType))
								Select Case GetDocumentCharset(b)
									Case DocumentCharsets.ASCII
										' Ничего
										Index = 0
									Case DocumentCharsets.Utf8BOM
										lstrcat(@wContentType, @ContentCharsetUtf8)
										Index = 3
									Case DocumentCharsets.Utf16LE
										lstrcat(wContentType, @ContentCharsetUtf16)
										Index = 0
									Case DocumentCharsets.Utf16BE
										lstrcat(wContentType, @ContentCharsetUtf16)
										Index = 2
								End Select
								state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
							Else
								' Кодировка ASCII
								Index = 0
							End If
						Else
							' b указывает на сжатый файл
							Index = 0
							Dim b2 As ZString * 4 = Any
							Dim BytesCount As DWORD = Any
							ReadFile(hFile, @b2, 3, @BytesCount, 0)
							If BytesCount >= 3 Then
								lstrcpy(@wContentType, state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType))
								Select Case GetDocumentCharset(b)
									Case DocumentCharsets.ASCII
										' Ничего
									Case DocumentCharsets.Utf8BOM
										lstrcat(wContentType, @ContentCharsetUtf8)
									Case DocumentCharsets.Utf16LE
										lstrcat(wContentType, @ContentCharsetUtf16)
									Case DocumentCharsets.Utf16BE
										lstrcat(wContentType, @ContentCharsetUtf16)
								End Select
								state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
							REM Else
								REM ' Кодировка ASCII
							End If
						End If
					Else
						Index = 0
					End If
					
					' Отправить дополнительные заголовки ответа
					Dim sExtHeadersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
					lstrcpy(@sExtHeadersFile, @www->PathTranslated)
					lstrcat(@sExtHeadersFile, @HeadersExtensionString)
					Dim hExtHeadersFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
					If hExtHeadersFile <> INVALID_HANDLE_VALUE Then
						Dim zExtHeaders As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
						Dim wExtHeaders As WString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
						
						Dim BytesCount As DWORD = Any
						If ReadFile(hExtHeadersFile, @zExtHeaders, ReadHeadersResult.MaxResponseHeaderBuffer, @BytesCount, 0) <> 0 Then
							If BytesCount > 2 Then
								zExtHeaders[BytesCount] = 0
								If MultiByteToWideChar(CP_UTF8, 0, @zExtHeaders, -1, @wExtHeaders, ReadHeadersResult.MaxResponseHeaderBuffer) > 0 Then
									Dim w As WString Ptr = @wExtHeaders
									Do
										Dim wName As WString Ptr = w
										' Найти двоеточие
										Dim wColon As WString Ptr = StrChr(w, ColonChar)
										' Найти vbCrLf и убрать
										w = StrStr(w, NewLineString)
										If w <> 0 Then
											w[0] = 0 ' и ещё w[1] = 0
											' Указываем на следующий символ после vbCrLf, если это ноль — то это конец
											w += 2
										End If
										If wColon > 0 Then
											wColon[0] = 0
											Do
												wColon += 1
											Loop While wColon[0] = 32
											state->AddResponseHeader(wName, wColon)
										End If
									Loop While lstrlen(w) > 0
								End If
							End If
						End If
						CloseHandle(hExtHeadersFile)
						#if __FB_DEBUG__ <> 0
							Print "Закрываю файл заголовков hExtHeadersFile"
						#endif
					End If
					
					' Создать и отправить заголовки ответа
					Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
					send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, FileSize.QuadPart - CLng(Index), hOutput), 0)
					
					' Тело
					If state->SendOnlyHeaders = False Then
						send(ClientSocket, b + Index, CInt(FileSize.QuadPart - CLng(Index)), 0)
					End If
					
					' Закрыть
					UnmapViewOfFile(b)
				End If
				CloseHandle(hFileMap)
				#if __FB_DEBUG__ <> 0
					Print "Закрываю отображённый в память файл hFileMap"
				#endif
			End If
		End If
	End If
	
	' Закрыть
	If hZipFile <> INVALID_HANDLE_VALUE Then
		CloseHandle(hZipFile)
		#if __FB_DEBUG__ <> 0
			Print "Закрываю сжатый файл hZipFile"
		#endif
	End If
	CloseHandle(hFile)
	#if __FB_DEBUG__ <> 0
		Print "Закрываю файл hFile"
	#endif
	Return True
End Function

Function ProcessDeleteRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle, ByVal hFile As Handle)As Boolean
	If hFile = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		' Файла не существет, записать ошибку клиенту
		Dim buf410 As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, @www->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile410 = INVALID_HANDLE_VALUE Then
			' Файлы не существует, но она может появиться позже
			state->StatusCode = 404
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError404FileNotFound, www->VirtualPath, hOutput)
		Else
			' Файла раньше существовала, но теперь удалена навсегда
			CloseHandle(hFile410)
			state->StatusCode = 410
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError410Gone, www->VirtualPath, hOutput)
		End If
		Return True
	End If
	CloseHandle(hFile)
	
	Dim mt As MimeType = GetMimeTypeOfExtension(fileExtention)
	If mt.ContentType = ContentTypes.None Then
		' Не обрабатываем файлы с неизвестным типом
		state->StatusCode = 403
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError403File, @www->VirtualPath, hOutput)
		Return False
	End If
	
	' Проверка заголовка Authorization
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return True
	End If
	
	' Необходимо удалить файл
	If DeleteFile(@www->PathTranslated) <> 0 Then
		' Удалить возможные заголовочные файлы
		Dim sExtHeadersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@sExtHeadersFile, @www->PathTranslated)
		lstrcat(@sExtHeadersFile, @HeadersExtensionString)
		DeleteFile(@sExtHeadersFile)
		
		' Создать файл «.410», показывающий, что файл был удалён
		lstrcpy(@sExtHeadersFile, @www->PathTranslated)
		lstrcat(@sExtHeadersFile, @FileGoneExtension)
		Dim hFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
		CloseHandle(hFile)
	Else
		' Ошибка
		' TODO Узнать код ошибки и отправить его клиенту
		state->StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		Return True
	End If
	' Отправить заголовки, что нет содержимого
	state->StatusCode = 204
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
	
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
	If lstrlen(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentType)) = 0 Then
		state->StatusCode = 501
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError501ContentTypeEmpty, @www->VirtualPath, hOutput)
		Return True
	End If
	' TODO Проверить тип содержимого
	
	' Сжатое содержимое не поддерживается
	If lstrlen(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentEncoding)) <> 0 Then
		state->StatusCode = 501
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError501ContentEncoding, @www->VirtualPath, hOutput)
		Return True
	End If
	
	' Требуется указание длины
	If lstrlen(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength)) = 0 Then
		state->StatusCode = 411
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError411LengthRequired, @www->VirtualPath, hOutput)
		Return True
	End If
	
	' Длина содержимого по заголовку Content-Length слишком большая
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	RequestBodyContentLength.QuadPart = wtol(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength))
	If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
		state->StatusCode = 413
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError413RequestEntityTooLarge, @www->VirtualPath, hOutput)
		Return True
	End If
	
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
	
	' если ресурс присутствовал и был изменен в результате запроса PUT,
	' выдается код статуса 200 (Ok) или 204 (No Content).
	' В случае отсутствия ресурса по указанному в заголовке URI,
	' сервер создает его и возвращает код статуса 201 (Created),
	
	Dim HeaderLocation As WString * (WebSite.MaxFilePathLength + 1) = Any
	
	' Открыть существующий файл для перезаписи
	Dim hFile As HANDLE = CreateFile(@www->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		' Создать каталог, если ещё не создан
		Dim intError As Integer = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print intError
		#endif
		Select Case intError
			Case ERROR_PATH_NOT_FOUND
				Dim FileDir As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
				lstrcpy(@FileDir, @www->PathTranslated)
				PathRemoveFileSpec(@FileDir)
				#if __FB_DEBUG__ <> 0
					Print www->PathTranslated
					Print FileDir
				#endif
				CreateDirectory(@FileDir, Null)
				#if __FB_DEBUG__ <> 0
					Print GetLastError()
				#endif
		End Select
		
		' Открыть файл с нуля
		hFile = CreateFile(@www->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile = INVALID_HANDLE_VALUE Then
			#if __FB_DEBUG__ <> 0
				Print "Нельзя создать файл"
			#endif
			' Нельзя открыть файл для перезаписи
			' TODO Узнать код ошибки и отправить его клиенту
			state->StatusCode = 500
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
			Return True
		End If
		
		state->StatusCode = 201
		lstrcpy(@HeaderLocation, "http://")
		lstrcat(@HeaderLocation, @www->HostName)
		lstrcat(@HeaderLocation, @www->FilePath)
		state->ResponseHeaders(HttpResponseHeaderIndices.HeaderLocation) = @HeaderLocation
	Else
		' Файл уже существует
		#if __FB_DEBUG__ <> 0
			Print "Файл уже существует"
		#endif
		state->StatusCode = 200
	End If
	
	Dim hFileMap As Handle = CreateFileMapping(hFile, 0, PAGE_READWRITE, RequestBodyContentLength.HighPart, RequestBodyContentLength.LowPart, 0)
	If hFileMap = 0 Then
		#if __FB_DEBUG__ <> 0
			Print "Не могу создать отображение файла в память"
		#endif
		' TODO Узнать код ошибки и отправить его клиенту
		state->StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
	Else
		Dim b As Byte Ptr = CPtr(Byte Ptr, MapViewOfFile(hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0))
		If b = 0 Then
			#if __FB_DEBUG__ <> 0
				Print "Не могу отобразить файл в память"
			#endif
			' TODO Узнать код ошибки и отправить его клиенту
			state->StatusCode = 500
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		Else
			' TODO Заголовки записать в специальный файл
			REM HeaderContentEncoding
			REM HeaderContentLanguage
			REM HeaderContentLocation
			REM HeaderContentMd5
			REM HeaderContentType
			
			' Записать предварительно загруженные данные и очистить
			Dim PreloadedContentLength As Integer = state->ClientReader.BufferLength - state->ClientReader.Start
			If PreloadedContentLength > 0 Then
				memcpy(b, @state->ClientReader.Buffer[state->ClientReader.Start], PreloadedContentLength)
				state->ClientReader.Flush()
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
			
			' Удалить файл 410, если он был
			Dim PathTranslated410 As WString * (WebSite.MaxFilePathTranslatedLength + 4 + 1) = Any
			lstrcpy(@PathTranslated410, @www->PathTranslated)
			lstrcat(@PathTranslated410, @FileGoneExtension)
			DeleteFile(@PathTranslated410) ' не проверяем ошибку удаления
			
			' Отправить клиенту текст, что всё хорошо и закрыть соединение
			WriteHttp201(ClientSocket, state, www, hOutput)
			
			UnmapViewOfFile(b)
		End If
		CloseHandle(hFileMap)
	End If
	CloseHandle(hFile)
	Return True
End Function

Function ProcessTraceRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Собрать все заголовки запроса и сформировать из них тело ответа
	
	state->StatusCode = 200
	state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = GetStringOfContentType(ContentTypes.MessageHttp)
	
	Dim ContentLength As Integer = state->ClientReader.Start - 2
	
	' Заголовки
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, ContentLength, hOutput), 0)
	
	' Тело
	send(ClientSocket, @state->ClientReader.Buffer, ContentLength, 0)
	Return True
End Function

Function ProcessOptionsRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Нет содержимого
	state->StatusCode = 204
	
	' Если звёздочка, то ко всему серверу
	If lstrcmp(state->ClientRequest.ClientURI.Url, "*") = 0 Then
		state->ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethods
	Else
		' If hFile = INVALID_HANDLE_VALUE Then
			' Файла не существет, записать ошибку клиенту
			' WriteNotFoundError(ClientSocket, state, www, hOutput)
			' Return True
		' End If
		' К конкретному ресурсу
		state->ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethodsFile
	End If
	
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
	Return True
End Function

Function ProcessConnectRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Проверка заголовка Authorization
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return True
	End If
	
	' Файл с настройками
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, @www->PhysicalDirectory, @WebServerIniFileString)
	
	Dim ConnectBindAddress As WString * 256 = Any
	Dim ConnectBindPort As WString * 16 = Any
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindAddressSectionString, @DefaultAddressString, @ConnectBindAddress, 255, @IniFileName)
	GetPrivateProfileString(@WebServerSectionString, @ConnectBindPortSectionString, @ConnectBindDefaultPort, @ConnectBindPort, 15, @IniFileName)
	
	' Соединиться с сервером
	Dim ServiceName As WString Ptr = Any
	Dim wColon As WString Ptr = StrChr(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderHost), ColonChar)
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
	
	Dim ServerSocket2 As SOCKET = ConnectToServer(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderHost), ServiceName, @ConnectBindAddress, @ConnectBindPort)
	If ServerSocket2 = INVALID_SOCKET Then
		' Не могу соединиться
		state->StatusCode = 504
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError504GatewayTimeout, @www->VirtualPath, hOutput)
		Return True
	End If

	' Отправить ответ о статусе соединения
	state->StatusCode = 200
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
	
	' Читать данные от клиента, отправлять на сервер
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
				' state->StatusCode = 502
				' WriteHttpError(state, ClientSocket, @HttpError504GatewayTimeout, @www->VirtualPath, hOutput)
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

/'
	Методы MOVE и COPY
	
	Request
	MOVE /pub2/folder1/ HTTP/1.1
	Destination: http://www.contoso.com/pub2/folder2/
	Host: www.contoso.com
	
	Response
	HTTP/1.1 201 Created
	Location: http://www.contoso.com/pub2/folder2/
	
	Ответы:
	201 The resource was moved successfully and a new resource was created at the specified destination URI.
	204 The resource was moved successfully to a pre-existing destination URI.
	403 The source URI and the destination URI are the same.
	409 (Conflict) A resource cannot be created at the destination URI until one or more intermediate collections are created.
	412 (Precondition Failed) Either the Overwrite header is "F" and the state of the destination resource is not null, or the method was used in a Depth: 0 transaction.
	423 (Locked) The destination resource is locked.
	502 (Bad Gateway) The destination URI is located on a different server, which refuses to accept the resource.
	507 (Insufficient Storage) The destination resource does not have sufficient storage space.
'/
