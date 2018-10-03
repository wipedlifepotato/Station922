#include once "ProcessGetHeadRequest.bi"
#include once "HttpConst.bi"
#include once "WriteHttpError.bi"
#include once "Mime.bi"
#include once "WebUtils.bi"
#include once "CharConstants.bi"
#include once "ProcessCgiRequest.bi"
#include once "ProcessDllRequest.bi"
#include once "SafeHandle.bi"
#include "win\Mswsock.bi"
#include once "win\shlwapi.bi"

Const MaxTransmitSize As DWORD = 2147483646 - 1 - 1 * 1024 * 1024

Function Minimum( _
		ByVal a As ULongInt, _
		ByVal b As ULongInt _
	)As ULongInt
	
	If a < b Then
		Return a
	End If
	
	Return b
End Function

Function GetFileBytesStartingIndex( _
		ByVal mt As MimeType Ptr, _
		ByVal hRequestedFile As HANDLE, _
		ByVal hZipFile As HANDLE _
	)As LongInt
	
	If mt->IsTextFormat Then
		Const MaxBytesRead As DWORD = 16 - 1
		Dim FileBytes As ZString * (MaxBytesRead + 1) = Any
		Dim BytesReaded As DWORD = Any
		
		If ReadFile(hRequestedFile, @FileBytes, MaxBytesRead, @BytesReaded, 0) <> 0 Then
			Dim FileBytesStartIndex As LongInt = Any
			
			If hZipFile = INVALID_HANDLE_VALUE Then
				
				If BytesReaded >= 3 Then
					
					mt->Charset = GetDocumentCharset(@FileBytes)
					
					Select Case mt->Charset
						
						Case DocumentCharsets.Utf8BOM
							FileBytesStartIndex = 3
							
						Case DocumentCharsets.Utf16LE
							FileBytesStartIndex = 0
							
						Case DocumentCharsets.Utf16BE
							FileBytesStartIndex = 2
							
						Case Else
							FileBytesStartIndex = 0
							
					End Select
					
				Else
					FileBytesStartIndex = 0
				End If
			Else
				FileBytesStartIndex = 0
				
			End If
			
			Dim liDistanceToMove As LARGE_INTEGER = Any
			liDistanceToMove.QuadPart = FileBytesStartIndex
			SetFilePointerEx(hRequestedFile, liDistanceToMove, NULL, FILE_BEGIN)
			
			Return FileBytesStartIndex
		End If
	End If
	
	Return 0
End Function

Sub AddExtendedHeaders( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal pRequestedFile As RequestedFile Ptr _
	)
	
	' TODO Убрать переполнение буфера при слишком длинных заголовках
	Dim wExtHeadersFile As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(@wExtHeadersFile, pRequestedFile->PathTranslated)
	lstrcat(@wExtHeadersFile, @HeadersExtensionString)
	
	Dim hExtHeadersFile As HANDLE = CreateFile(@wExtHeadersFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, NULL)
	
	If hExtHeadersFile <> INVALID_HANDLE_VALUE Then
		Dim zExtHeaders As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		Dim wExtHeaders As WString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		
		Dim BytesReaded As DWORD = Any
		If ReadFile(hExtHeadersFile, @zExtHeaders, WebResponse.MaxResponseHeaderBuffer, @BytesReaded, 0) <> 0 Then
			
			If BytesReaded > 2 Then
				zExtHeaders[BytesReaded] = 0
				
				If MultiByteToWideChar(CP_UTF8, 0, @zExtHeaders, -1, @wExtHeaders, WebResponse.MaxResponseHeaderBuffer) > 0 Then
					Dim w As WString Ptr = @wExtHeaders
					
					Do
						Dim wName As WString Ptr = w
						Dim wColon As WString Ptr = StrChr(w, ColonChar)
						
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
							pState->ServerResponse.AddResponseHeader(wName, wColon)
						End If
						
					Loop While lstrlen(w) > 0
					
				End If
			End If
		End If
		
		CloseHandle(hExtHeadersFile)
	End If
End Sub

Function ProcessGetHeadRequest( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pRequestedFile As RequestedFile Ptr _
	)As Boolean
	
	If pRequestedFile->FileHandle = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		Dim buf410 As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, pRequestedFile->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		Dim objHFile410 As SafeHandle = Type<SafeHandle>(hFile410)
		If hFile410 = INVALID_HANDLE_VALUE Then
			WriteHttpFileNotFound(pState, pClientReader->pStream, pWebSite)
		Else
			WriteHttpFileGone(pState, pClientReader->pStream, pWebSite)
		End If
		Return False
	End If
	
	' Проверка на CGI
	If NeedCGIProcessing(pState->ClientRequest.ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessCGIRequest(pState, ClientSocket, pWebSite, pClientReader, pRequestedFile)
	End If
	
	' Проверка на dll-cgi
	If NeedDLLProcessing(pState->ClientRequest.ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessDllCgiRequest(pState, ClientSocket, pWebSite, pClientReader, pRequestedFile)
	End If
	
	Dim objRequestedFile As SafeHandle = Type<SafeHandle>(pRequestedFile->FileHandle)
	
	' Проверка запрещённого MIME
	If GetMimeOfFileExtension(@pState->ServerResponse.Mime, PathFindExtension(pRequestedFile->PathTranslated)) = False Then
		WriteHttpForbidden(pState, pClientReader->pStream, pWebSite)
		Return False
	End If
	
	' TODO Проверить идентификацию для запароленных ресурсов
	
	' Заголовки сжатия
	Dim hZipFile As Handle = Any
	Dim IsAcceptEncoding As Boolean = Any
	If @pState->ServerResponse.Mime.IsTextFormat Then
		hZipFile = pState->SetResponseCompression(pRequestedFile->PathTranslated, @IsAcceptEncoding)
	Else
		hZipFile = INVALID_HANDLE_VALUE
		IsAcceptEncoding = False
	End If
	
	Dim objHZipFile As SafeHandle = Type<SafeHandle>(hZipFile)
	
	Dim FileSize As LARGE_INTEGER = Any
	Dim GetFileSizeExResult As Integer = Any
	If hZipFile = INVALID_HANDLE_VALUE Then
		GetFileSizeExResult = GetFileSizeEx(pRequestedFile->FileHandle, @FileSize)
	Else
		GetFileSizeExResult = GetFileSizeEx(hZipFile, @FileSize)
	End If
	
	If GetFileSizeExResult = 0 Then
		' TODO Оработать код ошибки через GetLastError()
		WriteHttpInternalServerError(pState, pClientReader->pStream, pWebSite)
		Return False
	End If
	
	Dim FileBytesStartingIndex As LongInt = GetFileBytesStartingIndex(@pState->ServerResponse.Mime, pRequestedFile->FileHandle, hZipFile)
	
	pState->AddResponseCacheHeaders(pRequestedFile->FileHandle)
	
	AddExtendedHeaders(pState, pRequestedFile)
	
	' В основном анализируются заголовки
	' Accept: text/css, */*
	' Accept-Charset: utf-8
	' Accept-Encoding: gzip, deflate
	' Accept-Language: ru-RU
	' User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36 Edge/15.15063
	' Серверу следует включать в ответ заголовок Vary
	
	' TODO вместо перезаписывания заголовка его нужно добавить
	If IsAcceptEncoding Then
		pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderVary) = @"Accept-Encoding"
	End If
	
	Select Case pState->ServerResponse.ResponseZipMode
		
		Case ZipModes.GZip
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentEncoding) = @GZipString
			
		Case ZipModes.Deflate
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentEncoding) = @DeflateString
			
	End Select
	
	Dim BodyLength As ULongInt = FileSize.QuadPart - FileBytesStartingIndex
	Dim wContentRange As WString * 512 = Any
	
	Select Case pState->ClientRequest.RequestByteRange.IsSet
		Case ByteRangeIsSet.FirstBytePositionIsSet
			' Окончательные 500 байт (байтовые смещения 9500-9999, включительно): bytes=9500-
			If pState->ClientRequest.RequestByteRange.FirstBytePosition <= BodyLength Then
				Dim TotalBodyLength As ULongInt = BodyLength
				
				If pState->ClientRequest.RequestByteRange.FirstBytePosition > 0 Then
					BodyLength -= pState->ClientRequest.RequestByteRange.FirstBytePosition
					
					Dim liDistanceToMove As LARGE_INTEGER = Any
					liDistanceToMove.QuadPart = pState->ClientRequest.RequestByteRange.FirstBytePosition
					If SetFilePointerEx(pRequestedFile->FileHandle, liDistanceToMove, NULL, FILE_CURRENT) = 0 Then
						#if __FB_DEBUG__ <> 0
							Dim dwError As DWORD = GetLastError()
							Print "Ошибка SetFilePointerEx", dwError
						#endif
					End If
				End If
				' Код ответа
				pState->ServerResponse.StatusCode = 206
				' Заголовок
				MakeContentRangeHeader(@wContentRange, pState->ClientRequest.RequestByteRange.FirstBytePosition, TotalBodyLength - 1, TotalBodyLength)
				pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentRange) = @wContentRange
			Else
				' Ошибка в диапазоне?
			End If
			
		Case ByteRangeIsSet.LastBytePositionIsSet
			' Окончательные 500 байт (байтовые смещения 9500-9999, включительно): bytes=-500
			' Только последние байты (9999): bytes=-1
			If pState->ClientRequest.RequestByteRange.LastBytePosition > 0 Then
				Dim TotalBodyLength As ULongInt = BodyLength
				BodyLength = Minimum(pState->ClientRequest.RequestByteRange.LastBytePosition, TotalBodyLength)
				
				If pState->ClientRequest.RequestByteRange.LastBytePosition < TotalBodyLength Then
					Dim liDistanceToMove As LARGE_INTEGER = Any
					liDistanceToMove.QuadPart = -BodyLength
					If SetFilePointerEx(pRequestedFile->FileHandle, liDistanceToMove, NULL, FILE_END) = 0 Then
						#if __FB_DEBUG__ <> 0
							Dim dwError As DWORD = GetLastError()
							Print "Ошибка SetFilePointerEx", dwError
						#endif
					End If
				End If
				' Код ответа
				pState->ServerResponse.StatusCode = 206
				' Заголовок
				MakeContentRangeHeader(@wContentRange, TotalBodyLength - BodyLength, TotalBodyLength - 1, TotalBodyLength)
				pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentRange) = @wContentRange
			Else
				' Ошибка в диапазоне?
			End If
			
		Case ByteRangeIsSet.FirstAndLastPositionIsSet
			' Первые 500 байтов (байтовые смещения 0-499 включительно): bytes=0-499
			' Второй 500 байтов (байтовые смещения 500-999 включительно): bytes=500-999
			If pState->ClientRequest.RequestByteRange.FirstBytePosition <= pState->ClientRequest.RequestByteRange.LastBytePosition Then
				Dim TotalBodyLength As ULongInt = BodyLength
				
				If pState->ClientRequest.RequestByteRange.FirstBytePosition < TotalBodyLength Then
					BodyLength = Minimum(pState->ClientRequest.RequestByteRange.LastBytePosition - pState->ClientRequest.RequestByteRange.FirstBytePosition + 1, BodyLength)
					
					If pState->ClientRequest.RequestByteRange.FirstBytePosition > 0 Then
						Dim liDistanceToMove As LARGE_INTEGER = Any
						liDistanceToMove.QuadPart = pState->ClientRequest.RequestByteRange.FirstBytePosition
						If SetFilePointerEx(pRequestedFile->FileHandle, liDistanceToMove, NULL, FILE_CURRENT) = 0 Then
							#if __FB_DEBUG__ <> 0
								Dim dwError As DWORD = GetLastError()
								Print "Ошибка SetFilePointerEx", dwError
							#endif
						End If
					End If
					
					' Код ответа
					pState->ServerResponse.StatusCode = 206
					' Заголовок
					MakeContentRangeHeader(@wContentRange, pState->ClientRequest.RequestByteRange.FirstBytePosition, pState->ClientRequest.RequestByteRange.FirstBytePosition + BodyLength - 1, TotalBodyLength)
					pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentRange) = @wContentRange
				Else
					' Ошибка в диапазоне?
				End If
			Else
				' Ошибка в диапазоне?
			End If
			
	End Select
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	Dim HeadersLength As Integer = pState->AllResponseHeadersToBytes(@SendBuffer, BodyLength)
	
	Dim TransmitHeader As TRANSMIT_FILE_BUFFERS = Any
	With TransmitHeader
		.Head = @SendBuffer
		.HeadLength = Cast(DWORD, HeadersLength)
		.Tail = NULL
		.TailLength = Cast(DWORD, 0)
	End With
	
	Dim hTransmitFile As HANDLE = Any
	If pState->ServerResponse.SendOnlyHeaders Then
		hTransmitFile = NULL
	Else
		If hZipFile <> INVALID_HANDLE_VALUE Then
			hTransmitFile = hZipFile
		Else
			hTransmitFile = pRequestedFile->FileHandle
		End If
	End If
	
	If TransmitFile(ClientSocket, hTransmitFile, Cast(DWORD, Minimum(MaxTransmitSize, BodyLength)), 0, NULL, @TransmitHeader, 0) = 0 Then
		#if __FB_DEBUG__ <> 0
			Dim intError As Integer = WSAGetLastError()
			Print "Ошибка отправки файла", intError
		#endif
		Return False
	End If
	
	If hTransmitFile <> NULL Then
		
		Dim i As ULongInt = 1
		
		Do While BodyLength > Cast(ULongInt, MaxTransmitSize)
			BodyLength -= Cast(ULongInt, MaxTransmitSize)
			
			Dim NewPointer As LARGE_INTEGER = Any
			NewPointer.QuadPart = i * Cast(LongInt, MaxTransmitSize)
			SetFilePointerEx(hTransmitFile, NewPointer, NULL, FILE_BEGIN)
			
			If BodyLength <> 0 Then
				If TransmitFile(ClientSocket, hTransmitFile, Cast(DWORD, Minimum(MaxTransmitSize, BodyLength)), 0, NULL, NULL, 0) = 0 Then
					#if __FB_DEBUG__ <> 0
						Dim intError As Integer = WSAGetLastError()
						Print "Ошибка отправки файла", intError
					#endif
					Return False
				End If
			End If
			
			i += 1
		Loop
		
	End If
	
	Return True
End Function
