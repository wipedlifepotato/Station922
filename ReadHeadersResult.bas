#include once "ReadHeadersResult.bi"
#include once "WebUtils.bi"
#include once "HttpConst.bi"
#include once "WebSite.bi"
#include once "CharConstants.bi"
#include once "AppendingBuffer.bi"
#include once "IntegerToWString.bi"

Const ColonWithSpaceString = ": "
Const UsersIniFileString = "users.config"
Const AdministratorsSectionString = "admins"

Sub InitializeReadHeadersResult( _
		ByVal pState As ReadHeadersResult Ptr _
	)
	InitializeWebRequest(@pState->ClientRequest)
	InitializeWebResponse(@pState->ServerResponse)
End Sub

Function ReadHeadersResult.HttpAuth( _
		ByVal www As WebSite Ptr, _
		ByVal ProxyAuthorization As Boolean _
	)As HttpAuthResult
	
	Dim HeaderAuthorization As WString Ptr = Any
	If ProxyAuthorization Then
		If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderProxyAuthorization)) = 0 Then
			HeaderAuthorization = ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderAuthorization)
		Else
			HeaderAuthorization = ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderProxyAuthorization)
		End If
	Else
		HeaderAuthorization = ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderAuthorization)
	End If
	
	If lstrlen(HeaderAuthorization) = 0 Then
		Return HttpAuthResult.NeedAuth
	End If
	
	
	Dim wSpace As WString Ptr = StrChr(HeaderAuthorization, SpaceChar)
	If wSpace = 0 Then
		Return HttpAuthResult.BadAuth
	End If
	
	wSpace[0] = 0
	If lstrcmp(HeaderAuthorization, @BasicAuthorization) <> 0 Then
		Return HttpAuthResult.NeedBasicAuth
	End If
	
	Dim UsernamePasswordUtf8 As ZString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	Dim dwUsernamePasswordUtf8Length As DWORD = WebRequest.MaxRequestHeaderBuffer
	
	CryptStringToBinary(wSpace + 1, 0, CRYPT_STRING_BASE64, @UsernamePasswordUtf8, @dwUsernamePasswordUtf8Length, 0, 0)
	
	UsernamePasswordUtf8[dwUsernamePasswordUtf8Length] = 0
	
	' Из массива байт в строку
	' Преобразуем utf8 в WString
	' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
	Dim UsernamePassword As WString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	MultiByteToWideChar(CP_UTF8, 0, @UsernamePasswordUtf8, -1, @UsernamePassword, WebRequest.MaxRequestHeaderBuffer)
	
	' Теперь wSpace хранит в себе указатель на разделитель‐двоеточие
	wSpace = StrChr(@UsernamePassword, ColonChar)
	If wSpace = 0 Then
		Return HttpAuthResult.EmptyPassword
	End If
	
	wSpace[0] = 0 ' Убрали двоеточие
	Dim UsersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
	www->MapPath(@UsersFile, @UsersIniFileString)
	
	Dim PasswordBuffer As WString * (255 + 1) = Any
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	GetPrivateProfileString(@AdministratorsSectionString, @UsernamePassword, @DefaultValue, @PasswordBuffer, 255, @UsersFile)
	
	If lstrlen(@PasswordBuffer) = 0 Then
		Return HttpAuthResult.BadUserNamePassword
	End If
	
	If lstrcmp(@PasswordBuffer, wSpace + 1) <> 0 Then
		Return HttpAuthResult.BadUserNamePassword
	End If
	
	Return HttpAuthResult.Success
End Function

Function ReadHeadersResult.SetResponseCompression( _
		ByVal PathTranslated As WString Ptr, _
		ByVal pAcceptEncoding As Boolean Ptr _
	)As Handle
	
	Scope
		Dim GZipFileName As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@GZipFileName, PathTranslated)
		lstrcat(@GZipFileName, @GZipExtensionString)
		
		Dim hFile As HANDLE = CreateFile(@GZipFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, NULL)
		
		If hFile <> INVALID_HANDLE_VALUE Then
			*pAcceptEncoding = True
			
			If ClientRequest.RequestZipModes(WebRequest.GZipIndex) Then
				ServerResponse.ResponseZipMode = ZipModes.GZip
				Return hFile
			End If
			
			CloseHandle(hFile)
		End If
	End Scope
	
	Scope
		Dim DeflateFileName As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@DeflateFileName, PathTranslated)
		lstrcat(@DeflateFileName, @DeflateExtensionString)
		
		Dim hFile As HANDLE = CreateFile(@DeflateFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, NULL)
		
		If hFile <> INVALID_HANDLE_VALUE Then
			*pAcceptEncoding = True
		
			If ClientRequest.RequestZipModes(WebRequest.DeflateIndex) Then
				ServerResponse.ResponseZipMode = ZipModes.Deflate
				Return hFile
			End If
			
			CloseHandle(hFile)
		End If
	End Scope
	
	Return INVALID_HANDLE_VALUE
End Function

Sub ReadHeadersResult.AddResponseCacheHeaders(ByVal hFile As HANDLE)
	Dim IsFileModified As Boolean = True
	' Дата последней модицикации
	Dim DateLastFileModified As FILETIME = Any
	If GetFileTime(hFile, 0, 0, @DateLastFileModified) = 0 Then
		Exit Sub
	End If
	
	Scope
		' TODO Уметь распознавать все три HTTP‐формата даты
		Dim dFileLastModified As SYSTEMTIME = Any
		FileTimeToSystemTime(@DateLastFileModified, @dFileLastModified)
		
		Dim strFileLastModifiedHttpDate As WString * 256 = Any
		GetHttpDate(@strFileLastModifiedHttpDate, @dFileLastModified)
		
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaders.HeaderLastModified, @strFileLastModifiedHttpDate)
		
		If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince)) <> 0 Then
			
			' Убрать ";" если есть
			Dim wSeparator As WString Ptr = StrChr(ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince), SemicolonChar)
			If wSeparator <> 0 Then
				wSeparator[0] = 0
			End If
			
			If lstrcmpi(@strFileLastModifiedHttpDate, ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince)) = 0 Then
				IsFileModified = False
			End If
		End If
	End Scope
	
	Scope
		Dim strETag As WString * 256 = Any
		lstrcpy(@strETag, @QuoteString)
		
		Dim ul As ULARGE_INTEGER = Any
		With ul
			.LowPart = DateLastFileModified.dwLowDateTime
			.HighPart = DateLastFileModified.dwHighDateTime
		End With
		
		ui64tow(ul.QuadPart, @strETag + 1, 10)
		
		Select Case ServerResponse.ResponseZipMode
			Case ZipModes.GZip
				lstrcat(@strETag, @GzipString)
			Case ZipModes.Deflate
				lstrcat(@strETag, @DeflateString)
		End Select
		
		lstrcat(@strETag, @QuoteString)
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaders.HeaderEtag, @strETag)
		
		If IsFileModified Then
			If lstrlen(ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderIfNoneMatch)) <> 0 Then
				If lstrcmpi(ClientRequest.RequestHeaders(HttpRequestHeaders.HeaderIfNoneMatch), @strETag) = 0 Then
					IsFileModified = False
				End If
			End If
		End If
	End Scope
	
	ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderCacheControl) = @DefaultCacheControl
	
	ServerResponse.SendOnlyHeaders OrElse= Not IsFileModified
	If IsFileModified = False Then
		ServerResponse.StatusCode = 304
	End If
End Sub

Function ReadHeadersResult.AllResponseHeadersToBytes( _
		ByVal zBuffer As ZString Ptr, _
		ByVal ContentLength As ULongInt _
	)As Integer
	' TODO Найти способ откатывать изменения буфера заголовков ответа
	
	'ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderServer) = @HttpServerNameString
	
	'If ServerResponse.StatusCode <> 206 Then
	'	ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderAcceptRanges) = @BytesString
	'End If
	
	If ClientRequest.KeepAlive Then
		If ClientRequest.HttpVersion = HttpVersions.Http10 Then
			ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderConnection) = @"Keep-Alive"
		End If
	Else
		ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderConnection) = @CloseString
	End If
	
	Select Case ServerResponse.StatusCode
		
		Case 100, 204
			ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentLength) = 0
			
		Case Else
			Dim strContentLength As WString * (64) = Any
			ui64tow(ContentLength, @strContentLength, 10)
			ServerResponse.AddKnownResponseHeader(HttpResponseHeaders.HeaderContentLength, @strContentLength)
			
	End Select
	
	Scope
		Dim datNowF As FILETIME = Any
		GetSystemTimeAsFileTime(@datNowF)
		
		Dim datNowS As SYSTEMTIME = Any
		FileTimeToSystemTime(@datNowF, @datNowS)
		
		Dim dtBuffer As WString * (32) = Any
		GetHttpDate(@dtBuffer, @datNowS)
		
		ServerResponse.AddKnownResponseHeader(HttpResponseHeaders.HeaderDate, @dtBuffer)
	End Scope
	
	Dim wHeadersBuffer As WString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	
	Dim HeadersAppendBuffer As AppendingBuffer = Type<AppendingBuffer>(@wHeadersBuffer)
	
	Scope
		Dim strStatusCode As WString * 16 = Any
		itow(ServerResponse.StatusCode, @strStatusCode, 10)
		
		HeadersAppendBuffer.AppendWString(@HttpVersion11, HttpVersion11Length)
		
		HeadersAppendBuffer.AppendWChar(SpaceChar)
		
		HeadersAppendBuffer.AppendWString(@strStatusCode, 3)
		
		HeadersAppendBuffer.AppendWChar(SpaceChar)
		
		If ServerResponse.StatusDescription = 0 Then
			Dim BufferLength As Integer = Any
			Dim wBuffer As WString Ptr = GetStatusDescription(ServerResponse.StatusCode, @BufferLength)
			HeadersAppendBuffer.AppendWLine(wBuffer, BufferLength)
		Else
			HeadersAppendBuffer.AppendWLine(ServerResponse.StatusDescription)
		End If
		
	End Scope
	
	For i As Integer = 0 To WebResponse.ResponseHeaderMaximum - 1
		If ServerResponse.ResponseHeaders(i) <> 0 Then
			
			Dim BufferLength As Integer = Any
			Dim wBuffer As WString Ptr = KnownResponseHeaderToString(i, @BufferLength)
			HeadersAppendBuffer.AppendWString(wBuffer, BufferLength)
			HeadersAppendBuffer.AppendWString(@ColonWithSpaceString, 2)
			HeadersAppendBuffer.AppendWLine(ServerResponse.ResponseHeaders(i))
			
		End If
	Next
	
	HeadersAppendBuffer.AppendWLine()
	
	#if __FB_DEBUG__ <> 0
		Print wHeadersBuffer
	#endif
	
	Dim HeadersLength As Integer = WideCharToMultiByte(CP_UTF8, 0, @wHeadersBuffer, -1, zBuffer, WebResponse.MaxResponseHeaderBuffer + 1, 0, 0) - 1
	
	' TODO Запись в лог
	' Dim LogBuffer As ZString * (StreamSocketReader.MaxBufferLength + WebResponse.MaxResponseHeaderBuffer) = Any
	' Dim WriteBytes As DWORD = Any
	' RtlCopyMemory(@LogBuffer, @ClientReader.Buffer, ClientReader.Start)
	' RtlCopyMemory(@LogBuffer + ClientReader.Start, zBuffer, HeadersLength)
	' WriteFile(hOutput, @LogBuffer, ClientReader.Start + HeadersLength, @WriteBytes, 0)
	Return HeadersLength
End Function
