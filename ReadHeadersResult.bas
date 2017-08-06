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
	RequestHeaderBufferLength = 0
	StatusDescription = 0
	URI.Url = 0
	URI.QueryString = 0
	StartResponseHeadersPtr = @ResponseHeaderBuffer
	ResponseZipMode = ZipModes.None
	ClientReader.Flush()
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
	
	Dim UsernamePasswordUtf8 As ZString * (MaxRequestHeaderBuffer + 1) = Any
	' Преобразовать из base64 в массив байт и поставить завершающий ноль
	UsernamePasswordUtf8[Decode64(@UsernamePasswordUtf8, wSpace + 1)] = 0
	
	' Из массива байт в строку
	' Преобразуем utf8 в WString
	' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
	Dim UsernamePassword As WString * (MaxRequestHeaderBuffer + 1) = Any
	MultiByteToWideChar(CP_UTF8, 0, @UsernamePasswordUtf8, -1, @UsernamePassword, MaxRequestHeaderBuffer)
	
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

Function ReadHeadersResult.SetResponseCompression(ByVal PathTranslated As WString Ptr)As Handle
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
	
	Return INVALID_HANDLE_VALUE
End Function

Sub ReadHeadersResult.AddResponseCacheHeaders(ByVal hFile As HANDLE)
	Dim IsFileModified As Boolean = True
	' Дата последней модицикации
	Dim ftWrite As FILETIME = Any
	If GetFileTime(hFile, 0, 0, @ftWrite) = 0 Then
		StatusCode = 200
		Exit Sub
	End If
	
	Dim dFileLastModified As SYSTEMTIME = Any
	FileTimeToSystemTime(@ftWrite, @dFileLastModified)
	
	' TODO Уметь распознавать все три HTTP‐формата даты
	Scope
		Dim strFileLastModifiedHttpDate As WString * 256 = Any
		' Получить строку с датой
		GetHttpDate(@strFileLastModifiedHttpDate, @dFileLastModified)
		AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderLastModified, @strFileLastModifiedHttpDate)
		
		If lstrlen(RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) <> 0 Then
			
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
			
			If lstrcmpi(@strFileLastModifiedHttpDate, RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) = 0 Then
				IsFileModified = False
			End If
		End If
	End Scope
	
	Scope
		Dim strETag As WString * 256 = Any
		lstrcpy(@strETag, @QuoteString)
		Dim ul As ULARGE_INTEGER = Any
		ul.LowPart = ftWrite.dwLowDateTime
		ul.HighPart = ftWrite.dwHighDateTime
		ltow(ul.QuadPart, @strETag + 1, 10)
		Select Case ResponseZipMode
			Case ZipModes.GZip
				lstrcat(@strETag, @GzipString)
			Case ZipModes.Deflate
				lstrcat(@strETag, @DeflateString)
		End Select
		lstrcat(@strETag, @QuoteString)
		AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderEtag, @strETag)
		
		If IsFileModified Then
			If lstrlen(RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch)) <> 0 Then
				If lstrcmpi(RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch), @strETag) = 0 Then
					IsFileModified = False
				End If
			End If
		End If
	End Scope
	
	Scope
		Dim strDateExpires As WString * 256 = Any
		' Текущая дата в виде файлового времени
		Dim datNowF As FILETIME = Any
		GetSystemTimeAsFileTime(@datNowF)
		
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
		GetHttpDate(@strDateExpires, @datAddMonth)
		AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderExpires, @strDateExpires)
	End Scope
	
	ResponseHeaders(HttpResponseHeaderIndices.HeaderCacheControl) = @DefaultCacheControl
	
	SendOnlyHeaders = SendOnlyHeaders OrElse Not IsFileModified
	StatusCode = Iif(IsFileModified, 200, 304)
End Sub

Sub ReadHeadersResult.AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	Dim HeaderIndex As Integer = GetKnownResponseHeaderIndex(HeaderName)
	If HeaderIndex >= 0 Then
		AddKnownResponseHeader(HeaderIndex, Value)
	End If
End Sub

Sub ReadHeadersResult.AddKnownResponseHeader(ByVal HeaderIndex As HttpResponseHeaderIndices, ByVal Value As WString Ptr)
	lstrcpy(StartResponseHeadersPtr, Value)
	ResponseHeaders(HeaderIndex) = StartResponseHeadersPtr
	StartResponseHeadersPtr += lstrlen(Value) + 2
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

Function ReadHeadersResult.GetResponseHeadersString(ByVal Buffer As ZString Ptr, ByVal ContentLength As LongInt, ByVal hOutput As Handle)As Integer
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
	Dim HeadersLength As Integer = WideCharToMultiByte(CP_UTF8, 0, @wHeadersBuffer, -1, Buffer, MaxResponseHeaderBuffer + 1, 0, 0) - 1
	
	' Запись в лог
	Dim LogBuffer As ZString * (StreamSocketReader.MaxBufferLength + MaxResponseHeaderBuffer) = Any
	Dim WriteBytes As DWORD = Any
	memcpy(@LogBuffer, @ClientReader.Buffer, ClientReader.Start)
	memcpy(@LogBuffer + ClientReader.Start, Buffer, HeadersLength)
	WriteFile(hOutput, @LogBuffer, ClientReader.Start + HeadersLength, @WriteBytes, 0)
	Return HeadersLength
End Function

Function ReadHeadersResult.ReadAllHeaders()As ParseRequestLineResult
	Dim wLine As WString Ptr = @RequestHeaderBuffer[RequestHeaderBufferLength]
	Dim wLineLength As Integer = ClientReader.ReadLine(@RequestHeaderBuffer[RequestHeaderBufferLength], MaxRequestHeaderBuffer - RequestHeaderBufferLength)
	RequestHeaderBufferLength += wLineLength + 1
	
	Select Case GetLastError()
		Case StreamSocketReader.BufferOverflowError
			#if __FB_DEBUG__ <> 0
				Print "Буфер переполнен"
			#endif
			Return ParseRequestLineResult.RequestHeaderFieldsTooLarge
			
		Case StreamSocketReader.SocketError
			#if __FB_DEBUG__ <> 0
				Print "Ошибка сокета"
			#endif
			Return ParseRequestLineResult.SocketError
			
		Case StreamSocketReader.ClientClosedSocketError
			#if __FB_DEBUG__ <> 0
				Print "Клиент закрыл соединение"
			#endif
			Return ParseRequestLineResult.EmptyRequest
			
	End Select
	
	' Метод, запрошенный ресурс и версия протокола
	' Первый пробел
	Dim wSpace As WString Ptr = StrChr(wLine, SpaceChar)
	If wSpace = 0 Then
		Return ParseRequestLineResult.BadRequest
	End If
	
	' Удалить пробел
	wSpace[0] = 0
	' Теперь в RequestLine содержится имя метода
	HttpMethod = GetHttpMethod(wLine)
	
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
	
	' TODO Звёздочка в пути допустима при методе OPTIONS
	If IsBadPath(@URI.Path) Then
		Return ParseRequestLineResult.BadPath
	End If
	
	' Получить все заголовки запроса
	Do
		wLine = @RequestHeaderBuffer[RequestHeaderBufferLength]
		wLineLength = ClientReader.ReadLine(@RequestHeaderBuffer[RequestHeaderBufferLength], MaxRequestHeaderBuffer - RequestHeaderBufferLength)
		RequestHeaderBufferLength += wLineLength + 1
		
		Select Case GetLastError()
			Case StreamSocketReader.BufferOverflowError
				#if __FB_DEBUG__ <> 0
					Print "2 Буфер переполнен"
				#endif
				Return ParseRequestLineResult.RequestHeaderFieldsTooLarge
				
			Case StreamSocketReader.SocketError
				#if __FB_DEBUG__ <> 0
					Print "2 Ошибка сокета"
				#endif
				Return ParseRequestLineResult.SocketError
				
			Case StreamSocketReader.ClientClosedSocketError
				#if __FB_DEBUG__ <> 0
					Print "2 Клиент закрыл соединение"
				#endif
				Return ParseRequestLineResult.EmptyRequest
				
		End Select
		
		If lstrlen(wLine) = 0 Then
			' Клиент отправил все данные, можно приступать к обработке
			Exit Do
		Else
			' TODO Обработать ситуацию, когда клиент отправляет заголовок с переносом на новую строку
			Dim wColon As WString Ptr = StrChr(wLine, ColonChar)
			If wColon <> 0 Then
				wColon[0] = 0
				Do
					wColon += 1
				Loop While wColon[0] = 32
				
				AddRequestHeader(wLine, wColon)
				
			End If
		End If
	Loop
	
	Return ParseRequestLineResult.Success
End Function
