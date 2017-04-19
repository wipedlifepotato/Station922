#ifndef unicode
#define unicode
#endif

#include once "Mime.bi"
#include once "Extensions.bi"
#include once "windows.bi"

Sub GetStringOfContentType(ByVal Buffer As WString Ptr, ByVal ContentType As ContentTypes)
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

Function GetMimeTypeOfExtension(ByVal ext As WString Ptr)As MimeType
	Dim mt As MimeType = Any
	mt.IsTextFormat = False
	' Для ускорения работы сперва проверить самые распространённые расширения файлов
	If lstrcmpi(ext, @ExtensionHtm) = 0 Then
		mt.ContentType = ContentTypes.TextHtml
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionXhtml) = 0 Then
		mt.ContentType = ContentTypes.ApplicationXhtml
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionCss) = 0 Then
		mt.ContentType = ContentTypes.TextCss
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionPng) = 0 Then
		mt.ContentType = ContentTypes.ImagePng
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionGif) = 0 Then
		mt.ContentType = ContentTypes.ImageGif
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionJpg) = 0 Then
		mt.ContentType = ContentTypes.ImageJpeg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionIco) = 0 Then
		mt.ContentType = ContentTypes.ImageIco
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionXml) = 0 Then
		mt.ContentType = ContentTypes.ApplicationXml
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionXsl) = 0 Then
		mt.ContentType = ContentTypes.ApplicationXmlXslt
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionXslt) = 0 Then
		mt.ContentType = ContentTypes.ApplicationXmlXslt
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionTxt) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionHeaders) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionRss) = 0 Then
		mt.ContentType = ContentTypes.ApplicationRssXml
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionJs) = 0 Then
		mt.ContentType = ContentTypes.ApplicationJavascript
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionZip) = 0 Then
		mt.ContentType = ContentTypes.ApplicationZip
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionHtml) = 0 Then
		mt.ContentType = ContentTypes.TextHtml
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionSvg) = 0 Then
		mt.ContentType = ContentTypes.ImageSvg
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionJpe) = 0 Then
		mt.ContentType = ContentTypes.ImageJpeg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionJpeg) = 0 Then
		mt.ContentType = ContentTypes.ImageJpeg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionTif) = 0 Then
		mt.ContentType = ContentTypes.ImageTiff
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionTiff) = 0 Then
		mt.ContentType = ContentTypes.ImageTiff
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionAtom) = 0 Then
		mt.ContentType = ContentTypes.ApplicationAtom
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @Extension7z) = 0 Then
		mt.ContentType = ContentTypes.Application7z
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionRar) = 0 Then
		mt.ContentType = ContentTypes.ApplicationRar
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionGz) = 0 Then
		mt.ContentType = ContentTypes.ApplicationGzip
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionTgz) = 0 Then
		mt.ContentType = ContentTypes.ApplicationXCompressed
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionRtf) = 0 Then
		mt.ContentType = ContentTypes.ApplicationRtf
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMpg) = 0 Then
		mt.ContentType = ContentTypes.VideoMpeg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMpeg) = 0 Then
		mt.ContentType = ContentTypes.VideoMpeg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOgv) = 0 Then
		mt.ContentType = ContentTypes.VideoOgg
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMp4) = 0 Then
		mt.ContentType = ContentTypes.VideoMp4
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionWebm) = 0 Then
		mt.ContentType = ContentTypes.VideoWebm
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionBin) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionExe) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionDll) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionDeb) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionDmg) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionEot) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionIso) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionImg) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMsi) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMsp) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionMsm) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOctetStream
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionSwf) = 0 Then
		mt.ContentType = ContentTypes.ApplicationFlash
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionRam) = 0 Then
		mt.ContentType = ContentTypes.AudioRealaudio
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionCrt) = 0 Then
		mt.ContentType = ContentTypes.ApplicationCertx509
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionCer) = 0 Then
		mt.ContentType = ContentTypes.ApplicationCertx509
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionPdf) = 0 Then
		mt.ContentType = ContentTypes.ApplicationPdf
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdt) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentText
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOtt) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentTextTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdg) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentGraphics
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOtg) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentGraphicsTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdp) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentPresentation
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOtp) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentPresentationTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOds) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheet
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOts) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdc) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentChart
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOtc) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentChartTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdi) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentImage
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOti) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentImageTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdf) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentFormula
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOtf) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentFormulaTemplate
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOdm) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentMaster
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionOth) = 0 Then
		mt.ContentType = ContentTypes.ApplicationOpenDocumentWeb
		Return mt
	End If
	
	' Исходный код
	If lstrcmpi(ext, @ExtensionBas) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionBi) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionVb) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionRc) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionAsm) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	If lstrcmpi(ext, @ExtensionIni) = 0 Then
		mt.ContentType = ContentTypes.TextPlain
		mt.IsTextFormat = True
		Return mt
	End If
	
	mt.ContentType = ContentTypes.None
	Return mt
End Function
