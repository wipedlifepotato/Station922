#include once "WebServer.bi"
#include once "Extensions.bi"

Sub SendFileToClient(ByVal ClientSocket As SOCKET, ByVal hFile As Handle, ByVal hZipFile As Handle, ByVal b As UByte Ptr, ByVal state As ReadHeadersResult Ptr, ByVal IsTextFormat As Boolean, ByVal FileSize As LARGE_INTEGER, ByVal wContentType As WString Ptr, ByVal hOutput As Handle)
	
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
	If IsTextFormat Then
		If hZipFile = INVALID_HANDLE_VALUE Then
			' b указывает на настоящий файл
			If FileSize.QuadPart > 3 Then
				Select Case GetDocumentCharset(b)
					Case DocumentCharsets.ASCII
						' Ничего
						Index = 0
					Case DocumentCharsets.Utf8BOM
						lstrcat(wContentType, @ContentCharsetUtf8)
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
			Dim BytesCount As Integer = Any
			ReadFile(hFile, @b2, 3, @BytesCount, 0)
			If BytesCount >=3 Then
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
			REM Else
				REM ' Кодировка ASCII
			End If
		End If
	Else
		Index = 0
	End If
	
	' Отправить дополнительные заголовки ответа
	Dim sExtHeadersFile As WString * (ReadHeadersResult.MaxFilePathTranslatedLength + 1) = Any
	lstrcpy(@sExtHeadersFile, @state->PathTranslated)
	lstrcat(@sExtHeadersFile, @HeadersExtensionString)
	Dim hExtHeadersFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hExtHeadersFile <> INVALID_HANDLE_VALUE Then
		Dim zExtHeaders As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
		Dim wExtHeaders As WString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
		
		Dim BytesCount As Integer = Any
		If ReadFile(hExtHeadersFile, @zExtHeaders, ReadHeadersResult.MaxResponseHeaderBuffer, @BytesCount, 0) <> 0 Then
			If BytesCount > 2 Then
				zExtHeaders[BytesCount] = 0
				If MultiByteToWideChar(CP_UTF8, 0, @zExtHeaders, -1, @wExtHeaders, ReadHeadersResult.MaxResponseHeaderBuffer) > 0 Then
					Dim w As WString Ptr = @wExtHeaders
					Do
						Dim wName As WString Ptr = w
						' Найти двоеточие
						Dim wColon As WString Ptr = StrStr(w, @ColonString)
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
	End If
	
	' Создать и отправить заголовки ответа
	Dim SendBuffer As ZString * (ReadHeadersResult.MaxResponseHeaderBuffer + 1) = Any
	send(ClientSocket, @SendBuffer, state->MakeResponseHeaders(@SendBuffer, FileSize.QuadPart - CLng(Index), hOutput), 0)
	
	' Тело
	If Not state->SendOnlyHeaders Then
		send(ClientSocket, b + Index, CInt(FileSize.QuadPart - CLng(Index)), 0)
	End If
End Sub

Sub UrlDecode(ByVal Buffer As WString Ptr, ByVal strUrl As WString Ptr)
	' Расшифровываем url-кодировку %XY
	Dim iAcc As UInteger = 0
	Dim iHex As UInteger = 0
	Dim j As Integer = 0
	
	Dim DecodedBytes As ZString * (ReadHeadersResult.MaxUrlLength + 1) = Any
	
	For i As Integer = 0 To lstrlen(strUrl) - 1
		Dim c As UInteger = strUrl[i]
		If iHex <> 0 Then
			' 0 = 30 = 48 = 0
			' 1 = 31 = 49 = 1
			' 2 = 32 = 50 = 2
			' 3 = 33 = 51 = 3
			' 4 = 34 = 52 = 4
			' 5 = 35 = 53 = 5
			' 6 = 36 = 54 = 6
			' 7 = 37 = 55 = 7
			' 8 = 38 = 56 = 8
			' 9 = 39 = 57 = 9
			' A = 41 = 65 = 10
			' B = 42 = 66 = 11
			' C = 43 = 67 = 12
			' D = 44 = 68 = 13
			' E = 45 = 69 = 14
			' F = 46 = 70 = 15
			iHex += 1 ' раскодировать
			iAcc *= 16
			Select Case c
				Case &h30, &h31, &h32, &h33, &h34, &h35, &h36, &h37, &h38, &h39
					iAcc += c - &h30 ' 48
				Case &h41, &h42, &h43, &h44, &h45, &h46 ' Коды ABCDEF
					iAcc += c - &h37 ' 55
				Case &h61, &h62, &h63, &h64, &h65, &h66 ' Коды abcdef
					iAcc += c - &h57 ' 87
			End Select
			
			If iHex = 3 Then
				c = iAcc
				iAcc = 0
				iHex = 0
			End if
		End if
		If c = &h25 Then '37 % hex code coming?
			iHex = 1
			iAcc = 0
		End if
		If iHex = 0 Then
			DecodedBytes[j] = c
			j += 1
		End If
	Next
	' Завершающий ноль
	DecodedBytes[j] = 0
	' Преобразовать
	MultiByteToWideChar(CP_UTF8, 0, @DecodedBytes, -1, Buffer, ReadHeadersResult.MaxUrlLength)
End Sub

Function GetDocumentCharset(ByVal b As UByte Ptr)As DocumentCharsets
	If b[0] = 239 AndAlso b[1] = 187 AndAlso b[2] = 191 Then
		Return DocumentCharsets.Utf8BOM
	End If
	If b[0] = 255 AndAlso b[1] = 254 Then
		Return DocumentCharsets.Utf16LE
	End If
	If b[0] = 254 AndAlso b[1] = 255 Then
		Return DocumentCharsets.Utf16BE
	End If
	Return DocumentCharsets.ASCII
End Function

Sub ContentTypesToString(ByVal Buffer As WString Ptr, ByVal ContentType As ContentTypes)
	Select Case ContentType
		Case ContentTypes.None
			lstrcpy(Buffer, "application/octet-stream")
			
		Case ContentTypes.ImageGif
			lstrcpy(Buffer, "image/gif")
		Case ContentTypes.ImageJpeg
			lstrcpy(Buffer, "image/jpeg")
		Case ContentTypes.ImagePjpeg
			lstrcpy(Buffer, "image/pjpeg")
		Case ContentTypes.ImagePng
			lstrcpy(Buffer, "image/png")
		Case ContentTypes.ImageSvg
			lstrcpy(Buffer, "image/svg+xml")
		Case ContentTypes.ImageTiff
			lstrcpy(Buffer, "image/tiff")
		Case ContentTypes.ImageIco
			lstrcpy(Buffer, "image/vnd.microsoft.icon")
		Case ContentTypes.ImageWbmp
			lstrcpy(Buffer, "image/vnd.wap.wbmp")
		Case ContentTypes.ImageWebp
			lstrcpy(Buffer, "image/webp")
			
		Case ContentTypes.TextCmd
			lstrcpy(Buffer, "text/cmd")
		Case ContentTypes.TextCss
			lstrcpy(Buffer, "text/css")
		Case ContentTypes.TextCsv
			lstrcpy(Buffer, "text/csv")
		Case ContentTypes.TextHtml
			lstrcpy(Buffer, "text/html")
		Case ContentTypes.TextPlain
			lstrcpy(Buffer, "text/plain")
		Case ContentTypes.TextPhp
			lstrcpy(Buffer, "text/php")
		Case ContentTypes.TextXml
			lstrcpy(Buffer, "text/xml")
			
		Case ContentTypes.ApplicationXml
			lstrcpy(Buffer, "application/xml")
		Case ContentTypes.ApplicationXmlXslt
			lstrcpy(Buffer, "application/xml+xslt")
		Case ContentTypes.ApplicationXhtml
			lstrcpy(Buffer, "application/xhtml+xml")
		Case ContentTypes.ApplicationAtom
			lstrcpy(Buffer, "application/atom+xml")
		Case ContentTypes.ApplicationRssXml
			lstrcpy(Buffer, "application/rss+xml")
		Case ContentTypes.ApplicationJavascript
			lstrcpy(Buffer, "application/javascript")
		Case ContentTypes.ApplicationXJavascript
			lstrcpy(Buffer, "application/x-javascript")
		Case ContentTypes.ApplicationJson
			lstrcpy(Buffer, "application/json")
		Case ContentTypes.ApplicationSoapxml
			lstrcpy(Buffer, "application/soap+xml")
		Case ContentTypes.ApplicationXmldtd
			lstrcpy(Buffer, "application/xml-dtd")
			
		Case ContentTypes.Application7z
			lstrcpy(Buffer, "application/x-7z-compressed")
		Case ContentTypes.ApplicationRar
			lstrcpy(Buffer, "application/x-rar-compressed")
		Case ContentTypes.ApplicationZip
			lstrcpy(Buffer, "application/zip")
		Case ContentTypes.ApplicationGzip
			lstrcpy(Buffer, "application/x-gzip")
		Case ContentTypes.ApplicationXCompressed
			lstrcpy(Buffer, "application/x-compressed")
			
		Case ContentTypes.ApplicationRtf
			lstrcpy(Buffer, "application/rtf")
		Case ContentTypes.ApplicationPdf
			lstrcpy(Buffer, "application/pdf")
		Case ContentTypes.ApplicationOpenDocumentText
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.text")
		Case ContentTypes.ApplicationOpenDocumentTextTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.text-template")
		Case ContentTypes.ApplicationOpenDocumentGraphics
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.graphics")
		Case ContentTypes.ApplicationOpenDocumentGraphicsTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.graphics-template")
		Case ContentTypes.ApplicationOpenDocumentPresentation
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.presentation")
		Case ContentTypes.ApplicationOpenDocumentPresentationTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.presentation-template")
		Case ContentTypes.ApplicationOpenDocumentSpreadsheet
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.spreadsheet")
		Case ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.spreadsheet-template")
		Case ContentTypes.ApplicationOpenDocumentChart
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.chart")
		Case ContentTypes.ApplicationOpenDocumentChartTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.chart-template")
		Case ContentTypes.ApplicationOpenDocumentImage
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.image")
		Case ContentTypes.ApplicationOpenDocumentImageTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.image-template")
		Case ContentTypes.ApplicationOpenDocumentFormula
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.formula")
		Case ContentTypes.ApplicationOpenDocumentFormulaTemplate
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.formula-template")
		Case ContentTypes.ApplicationOpenDocumentMaster
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.text-master")
		Case ContentTypes.ApplicationOpenDocumentWeb
			lstrcpy(Buffer, "application/vnd.oasis.opendocument.text-web")
		Case ContentTypes.ApplicationVndmsexcel
			lstrcpy(Buffer, "application/vnd.ms-excel")
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet
			lstrcpy(Buffer, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
		Case ContentTypes.ApplicationVndmspowerpoint
			lstrcpy(Buffer, "application/vnd.ms-powerpoint")
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation
			lstrcpy(Buffer, "application/vnd.openxmlformats-officedocument.presentationml.presentation")
		Case ContentTypes.ApplicationMsword
			lstrcpy(Buffer, "application/msword")
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument
			lstrcpy(Buffer, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
			
		Case ContentTypes.ApplicationFontwoff
			lstrcpy(Buffer, "application/font-woff")
		Case ContentTypes.ApplicationXfontttf
			lstrcpy(Buffer, "application/x-font-ttf")
			
		Case ContentTypes.AudioBasic
			lstrcpy(Buffer, "audio/basic")
		Case ContentTypes.AudioL24
			lstrcpy(Buffer, "audio/L24")
		Case ContentTypes.AudioMp4
			lstrcpy(Buffer, "audio/mp4")
		Case ContentTypes.AudioAac
			lstrcpy(Buffer, "audio/aac")
		Case ContentTypes.AudioMpeg
			lstrcpy(Buffer, "audio/mpeg")
		Case ContentTypes.AudioOgg
			lstrcpy(Buffer, "audio/ogg")
		Case ContentTypes.AudioVorbis
			lstrcpy(Buffer, "audio/vorbis")
		Case ContentTypes.AudioXmswma
			lstrcpy(Buffer, "audio/x-ms-wma")
		Case ContentTypes.AudioXmswax
			lstrcpy(Buffer, "audio/x-ms-wax")
		Case ContentTypes.AudioRealaudio
			lstrcpy(Buffer, "audio/vnd.rn-realaudio")
		Case ContentTypes.AudioVndwave
			lstrcpy(Buffer, "audio/vnd.wave")
		Case ContentTypes.AudioWebm
			lstrcpy(Buffer, "audio/webm")
			
		Case ContentTypes.MessageHttp
			lstrcpy(Buffer, "message/http")
		Case ContentTypes.MessageImdnxml
			lstrcpy(Buffer, "message/imdn+xml")
		Case ContentTypes.MessagePartial
			lstrcpy(Buffer, "message/partial")
		Case ContentTypes.MessageRfc822
			lstrcpy(Buffer, "message/rfc822")
			
		Case ContentTypes.VideoMpeg
			lstrcpy(Buffer, "video/mpeg")
		Case ContentTypes.VideoOgg
			lstrcpy(Buffer, "video/ogg")
		Case ContentTypes.VideoMp4
			lstrcpy(Buffer, "video/mp4")
		Case ContentTypes.VideoQuicktime
			lstrcpy(Buffer, "video/quicktime")
		Case ContentTypes.VideoWebm
			lstrcpy(Buffer, "video/webm")
		Case ContentTypes.VideoXmswmv
			lstrcpy(Buffer, "video/x-ms-wmv")
		Case ContentTypes.VideoXflv
			lstrcpy(Buffer, "video/x-flv")
		Case ContentTypes.Video3gpp
			lstrcpy(Buffer, "video/3gpp")
		Case ContentTypes.Video3gpp2
			lstrcpy(Buffer, "video/3gpp2")
			
		Case ContentTypes.MultipartMixed
			lstrcpy(Buffer, "multipart/mixed")
		Case ContentTypes.MultipartAlternative
			lstrcpy(Buffer, "multipart/alternative")
		Case ContentTypes.MultipartRelated
			lstrcpy(Buffer, "multipart/related")
		Case ContentTypes.MultipartFormdata
			lstrcpy(Buffer, "multipart/form-data")
		Case ContentTypes.MultipartSigned
			lstrcpy(Buffer, "multipart/signed")
		Case ContentTypes.MultipartEncrypted
			lstrcpy(Buffer, "multipart/encrypted")
		Case ContentTypes.ApplicationXwwwformurlencoded
			lstrcpy(Buffer, "application/x-www-form-urlencoded")
			
		Case ContentTypes.ApplicationOctetStream
			lstrcpy(Buffer, "application/octet-stream")
		Case ContentTypes.ApplicationXbittorrent
			lstrcpy(Buffer, "application/x-bittorrent")
		Case ContentTypes.ApplicationOgg
			lstrcpy(Buffer, "application/ogg")
			
		Case ContentTypes.ApplicationFlash
			lstrcpy(Buffer, "application/x-shockwave-flash")
		Case ContentTypes.ApplicationCertx509
			lstrcpy(Buffer, "application/x-x509-ca-cert")
	End Select
End Sub

Sub GetMimeType(ByVal mt As MimeType Ptr, ByVal ext As WString Ptr)
	mt->IsTextFormat = False
	' Для ускорения работы сперва проверить самые распространённые расширения файлов
	If lstrcmpi(ext, @ExtensionHtm) = 0 Then
		mt->ContentType = ContentTypes.TextHtml
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionXhtml) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXhtml
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionCss) = 0 Then
		mt->ContentType = ContentTypes.TextCss
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionPng) = 0 Then
		mt->ContentType = ContentTypes.ImagePng
		Return
	End If
	If lstrcmpi(ext, @ExtensionGif) = 0 Then
		mt->ContentType = ContentTypes.ImageGif
		Return
	End If
	If lstrcmpi(ext, @ExtensionJpg) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return
	End If
	If lstrcmpi(ext, @ExtensionIco) = 0 Then
		mt->ContentType = ContentTypes.ImageIco
		Return
	End If
	If lstrcmpi(ext, @ExtensionXml) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXml
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionXsl) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXmlXslt
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionXslt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXmlXslt
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionTxt) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionHeaders) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionRss) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRssXml
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionJs) = 0 Then
		mt->ContentType = ContentTypes.ApplicationJavascript
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionZip) = 0 Then
		mt->ContentType = ContentTypes.ApplicationZip
		Return
	End If
	If lstrcmpi(ext, @ExtensionHtml) = 0 Then
		mt->ContentType = ContentTypes.TextHtml
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionSvg) = 0 Then
		mt->ContentType = ContentTypes.ImageSvg
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionJpe) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return
	End If
	If lstrcmpi(ext, @ExtensionJpeg) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return
	End If
	If lstrcmpi(ext, @ExtensionTif) = 0 Then
		mt->ContentType = ContentTypes.ImageTiff
		Return
	End If
	If lstrcmpi(ext, @ExtensionTiff) = 0 Then
		mt->ContentType = ContentTypes.ImageTiff
		Return
	End If
	If lstrcmpi(ext, @ExtensionAtom) = 0 Then
		mt->ContentType = ContentTypes.ApplicationAtom
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @Extension7z) = 0 Then
		mt->ContentType = ContentTypes.Application7z
		Return
	End If
	If lstrcmpi(ext, @ExtensionRar) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRar
		Return
	End If
	If lstrcmpi(ext, @ExtensionGz) = 0 Then
		mt->ContentType = ContentTypes.ApplicationGzip
		Return
	End If
	If lstrcmpi(ext, @ExtensionTgz) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXCompressed
		Return
	End If
	If lstrcmpi(ext, @ExtensionRtf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRtf
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionMpg) = 0 Then
		mt->ContentType = ContentTypes.VideoMpeg
		Return
	End If
	If lstrcmpi(ext, @ExtensionMpeg) = 0 Then
		mt->ContentType = ContentTypes.VideoMpeg
		Return
	End If
	If lstrcmpi(ext, @ExtensionOgv) = 0 Then
		mt->ContentType = ContentTypes.VideoOgg
		Return
	End If
	If lstrcmpi(ext, @ExtensionMp4) = 0 Then
		mt->ContentType = ContentTypes.VideoMp4
		Return
	End If
	If lstrcmpi(ext, @ExtensionWebm) = 0 Then
		mt->ContentType = ContentTypes.VideoWebm
		Return
	End If
	If lstrcmpi(ext, @ExtensionBin) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionExe) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionDll) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionDeb) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionDmg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionEot) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionIso) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionImg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionMsi) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionMsp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionMsm) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return
	End If
	If lstrcmpi(ext, @ExtensionSwf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationFlash
		Return
	End If
	If lstrcmpi(ext, @ExtensionRam) = 0 Then
		mt->ContentType = ContentTypes.AudioRealaudio
		Return
	End If
	If lstrcmpi(ext, @ExtensionCrt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationCertx509
		Return
	End If
	If lstrcmpi(ext, @ExtensionCer) = 0 Then
		mt->ContentType = ContentTypes.ApplicationCertx509
		Return
	End If
	If lstrcmpi(ext, @ExtensionPdf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationPdf
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentText
		Return
	End If
	If lstrcmpi(ext, @ExtensionOtt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentTextTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphics
		Return
	End If
	If lstrcmpi(ext, @ExtensionOtg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphicsTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentation
		Return
	End If
	If lstrcmpi(ext, @ExtensionOtp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentationTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOds) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheet
		Return
	End If
	If lstrcmpi(ext, @ExtensionOts) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdc) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChart
		Return
	End If
	If lstrcmpi(ext, @ExtensionOtc) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChartTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdi) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImage
		Return
	End If
	If lstrcmpi(ext, @ExtensionOti) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImageTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormula
		Return
	End If
	If lstrcmpi(ext, @ExtensionOtf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormulaTemplate
		Return
	End If
	If lstrcmpi(ext, @ExtensionOdm) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentMaster
		Return
	End If
	If lstrcmpi(ext, @ExtensionOth) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentWeb
		Return
	End If
	
	' Исходный код
	If lstrcmpi(ext, @ExtensionBas) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionBi) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionVb) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionRc) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionAsm) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	If lstrcmpi(ext, @ExtensionIni) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return
	End If
	mt->ContentType = ContentTypes.None
End Sub

Sub GetDefaultFileName(ByVal Buffer As WString Ptr, ByVal Index As Integer)
	Select Case Index
		Case 0
			lstrcpy(Buffer, @DefaultFileNameString1)
		Case 1
			lstrcpy(Buffer, @DefaultFileNameString2)
		Case 2
			lstrcpy(Buffer, @DefaultFileNameString3)
		Case 3
			lstrcpy(Buffer, @DefaultFileNameString4)
		Case Else
			Buffer[0] = 0
	End Select
End Sub

Sub GetSafeString(ByVal Buffer As WString Ptr, ByVal strSafe As WString Ptr)
	Dim Counter As Integer = 0
	For i As Integer = 0 To lstrlen(strSafe) - 1
		Dim Number As Integer = strSafe[i]
		Select Case Number
			Case 34 ' "
				' &quot;
				Buffer[Counter] = 38			' &
				Buffer[Counter + 1] = &h71	' q
				Buffer[Counter + 2] = &h75	' u
				Buffer[Counter + 3] = &h6f	' o
				Buffer[Counter + 4] = &h74	' t
				Buffer[Counter + 5] = &h3b	' ;
				Counter += 6
			Case 38 ' &
				' &amp;
				Buffer[Counter] = 38			' &
				Buffer[Counter + 1] = &h61			' a
				Buffer[Counter + 2] = &h6d			' m
				Buffer[Counter + 3] = &h70			' p
				Buffer[Counter + 4] = &h3b			' ;
				Counter += 5
			Case 39 ' '
				' &apos;
				Buffer[Counter] = 38			' &
				Buffer[Counter + 1] = &h61			' a
				Buffer[Counter + 2] = &h70			' p
				Buffer[Counter + 3] = &h6f			' o
				Buffer[Counter + 4] = &h73			' s
				Buffer[Counter + 5] = &h3b	' ;
				Counter += 6
			Case 60 ' <
				' &lt;
				Buffer[Counter] = 38			' &
				Buffer[Counter + 1] = &h6c			' l
				Buffer[Counter + 2] = &h74			' t
				Buffer[Counter + 3] = &h3b	' ;
				Counter += 4
			Case 62 ' >
				' &gt;
				Buffer[Counter] = 38			' &
				Buffer[Counter + 1] = &h67			' g
				Buffer[Counter + 2] = &h74			' t
				Buffer[Counter + 3] = &h3b	' ;
				Counter += 4
			Case Else
				Buffer[Counter] = Number
				Counter += 1
		End Select
	Next
	' Завершающий нулевой символ
	Buffer[Counter] = 0
End Sub

Sub GetHttpMethodName(ByVal Buffer As WString Ptr, ByVal HttpMethod As HttpMethods)
	Select Case HttpMethod
		Case HttpGet
			lstrcpy(Buffer, @HttpMethodGet)
		Case HttpHead
			lstrcpy(Buffer, @HttpMethodHead)
		Case HttpPut
			lstrcpy(Buffer, @HttpMethodPut)
		Case HttpPatch
			lstrcpy(Buffer, @HttpMethodPatch)
		Case HttpDelete
			lstrcpy(Buffer, @HttpMethodDelete)
		Case HttpPost
			lstrcpy(Buffer, @HttpMethodPost)
		Case HttpOptions
			lstrcpy(Buffer, @HttpMethodOptions)
		Case HttpTrace
			lstrcpy(Buffer, @HttpMethodTrace)
		Case HttpCopy
			lstrcpy(Buffer, @HttpMethodCopy)
		Case HttpMove
			lstrcpy(Buffer, @HttpMethodMove)
		Case HttpPropfind
			lstrcpy(Buffer, @HttpMethodPropfind)
	End Select
End Sub

Sub GetWebSite(ByVal ExeDir As WString Ptr, ByVal site As WebSite Ptr, ByVal HostName As WString Ptr)
	' Имя файла настроек программы
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, ExeDir, @WebSitesIniFileString)
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	
	GetPrivateProfileString(HostName, @VirtualPathSectionString, @DefaultValue, @site->VirtualPath, WebSite.MaxHostNameLength, IniFileName)
	GetPrivateProfileString(HostName, @PhisycalDirSectionString, @DefaultValue, @site->PhysicalDirectory, MAX_PATH, IniFileName)
	Dim Result2 As UINT = GetPrivateProfileInt(HostName, @IsMovedSectionString, 0, IniFileName)
	If Result2 = 0 Then
		site->IsMoved = False
	Else
		site->IsMoved = True
	End If
	GetPrivateProfileString(HostName, @MovedUrlSectionString, @DefaultValue, @site->MovedUrl, WebSite.MaxHostNameLength, IniFileName)
	lstrcpy(@site->HostName, HostName)
End sub

Function WebSiteExists(ByVal ExeDir As WString Ptr, ByVal wSiteName As WString Ptr)As Boolean
	' HACK Придумать правильныое хранение данных о сайте
	Const SectionsLength As Integer = 31999
	Dim AllSections As WString * (SectionsLength + 1) = Any
	' Имя файла настроек программы
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, ExeDir, @WebSitesIniFileString)
	
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	' Получить имена всех секций
	Dim Result2 As DWORD = GetPrivateProfileString(Null, Null, @DefaultValue, @AllSections, SectionsLength, @IniFileName)
	
	Dim Start As Integer = 0
	Dim w As WString Ptr = Any
	Do
		' Получить указатель на начало строки
		w = @AllSections[Start]
		If lstrcmpi(w, wSiteName) = 0 Then
			Return True
		End If
		' Измерить длину строки, прибавить это к указателю + 1
		Start += lstrlen(w) + 1
	Loop While Start < Result2
	Return False
End Function

Sub GetHttpDate(ByVal Buffer As WString Ptr, ByVal dt As SYSTEMTIME Ptr)
	' Tue, 15 Nov 1994 12:45:26 GMT
	Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, dt, @DateFormatString, Buffer, 31) - 1
	GetTimeFormat(LOCALE_INVARIANT, 0, dt, @TimeFormatString, @Buffer[dtBufferLength], 31 - dtBufferLength)
End Sub

Sub GetHttpDate(ByVal Buffer As WString Ptr)
	Dim dt As SYSTEMTIME = Any
	GetSystemTime(@dt)
	GetHttpDate(Buffer, @dt)
End Sub

Sub GetStatusDescription(ByVal Buffer As WString Ptr, ByVal StatusCode As Integer)
	Select Case StatusCode
		Case 100
			lstrcpy(Buffer, @HttpStatusCodeString100)
		Case 101
			lstrcpy(Buffer, @HttpStatusCodeString101)
		Case 102
			lstrcpy(Buffer, @HttpStatusCodeString102)
		Case 200
			lstrcpy(Buffer, @HttpStatusCodeString200)
		Case 201
			lstrcpy(Buffer, @HttpStatusCodeString201)
		Case 202
			lstrcpy(Buffer, @HttpStatusCodeString202)
		Case 203
			lstrcpy(Buffer, @HttpStatusCodeString203)
		Case 204
			lstrcpy(Buffer, @HttpStatusCodeString204)
		Case 205
			lstrcpy(Buffer, @HttpStatusCodeString205)
		Case 206
			lstrcpy(Buffer, @HttpStatusCodeString206)
      Case 207
			lstrcpy(Buffer, @HttpStatusCodeString207)
		Case 226
			lstrcpy(Buffer, @HttpStatusCodeString226)
		Case 300
			lstrcpy(Buffer, @HttpStatusCodeString300)
		Case 301
			lstrcpy(Buffer, @HttpStatusCodeString301)
		Case 302
			lstrcpy(Buffer, @HttpStatusCodeString302)
		Case 303
			lstrcpy(Buffer, @HttpStatusCodeString303)
		Case 304
			lstrcpy(Buffer, @HttpStatusCodeString304)
		Case 305
			lstrcpy(Buffer, @HttpStatusCodeString305)
		Case 307
			lstrcpy(Buffer, @HttpStatusCodeString307)
		Case 400
			lstrcpy(Buffer, @HttpStatusCodeString400)
		Case 401
			lstrcpy(Buffer, @HttpStatusCodeString401)
		Case 402
			lstrcpy(Buffer, @HttpStatusCodeString402)
		Case 403
			lstrcpy(Buffer, @HttpStatusCodeString403)
		Case 404
			lstrcpy(Buffer, @HttpStatusCodeString404)
		Case 405
			lstrcpy(Buffer, @HttpStatusCodeString405)
		Case 406
			lstrcpy(Buffer, @HttpStatusCodeString406)
		Case 407
			lstrcpy(Buffer, @HttpStatusCodeString407)
		Case 408
			lstrcpy(Buffer, @HttpStatusCodeString408)
		Case 409
			lstrcpy(Buffer, @HttpStatusCodeString409)
		Case 410
			lstrcpy(Buffer, @HttpStatusCodeString410)
		Case 411
			lstrcpy(Buffer, @HttpStatusCodeString411)
		Case 412
			lstrcpy(Buffer, @HttpStatusCodeString412)
		Case 413
			lstrcpy(Buffer, @HttpStatusCodeString413)
		Case 414
			lstrcpy(Buffer, @HttpStatusCodeString414)
		Case 415
			lstrcpy(Buffer, @HttpStatusCodeString415)
		Case 416
			lstrcpy(Buffer, @HttpStatusCodeString416)
		Case 417
			lstrcpy(Buffer, @HttpStatusCodeString417)
		Case 418
			lstrcpy(Buffer, @HttpStatusCodeString418)
		REM Case 422
			REM lstrcpy(Buffer, @HttpStatusCodeString422)
		REM Case 423
			REM lstrcpy(Buffer, @HttpStatusCodeString423)
		REM Case 424
			REM lstrcpy(Buffer, @HttpStatusCodeString424)
		REM Case 425
			REM lstrcpy(Buffer, @HttpStatusCodeString425)
		Case 426
			lstrcpy(Buffer, @HttpStatusCodeString426)
		Case 428
			lstrcpy(Buffer, @HttpStatusCodeString428)
		Case 429
			lstrcpy(Buffer, @HttpStatusCodeString429)
		Case 431
			lstrcpy(Buffer, @HttpStatusCodeString431)
		REM Case 449
			REM lstrcpy(Buffer, @HttpStatusCodeString449)
		Case 451
			lstrcpy(Buffer, @HttpStatusCodeString451)
		Case 500
			lstrcpy(Buffer, @HttpStatusCodeString500)
		Case 501
			lstrcpy(Buffer, @HttpStatusCodeString501)
		Case 502
			lstrcpy(Buffer, @HttpStatusCodeString502)
		Case 503
			lstrcpy(Buffer, @HttpStatusCodeString503)
		Case 504
			lstrcpy(Buffer, @HttpStatusCodeString504)
		Case 505
			lstrcpy(Buffer, @HttpStatusCodeString505)
		Case 506
			lstrcpy(Buffer, @HttpStatusCodeString506)
		Case 507
			lstrcpy(Buffer, @HttpStatusCodeString507)
		Case 508
			lstrcpy(Buffer, @HttpStatusCodeString508)
		Case 509
			lstrcpy(Buffer, @HttpStatusCodeString509)
		Case 510
			lstrcpy(Buffer, @HttpStatusCodeString510)
		Case 511
			lstrcpy(Buffer, @HttpStatusCodeString511)
		Case Else
			lstrcpy(Buffer, @HttpStatusCodeString200)
	End Select
End Sub

Function FormatErrorMessageBody(ByVal Buffer As WString Ptr, ByVal StatusCode As Integer, ByVal VirtualPath As WString Ptr, ByVal strMessage As WString Ptr)As Long
	Dim strStatusCode As WString * 8 = Any
	itow(StatusCode, @strStatusCode, 10) ' Число в строку
	
	Dim desc As WString * 32 = Any
	GetStatusDescription(@desc, statusCode)
	
	lstrcpy(Buffer, HttpErrorHead1)
	lstrcat(Buffer, @desc)
	lstrcat(Buffer, HttpErrorHead2)
	
	lstrcat(Buffer, HttpErrorBody1)
	If statusCode >= 500 Then
		lstrcat(Buffer, @ServerErrorString)
	Else
		lstrcat(Buffer, @ClientErrorString)
	End If
	lstrcat(Buffer, HttpErrorBody2)
	lstrcat(Buffer, VirtualPath)
	lstrcat(Buffer, HttpErrorBody3)
	lstrcat(Buffer, @strStatusCode)
	lstrcat(Buffer, HttpErrorBody4)
	lstrcat(Buffer, desc)
	lstrcat(Buffer, HttpErrorBody5)
	lstrcat(Buffer, strMessage)
	lstrcat(Buffer, HttpErrorBody6)
	Return CLng(lstrlen(Buffer))
End Function

Sub InitializeState(ByVal state As ReadHeadersResult Ptr)
	memset(@state->RequestHeaders(0), 0, ReadHeadersResult.RequestHeaderMaximum * SizeOf(WString Ptr))
	memset(@state->ResponseHeaders(0), 0, ReadHeadersResult.ResponseHeaderMaximum * SizeOf(WString Ptr))
	With *state
		.KeepAlive = False
		.SendOnlyHeaders = False
		.HttpVersion = HttpVersions.Http11
		.EndHeadersOffset = 0
		.HeaderBytesLength = 0
		.RequestHeaderBufferLength = 0
		.StatusDescription = 0
		.Url = 0
		.QueryString = 0
		.StartResponseHeadersPtr = @state->ResponseHeaderBuffer
	End With
End Sub

Function GetKnownRequestHeaderIndex(ByVal Header As WString Ptr)As Integer
	If lstrcmpi(Header, HeaderAcceptString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderAccept
	End If
	If lstrcmpi(Header, HeaderAcceptCharsetString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderAcceptCharset
	End If
	If lstrcmpi(Header, HeaderAcceptEncodingString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderAcceptEncoding
	End If
	If lstrcmpi(Header, HeaderAcceptLanguageString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderAcceptLanguage
	End If
	If lstrcmpi(Header, HeaderAuthorizationString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderAuthorization
	End If
	If lstrcmpi(Header, HeaderCacheControlString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderCacheControl
	End If
	If lstrcmpi(Header, HeaderConnectionString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderConnection
	End If
	If lstrcmpi(Header, HeaderContentEncodingString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentEncoding
	End If
	If lstrcmpi(Header, HeaderContentLanguageString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentLanguage
	End If
	If lstrcmpi(Header, HeaderContentLengthString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentLength
	End If
	If lstrcmpi(Header, HeaderContentMd5String) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentMd5
	End If
	If lstrcmpi(Header, HeaderContentRangeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentRange
	End If
	If lstrcmpi(Header, HeaderContentTypeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderContentType
	End If
	If lstrcmpi(Header, HeaderCookieString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderCookie
	End If
	If lstrcmpi(Header, HeaderExpectString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderExpect
	End If
	If lstrcmpi(Header, HeaderFromString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderFrom
	End If
	If lstrcmpi(Header, HeaderHostString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderHost
	End If
	If lstrcmpi(Header, HeaderIfMatchString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderIfMatch
	End If
	If lstrcmpi(Header, HeaderIfModifiedSinceString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderIfModifiedSince
	End If
	If lstrcmpi(Header, HeaderIfNoneMatchString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderIfNoneMatch
	End If
	If lstrcmpi(Header, HeaderIfRangeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderIfRange
	End If
	If lstrcmpi(Header, HeaderIfUnmodifiedSinceString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderIfUnmodifiedSince
	End If
	If lstrcmpi(Header, HeaderKeepAliveString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderKeepAlive
	End If
	If lstrcmpi(Header, HeaderMaxForwardsString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderMaxForwards
	End If
	If lstrcmpi(Header, HeaderPragmaString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderPragma
	End If
	If lstrcmpi(Header, HeaderProxyAuthorizationString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderProxyAuthorization
	End If
	If lstrcmpi(Header, HeaderRangeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderRange
	End If
	If lstrcmpi(Header, HeaderRefererString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderReferer
	End If
	If lstrcmpi(Header, HeaderTeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderTe
	End If
	If lstrcmpi(Header, HeaderTrailerString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderTrailer
	End If
	If lstrcmpi(Header, HeaderTransferEncodingString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderTransferEncoding
	End If
	If lstrcmpi(Header, HeaderUpgradeString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderUpgrade
	End If
	If lstrcmpi(Header, HeaderTransferEncodingString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderTransferEncoding
	End If
	If lstrcmpi(Header, HeaderUserAgentString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderUserAgent
	End If
	If lstrcmpi(Header, HeaderViaString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderVia
	End If
	If lstrcmpi(Header, HeaderWarningString) = 0 Then
		Return HttpRequestHeaderIndices.HeaderWarning
	End If
	Return -1
End Function

Function GetKnownResponseHeaderIndex(ByVal Header As WString Ptr)As Integer
	If lstrcmpi(Header, @HeaderAcceptRangesString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderAcceptRanges
	End If
	If lstrcmpi(Header, @HeaderAgeString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderAge
	End If
	If lstrcmpi(Header, @HeaderAllowString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderAllow
	End If
	If lstrcmpi(Header, @HeaderCacheControlString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderCacheControl
	End If
	If lstrcmpi(Header, @HeaderConnectionString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderConnection
	End If
	If lstrcmpi(Header, @HeaderContentEncodingString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentEncoding
	End If
	If lstrcmpi(Header, @HeaderContentLanguageString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentLanguage
	End If
	If lstrcmpi(Header, @HeaderContentLengthString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentLength
	End If
	If lstrcmpi(Header, @HeaderContentLocationString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentLocation
	End If
	If lstrcmpi(Header, @HeaderContentMd5String) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentMd5
	End If
	If lstrcmpi(Header, @HeaderContentRangeString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentRange
	End If
	If lstrcmpi(Header, @HeaderContentTypeString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderContentType
	End If
	If lstrcmpi(Header, @HeaderDateString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderDate
	End If
	If lstrcmpi(Header, @HeaderETagString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderETag
	End If
	If lstrcmpi(Header, @HeaderExpiresString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderExpires
	End If
	If lstrcmpi(Header, @HeaderKeepAliveString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderKeepAlive
	End If
	If lstrcmpi(Header, @HeaderLastModifiedString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderLastModified
	End If
	If lstrcmpi(Header, @HeaderLocationString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderLocation
	End If
	If lstrcmpi(Header, @HeaderPragmaString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderPragma
	End If
	If lstrcmpi(Header, @HeaderProxyAuthenticateString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderProxyAuthenticate
	End If
	If lstrcmpi(Header, @HeaderRetryAfterString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderRetryAfter
	End If
	If lstrcmpi(Header, @HeaderServerString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderServer
	End If
	If lstrcmpi(Header, @HeaderSetCookieString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderSetCookie
	End If
	If lstrcmpi(Header, @HeaderTrailerString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderTrailer
	End If
	If lstrcmpi(Header, @HeaderTransferEncodingString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderTransferEncoding
	End If
	If lstrcmpi(Header, @HeaderUpgradeString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderUpgrade
	End If
	If lstrcmpi(Header, @HeaderVaryString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderVary
	End If
	If lstrcmpi(Header, @HeaderViaString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderVia
	End If
	If lstrcmpi(Header, @HeaderWarningString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderWarning
	End If
	If lstrcmpi(Header, @HeaderWWWAuthenticateString) = 0 Then
		Return HttpResponseHeaderIndices.HeaderWwwAuthenticate
	End If
	Return -1
End Function

Function GetKnownResponseHeaderName(ByVal Buffer As WString Ptr, ByVal HeaderIndex As HttpResponseHeaderIndices)As Boolean
	Select Case HeaderIndex
		Case HttpResponseHeaderIndices.HeaderAcceptRanges
			lstrcpy(Buffer, @HeaderAcceptRangesString)
		Case HttpResponseHeaderIndices.HeaderAge
			lstrcpy(Buffer, @HeaderAgeString)
		Case HttpResponseHeaderIndices.HeaderAllow
			lstrcpy(Buffer, @HeaderAllowString)
		Case HttpResponseHeaderIndices.HeaderCacheControl
			lstrcpy(Buffer, @HeaderCacheControlString)
		Case HttpResponseHeaderIndices.HeaderConnection
			lstrcpy(Buffer, @HeaderConnectionString)
		Case HttpResponseHeaderIndices.HeaderContentEncoding
			lstrcpy(Buffer, @HeaderContentEncodingString)
		Case HttpResponseHeaderIndices.HeaderContentLength
			lstrcpy(Buffer, @HeaderContentLengthString)
		Case HttpResponseHeaderIndices.HeaderContentLanguage
			lstrcpy(Buffer, @HeaderContentLanguageString)
		Case HttpResponseHeaderIndices.HeaderContentLocation
			lstrcpy(Buffer, @HeaderContentLocationString)
		Case HttpResponseHeaderIndices.HeaderContentMd5
			lstrcpy(Buffer, @HeaderContentMd5String)
		Case HttpResponseHeaderIndices.HeaderContentRange
			lstrcpy(Buffer, @HeaderContentRangeString)
		Case HttpResponseHeaderIndices.HeaderContentType
			lstrcpy(Buffer, @HeaderContentTypeString)
		Case HttpResponseHeaderIndices.HeaderDate
			lstrcpy(Buffer, @HeaderDateString)
		Case HttpResponseHeaderIndices.HeaderEtag
			lstrcpy(Buffer, @HeaderETagString)
		Case HttpResponseHeaderIndices.HeaderExpires
			lstrcpy(Buffer, @HeaderExpiresString)
		Case HttpResponseHeaderIndices.HeaderKeepAlive
			lstrcpy(Buffer, @HeaderKeepAliveString)
		Case HttpResponseHeaderIndices.HeaderLastModified
			lstrcpy(Buffer, @HeaderLastModifiedString)
		Case HttpResponseHeaderIndices.HeaderLocation
			lstrcpy(Buffer, @HeaderLocationString)
		Case HttpResponseHeaderIndices.HeaderPragma
			lstrcpy(Buffer, @HeaderPragmaString)
		Case HttpResponseHeaderIndices.HeaderProxyAuthenticate
			lstrcpy(Buffer, @HeaderProxyAuthenticateString)
		Case HttpResponseHeaderIndices.HeaderRetryAfter
			lstrcpy(Buffer, @HeaderRetryAfterString)
		Case HttpResponseHeaderIndices.HeaderServer
			lstrcpy(Buffer, @HeaderServerString)
		Case HttpResponseHeaderIndices.HeaderSetCookie
			lstrcpy(Buffer, @HeaderSetCookieString)
		Case HttpResponseHeaderIndices.HeaderTrailer
			lstrcpy(Buffer, @HeaderTrailerString)
		Case HttpResponseHeaderIndices.HeaderTransferEncoding
			lstrcpy(Buffer, @HeaderTransferEncodingString)
		Case HttpResponseHeaderIndices.HeaderUpgrade
			lstrcpy(Buffer, @HeaderUpgradeString)
		Case HttpResponseHeaderIndices.HeaderVary
			lstrcpy(Buffer, @HeaderVaryString)
		Case HttpResponseHeaderIndices.HeaderVia
			lstrcpy(Buffer, @HeaderViaString)
		Case HttpResponseHeaderIndices.HeaderWarning
			lstrcpy(Buffer, @HeaderWarningString)
		Case HttpResponseHeaderIndices.HeaderWwwAuthenticate
			lstrcpy(Buffer, @HeaderWWWAuthenticateString)
		Case Else
			Return False
	End Select
	Return True
End Function

Function GetHttpMethod(ByVal s As WString Ptr)As HttpMethods
	If lstrcmp(s, HttpMethodGet) = 0 Then
		Return HttpMethods.HttpGet
	End If
	If lstrcmp(s, HttpMethodHead) = 0 Then
		Return HttpMethods.HttpHead
	End If
	If lstrcmp(s, HttpMethodPut) = 0 Then
		Return HttpMethods.HttpPut
	End If
	If lstrcmp(s, HttpMethodConnect) = 0 Then
		Return HttpMethods.HttpConnect
	End If
	If lstrcmp(s, HttpMethodDelete) = 0 Then
		Return HttpMethods.HttpDelete
	End If
	If lstrcmp(s, HttpMethodOptions) = 0 Then
		Return HttpMethods.HttpOptions
	End If
	If lstrcmp(s, HttpMethodTrace) = 0 Then
		Return HttpMethods.HttpTrace
	Else
		Return HttpMethods.None
	End If
End Function

Function IsBadPath(ByVal Path As WString Ptr)As Boolean
	If Path[0] = 0 Then
		Return True
	End If
	Dim PathLen As Integer = lstrlen(Path)
	If Path[PathLen - 1] = &h2e Then ' .
		Return True
	End If
	For i As Integer = 0 To PathLen - 1
		Dim c As Integer = Path[i]
		Select Case c
			Case Is < 32
				Return True
			Case 34 ' "
				Return True
			Case 36 ' $
				Return True
			Case 37 ' %
				Return True
			Case 60 ' <
				Return True
			Case 62 ' >
				Return True
			Case 63 ' ?
				Return True
			Case 124 ' |
				Return True
		End Select
	Next
	If StrStr(Path, DotDotString) > 0 Then
		Return True
	End If
	Return False
End Function

Sub MapPath(ByVal Buffer As WString Ptr, ByVal path As WString Ptr, ByVal PhysicalPath As WString Ptr)
	lstrcpy(Buffer, PhysicalPath)
	Dim BufferLength As Integer = lstrlen(Buffer)
	
	' Добавить \ если там его нет
	If Buffer[BufferLength - 1] <> &h5c Then
		Buffer[BufferLength] = &h5c
		BufferLength += 1
		Buffer[BufferLength] = 0
	End If
	
	' Объединение физической директории и пути
	If lstrlen(path) <> 0 Then
		If path[0] = &h2f Then
			lstrcat(Buffer, path + 1)
		Else
			lstrcat(Buffer, path)
		End If
	End If
	
	' замена / на \
	For i As Integer = 0 To BufferLength - 1
		If Buffer[i] = &h2f Then
			Buffer[i] = &h5c
		End If
	Next
End Sub

Function FindCrLfA(ByVal Buffer As ZString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer
	For i As Integer = Start To BufferLength - 2 ' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			Return i
		End If
	Next
	Return -1
End Function

Function FindCrLfW(ByVal Buffer As WString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer
	For i As Integer = Start To BufferLength - 2 ' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			Return i
		End If
	Next
	Return -1
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

Function HttpAuthUtil(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
	Dim intHttpAuth As HttpAuthResult = state->HttpAuth(@www->PhysicalDirectory)
	If intHttpAuth <> HttpAuthResult.Success Then
		state->StatusCode = 401
		Select Case intHttpAuth
			Case HttpAuthResult.NeedAuth
				' Требуется авторизация
				state->ResponseHeaders(HttpResponseHeaderIndices.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
				WriteHttpError(state, ClientSocket, @NeedUsernamePasswordString, @www->VirtualPath, hOutput)
			Case HttpAuthResult.BadAuth
				' Параметры авторизации неверны
				state->ResponseHeaders(HttpResponseHeaderIndices.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate1
				WriteHttpError(state, ClientSocket, @NeedUsernamePasswordString1, @www->VirtualPath, hOutput)
			Case HttpAuthResult.NeedBasicAuth
				' Необходимо использовать Basic‐авторизацию
				state->ResponseHeaders(HttpResponseHeaderIndices.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate2
				WriteHttpError(state, ClientSocket, NeedUsernamePasswordString2, @www->VirtualPath, hOutput)
			Case HttpAuthResult.EmptyPassword
				' Пароль не может быть пустым
				state->ResponseHeaders(HttpResponseHeaderIndices.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
				WriteHttpError(state, ClientSocket, NeedUsernamePasswordString3, @www->VirtualPath, hOutput)
			Case HttpAuthResult.BadUserNamePassword
				' Имя пользователя или пароль не подходят
				state->ResponseHeaders(HttpResponseHeaderIndices.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
				WriteHttpError(state, ClientSocket, NeedUsernamePasswordString, @www->VirtualPath, hOutput)
		End Select
		Return False
	End If
	Return True
End Function