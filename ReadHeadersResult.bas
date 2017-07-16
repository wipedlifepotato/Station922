#include once "ReadHeadersResult.bi"
#include once "WebUtils.bi"
#include once "base64.bi"
#include once "HttpConst.bi"
#include once "WebSite.bi"
#include once "CharConstants.bi"

Sub ReadHeadersResult.Initialize()
	memset(@RequestHeaders(0), 0, RequestHeaderMaximum * SizeOf(WString Ptr))
	memset(@ResponseHeaders(0), 0, ResponseHeaderMaximum * SizeOf(WString Ptr))
	memset(@RequestZipModes(0), 0, MaxRequestZipEnabled * SizeOf(Boolean))
	KeepAlive = False
	SendOnlyHeaders = False
	HttpVersion = HttpVersions.Http11
	EndHeadersOffset = 0
	HeaderBytesLength = 0
	RequestHeaderBufferLength = 0
	StatusDescription = 0
	URI.Url = 0
	URI.QueryString = 0
	StartResponseHeadersPtr = @ResponseHeaderBuffer
	ResponseZipMode = ZipModes.None
End Sub

Function ReadHeadersResult.HttpAuth(ByVal www As WebSite Ptr)As HttpAuthResult
	If lstrlen(RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization)) = 0 Then
		' Требуется авторизация
		Return HttpAuthResult.NeedAuth
	End If
	
	Dim wSpace As WString Ptr = StrChr(RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization), SpaceChar)
	If wSpace = 0 Then
		' Параметры авторизации неверны
		Return HttpAuthResult.BadAuth
	End If
	
	wSpace[0] = 0
	If lstrcmp(RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization), @BasicAuthorization) <> 0 Then
		' Необходимо использовать Basic‐авторизацию
		Return HttpAuthResult.NeedBasicAuth
	End If
	
	Dim UsernamePasswordUtf8 As ZString * (MaxRequestHeaderBytes + 1) = Any
	' Преобразовать из base64 в массив байт и поставить завершающий ноль
	UsernamePasswordUtf8[Decode64(@UsernamePasswordUtf8, wSpace + 1)] = 0
	
	' Из массива байт в строку
	' Преобразуем utf8 в WString
	' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
	Dim UsernamePassword As WString * (MaxRequestHeaderBytes + 1) = Any
	MultiByteToWideChar(CP_UTF8, 0, @UsernamePasswordUtf8, -1, @UsernamePassword, MaxRequestHeaderBytes)
	
	' Теперь wSpace хранит в себе указатель на разделитель‐двоеточие
	wSpace = StrChr(@UsernamePassword, ColonChar)
	If wSpace = 0 Then
		' Пароль не может быть пустым
		Return HttpAuthResult.EmptyPassword
	End If
	
	wSpace[0] = 0 ' Убрали двоеточие
	Dim UsersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
	www->MapPath(@UsersFile, @UsersIniFileString)
	#if __FB_DEBUG__ <> 0
		Print UsersFile
	#endif
	
	Dim PasswordBuffer As WString * (255 + 1) = Any
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	GetPrivateProfileString(@AdministratorsSectionString, @UsernamePassword, @DefaultValue, @PasswordBuffer, 255, @UsersFile)
	
	If lstrlen(@PasswordBuffer) = 0 Then
		' Имя пользователя не подходит
		Return HttpAuthResult.BadUserNamePassword
	End If
	
	If lstrcmp(@PasswordBuffer, wSpace + 1) <> 0 Then
		' Пароль не подходит
		Return HttpAuthResult.BadUserNamePassword
	End If
	
	' Аутентификация успешно пройдена
	Return HttpAuthResult.Success
End Function

Function ReadHeadersResult.SetResponseCompression(ByVal IsTextFormat As Boolean, ByVal PathTranslated As WString Ptr)As Handle
	If IsTextFormat Then
		If RequestZipModes(GZipIndex) Then
			Dim Buf As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
			lstrcpy(Buf, PathTranslated)
			lstrcat(Buf, @GZipExtensionString)
			Dim hFile As HANDLE = CreateFile(@Buf, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
			If hFile <> INVALID_HANDLE_VALUE Then
				ResponseZipMode = ZipModes.GZip
				Return hFile
			End If
		End If
		
		If RequestZipModes(DeflateIndex) Then
			' Найти файлу со сжатием
			Dim Buf As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
			lstrcpy(Buf, PathTranslated)
			lstrcat(Buf, @DeflateExtensionString)
			
			Dim hFile As HANDLE = CreateFile(@Buf, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
			If hFile <> INVALID_HANDLE_VALUE Then
				ResponseZipMode = ZipModes.Deflate
				Return hFile
			End If
		End If
		
	End If
	Return INVALID_HANDLE_VALUE
End Function

Sub ReadHeadersResult.AddResponseCacheHeaders(ByVal hFile As HANDLE)
	Dim bModified As Boolean = True
	' Дата последней модицикации
	Dim ftWrite As FILETIME = Any
	If GetFileTime(hFile, 0, 0, @ftWrite) <> 0 Then
		Dim dFileLastModified As SYSTEMTIME = Any
		FileTimeToSystemTime(@ftWrite, @dFileLastModified)
		
		Dim dtBuffer As WString Ptr = StartResponseHeadersPtr
		' Получить строку с датой
		GetHttpDate(dtBuffer, @dFileLastModified)
		' Передвинуть
		StartResponseHeadersPtr += lstrlen(dtBuffer) + 2
		
		' 64‐битное число (время создания файла) в строку
		Dim ETagBuffer As WString Ptr = StartResponseHeadersPtr
		lstrcpy(ETagBuffer, @QuoteString)
		Dim ul As ULARGE_INTEGER = Any
		ul.LowPart = ftWrite.dwLowDateTime
		ul.HighPart = ftWrite.dwHighDateTime
		ltow(ul.QuadPart, ETagBuffer + 1, 10)
		Select Case ResponseZipMode
			Case ZipModes.GZip
				lstrcat(ETagBuffer, @GzipString)
			Case ZipModes.Deflate
				lstrcat(ETagBuffer, @DeflateString)
		End Select
		lstrcat(ETagBuffer, @QuoteString)
		' Передвинуть
		StartResponseHeadersPtr += lstrlen(ETagBuffer) + 2
		
		' TODO Уметь распознавать все три HTTP‐формата даты
		If lstrlen(RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) = 0 Then
			' Убрать ";" если есть
			Dim wSeparator As WString Ptr = StrChr(RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince), SemicolonChar)
			If wSeparator <> 0 Then
				wSeparator[0] = 0
			End If
			
			' Убрать UTC и заменить на GMT
			'If-Modified-Since: Thu, 24 Mar 2016 16:10:31 UTC
			'If-Modified-Since: Tue, 11 Mar 2014 20:07:57 GMT
			Dim wUTC As WString Ptr = StrStr(RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince), "UTC")
			If wUTC <> 0 Then
				lstrcpy(wUTC, "GMT")
			End If
			
			If lstrcmpi(dtBuffer, RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) = 0 Then
				' Дата от клиента совпадает с датой модификации файла
				bModified = False
			End If
		End If
		
		If bModified Then
			If lstrlen(RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch)) = 0 Then
				If lstrcmpi(RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch), ETagBuffer) <> 0 Then
					bModified = True
				End If
			End If
		End If
		
		SendOnlyHeaders = SendOnlyHeaders OrElse Not bModified
		ResponseHeaders(HttpResponseHeaderIndices.HeaderLastModified) = dtBuffer
		ResponseHeaders(HttpResponseHeaderIndices.HeaderEtag) = ETagBuffer
		ResponseHeaders(HttpResponseHeaderIndices.HeaderCacheControl) = @DefaultCacheControl ' Целый месяц кэширования
		
	End If
	StatusCode = Iif(bModified, 200, 304)
End Sub

Sub ReadHeadersResult.AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	' Получить индекс заголовка по имени
	Dim HeaderIndex As Integer = GetKnownResponseHeaderIndex(HeaderName)
	If HeaderIndex >=0 Then
		' Скопировать
		lstrcpy(StartResponseHeadersPtr, Value)
		' Сохранить указатель
		ResponseHeaders(HeaderIndex) = StartResponseHeadersPtr
		' Передвинуть
		StartResponseHeadersPtr += lstrlen(Value) + 2
	End If
End Sub

Sub ReadHeadersResult.SetStatusDescription(ByVal Description As WString Ptr)
	' Скопировать
	lstrcpy(StartResponseHeadersPtr, Description)
	' Сохранить указатель
	StatusDescription = StartResponseHeadersPtr
	' Передвинуть
	StartResponseHeadersPtr += lstrlen(Description) + 2
End Sub

Sub ReadHeadersResult.AddRequestHeader(ByVal Header As WString Ptr, ByVal Value As WString Ptr)
	Dim HeaderIndex As Integer = GetKnownRequestHeaderIndex(Header)
	If HeaderIndex >= 0 Then
		Select Case HeaderIndex
			Case HttpRequestHeaderIndices.HeaderConnection
				If StrStrI(Value, @CloseString) <> 0 Then
					KeepAlive = False
				Else
					If StrStrI(Value, @HeaderKeepAliveString) Then
						KeepAlive = True
					End If
				End If
			Case HttpRequestHeaderIndices.HeaderAcceptEncoding
				If StrStrI(Value, @GzipString) <> 0 Then
					RequestZipModes(GZipIndex) = True
				End If
				If StrStrI(Value, @DeflateString) <> 0 Then
					RequestZipModes(DeflateIndex) = True
				End If
		End Select
		RequestHeaders(HeaderIndex) = Value
	Else
		' TODO Добавить в нераспознанные заголовки запроса
	End If
End Sub

Function ReadHeadersResult.MakeResponseHeaders(ByVal Buffer As ZString Ptr, ByVal ContentLength As LongInt, ByVal hOutput As Handle)As Integer
	Dim wHeadersBuffer As WString * (MaxResponseHeaderBuffer + 1) = Any
	
	Scope
		Const SpaceChar As Integer = 32
		
		Dim strStatusCode As WString * (10 + 1) = Any
		itow(StatusCode, @strStatusCode, 10) ' Число в строку
		
		lstrcpy(@wHeadersBuffer, @HttpVersion11)
		wHeadersBuffer[HttpVersion11Length] = SpaceChar
		lstrcpy(@wHeadersBuffer + HttpVersion11Length + 1, @strStatusCode)
		wHeadersBuffer[HttpVersion11Length + 1 + 3] = SpaceChar
		If StatusDescription = 0 Then
			Dim wStatusDescription As WString * 32 = Any
			GetStatusDescription(@wStatusDescription, StatusCode)
			lstrcpy(@wHeadersBuffer + HttpVersion11Length + 1 + 3 + 1, @wStatusDescription)
		Else
			lstrcpy(@wHeadersBuffer + HttpVersion11Length + 1 + 3 + 1, StatusDescription)
		End If
		lstrcat(@wHeadersBuffer, @NewLineString)
	End Scope
	
	Dim wStart As WString Ptr = @wHeadersBuffer[lstrlen(@wHeadersBuffer)]
	
	' Установить заголовок сжатия
	Select Case ResponseZipMode
		Case ZipModes.GZip
			ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @GZipString
			' Указание кешу, чтобы различал содержимое по методу кодирования (gzip, deflate)
			ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @HeaderAcceptEncodingString
		Case ZipModes.Deflate
			ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @DeflateString
			ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @HeaderAcceptEncodingString
	End Select
	
	' TODO Разрешение выполнять частичный GET
	' ResponseHeaders(HttpWorkerRequest.HeaderAcceptRanges) = @BytesString
	
	' Самореклама
	ResponseHeaders(HttpResponseHeaderIndices.HeaderServer) = @HttpServerNameString
	
	' Соединение
	If KeepAlive Then
		If HttpVersion = HttpVersions.Http10 Then
			' Только для версии протокола 1.0
			ResponseHeaders(HttpResponseHeaderIndices.HeaderConnection) = @HeaderKeepAliveString
		End If
	Else
		ResponseHeaders(HttpResponseHeaderIndices.HeaderConnection) = @CloseString
	End If
	
	' Длина содержимого
	Dim strContentLength As WString * (32) = Any
	If ContentLength >= 0 Then
		Select Case StatusCode
			Case 100
				ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLength) = 0
			Case 204
				ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLength) = 0
			Case Else
				ltow(ContentLength, @strContentLength, 10)
				ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLength) = @strContentLength
		End Select
	End If
	
	' Текущая дата в виде файлового времени
	Dim datNowF As FILETIME = Any
	GetSystemTimeAsFileTime(@datNowF)
	
	Dim dtBuffer2 As WString * (32) = Any
	If ResponseHeaders(HttpResponseHeaderIndices.HeaderExpires) = 0 Then
		' Добавить целый месяц к заголовку протухания
		Dim udatNow As ULARGE_INTEGER = Any
		udatNow.LowPart = datNowF.dwLowDateTime
		udatNow.HighPart = datNowF.dwHighDateTime
		udatNow.QuadPart += 10 * 1000 * 1000 * SecondsInOneMonths
		
		Dim datNow2 As FILETIME = Any
		datNow2.dwLowDateTime = udatNow.LowPart
		datNow2.dwHighDateTime = udatNow.HighPart
		
		Dim datAddMonth As SYSTEMTIME = Any
		FileTimeToSystemTime(@datNow2, @datAddMonth)
		GetHttpDate(@dtBuffer2, @datAddMonth)
		ResponseHeaders(HttpResponseHeaderIndices.HeaderExpires) = @dtBuffer2
	End If
	
	' Текущая дата
	Dim datNowS As SYSTEMTIME = Any
	FileTimeToSystemTime(@datNowF, @datNowS)
	Dim dtBuffer As WString * (32) = Any
	GetHttpDate(@dtBuffer, @datNowS)
	ResponseHeaders(HttpResponseHeaderIndices.HeaderDate) = @dtBuffer
	
	' Сборка всех заголовков в одну строку
	For i As Integer = 0 To ResponseHeaderMaximum - 1
		If ResponseHeaders(i) <> 0 Then
			Dim HeadersBuffer As WString * (MaxResponseHeaderBuffer + 1) = Any
			Dim HeaderNameLength As Integer = GetKnownResponseHeaderName(@HeadersBuffer, Cast(HttpResponseHeaderIndices, i))
			lstrcpy(@HeadersBuffer + HeaderNameLength, @ColonWithSpaceString)
			lstrcpy(@HeadersBuffer + HeaderNameLength + 2, ResponseHeaders(i))
			Dim ResponseHeaderLength As Integer = lstrlen(ResponseHeaders(i))
			lstrcpy(@HeadersBuffer + HeaderNameLength + 2 + ResponseHeaderLength, @NewLineString)
			
			lstrcpy(wStart, @HeadersBuffer)
			
			wStart += HeaderNameLength + 2 + ResponseHeaderLength + 2
		End If
	Next
	
	' Пустая строка для разделения заголовков и тела
	lstrcat(wStart, @NewLineString)
	
	#if __FB_DEBUG__ <> 0
		Print wHeadersBuffer
	#endif
	' Перекодировать в ANSI
	Dim HeadersLength As Integer = WideCharToMultiByte(CP_UTF8, 0, @wHeadersBuffer, -1, Buffer, ReadHeadersResult.MaxResponseHeaderBuffer + 1, 0, 0) - 1
	
	' Запись в лог
	Dim LogBuffer As ZString * (MaxRequestHeaderBytes + MaxResponseHeaderBuffer) = Any
	Dim WriteBytes As DWORD = Any
	memcpy(@LogBuffer, @HeaderBytes, EndHeadersOffset)
	memcpy(@LogBuffer + EndHeadersOffset, Buffer, HeadersLength)
	WriteFile(hOutput, @LogBuffer, EndHeadersOffset + HeadersLength, @WriteBytes, 0)
	Return HeadersLength
End Function

Sub ReadHeadersResult.ReadLine(ByVal wResult As ReadLineResult Ptr, ByVal ClientSocket As SOCKET)
	' Найти в буфере vbCrLf
	Dim FindIndex As Integer = FindCrLfA(@HeaderBytes, EndHeadersOffset, HeaderBytesLength)
	
	Do While FindIndex = -1
		' Символы переноса строки не найдены
		' Если буфер заполнен, то считывать данные больше нельзя
		If HeaderBytesLength >= ReadHeadersResult.MaxRequestHeaderBytes Then
			wResult->ErrorStatus = ParseRequestLineResult.RequestHeaderFieldsTooLarge
			Return
		End If
		' Считать данные
		Dim numReceived As Integer = recv(ClientSocket, @HeaderBytes[HeaderBytesLength], MaxRequestHeaderBytes - HeaderBytesLength, 0)
		Select Case numReceived
			Case SOCKET_ERROR
				' Ошибка, так как должно быть минимум 1 байт на блокирующем сокете
				wResult->ErrorStatus = ParseRequestLineResult.EmptyRequest
				Return
			Case 0
				' Клиент закрыл соединение
				If EndHeadersOffset >= HeaderBytesLength Then
					wResult->ErrorStatus = ParseRequestLineResult.EmptyRequest
				Else
					' В буфере что‐то есть
					wResult->wLine = @RequestHeaderBuffer[RequestHeaderBufferLength]
					HeaderBytes[HeaderBytesLength] = 0 ' Теперь валидная строка для винапи
					
					' Преобразуем utf-8 в WString
					' Нулевой символ будет записан в буфер автоматически
					' Длина строки будет указывать на следующий символ после нулевого
					RequestHeaderBufferLength += MultiByteToWideChar(CP_UTF8, 0, @HeaderBytes[EndHeadersOffset], -1, @RequestHeaderBuffer[RequestHeaderBufferLength], MaxRequestHeaderBuffer - RequestHeaderBufferLength)
					' Вернуть символ на место
					HeaderBytes[HeaderBytesLength] = 13
					
					' Поставить конец заголовков за пределы полученных байт
					EndHeadersOffset = HeaderBytesLength
					wResult->ErrorStatus = ParseRequestLineResult.Success
				End If
				Return
			Case Else
				' Сколько байт получили, на столько и увеличили буфер
				HeaderBytesLength += numReceived
		End Select
		' Найти vbCrLf опять
		FindIndex = FindCrLfA(@HeaderBytes, EndHeadersOffset, HeaderBytesLength)
	Loop
	
	' vbCrLf найдено, получить строку
	wResult->wLine = @RequestHeaderBuffer[RequestHeaderBufferLength]
	' На место CrLf записываем ноль
	HeaderBytes[FindIndex] = 0 ' Теперь валидная строка для винапи
	
	' Преобразуем utf-8 в WString
	' Нулевой символ будет записан в буфер автоматически
	' Длина строки будет указывать на следующий символ после нулевого
	RequestHeaderBufferLength += MultiByteToWideChar(CP_UTF8, 0, @HeaderBytes[EndHeadersOffset], -1, @RequestHeaderBuffer[RequestHeaderBufferLength], MaxRequestHeaderBuffer - RequestHeaderBufferLength)
	' Вернуть символ на место
	HeaderBytes[FindIndex] = 13
	
	' Сдвинуть конец заголовков вправо на FindIndex + len(vbCrLf)
	EndHeadersOffset = FindIndex + 2
	
	wResult->ErrorStatus = ParseRequestLineResult.Success
End Sub

Function ReadHeadersResult.ReadAllHeaders(ByVal ClientSocket As SOCKET)As ParseRequestLineResult
	' Проверить наличие данных от клиента
	Dim wResult As ReadLineResult = Any
	ReadLine(@wResult, ClientSocket)
	If wResult.ErrorStatus <> ParseRequestLineResult.Success Then
		Return wResult.ErrorStatus
	End If
	
	' Метод, запрошенный ресурс и версия протокола
	' Первый пробел
	Dim wSpace As WString Ptr = StrChr(wResult.wLine, SpaceChar)
	If wSpace = 0 Then
		Return ParseRequestLineResult.BadRequest
	End If
	
	' Удалить пробел
	wSpace[0] = 0
	' Теперь в RequestLine содержится имя метода
	' Проверить поддерживаемый метод
	HttpMethod = GetHttpMethod(wResult.wLine)
	If HttpMethod = HttpMethods.None Then
		Return ParseRequestLineResult.MethodNotSupported
	End If
	
	' Здесь начинается Url
	URI.Url = wSpace + 1
	
	' Второй пробел
	wSpace = StrChr(URI.Url, SpaceChar)
	If wSpace = 0 Then
		' Есть только метод и Url, значит, версия HTTP = 0.9
		HttpVersion = HttpVersions.Http09
	Else
		' Убрать пробел
		wSpace[0] = 0
		
		' Третий пробел
		If StrChr(URI.Url, SpaceChar) <> 0 Then
			' Слишком много пробелов
			Return ParseRequestLineResult.BadRequest
		End If
		
		' Теперь в (wSpace + 1) находится версия протокола, определить
		If lstrcmp(wSpace + 1, HttpVersion10) = 0 Then
			HttpVersion = HttpVersions.Http10
		Else
			If lstrcmp(wSpace + 1, HttpVersion11) = 0 Then
				HttpVersion = HttpVersions.Http11
				KeepAlive = True ' Для версии 1.1 это по умолчанию
			Else
				' Версия не поддерживается
				Return ParseRequestLineResult.HTTPVersionNotSupported
			End If
		End If
	End If
	
	If lstrlen(URI.Url) > URI.MaxUrlLength Then
		Return ParseRequestLineResult.RequestUrlTooLong
	End If
	
	' Если есть «?», значит там строка запроса
	Dim wQS As WString Ptr = StrChr(URI.Url, QuestionMarkChar)
	If wQS = 0 Then
		lstrcpy(@URI.Path, URI.Url)
	Else
		URI.QueryString = wQS + 1
		' Получение пути
		wQS[0] = 0 ' убрать вопросительный знак
		lstrcpy(@URI.Path, URI.Url)
		wQS[0] = &h3F ' вернуть, чтобы не портить Url
	End If
	
	' Раскодировка пути
	If StrChr(@URI.Path, PercentSign) <> 0 Then
		Dim DecodedPath As WString * (URI.MaxUrlLength + 1) = Any
		UrlDecode(@DecodedPath, @URI.Path)
		lstrcpy(@URI.Path, @DecodedPath)
	End If
	
	' Звёздочка в пути допустима при методе OPTIONS
	If IsBadPath(@URI.Path) Then
		Return ParseRequestLineResult.BadPath
	End If
	
	' Отправлять только заголовки
	If HttpMethod = HttpMethods.HttpHead Then
		SendOnlyHeaders = True
	End If
	
	' Получить все заголовки запроса
	Do
		ReadLine(@wResult, ClientSocket)
		If wResult.ErrorStatus <> ParseRequestLineResult.Success Then
			Return wResult.ErrorStatus
		End If
		
		If lstrlen(wResult.wLine) = 0 Then
			' Клиент отправил все данные, можно приступать к обработке
			Exit Do
		Else
			' TODO Обработать ситуацию, когда клиент отправляет заголовок с переносом на новую строку
			Dim wColon As WString Ptr = StrChr(wResult.wLine, ColonChar)
			If wColon <> 0 Then
				wColon[0] = 0
				Do
					wColon += 1
				Loop While wColon[0] = 32
				
				AddRequestHeader(wResult.wLine, wColon)
				
			End If
		End If
	Loop
	
	Return ParseRequestLineResult.Success
End Function
