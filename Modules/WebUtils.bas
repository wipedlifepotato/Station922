#include "WebUtils.bi"
#include "HttpConst.bi"
#include "URI.bi"
#include "IntegerToWString.bi"
#include "CharacterConstants.bi"
#include "WriteHttpError.bi"
#include "win\shlwapi.bi"
#include "win\wincrypt.bi"
#include "ConsoleColors.bi"
#include "StringConstants.bi"
#include "IniConst.bi"
#include "ArrayStringWriter.bi"

Const DateFormatString = "ddd, dd MMM yyyy "
Const TimeFormatString = "HH:mm:ss GMT"
Const ColonWithSpaceString = ": "
Const DefaultCacheControl = "max-age=2678400"

Function GetHtmlSafeString( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal HtmlSafe As WString Ptr, _
		ByVal pHtmlSafeLength As Integer Ptr _
	)As Boolean
	
	Const MaxQuotationMarkSafeStringLength As Integer = 6
	Const MaxAmpersandSafeStringLength As Integer = 5
	Const MaxApostropheSafeStringLength As Integer = 6
	Const MaxLessThanSignSafeStringLength As Integer = 4
	Const MaxGreaterThanSignSafeStringLength As Integer = 4
	
	Dim SafeLength As Integer = Any
	
	' Посчитать размер буфера
	Scope
		
		Dim cbNeedenBufferLength As Integer = 0
		
		Dim i As Integer = 0
		Do While HtmlSafe[i] <> 0
			Dim Number As Integer = HtmlSafe[i]
			
			Select Case Number
				
				Case Characters.QuotationMark
					cbNeedenBufferLength += MaxQuotationMarkSafeStringLength
					
				Case Characters.Ampersand
					cbNeedenBufferLength += MaxAmpersandSafeStringLength
					
				Case Characters.Apostrophe
					cbNeedenBufferLength += MaxApostropheSafeStringLength
					
				Case Characters.LessThanSign
					cbNeedenBufferLength += MaxLessThanSignSafeStringLength
					
				Case Characters.GreaterThanSign
					cbNeedenBufferLength += MaxGreaterThanSignSafeStringLength
					
				Case Else
					cbNeedenBufferLength += 1
					
			End Select
			
			i += 1
		Loop
		SafeLength = i
		
		*pHtmlSafeLength = cbNeedenBufferLength
		
		If Buffer = 0 Then
			SetLastError(ERROR_SUCCESS)
			Return True
		End If
		
		If BufferLength < cbNeedenBufferLength Then
			SetLastError(ERROR_INSUFFICIENT_BUFFER)
			Return False
		End If
	End Scope
	
	Scope
		
		Dim BufferIndex As Integer = 0
		
		For OriginalIndex As Integer = 0 To SafeLength - 1
			Dim Number As Integer = HtmlSafe[OriginalIndex]
			
			Select Case Number
				Case Is < 32
					
				Case Characters.QuotationMark
					' Заменить на &quot;
					Buffer[BufferIndex + 0] = Characters.Ampersand
					Buffer[BufferIndex + 1] = &h71  ' q
					Buffer[BufferIndex + 2] = &h75  ' u
					Buffer[BufferIndex + 3] = &h6f  ' o
					Buffer[BufferIndex + 4] = &h74  ' t
					Buffer[BufferIndex + 5] = Characters.Semicolon
					BufferIndex += MaxQuotationMarkSafeStringLength
					
				Case Characters.Ampersand
					' Заменить на &amp;
					Buffer[BufferIndex + 0] = Characters.Ampersand
					Buffer[BufferIndex + 1] = &h61  ' a
					Buffer[BufferIndex + 2] = &h6d  ' m
					Buffer[BufferIndex + 3] = &h70  ' p
					Buffer[BufferIndex + 4] = Characters.Semicolon
					BufferIndex += MaxAmpersandSafeStringLength
					
				Case Characters.Apostrophe
					' Заменить на &apos;
					Buffer[BufferIndex + 0] = Characters.Ampersand
					Buffer[BufferIndex + 1] = &h61  ' a
					Buffer[BufferIndex + 2] = &h70  ' p
					Buffer[BufferIndex + 3] = &h6f  ' o
					Buffer[BufferIndex + 4] = &h73  ' s
					Buffer[BufferIndex + 5] = Characters.Semicolon
					BufferIndex += MaxApostropheSafeStringLength
					
				Case Characters.LessThanSign
					' Заменить на &lt;
					Buffer[BufferIndex + 0] = Characters.Ampersand
					Buffer[BufferIndex + 1] = &h6c  ' l
					Buffer[BufferIndex + 2] = &h74  ' t
					Buffer[BufferIndex + 3] = Characters.Semicolon
					BufferIndex += MaxLessThanSignSafeStringLength
					
				Case Characters.GreaterThanSign
					' Заменить на &gt;
					Buffer[BufferIndex + 0] = Characters.Ampersand
					Buffer[BufferIndex + 1] = &h67  ' g
					Buffer[BufferIndex + 2] = &h74  ' t
					Buffer[BufferIndex + 3] = Characters.Semicolon
					BufferIndex += MaxGreaterThanSignSafeStringLength
					
				Case Else
					Buffer[BufferIndex] = Number
					BufferIndex += 1
					
			End Select
			
		Next
		
		' Завершающий нулевой символ
		Buffer[BufferIndex] = 0
		SetLastError(ERROR_SUCCESS)
		Return True
	End Scope
End Function

Function GetDocumentCharset( _
		ByVal bytes As ZString Ptr _
	)As DocumentCharsets
	
	If bytes[0] = 239 AndAlso bytes[1] = 187 AndAlso bytes[2] = 191 Then
		Return DocumentCharsets.Utf8BOM
	End If
	
	If bytes[0] = 255 AndAlso bytes[1] = 254 Then
		Return DocumentCharsets.Utf16LE
	End If
	
	If bytes[0] = 254 AndAlso bytes[1] = 255 Then
		Return DocumentCharsets.Utf16BE
	End If
	
	Return DocumentCharsets.ASCII
End Function

Sub GetHttpDate( _
		ByVal Buffer As WString Ptr, _
		ByVal dt As SYSTEMTIME Ptr _
	)
	' Tue, 15 Nov 1994 12:45:26 GMT
	Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, dt, @DateFormatString, Buffer, 31) - 1
	GetTimeFormat(LOCALE_INVARIANT, 0, dt, @TimeFormatString, @Buffer[dtBufferLength], 31 - dtBufferLength)
End Sub

Sub GetHttpDate(ByVal Buffer As WString Ptr)
	Dim dt As SYSTEMTIME = Any
	GetSystemTime(@dt)
	GetHttpDate(Buffer, @dt)
End Sub

Function FindCrLfA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal Start As Integer, _
		ByVal pFindedIndex As Integer Ptr _
	)As Boolean
	' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
	For i As Integer = Start To BufferLength - 2
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			*pFindedIndex = i
			Return True
		End If
	Next
	*pFindedIndex = 0
	Return False
End Function

Function FindCrLfW( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal Start As Integer, _
		ByVal pFindedIndex As Integer Ptr _
	)As Boolean
	' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
	For i As Integer = Start To BufferLength - 2
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			*pFindedIndex = i
			Return True
		End If
	Next
	*pFindedIndex = 0
	Return False
End Function

Function HttpAuthUtil( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal pStream As IBaseStream Ptr, _
		ByVal www As SimpleWebSite Ptr,  _
		ByVal ProxyAuthorization As Boolean _
	)As Boolean
	
	Dim HeaderAuthorization As WString Ptr = Any
	If ProxyAuthorization Then
		If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderProxyAuthorization)) = 0 Then
			HeaderAuthorization = pRequest->RequestHeaders(HttpRequestHeaders.HeaderAuthorization)
		Else
			HeaderAuthorization = pRequest->RequestHeaders(HttpRequestHeaders.HeaderProxyAuthorization)
		End If
	Else
		HeaderAuthorization = pRequest->RequestHeaders(HttpRequestHeaders.HeaderAuthorization)
	End If
	
	If lstrlen(HeaderAuthorization) = 0 Then
		WriteHttpNeedAuthenticate(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	Dim pSpace As WString Ptr = StrChr(HeaderAuthorization, Characters.WhiteSpace)
	If pSpace = 0 Then
		WriteHttpBadAuthenticateParam(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	pSpace[0] = 0
	If lstrcmp(HeaderAuthorization, @BasicAuthorization) <> 0 Then
		WriteHttpNeedBasicAuthenticate(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	Dim UsernamePasswordUtf8 As ZString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	Dim dwUsernamePasswordUtf8Length As DWORD = WebRequest.MaxRequestHeaderBuffer
	
	CryptStringToBinary(pSpace + 1, 0, CRYPT_STRING_BASE64, @UsernamePasswordUtf8, @dwUsernamePasswordUtf8Length, 0, 0)
	
	UsernamePasswordUtf8[dwUsernamePasswordUtf8Length] = 0
	
	' Из массива байт в строку
	' Преобразуем utf8 в WString
	' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
	Dim UsernamePassword As WString * (WebRequest.MaxRequestHeaderBuffer + 1) = Any
	MultiByteToWideChar(CP_UTF8, 0, @UsernamePasswordUtf8, -1, @UsernamePassword, WebRequest.MaxRequestHeaderBuffer)
	
	' Теперь pSpace хранит в себе указатель на разделитель‐двоеточие
	pSpace = StrChr(@UsernamePassword, Characters.Colon)
	If pSpace = 0 Then
		WriteHttpEmptyPassword(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	pSpace[0] = 0 ' Убрали двоеточие
	Dim SettingsFileName As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
	www->MapPath(@SettingsFileName, @UsersIniFileString)
	
	Dim PasswordBuffer As WString * (255 + 1) = Any
	GetPrivateProfileString(@AdministratorsSectionString, @UsernamePassword, @EmptyString, @PasswordBuffer, 255, @SettingsFileName)
	
	If lstrlen(@PasswordBuffer) = 0 Then
		WriteHttpBadUserNamePassword(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	If lstrcmp(@PasswordBuffer, pSpace + 1) <> 0 Then
		WriteHttpBadUserNamePassword(pRequest, pResponse, pStream, www)
		Return False
	End If
	
	Return True
End Function

Sub GetETag( _
		ByVal wETag As WString Ptr, _
		ByVal pDateLastFileModified As FILETIME Ptr, _
		ByVal ResponseZipMode As ZipModes _
	)
	
	lstrcpy(wETag, @QuoteString)
	
	Dim ul As ULARGE_INTEGER = Any
	With ul
		.LowPart = pDateLastFileModified->dwLowDateTime
		.HighPart = pDateLastFileModified->dwHighDateTime
	End With
	
	ui64tow(ul.QuadPart, wETag[1], 10)
	
	Select Case ResponseZipMode
		Case ZipModes.GZip
			lstrcat(wETag, @GzipString)
			
		Case ZipModes.Deflate
			lstrcat(wETag, @DeflateString)
			
	End Select
	
	lstrcat(wETag, @QuoteString)
End Sub

Sub MakeContentRangeHeader( _
		ByVal pIWriter As ITextWriter Ptr, _
		ByVal FirstBytePosition As ULongInt, _
		ByVal LastBytePosition As ULongInt, _
		ByVal TotalLength As ULongInt _
	)
	
	'Content-Range: bytes 88080384-160993791/160993792
	
	pIWriter->pVirtualTable->WriteLengthString(pIWriter, "bytes ", 6)
	
	pIWriter->pVirtualTable->WriteUInt64(pIWriter, FirstBytePosition)
	pIWriter->pVirtualTable->WriteChar(pIWriter, Characters.HyphenMinus)
	
	pIWriter->pVirtualTable->WriteUInt64(pIWriter, LastBytePosition)
	pIWriter->pVirtualTable->WriteChar(pIWriter, Characters.Solidus)
	
	pIWriter->pVirtualTable->WriteUInt64(pIWriter, TotalLength)
End Sub

Function Minimum( _
		ByVal a As ULongInt, _
		ByVal b As ULongInt _
	)As ULongInt
	
	If a < b Then
		Return a
	End If
	
	Return b
End Function

Function AllResponseHeadersToBytes( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal zBuffer As ZString Ptr, _
		ByVal ContentLength As ULongInt _
	)As Integer
	' TODO Найти способ откатывать изменения буфера заголовков ответа
	
	'pResponse->ResponseHeaders(HttpResponseHeaders.HeaderServer) = @HttpServerNameString
	
	If pResponse->StatusCode <> 206 Then
		pResponse->ResponseHeaders(HttpResponseHeaders.HeaderAcceptRanges) = @BytesString
	End If
	
	If pRequest->KeepAlive Then
		If pRequest->HttpVersion = HttpVersions.Http10 Then
			pResponse->ResponseHeaders(HttpResponseHeaders.HeaderConnection) = @"Keep-Alive"
		End If
	Else
		pResponse->ResponseHeaders(HttpResponseHeaders.HeaderConnection) = @CloseString
	End If
	
	Select Case pResponse->StatusCode
		
		Case 100, 204
			pResponse->ResponseHeaders(HttpResponseHeaders.HeaderContentLength) = 0
			
		Case Else
			Dim strContentLength As WString * (64) = Any
			ui64tow(ContentLength, @strContentLength, 10)
			pResponse->AddKnownResponseHeader(HttpResponseHeaders.HeaderContentLength, @strContentLength)
			
	End Select
	
	Dim wContentType As WString * (MaxContentTypeLength + 1) = Any
	
	If pResponse->Mime.ContentType <> ContentTypes.Unknown Then
		GetContentTypeOfMimeType(@wContentType, @pResponse->Mime)
		pResponse->ResponseHeaders(HttpResponseHeaders.HeaderContentType) = @wContentType
	End If
	
	Scope
		Dim datNowF As FILETIME = Any
		GetSystemTimeAsFileTime(@datNowF)
		
		Dim datNowS As SYSTEMTIME = Any
		FileTimeToSystemTime(@datNowF, @datNowS)
		
		Dim dtBuffer As WString * (32) = Any
		GetHttpDate(@dtBuffer, @datNowS)
		
		pResponse->AddKnownResponseHeader(HttpResponseHeaders.HeaderDate, @dtBuffer)
	End Scope
	
	Dim HeadersWriter As ArrayStringWriter = Any
	
	Dim pIWriter As ITextWriter Ptr = CPtr(ITextWriter Ptr, New(@HeadersWriter) ArrayStringWriter())
	
	pIWriter->pVirtualTable->WriteLengthString(pIWriter, @HttpVersion11, HttpVersion11Length)
	pIWriter->pVirtualTable->WriteChar(pIWriter, Characters.WhiteSpace)
	pIWriter->pVirtualTable->WriteInt32(pIWriter, pResponse->StatusCode)
	pIWriter->pVirtualTable->WriteChar(pIWriter, Characters.WhiteSpace)
	
	If pResponse->StatusDescription = 0 Then
		Dim BufferLength As Integer = Any
		Dim wBuffer As WString Ptr = GetStatusDescription(pResponse->StatusCode, @BufferLength)
		pIWriter->pVirtualTable->WriteLengthStringLine(pIWriter, wBuffer, BufferLength)
	Else
		pIWriter->pVirtualTable->WriteStringLine(pIWriter, pResponse->StatusDescription)
	End If
	
	For i As Integer = 0 To WebResponse.ResponseHeaderMaximum - 1
		
		If pResponse->ResponseHeaders(i) <> 0 Then
			
			Dim BufferLength As Integer = Any
			Dim wBuffer As WString Ptr = KnownResponseHeaderToString(i, @BufferLength)
			
			pIWriter->pVirtualTable->WriteLengthString(pIWriter, wBuffer, BufferLength)
			pIWriter->pVirtualTable->WriteLengthString(pIWriter, @ColonWithSpaceString, 2)
			pIWriter->pVirtualTable->WriteStringLine(pIWriter, pResponse->ResponseHeaders(i))
		End If
	Next
	
	pIWriter->pVirtualTable->WriteNewLine(pIWriter)
	
	Dim pIToString As IStringable Ptr = Any
	pIWriter->pVirtualTable->InheritedTable.QueryInterface(pIWriter, @IID_ISTRINGABLE, @pIToString)
	
	Dim wHeadersBuffer As WString Ptr = Any
	pIToString->pVirtualTable->ToString(pIToString, @wHeadersBuffer)
	
	#if __FB_DEBUG__ <> 0
		Color ConsoleColors.Red
		Print *wHeadersBuffer
	#endif
	
	Dim HeadersLength As Integer = WideCharToMultiByte( _
		CP_UTF8, _
		0, _
		wHeadersBuffer, _
		-1, _
		zBuffer, _
		WebResponse.MaxResponseHeaderBuffer + 1, _
		0, _
		0 _
	) - 1
	
	pIToString->pVirtualTable->InheritedTable.Release(pIToString)
	
	' TODO Запись в лог
	' Dim LogBuffer As ZString * (StreamSocketReader.MaxBufferLength + WebResponse.MaxResponseHeaderBuffer) = Any
	' Dim WriteBytes As DWORD = Any
	' RtlCopyMemory(@LogBuffer, @ClientReader.Buffer, ClientReader.Start)
	' RtlCopyMemory(@LogBuffer + ClientReader.Start, zBuffer, HeadersLength)
	' WriteFile(hOutput, @LogBuffer, ClientReader.Start + HeadersLength, @WriteBytes, 0)
	Return HeadersLength
End Function

Function SetResponseCompression( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal PathTranslated As WString Ptr, _
		ByVal pAcceptEncoding As Boolean Ptr _
	)As Handle
	
	Const GzipExtensionString = ".gz"
	Const DeflateExtensionString = ".deflate"
	
	*pAcceptEncoding = False
	
	Scope
		Dim GZipFileName As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@GZipFileName, PathTranslated)
		lstrcat(@GZipFileName, @GZipExtensionString)
		
		Dim hFile As HANDLE = CreateFile( _
			@GZipFileName, _
			GENERIC_READ, _
			FILE_SHARE_READ, _
			NULL, _
			OPEN_EXISTING, _
			FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, _
			NULL _
		)
		
		If hFile <> INVALID_HANDLE_VALUE Then
			*pAcceptEncoding = True
			
			If pRequest->RequestZipModes(WebRequest.GZipIndex) Then
				pResponse->ResponseZipMode = ZipModes.GZip
				Return hFile
			End If
			
			CloseHandle(hFile)
		End If
	End Scope
	
	Scope
		Dim DeflateFileName As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@DeflateFileName, PathTranslated)
		lstrcat(@DeflateFileName, @DeflateExtensionString)
		
		Dim hFile As HANDLE = CreateFile( _
			@DeflateFileName, _
			GENERIC_READ, _
			FILE_SHARE_READ, _
			NULL, _
			OPEN_EXISTING, _
			FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, _
			NULL _
		)
		
		If hFile <> INVALID_HANDLE_VALUE Then
			*pAcceptEncoding = True
		
			If pRequest->RequestZipModes(WebRequest.DeflateIndex) Then
				pResponse->ResponseZipMode = ZipModes.Deflate
				Return hFile
			End If
			
			CloseHandle(hFile)
		End If
	End Scope
	
	Return INVALID_HANDLE_VALUE
End Function

Sub AddResponseCacheHeaders( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal hFile As HANDLE _
	)
	Dim IsFileModified As Boolean = True
	
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
		
		pResponse->AddKnownResponseHeader(HttpResponseHeaders.HeaderLastModified, @strFileLastModifiedHttpDate)
		
		If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince)) <> 0 Then
			
			Dim wSeparator As WString Ptr = StrChr(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince), Characters.Semicolon)
			If wSeparator <> 0 Then
				wSeparator[0] = 0
			End If
			
			If lstrcmpi(@strFileLastModifiedHttpDate, pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfModifiedSince)) = 0 Then
				IsFileModified = False
			End If
		End If
		
		If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfUnModifiedSince)) <> 0 Then
			
			Dim wSeparator As WString Ptr = StrChr(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfUnModifiedSince), Characters.Semicolon)
			If wSeparator <> 0 Then
				wSeparator[0] = 0
			End If
			
			If lstrcmpi(@strFileLastModifiedHttpDate, pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfUnModifiedSince)) = 0 Then
				IsFileModified = True
			End If
		End If
	End Scope
	
	Scope
		Dim strETag As WString * 256 = Any
		GetETag(@strETag, @DateLastFileModified, pResponse->ResponseZipMode)
		
		pResponse->AddKnownResponseHeader(HttpResponseHeaders.HeaderEtag, @strETag)
		
		If IsFileModified Then
			If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfNoneMatch)) <> 0 Then
				If lstrcmpi(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfNoneMatch), @strETag) = 0 Then
					IsFileModified = False
				End If
			End If
		End If
		
		If IsFileModified = False Then
			If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfMatch)) <> 0 Then
				If lstrcmpi(pRequest->RequestHeaders(HttpRequestHeaders.HeaderIfMatch), @strETag) = 0 Then
					IsFileModified = True
				End If
			End If
		End If
	End Scope
	
	pResponse->ResponseHeaders(HttpResponseHeaders.HeaderCacheControl) = @DefaultCacheControl
	
	pResponse->SendOnlyHeaders OrElse= Not IsFileModified
	If IsFileModified = False Then
		pResponse->StatusCode = 304
	End If
End Sub
