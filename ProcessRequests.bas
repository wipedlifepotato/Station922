#include once "ProcessRequests.bi"
#include once "Mime.bi"
#include once "HttpConst.bi"
#include once "WebUtils.bi"
#include once "Network.bi"
#include once "IniConst.bi"
#include once "URI.bi"
#include once "CharConstants.bi"
#include once "WriteHttpError.bi"
#include once "ServerState.bi"

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

' Размером клиентского буфера один мегабайт
Const MaxClientBufferLength As Integer = 512 * 1024




Function DllCgiGetRequestHeader(ByVal objState As ServerState_ Ptr, ByVal Value As WString Ptr, ByVal BufferLength As Integer, ByVal HeaderIndex As HttpRequestHeaderIndices)As Integer
	Dim HeaderLength As Integer = lstrlen(objState->state->ClientRequest.RequestHeaders(HeaderIndex))
	If HeaderLength > BufferLength Then
		SetLastError(ERROR_INSUFFICIENT_BUFFER)
		Return -1
	End If
	
	SetLastError(ERROR_SUCCESS)
	lstrcpy(Value, objState->state->ClientRequest.RequestHeaders(HeaderIndex))
	Return HeaderLength
End Function

Function DllCgiGetHttpMethod(ByVal objState As ServerState_ Ptr)As HttpMethods
	SetLastError(ERROR_SUCCESS)
	Return objState->state->ClientRequest.HttpMethod
End Function

Function DllCgiGetHttpVersion(ByVal objState As ServerState_ Ptr)As HttpVersions
	SetLastError(ERROR_SUCCESS)
	Return objState->state->ClientRequest.HttpVersion
End Function

Sub DllCgiSetStatusCode(ByVal objState As ServerState_ Ptr, ByVal Code As Integer)
	objState->state->ServerResponse.StatusCode = Code
End Sub

Sub DllCgiSetStatusDescription(ByVal objState As ServerState_ Ptr, ByVal Description As WString Ptr)
	' TODO Устранить потенциальное переполнение буфера
	objState->state->ServerResponse.SetStatusDescription(Description)
End Sub

Sub DllCgiSetResponseHeader(ByVal objState As ServerState_ Ptr, ByVal HeaderIndex As HttpResponseHeaderIndices, ByVal Value As WString Ptr)
	' TODO Устранить потенциальное переполнение буфера
	objState->state->ServerResponse.AddKnownResponseHeader(HeaderIndex, Value)
End Sub

Function DllCgiWriteData(ByVal objState As ServerState_ Ptr, ByVal Buffer As Any Ptr, ByVal BytesCount As Integer)As Boolean
	If BytesCount > MaxClientBufferLength - objState->BufferLength Then
		SetLastError(ERROR_BUFFER_OVERFLOW)
		Return False
	End If
	
	RtlCopyMemory(objState->ClientBuffer, Buffer, BytesCount)
	objState->BufferLength += BytesCount
	SetLastError(ERROR_SUCCESS)
	
	Return True
End Function

Function DllCgiReadData(ByVal objState As ServerState_ Ptr, ByVal Buffer As Any Ptr, ByVal BufferLength As Integer, ByVal ReadedBytesCount As Integer Ptr)As Boolean
	Return False
End Function





Function ProcessDllCgiRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean
	' Создать клиентский буфер
	Dim hMapFile As HANDLE = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, MaxClientBufferLength, NULL)
	If hMapFile = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка CreateFileMapping", intError
		#endif
		state->ServerResponse.StatusCode = 503
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderRetryAfter) = @"Retry-After: 300"
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError503Memory, @www->VirtualPath, hOutput)
		Return False
	End If
	
	Dim ClientBuffer As Any Ptr = MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, MaxClientBufferLength)
	If ClientBuffer = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка MapViewOfFile", intError
		#endif
		CloseHandle(hMapFile)
		state->ServerResponse.StatusCode = 503
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderRetryAfter) = @"Retry-After: 300"
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError503Memory, @www->VirtualPath, hOutput)
		Return False
	End If
	
	Dim hModule As HINSTANCE = LoadLibrary(@www->PathTranslated)
	If hModule = NULL Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка загрузки DLL", intError
		#endif
		state->ServerResponse.StatusCode = 503
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderRetryAfter) = @"Retry-After: 300"
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError503Memory, @www->VirtualPath, hOutput)
		Return False
	End If
	
	Dim ProcessDllRequest As Function(ByVal objServerState As ServerState Ptr)As Boolean
	
	Dim DllFunction As Any Ptr = GetProcAddress(hModule, "ProcessDllRequest")
	If DllFunction = 0 Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Ошибка поиска функции ProcessDllRequest", intError
		#endif
		FreeLibrary(hModule)
		state->ServerResponse.StatusCode = 502
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError502BadGateway, @www->VirtualPath, hOutput)
		Return False
	End If
	
	ProcessDllRequest = DllFunction
	
	Dim objVirtualTable As IServerState = Any
	objVirtualTable.GetRequestHeader = @DllCgiGetRequestHeader
	objVirtualTable.GetHttpMethod = @DllCgiGetHttpMethod
	objVirtualTable.GetHttpVersion = @DllCgiGetHttpVersion
	objVirtualTable.SetStatusCode = @DllCgiSetStatusCode
	objVirtualTable.SetStatusDescription = @DllCgiSetStatusDescription
	objVirtualTable.SetResponseHeader = @DllCgiSetResponseHeader
	objVirtualTable.GetSafeString = @GetSafeString
	objVirtualTable.WriteData = @DllCgiWriteData
	objVirtualTable.ReadData = @DllCgiReadData
	
	Dim objServerState As ServerState = Any
	objServerState.VirtualTable = @objVirtualTable
	objServerState.ClientSocket = ClientSocket
	objServerState.state = state
	objServerState.www = www
	objServerState.hMapFile = hMapFile
	objServerState.ClientBuffer = ClientBuffer
	objServerState.BufferLength = 0
	
	Dim Result As Boolean = ProcessDllRequest(@objServerState)
	If Result = False Then
		Dim intError As DWORD = GetLastError()
		#if __FB_DEBUG__ <> 0
			Print "Функция ProcessDllRequest завершилась ошибкой", intError
		#endif
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		state->ServerResponse.StatusCode = 503
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError503Memory, @www->VirtualPath, hOutput)
		Return False
	End If
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, objServerState.BufferLength, hOutput), 0) = SOCKET_ERROR Then
		UnmapViewOfFile(objServerState.ClientBuffer)
		CloseHandle(hMapFile)
		Return False
	End If
	
	' Тело
	If state->ServerResponse.SendOnlyHeaders = False Then
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
			state->ServerResponse.StatusCode = 404
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError404FileNotFound, www->VirtualPath, hOutput)
		Else
			' Файла раньше существовала, но теперь удалена навсегда
			CloseHandle(hFile410)
			state->ServerResponse.StatusCode = 410
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError410Gone, www->VirtualPath, hOutput)
		End If
		Return False
	End If
	
	' Проверка на CGI
	If NeedCGIProcessing(state->ClientRequest.ClientUri.Path) Then
		' CloseHandle(hFile)
		' Return ProcessCGIRequest(ClientSocket, state, www, fileExtention, hOutput)
	End If
	
	' Проверка на dll-cgi
	If NeedDLLProcessing(state->ClientRequest.ClientUri.Path) Then
		CloseHandle(hFile)
		Return ProcessDllCgiRequest(ClientSocket, state, www, fileExtention, hOutput)
	End If
	
	' Не обрабатываем файлы с неизвестным типом
	Dim mt As MimeType = GetMimeTypeOfExtension(fileExtention)
	If mt.ContentType = ContentTypes.None Then
		state->ServerResponse.StatusCode = 403
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError403File, @www->VirtualPath, hOutput)
		CloseHandle(hFile)
		Return False
	End If
	
	' TODO Проверить идентификацию для запароленных ресурсов
	
	Dim hZipFile As Handle = Any
	If mt.IsTextFormat Then
		hZipFile = state->SetResponseCompression(@www->PathTranslated)
	Else
		hZipFile = INVALID_HANDLE_VALUE
	End If
	
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
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		CloseHandle(hZipFile)
		CloseHandle(hFile)
		Return False
	End If
	
	' Строка с типом документа
	Dim wContentType As WString * (2 * MaxContentTypeLength + 1) = Any
	lstrcpy(@wContentType, GetStringOfContentType(mt.ContentType))
	
	If FileSize.QuadPart = 0 Then
		' Создать заголовки ответа и отправить клиенту
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
		state->AddResponseCacheHeaders(hFile)
		Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		Dim SendResult As Integer = send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
		CloseHandle(hZipFile)
		CloseHandle(hFile)
		If SendResult = SOCKET_ERROR Then
			Return False
		End If
		Return True
	End If
	
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
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		CloseHandle(hZipFile)
		CloseHandle(hFile)
		Return False
	End If
	
	' Всё хорошо
	' Создать представление файла
	Dim b As UByte Ptr = CPtr(UByte Ptr, MapViewOfFile(hFileMap, FILE_MAP_READ, 0, 0, 0))
	If b = 0 Then
		' Чтение файла завершилось неудачей
		' TODO Узнать код ошибки и отправить его клиенту
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		CloseHandle(hFileMap)
		CloseHandle(hZipFile)
		CloseHandle(hFile)
		Return False
	End If
	
	' HTTP/1.1 206 Partial Content
	' Обратите внимание на заголовок Content-Length — в нём указывается размер тела сообщения,
	' то есть передаваемого фрагмента. Если сервер вернёт несколько фрагментов,
	' то Content-Length будет содержать их суммарный объём.
	' Content-Range: bytes 471104-2355520/2355521
	' state->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentRange) = "bytes 471104-2355520/2355521"
	
	Dim Index As Integer = Any ' Смещение относительно начала файла, чтобы не отправлять BOM
	If mt.IsTextFormat Then
		If hZipFile = INVALID_HANDLE_VALUE Then
			' b указывает на настоящий файл
			If FileSize.QuadPart > 3 Then
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
			Else
				' Кодировка ASCII
				Index = 0
			End If
		Else
			' b указывает на сжатый файл
			Index = 0
			Dim b2 As ZString * 4 = Any
			Dim BytesCount As DWORD = Any
			If ReadFile(hFile, @b2, 3, @BytesCount, 0) <> 0 Then
				If BytesCount >= 3 Then
					Select Case GetDocumentCharset(@b2)
						Case DocumentCharsets.ASCII
							' Ничего
						Case DocumentCharsets.Utf8BOM
							lstrcat(wContentType, @ContentCharsetUtf8)
						Case DocumentCharsets.Utf16LE
							lstrcat(wContentType, @ContentCharsetUtf16)
						Case DocumentCharsets.Utf16BE
							lstrcat(wContentType, @ContentCharsetUtf16)
					End Select
				REM Else
					REM ' Кодировка ASCII
				End If
			End If
		End If
	Else
		Index = 0
	End If
	
	state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
	state->AddResponseCacheHeaders(hFile)
	
	' Добавить пользовательские заголовки ответа
	' TODO Может быть переполнение буфера при слишком длинных заголовках ответа
	Dim sExtHeadersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(@sExtHeadersFile, @www->PathTranslated)
	lstrcat(@sExtHeadersFile, @HeadersExtensionString)
	Dim hExtHeadersFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hExtHeadersFile <> INVALID_HANDLE_VALUE Then
		Dim zExtHeaders As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		Dim wExtHeaders As WString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		
		Dim BytesCount As DWORD = Any
		If ReadFile(hExtHeadersFile, @zExtHeaders, WebResponse.MaxResponseHeaderBuffer, @BytesCount, 0) <> 0 Then
			If BytesCount > 2 Then
				zExtHeaders[BytesCount] = 0
				If MultiByteToWideChar(CP_UTF8, 0, @zExtHeaders, -1, @wExtHeaders, WebResponse.MaxResponseHeaderBuffer) > 0 Then
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
							state->ServerResponse.AddResponseHeader(wName, wColon)
						End If
					Loop While lstrlen(w) > 0
				End If
			End If
		End If
		CloseHandle(hExtHeadersFile)
	End If
	
	' В основном анализируются заголовки
	' Accept: text/css, */*
	' Accept-Charset: utf-8
	' Accept-Encoding: gzip, deflate
	' Accept-Language: ru-RU
	' User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36 Edge/15.15063
	' Серверу желательно включать в ответ заголовок Vary с указанием параметров,
	' по которым различается содержимое по запрашиваемому URI.
	
	' Заголовки сжатия
	' TODO вместо перезаписывания заголовка его нужно добавить
	Select Case state->ServerResponse.ResponseZipMode
		
		Case ZipModes.GZip
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @GZipString
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @"Accept-Encoding"
			
		Case ZipModes.Deflate
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @DeflateString
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @"Accept-Encoding"
			
		Case Else
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = 0
			
	End Select
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, FileSize.QuadPart - Cast(LongInt, Index), hOutput), 0) = SOCKET_ERROR Then
		UnmapViewOfFile(b)
		CloseHandle(hFileMap)
		CloseHandle(hZipFile)
		CloseHandle(hFile)
		Return False
	End If
	
	' Тело
	If state->ServerResponse.SendOnlyHeaders = False Then
		If send(ClientSocket, b + Index, CInt(FileSize.QuadPart - CLng(Index)), 0) = SOCKET_ERROR Then
			UnmapViewOfFile(b)
			CloseHandle(hFileMap)
			CloseHandle(hZipFile)
			CloseHandle(hFile)
			Return False
		End If
	End If
	
	' Закрыть
	UnmapViewOfFile(b)
	CloseHandle(hFileMap)
	#if __FB_DEBUG__ <> 0
		Print "Закрываю отображённый в память файл hFileMap"
	#endif
	
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

Function ProcessDeleteRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle, ByVal hFile As Handle)As Boolean
	If hFile = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		' Файла не существет, записать ошибку клиенту
		Dim buf410 As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, @www->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile410 = INVALID_HANDLE_VALUE Then
			' Файлы не существует, но она может появиться позже
			state->ServerResponse.StatusCode = 404
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError404FileNotFound, www->VirtualPath, hOutput)
		Else
			' Файла раньше существовала, но теперь удалена навсегда
			CloseHandle(hFile410)
			state->ServerResponse.StatusCode = 410
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError410Gone, www->VirtualPath, hOutput)
		End If
		Return False
	End If
	CloseHandle(hFile)
	
	' Проверка заголовка Authorization
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return False
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
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		Return False
	End If
	' Отправить заголовки, что нет содержимого
	state->ServerResponse.StatusCode = 204
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0) = SOCKET_ERROR Then
		Return False
	End If
	
	Return True
End Function

Function ProcessPutRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Проверка авторизации пользователя
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return False
	End If
	
	' Если какой-то из переданных серверу заголовков Content-* не опознан или не может быть использован в данной ситуации
	' сервер возвращает статус ошибки 501 (Not Implemented).
	' Если ресурс с указанным URI не может быть создан или модифицирован,
	' должно быть послано соответствующее сообщение об ошибке. 
	
	' Не указан тип содержимого
	If lstrlen(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentType)) = 0 Then
		state->ServerResponse.StatusCode = 501
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError501ContentTypeEmpty, @www->VirtualPath, hOutput)
		Return False
	End If
	' TODO Проверить тип содержимого
	
	' Сжатое содержимое не поддерживается
	If lstrlen(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentEncoding)) <> 0 Then
		state->ServerResponse.StatusCode = 501
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError501ContentEncoding, @www->VirtualPath, hOutput)
		Return False
	End If
	
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	
	' Требуется указание длины
	If StrToInt64Ex(state->ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderContentLength), STIF_DEFAULT, @RequestBodyContentLength.QuadPart) = 0 Then
		state->ServerResponse.StatusCode = 411
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError411LengthRequired, @www->VirtualPath, hOutput)
		Return False
	End If
	
	' Длина содержимого по заголовку Content-Length слишком большая
	If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
		state->ServerResponse.StatusCode = 413
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError413RequestEntityTooLarge, @www->VirtualPath, hOutput)
		Return False
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
	
	Dim HeaderLocation As WString * (WebSite.MaxFilePathLength + 1) = Any
	
	' Открыть существующий файл для перезаписи
	Dim hFile As HANDLE = CreateFile(@www->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, TRUNCATE_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		' Создать каталог, если ещё не создан
		
		Select Case GetLastError()
			
			Case ERROR_PATH_NOT_FOUND
				Dim FileDir As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
				lstrcpy(@FileDir, @www->PathTranslated)
				PathRemoveFileSpec(@FileDir)
				CreateDirectory(@FileDir, Null)
				
		End Select
		
		' Открыть файл с нуля
		hFile = CreateFile(@www->PathTranslated, GENERIC_READ + GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile = INVALID_HANDLE_VALUE Then
			' Нельзя открыть файл для перезаписи
			' TODO Узнать код ошибки и отправить его клиенту
			state->ServerResponse.StatusCode = 500
			WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
			Return False
		End If
		
		state->ServerResponse.StatusCode = 201
		lstrcpy(@HeaderLocation, "http://")
		lstrcat(@HeaderLocation, @www->HostName)
		lstrcat(@HeaderLocation, @www->FilePath)
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderLocation) = @HeaderLocation
	End If
	
	Dim hFileMap As Handle = CreateFileMapping(hFile, 0, PAGE_READWRITE, RequestBodyContentLength.HighPart, RequestBodyContentLength.LowPart, 0)
	If hFileMap = 0 Then
		' TODO Узнать код ошибки и отправить его клиенту
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		
		CloseHandle(hFile)
		Return False
	End If
	
	Dim b As Byte Ptr = CPtr(Byte Ptr, MapViewOfFile(hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0))
	If b = 0 Then
		' TODO Узнать код ошибки и отправить его клиенту
		state->ServerResponse.StatusCode = 500
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError500NotAvailable, @www->VirtualPath, hOutput)
		
		CloseHandle(hFileMap)
		CloseHandle(hFile)
		Return False
	End If
	
	' TODO Заголовки записать в специальный файл
	REM HeaderContentEncoding
	REM HeaderContentLanguage
	REM HeaderContentLocation
	REM HeaderContentMd5
	REM HeaderContentType
	
	' Записать предварительно загруженные данные и удалить их из клиентского буфера
	Dim PreloadedContentLength As Integer = state->ClientReader.BufferLength - state->ClientReader.Start
	If PreloadedContentLength > 0 Then
		RtlCopyMemory(b, @state->ClientReader.Buffer[state->ClientReader.Start], PreloadedContentLength)
		' TODO Проверить на ошибки записи
		state->ClientReader.Flush()
	End If
	
	' Записать всё остальное
	Do While PreloadedContentLength < RequestBodyContentLength.QuadPart
		Dim numReceived As Integer = recv(ClientSocket, @b[PreloadedContentLength], RequestBodyContentLength.QuadPart - PreloadedContentLength, 0)
		
		' TODO Проверить на ошибки получения данных из сокета
		Select Case numReceived
			
			Case SOCKET_ERROR
				Exit Do
				
			Case 0
				Exit Do
				
			Case Else
				' Сколько байт получили, на столько и увеличили буфер
				PreloadedContentLength += numReceived
				
		End Select
		
	Loop
	
	' Удалить файл 410, если он был
	Dim PathTranslated410 As WString * (WebSite.MaxFilePathTranslatedLength + 4 + 1) = Any
	lstrcpy(@PathTranslated410, @www->PathTranslated)
	lstrcat(@PathTranslated410, @FileGoneExtension)
	DeleteFile(@PathTranslated410) ' не проверяем ошибку удаления
	
	' Отправить клиенту текст, что всё хорошо
	Dim WriteResult As Boolean = WriteHttp201(ClientSocket, state, www, hOutput)
	
	UnmapViewOfFile(b)
	
	CloseHandle(hFileMap)
	CloseHandle(hFile)
	
	Return WriteResult
End Function

Function ProcessTraceRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal hOutput As Handle)As Boolean
	' Собрать все заголовки запроса и сформировать из них тело ответа
	
	state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = GetStringOfContentType(ContentTypes.MessageHttp)
	
	Dim ContentLength As Integer = state->ClientReader.Start - 2
	
	' Заголовки
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, ContentLength, hOutput), 0) = SOCKET_ERROR Then
		Return False
	End If
	
	' Тело
	If send(ClientSocket, @state->ClientReader.Buffer, ContentLength, 0) = SOCKET_ERROR Then
		Return False
	End If
	
	Return True
End Function

Function ProcessOptionsRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal hOutput As Handle)As Boolean
	' Нет содержимого
	state->ServerResponse.StatusCode = 204
	
	' Если звёздочка, то ко всему серверу
	If lstrcmp(state->ClientRequest.ClientURI.Url, "*") = 0 Then
		state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethods
	Else
		' К конкретному ресурсу
		' Проверка на CGI
		If NeedCGIProcessing(state->ClientRequest.ClientUri.Path) Then
			state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethodsScript
		Else
			' Проверка на dll-cgi
			If NeedDLLProcessing(state->ClientRequest.ClientUri.Path) Then
				state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethodsScript
			Else
				state->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = @AllSupportHttpMethodsFile
			End If
		End If
	End If
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0) = SOCKET_ERROR Then
		Return False
	End If
	
	Return True
End Function

Function ProcessConnectRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	' Проверка заголовка Authorization
	If HttpAuthUtil(ClientSocket, state, www, hOutput) = False Then
		Return False
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
		state->ServerResponse.StatusCode = 504
		WriteHttpError(state, ClientSocket, HttpErrors.HttpError504GatewayTimeout, @www->VirtualPath, hOutput)
		Return False
	End If

	' Отправить ответ о статусе соединения
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->GetResponseHeadersString(@SendBuffer, 0, hOutput), 0)
	
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
