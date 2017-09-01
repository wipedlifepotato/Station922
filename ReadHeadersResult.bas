#include once "ReadHeadersResult.bi"
#include once "WebUtils.bi"
#include once "base64.bi"
#include once "HttpConst.bi"
#include once "WebSite.bi"
#include once "CharConstants.bi"
#include once "AppendingBuffer.bi"

Const ColonWithSpaceString = ": "
Const SpaceString = " "
Const ColonString = ":"
Const UsersIniFileString = "users.config"
Const AdministratorsSectionString = "admins"

Sub ReadHeadersResult.Initialize()
	ClientRequest.Initialize()
	ServerResponse.Initialize()
	ClientReader.Flush()
End Sub

Function ReadHeadersResult.HttpAuth(ByVal www As WebSite Ptr)As HttpAuthResult
	If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization)) = 0 Then
		' Требуется авторизация
		Return HttpAuthResult.NeedAuth
	End If
	
	Dim wSpace As WString Ptr = StrChr(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization), SpaceChar)
	If wSpace = 0 Then
		' Параметры авторизации неверны
		Return HttpAuthResult.BadAuth
	End If
	
	wSpace[0] = 0
	If lstrcmp(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderAuthorization), @BasicAuthorization) <> 0 Then
		' Необходимо использовать Basic‐авторизацию
		Return HttpAuthResult.NeedBasicAuth
	End If
	
	Dim UsernamePasswordUtf8 As ZString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	' Преобразовать из base64 в массив байт и поставить завершающий ноль
	UsernamePasswordUtf8[Decode64(@UsernamePasswordUtf8, wSpace + 1)] = 0
	
	' Из массива байт в строку
	' Преобразуем utf8 в WString
	' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
	Dim UsernamePassword As WString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	MultiByteToWideChar(CP_UTF8, 0, @UsernamePasswordUtf8, -1, @UsernamePassword, WebRequest.MaxRequestHeaderBuffer)
	
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
	If ClientRequest.RequestZipModes(WebRequest.GZipIndex) Then
		Dim Buf As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(Buf, PathTranslated)
		lstrcat(Buf, @GZipExtensionString)
		Dim hFile As HANDLE = CreateFile(@Buf, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile <> INVALID_HANDLE_VALUE Then
			ServerResponse.ResponseZipMode = ZipModes.GZip
			Return hFile
		End If
	End If
	
	If ClientRequest.RequestZipModes(WebRequest.DeflateIndex) Then
		Dim Buf As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(Buf, PathTranslated)
		lstrcat(Buf, @DeflateExtensionString)
		
		Dim hFile As HANDLE = CreateFile(@Buf, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile <> INVALID_HANDLE_VALUE Then
			ServerResponse.ResponseZipMode = ZipModes.Deflate
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
		Exit Sub
	End If
	
	Dim dFileLastModified As SYSTEMTIME = Any
	FileTimeToSystemTime(@ftWrite, @dFileLastModified)
	
	' TODO Уметь распознавать все три HTTP‐формата даты
	Scope
		Dim strFileLastModifiedHttpDate As WString * 256 = Any
		' Получить строку с датой
		GetHttpDate(@strFileLastModifiedHttpDate, @dFileLastModified)
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderLastModified, @strFileLastModifiedHttpDate)
		
		If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) <> 0 Then
			
			' Убрать ";" если есть
			Dim wSeparator As WString Ptr = StrChr(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince), SemicolonChar)
			If wSeparator <> 0 Then
				wSeparator[0] = 0
			End If
			
			If lstrcmpi(@strFileLastModifiedHttpDate, ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderIfModifiedSince)) = 0 Then
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
		Select Case ServerResponse.ResponseZipMode
			Case ZipModes.GZip
				lstrcat(@strETag, @GzipString)
			Case ZipModes.Deflate
				lstrcat(@strETag, @DeflateString)
		End Select
		lstrcat(@strETag, @QuoteString)
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderEtag, @strETag)
		
		If IsFileModified Then
			If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch)) <> 0 Then
				If lstrcmpi(ClientRequest.RequestHeaders(HttpRequestHeaderIndices.HeaderIfNoneMatch), @strETag) = 0 Then
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
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderExpires, @strDateExpires)
	End Scope
	
	ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderCacheControl) = @DefaultCacheControl
	
	ServerResponse.SendOnlyHeaders OrElse= Not IsFileModified
	If IsFileModified = False Then
		ServerResponse.StatusCode = 304
	End If
End Sub

Function ReadHeadersResult.GetResponseHeadersString(ByVal Buffer As ZString Ptr, ByVal ContentLength As LongInt, ByVal hOutput As Handle)As Integer
	' TODO Найти способ откатывать изменения буфера заголовков ответа
	
	' Самореклама
	ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderServer) = @HttpServerNameString
	
	' Разрешение выполнять частичный GET
	If ServerResponse.StatusCode <> 206 Then
		ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderAcceptRanges) = @BytesString
	End If
	
	' Соединение
	If ClientRequest.KeepAlive Then
		If ClientRequest.HttpVersion = HttpVersions.Http10 Then
			' Только для версии протокола 1.0
			ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderConnection) = @"Keep-Alive"
		End If
	Else
		ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderConnection) = @CloseString
	End If
	
	Select Case ServerResponse.StatusCode
		
		Case 100
			ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLength) = 0
			
		Case 204
			ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentLength) = 0
			
		Case Else
			Dim strContentLength As WString * (64) = Any
			ltow(ContentLength, @strContentLength, 10)
			ServerResponse.AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderContentLength, @strContentLength)
			
	End Select
	
	Scope
		' Текущая дата в виде файлового времени
		Dim datNowF As FILETIME = Any
		GetSystemTimeAsFileTime(@datNowF)
		
		' Текущая дата
		Dim datNowS As SYSTEMTIME = Any
		FileTimeToSystemTime(@datNowF, @datNowS)
		Dim dtBuffer As WString * (32) = Any
		GetHttpDate(@dtBuffer, @datNowS)
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaderIndices.HeaderDate, @dtBuffer)
	End Scope
	
	Dim wHeadersBuffer As WString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	
	Dim AppendBuffer As AppendingBuffer = Any
	AppendBuffer.Buffer = @wHeadersBuffer
	AppendBuffer.BufferLength = 0
	
	Scope
		Dim strStatusCode As WString * 16 = Any
		itow(ServerResponse.StatusCode, @strStatusCode, 10)
		
		AppendBuffer.AppendWString(@HttpVersion11, HttpVersion11Length)
		
		AppendBuffer.AppendWChar(SpaceChar)
		
		AppendBuffer.AppendWString(@strStatusCode, 3)
		
		AppendBuffer.AppendWChar(SpaceChar)
		
		If ServerResponse.StatusDescription = 0 Then
			Dim BufferLength As Integer = Any
			Dim Buffer As WString Ptr = GetStatusDescription(ServerResponse.StatusCode, BufferLength)
			AppendBuffer.AppendWString(Buffer, BufferLength)
		Else
			AppendBuffer.AppendWString(ServerResponse.StatusDescription)
		End If
		AppendBuffer.AppendWString(@NewLineString)
	End Scope
	
	For i As Integer = 0 To WebResponse.ResponseHeaderMaximum - 1
		If ServerResponse.ResponseHeaders(i) <> 0 Then
			
			Dim BufferLength As Integer = Any
			Dim Buffer As WString Ptr = GetKnownResponseHeaderName(i, BufferLength)
			AppendBuffer.AppendWString(Buffer, BufferLength)
			AppendBuffer.AppendWString(@ColonWithSpaceString, 2)
			AppendBuffer.AppendWString(ServerResponse.ResponseHeaders(i))
			AppendBuffer.AppendWString(@NewLineString, 2)
			
		End If
	Next
	
	' Пустая строка для разделения заголовков и тела
	AppendBuffer.AppendWString(@NewLineString, 2)
	
	#if __FB_DEBUG__ <> 0
		Print wHeadersBuffer
	#endif
	' Перекодировать в ANSI
	Dim HeadersLength As Integer = WideCharToMultiByte(CP_UTF8, 0, @wHeadersBuffer, -1, Buffer, WebResponse.MaxResponseHeaderBuffer + 1, 0, 0) - 1
	
	' Запись в лог
	Dim LogBuffer As ZString * (StreamSocketReader.MaxBufferLength + WebResponse.MaxResponseHeaderBuffer) = Any
	Dim WriteBytes As DWORD = Any
	RtlCopyMemory(@LogBuffer, @ClientReader.Buffer, ClientReader.Start)
	RtlCopyMemory(@LogBuffer + ClientReader.Start, Buffer, HeadersLength)
	WriteFile(hOutput, @LogBuffer, ClientReader.Start + HeadersLength, @WriteBytes, 0)
	Return HeadersLength
End Function
