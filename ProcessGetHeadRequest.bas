#include once "ProcessGetHeadRequest.bi"
#include once "HttpConst.bi"
#include once "WriteHttpError.bi"
#include once "Mime.bi"
#include once "WebUtils.bi"
#include once "CharConstants.bi"
#include once "ProcessCgiRequest.bi"
#include once "ProcessDllRequest.bi"

Type SafeHandle
	Declare Constructor(ByVal hFile As HANDLE)
	Declare Destructor()
	Dim FileHandle As HANDLE
End Type

Type SafeMemoryMap
	Declare Constructor(ByVal pMemoryMap As Any Ptr)
	Declare Destructor()
	Dim MemoryMapPointer As Any Ptr
End Type

Constructor SafeHandle(ByVal hFile As HANDLE)
	#if __FB_DEBUG__ <> 0
		Print "Захватываю описатель файла hFile"
	#endif
	FileHandle = hFile
End Constructor

Destructor SafeHandle()
	#if __FB_DEBUG__ <> 0
		Print "Закрываю файл hFile"
	#endif
	If FileHandle <> INVALID_HANDLE_VALUE Then
		CloseHandle(FileHandle)
	End If
End Destructor

Constructor SafeMemoryMap(ByVal pMemoryMap As Any Ptr)
	#if __FB_DEBUG__ <> 0
		Print "Захватываю указатель на данные отображения hFileMap"
	#endif
	MemoryMapPointer = pMemoryMap
End Constructor

Destructor SafeMemoryMap()
	#if __FB_DEBUG__ <> 0
		Print "Выгружаю отображение из памяти hFileMap"
	#endif
	If MemoryMapPointer <> 0 Then
		UnmapViewOfFile(MemoryMapPointer)
	End If
End Destructor

Function ProcessGetHeadRequest( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr, _
		ByVal fileExtention As WString Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal hOutput As Handle, _
		ByVal hRequestedFile As Handle _
	)As Boolean
	
	Dim objRequestedFile As SafeHandle = Type<SafeHandle>(hRequestedFile)
	
	If hRequestedFile = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		' Файла не существет, записать ошибку клиенту
		Dim buf410 As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, @pWebSite->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		Dim objHFile410 As SafeHandle = Type<SafeHandle>(hFile410)
		If hFile410 = INVALID_HANDLE_VALUE Then
			' Файлы не существует, но она может появиться позже
			pState->ServerResponse.StatusCode = 404
			WriteHttpError(pState, ClientSocket, HttpErrors.HttpError404FileNotFound, pWebSite->VirtualPath, hOutput)
		Else
			' Файла раньше существовала, но теперь удалена навсегда
			pState->ServerResponse.StatusCode = 410
			WriteHttpError(pState, ClientSocket, HttpErrors.HttpError410Gone, pWebSite->VirtualPath, hOutput)
		End If
		Return False
	End If
	
	' Проверка на CGI
	If NeedCGIProcessing(pState->ClientRequest.ClientUri.Path) Then
		Return ProcessCGIRequest(pState, ClientSocket, pWebSite, fileExtention, pClientReader, hOutput)
	End If
	
	' Проверка на dll-cgi
	If NeedDLLProcessing(pState->ClientRequest.ClientUri.Path) Then
		Return ProcessDllCgiRequest(pState, ClientSocket, pWebSite, fileExtention, hOutput)
	End If
	
	' Не обрабатываем файлы с неизвестным типом
	Dim mt As MimeType = Any
	If GetMimeOfFileExtension(@mt, fileExtention) = False Then
		pState->ServerResponse.StatusCode = 403
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError403File, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	' TODO Проверить идентификацию для запароленных ресурсов
	
	' Заголовки сжатия
	Dim hZipFile As Handle = Any
	If mt.IsTextFormat Then
		hZipFile = pState->SetResponseCompression(@pWebSite->PathTranslated)
	Else
		hZipFile = INVALID_HANDLE_VALUE
	End If
	Dim objHZipFile As SafeHandle = Type<SafeHandle>(hZipFile)
	
	' Нельзя отображать файлы нулевого размера
	Dim FileSize As LARGE_INTEGER = Any
	Dim GetFileSizeExResult As Integer = Any
	If hZipFile = INVALID_HANDLE_VALUE Then
		GetFileSizeExResult = GetFileSizeEx(hRequestedFile, @FileSize)
	Else
		GetFileSizeExResult = GetFileSizeEx(hZipFile, @FileSize)
	End If
	
	If GetFileSizeExResult = 0 Then
		' TODO узнать причину неудачи через GetLastError() = ERROR_ALREADY_EXISTS
		pState->ServerResponse.StatusCode = 500
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError500NotAvailable, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	' Строка с типом документа
	Dim wContentType As WString * (2 * MaxContentTypeLength + 1) = Any
	lstrcpy(@wContentType, ContentTypeToString(mt.ContentType))
	
	If FileSize.QuadPart = 0 Then
		' Создать заголовки ответа и отправить клиенту
		pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
		pState->AddResponseCacheHeaders(hRequestedFile)
		Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		Dim SendResult As Integer = send(ClientSocket, @SendBuffer, pState->AllResponseHeadersToBytes(@SendBuffer, 0, hOutput), 0)
		If SendResult = SOCKET_ERROR Then
			Return False
		End If
		Return True
	End If
	
	' Отобразить файл
	Dim hFileMap As Handle = Any
	If hZipFile = INVALID_HANDLE_VALUE Then
		hFileMap = CreateFileMapping(hRequestedFile, 0, PAGE_READONLY, 0, 0, 0)
	Else
		hFileMap = CreateFileMapping(hZipFile, 0, PAGE_READONLY, 0, 0, 0)
	End If
	Dim objHFileMap As SafeHandle = Type<SafeHandle>(hFileMap)
	If hFileMap = 0 Then
		' TODO узнать причину неудачи через GetLastError() = ERROR_ALREADY_EXISTS
		' Чтение файла завершилось неудачей
		pState->ServerResponse.StatusCode = 500
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError500NotAvailable, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	' Всё хорошо
	' Создать представление файла
	Dim pFileBytes As UByte Ptr = CPtr(UByte Ptr, MapViewOfFile(hFileMap, FILE_MAP_READ, 0, 0, 0))
	Dim objFileBytes As SafeMemoryMap = Type<SafeMemoryMap>(pFileBytes)
	If pFileBytes = 0 Then
		' Чтение файла завершилось неудачей
		' TODO Узнать код ошибки и отправить его клиенту
		pState->ServerResponse.StatusCode = 500
		WriteHttpError(pState, ClientSocket, HttpErrors.HttpError500NotAvailable, @pWebSite->VirtualPath, hOutput)
		Return False
	End If
	
	' HTTP/1.1 206 Partial Content
	' Обратите внимание на заголовок Content-Length — в нём указывается размер тела сообщения,
	' то есть передаваемого фрагмента. Если сервер вернёт несколько фрагментов,
	' то Content-Length будет содержать их суммарный объём.
	' Content-Range: bytes 471104-2355520/2355521
	' pState->ResponseHeaders(HttpResponseHeaderIndices.HeaderContentRange) = "bytes 471104-2355520/2355521"
	
	Dim FileBytesStartIndex As Integer = Any
	If mt.IsTextFormat Then
		If hZipFile = INVALID_HANDLE_VALUE Then
			' pFileBytes указывает на настоящий файл
			If FileSize.QuadPart > 3 Then
				Select Case GetDocumentCharset(pFileBytes)
					Case DocumentCharsets.ASCII
						' Ничего
						FileBytesStartIndex = 0
					Case DocumentCharsets.Utf8BOM
						lstrcat(@wContentType, @ContentCharsetUtf8)
						FileBytesStartIndex = 3
					Case DocumentCharsets.Utf16LE
						lstrcat(wContentType, @ContentCharsetUtf16)
						FileBytesStartIndex = 0
					Case DocumentCharsets.Utf16BE
						lstrcat(wContentType, @ContentCharsetUtf16)
						FileBytesStartIndex = 2
				End Select
			Else
				' Кодировка ASCII
				FileBytesStartIndex = 0
			End If
		Else
			' pFileBytes указывает на сжатый файл
			FileBytesStartIndex = 0
			Dim b2 As ZString * 4 = Any
			Dim BytesCount As DWORD = Any
			If ReadFile(hRequestedFile, @b2, 3, @BytesCount, 0) <> 0 Then
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
		FileBytesStartIndex = 0
	End If
	
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentType) = @wContentType
	pState->AddResponseCacheHeaders(hRequestedFile)
	
	' Добавить пользовательские заголовки ответа
	' TODO Может быть переполнение буфера при слишком длинных заголовках ответа
	Dim sExtHeadersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(@sExtHeadersFile, @pWebSite->PathTranslated)
	lstrcat(@sExtHeadersFile, @HeadersExtensionString)
	Dim hExtHeadersFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	Dim objHFileExtHeaders As SafeHandle = Type<SafeHandle>(hExtHeadersFile)
	If hExtHeadersFile <> INVALID_HANDLE_VALUE Then
		Dim zExtHeaders As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		Dim wExtHeaders As WString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
		
		Dim ReadedBytesCount As DWORD = Any
		If ReadFile(hExtHeadersFile, @zExtHeaders, WebResponse.MaxResponseHeaderBuffer, @ReadedBytesCount, 0) <> 0 Then
			If ReadedBytesCount > 2 Then
				zExtHeaders[ReadedBytesCount] = 0
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
							pState->ServerResponse.AddResponseHeader(wName, wColon)
						End If
					Loop While lstrlen(w) > 0
				End If
			End If
		End If
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
	Select Case pState->ServerResponse.ResponseZipMode
		
		Case ZipModes.GZip
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @GZipString
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @"Accept-Encoding"
			
		Case ZipModes.Deflate
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderContentEncoding) = @DeflateString
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = @"Accept-Encoding"
			
		Case Else
			pState->ServerResponse.ResponseHeaders(HttpResponseHeaderIndices.HeaderVary) = 0
			
	End Select
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	Dim BodyLength As Integer = FileSize.QuadPart - FileBytesStartIndex
	Dim HeadersLength As Integer = pState->AllResponseHeadersToBytes(@SendBuffer, BodyLength, hOutput)
	
	If HeadersLength + BodyLength < WebResponse.MaxResponseHeaderBuffer Then
		' Заголовки и тело в одном ответе
		
		#if __FB_DEBUG__ <> 0
			Print "Заголовки и тело в одном ответе"
		#endif
		
		If pState->ServerResponse.SendOnlyHeaders = False Then
			memcpy	(@SendBuffer + HeadersLength, pFileBytes + FileBytesStartIndex, BodyLength)
		End If
		If send(ClientSocket, @SendBuffer, HeadersLength + BodyLength, 0) = SOCKET_ERROR Then
			Return False
		End If
	Else
		' Заголовки и тело в двух ответах
		If send(ClientSocket, @SendBuffer, HeadersLength, 0) = SOCKET_ERROR Then
			Return False
		End If
		
		If pState->ServerResponse.SendOnlyHeaders = False Then
			If send(ClientSocket, pFileBytes + FileBytesStartIndex, BodyLength, 0) = SOCKET_ERROR Then
				Return False
			End If
		End If
	End If
	
	Return True
End Function
