#ifndef unicode
#define unicode
#endif

#include "Mime.bi"
#include "windows.bi"
#include "win\shlwapi.bi"

Const ParamSeparator = ";"
Const ContentCharsetUtf8 = "charset=utf-8"
Const ContentCharsetUtf16LE = "charset=utf-16"
Const ContentCharsetUtf16BE = "charset=utf-16"

Const ExtensionZip = ".zip"
Const Extension7z = ".7z"
Const ExtensionRar = ".rar"
Const ExtensionGz = ".gz"
Const ExtensionTgz = ".tgz"
Const ExtensionBin = ".bin"
Const ExtensionExe = ".exe"
Const ExtensionDll = ".dll"
Const ExtensionDeb = ".deb"
Const ExtensionDmg = ".dmg"
Const ExtensionEot = ".eot"
Const ExtensionIso = ".iso"
Const ExtensionImg = ".img"
Const ExtensionMsi = ".msi"
Const ExtensionMsp = ".msp"
Const ExtensionMsm = ".msm"
Const ExtensionCrt = ".crt"
Const ExtensionCer = ".cer"
Const ExtensionRtf = ".rtf"
Const ExtensionPdf = ".pdf"
Const ExtensionOdt = ".odt"
Const ExtensionOtt = ".ott"
Const ExtensionOdg = ".odg"
Const ExtensionOtg = ".otg"
Const ExtensionOdp = ".odp"
Const ExtensionOtp = ".otp"
Const ExtensionOds = ".ods"
Const ExtensionOts = ".ots"
Const ExtensionOdc = ".odc"
Const ExtensionOtc = ".otc"
Const ExtensionOdi = ".odi"
Const ExtensionOti = ".oti"
Const ExtensionOdf = ".odf"
Const ExtensionOtf = ".otf"
Const ExtensionOdm = ".odm"
Const ExtensionOth = ".oth"

Const ExtensionAvi = ".avi"
Const ExtensionMpg = ".mpg"
Const ExtensionMpeg = ".mpeg"
Const ExtensionMkv = ".mkv"
Const ExtensionOgv = ".ogv"
Const ExtensionMp4 = ".mp4"
Const ExtensionWebm = ".webm"
Const ExtensionSwf = ".swf"
Const ExtensionRam = ".ram"
Const ExtensionMp3 = ".mp3"
Const ExtensionWmv = ".wmv"

Const ExtensionPng = ".png"
Const ExtensionGif = ".gif"
Const ExtensionIco = ".ico"
Const ExtensionJpg = ".jpg"
Const ExtensionJpe = ".jpe"
Const ExtensionJpeg = ".jpeg"
Const ExtensionTif = ".tif"
Const ExtensionTiff = ".tiff"
Const ExtensionSvg = ".svg"

Const ExtensionHtm = ".htm"
Const ExtensionHtml = ".html"
Const ExtensionXhtml = ".xhtml"
Const ExtensionCss = ".css"
Const ExtensionTxt = ".txt"
Const ExtensionXml = ".xml"
Const ExtensionXsl = ".xsl"
Const ExtensionXslt = ".xslt"
Const ExtensionRss = ".rss"
Const ExtensionAtom = ".atom"
Const ExtensionJs = ".js"

Const ContentTypesAnyAny = "*/*"

Const ContentTypesApplicationAny = "application/*"
Const ContentTypesApplicationOctetStream = "application/octet-stream"
Const ContentTypesApplicationXml = "application/xml"
Const ContentTypesApplicationXmlXslt = "application/xml+xslt"
Const ContentTypesApplicationXhtml = "application/xhtml+xml"
Const ContentTypesApplicationAtom = "application/atom+xml"
Const ContentTypesApplicationRssXml = "application/rss+xml"
Const ContentTypesApplicationJavascript = "application/javascript"
Const ContentTypesApplicationXJavascript = "application/x-javascript"
Const ContentTypesApplicationJson = "application/json"
Const ContentTypesApplicationSoapxml = "application/soap+xml"
Const ContentTypesApplicationXmldtd = "application/xml-dtd"
Const ContentTypesApplication7z = "application/x-7z-compressed"
Const ContentTypesApplicationRar = "application/x-rar-compressed"
Const ContentTypesApplicationZip = "application/zip"
Const ContentTypesApplicationGzip = "application/x-gzip"
Const ContentTypesApplicationXCompressed = "application/x-compressed"
Const ContentTypesApplicationRtf = "application/rtf"
Const ContentTypesApplicationPdf = "application/pdf"
Const ContentTypesApplicationOpenDocumentText = "application/vnd.oasis.opendocument.text"
Const ContentTypesApplicationOpenDocumentTextTemplate = "application/vnd.oasis.opendocument.text-template"
Const ContentTypesApplicationOpenDocumentGraphics = "application/vnd.oasis.opendocument.graphics"
Const ContentTypesApplicationOpenDocumentGraphicsTemplate = "application/vnd.oasis.opendocument.graphics-template"
Const ContentTypesApplicationOpenDocumentPresentation = "application/vnd.oasis.opendocument.presentation"
Const ContentTypesApplicationOpenDocumentPresentationTemplate = "application/vnd.oasis.opendocument.presentation-template"
Const ContentTypesApplicationOpenDocumentSpreadsheet = "application/vnd.oasis.opendocument.spreadsheet"
Const ContentTypesApplicationOpenDocumentSpreadsheetTemplate = "application/vnd.oasis.opendocument.spreadsheet-template"
Const ContentTypesApplicationOpenDocumentChart = "application/vnd.oasis.opendocument.chart"
Const ContentTypesApplicationOpenDocumentChartTemplate = "application/vnd.oasis.opendocument.chart-template"
Const ContentTypesApplicationOpenDocumentImage = "application/vnd.oasis.opendocument.image"
Const ContentTypesApplicationOpenDocumentImageTemplate = "application/vnd.oasis.opendocument.image-template"
Const ContentTypesApplicationOpenDocumentFormula = "application/vnd.oasis.opendocument.formula"
Const ContentTypesApplicationOpenDocumentFormulaTemplate = "application/vnd.oasis.opendocument.formula-template"
Const ContentTypesApplicationOpenDocumentMaster = "application/vnd.oasis.opendocument.text-master"
Const ContentTypesApplicationOpenDocumentWeb = "application/vnd.oasis.opendocument.text-web"
Const ContentTypesApplicationVndmsexcel = "application/vnd.ms-excel"
Const ContentTypesApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
Const ContentTypesApplicationVndmspowerpoint = "application/vnd.ms-powerpoint"
Const ContentTypesApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
Const ContentTypesApplicationMsword = "application/msword"
Const ContentTypesApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
Const ContentTypesApplicationFontwoff = "application/font-woff"
Const ContentTypesApplicationXfontttf = "application/x-font-ttf"
Const ContentTypesApplicationXwwwformurlencoded = "application/x-www-form-urlencoded"
Const ContentTypesApplicationXbittorrent = "application/x-bittorrent"
Const ContentTypesApplicationOgg = "application/ogg"
Const ContentTypesApplicationFlash = "application/x-shockwave-flash"
Const ContentTypesApplicationCertx509 = "application/x-x509-ca-cert"

Const ContentTypesAudioAny = "audio/*"
Const ContentTypesAudioBasic = "audio/basic"
Const ContentTypesAudioL24 = "audio/L24"
Const ContentTypesAudioMp4 = "audio/mp4"
Const ContentTypesAudioAac = "audio/aac"
Const ContentTypesAudioMpeg = "audio/mpeg"
Const ContentTypesAudioOgg = "audio/ogg"
Const ContentTypesAudioVorbis = "audio/vorbis"
Const ContentTypesAudioXmswma = "audio/x-ms-wma"
Const ContentTypesAudioXmswax = "audio/x-ms-wax"
Const ContentTypesAudioRealaudio = "audio/vnd.rn-realaudio"
Const ContentTypesAudioVndwave = "audio/vnd.wave"
Const ContentTypesAudioWebm = "audio/webm"

Const ContentTypesImageAny = "image/*"
Const ContentTypesImageGif = "image/gif"
Const ContentTypesImageJpeg = "image/jpeg"
Const ContentTypesImagePJpeg = "image/pjpeg"
Const ContentTypesImagePng = "image/png"
Const ContentTypesImageSvg = "image/svg+xml"
Const ContentTypesImageTiff = "image/tiff"
Const ContentTypesImageIco = "image/vnd.microsoft.icon"
Const ContentTypesImageWbmp = "image/vnd.wap.wbmp"
Const ContentTypesImageWebp = "image/webp"

Const ContentTypesMessageAny = "message/*"
Const ContentTypesMessageHttp = "message/http"
Const ContentTypesMessageImdnxml = "message/imdn+xml"
Const ContentTypesMessagePartial = "message/partial"
Const ContentTypesMessageRfc822 = "message/rfc822"

Const ContentTypesMultipartAny = "multipart/*"
Const ContentTypesMultipartMixed = "multipart/mixed"
Const ContentTypesMultipartAlternative = "multipart/alternative"
Const ContentTypesMultipartRelated = "multipart/related"
Const ContentTypesMultipartFormdata = "multipart/form-data"
Const ContentTypesMultipartSigned = "multipart/signed"
Const ContentTypesMultipartEncrypted = "multipart/encrypted"

Const ContentTypesTextAny = "text/*"
Const ContentTypesTextCmd = "text/cmd"
Const ContentTypesTextCss = "text/css"
Const ContentTypesTextCsv = "text/csv"
Const ContentTypesTextHtml = "text/html"
Const ContentTypesTextPlain = "text/plain"
Const ContentTypesTextPhp = "text/php"
Const ContentTypesTextXml = "text/xml"

Const ContentTypesVideoAny = "video/*"
Const ContentTypesVideoMpeg = "video/mpeg"
Const ContentTypesVideoOgg = "video/ogg"
Const ContentTypesVideoMp4 = "video/mp4"
Const ContentTypesVideoQuicktime = "video/quicktime"
Const ContentTypesVideoWebm = "video/webm"
Const ContentTypesVideoXMatroska = "video/x-matroska"
Const ContentTypesVideoXMsvideo = "video/x-msvideo"
Const ContentTypesVideoXmswmv = "video/x-ms-wmv"
Const ContentTypesVideoXflv = "video/x-flv"
Const ContentTypesVideo3gpp = "video/3gpp"
Const ContentTypesVideo3gpp2 = "video/3gpp2"

Sub GetContentTypeOfMimeType( _
		ByVal ContentType As WString Ptr, _
		ByVal mt As MimeType Ptr _
	)
	
	Select Case mt->ContentType
		
		Case ContentTypes.AnyAny
			lstrcpy(ContentType, @ContentTypesAnyAny)
		
		Case ContentTypes.ImageAny
			lstrcpy(ContentType, @ContentTypesImageAny)
			
		Case ContentTypes.ImageGif
			lstrcpy(ContentType, @ContentTypesImageGif)
			
		Case ContentTypes.ImageJpeg
			lstrcpy(ContentType, @ContentTypesImageJpeg)
			
		Case ContentTypes.ImagePjpeg
			lstrcpy(ContentType, @ContentTypesImagePJpeg)
			
		Case ContentTypes.ImagePng
			lstrcpy(ContentType, @ContentTypesImagePng)
			
		Case ContentTypes.ImageSvg
			lstrcpy(ContentType, @ContentTypesImageSvg)
			
		Case ContentTypes.ImageTiff
			lstrcpy(ContentType, @ContentTypesImageTiff)
			
		Case ContentTypes.ImageIco
			lstrcpy(ContentType, @ContentTypesImageIco)
			
		Case ContentTypes.ImageWbmp
			lstrcpy(ContentType, @ContentTypesImageWbmp)
			
		Case ContentTypes.ImageWebp
			lstrcpy(ContentType, @ContentTypesImageWebp)
			
		Case ContentTypes.TextAny
			lstrcpy(ContentType, @ContentTypesTextAny)
			
		Case ContentTypes.TextCmd
			lstrcpy(ContentType, @ContentTypesTextCmd)
			
		Case ContentTypes.TextCss
			lstrcpy(ContentType, @ContentTypesTextCss)
			
		Case ContentTypes.TextCsv
			lstrcpy(ContentType, @ContentTypesTextCsv)
			
		Case ContentTypes.TextHtml
			lstrcpy(ContentType, @ContentTypesTextHtml)
			
		Case ContentTypes.TextPlain
			lstrcpy(ContentType, @ContentTypesTextPlain)
			
		Case ContentTypes.TextPhp
			lstrcpy(ContentType, @ContentTypesTextPhp)
			
		Case ContentTypes.TextXml
			lstrcpy(ContentType, @ContentTypesTextXml)
			
		Case ContentTypes.ApplicationAny
			lstrcpy(ContentType, @ContentTypesApplicationAny)
			
		Case ContentTypes.ApplicationXml
			lstrcpy(ContentType, @ContentTypesApplicationXml)
			
		Case ContentTypes.ApplicationXmlXslt
			lstrcpy(ContentType, @ContentTypesApplicationXmlXslt)
			
		Case ContentTypes.ApplicationXhtml
			lstrcpy(ContentType, @ContentTypesApplicationXhtml)
			
		Case ContentTypes.ApplicationAtom
			lstrcpy(ContentType, @ContentTypesApplicationAtom)
			
		Case ContentTypes.ApplicationRssXml
			lstrcpy(ContentType, @ContentTypesApplicationRssXml)
			
		Case ContentTypes.ApplicationJavascript
			lstrcpy(ContentType, @ContentTypesApplicationJavascript)
			
		Case ContentTypes.ApplicationXJavascript
			lstrcpy(ContentType, @ContentTypesApplicationXJavascript)
			
		Case ContentTypes.ApplicationJson
			lstrcpy(ContentType, @ContentTypesApplicationJson)
			
		Case ContentTypes.ApplicationSoapxml
			lstrcpy(ContentType, @ContentTypesApplicationSoapxml)
			
		Case ContentTypes.ApplicationXmldtd
			lstrcpy(ContentType, @ContentTypesApplicationXmldtd)
			
		Case ContentTypes.Application7z
			lstrcpy(ContentType, @ContentTypesApplication7z)
			
		Case ContentTypes.ApplicationRar
			lstrcpy(ContentType, @ContentTypesApplicationRar)
			
		Case ContentTypes.ApplicationZip
			lstrcpy(ContentType, @ContentTypesApplicationZip)
			
		Case ContentTypes.ApplicationGzip
			lstrcpy(ContentType, @ContentTypesApplicationGzip)
			
		Case ContentTypes.ApplicationXCompressed
			lstrcpy(ContentType, @ContentTypesApplicationXCompressed)
			
		Case ContentTypes.ApplicationRtf
			lstrcpy(ContentType, @ContentTypesApplicationRtf)
			
		Case ContentTypes.ApplicationPdf
			lstrcpy(ContentType, @ContentTypesApplicationPdf)
			
		Case ContentTypes.ApplicationOpenDocumentText
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentText)
			
		Case ContentTypes.ApplicationOpenDocumentTextTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentTextTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentGraphics
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentGraphics)
			
		Case ContentTypes.ApplicationOpenDocumentGraphicsTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentGraphicsTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentPresentation
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentPresentation)
			
		Case ContentTypes.ApplicationOpenDocumentPresentationTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentPresentationTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentSpreadsheet
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentSpreadsheet)
			
		Case ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentSpreadsheetTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentChart
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentChart)
			
		Case ContentTypes.ApplicationOpenDocumentChartTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentChartTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentImage
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentImage)
			
		Case ContentTypes.ApplicationOpenDocumentImageTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentImageTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentFormula
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentFormula)
			
		Case ContentTypes.ApplicationOpenDocumentFormulaTemplate
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentFormulaTemplate)
			
		Case ContentTypes.ApplicationOpenDocumentMaster
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentMaster)
			
		Case ContentTypes.ApplicationOpenDocumentWeb
			lstrcpy(ContentType, @ContentTypesApplicationOpenDocumentWeb)
			
		Case ContentTypes.ApplicationVndmsexcel
			lstrcpy(ContentType, @ContentTypesApplicationVndmsexcel)
			
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet
			lstrcpy(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet)
			
		Case ContentTypes.ApplicationVndmspowerpoint
			lstrcpy(ContentType, @ContentTypesApplicationVndmspowerpoint)
			
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation
			lstrcpy(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation)
			
		Case ContentTypes.ApplicationMsword
			lstrcpy(ContentType, @ContentTypesApplicationMsword)
			
		Case ContentTypes.ApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument
			lstrcpy(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument)
			
		Case ContentTypes.ApplicationFontwoff
			lstrcpy(ContentType, @ContentTypesApplicationFontwoff)
			
		Case ContentTypes.ApplicationXfontttf
			lstrcpy(ContentType, @ContentTypesApplicationXfontttf)
			
		Case ContentTypes.ApplicationXwwwformurlencoded
			lstrcpy(ContentType, @ContentTypesApplicationXwwwformurlencoded)
			
		Case ContentTypes.ApplicationOctetStream
			lstrcpy(ContentType, @ContentTypesApplicationOctetStream)
			
		Case ContentTypes.ApplicationXbittorrent
			lstrcpy(ContentType, @ContentTypesApplicationXbittorrent)
			
		Case ContentTypes.ApplicationOgg
			lstrcpy(ContentType, @ContentTypesApplicationOgg)
			
		Case ContentTypes.ApplicationFlash
			lstrcpy(ContentType, @ContentTypesApplicationFlash)
			
		Case ContentTypes.ApplicationCertx509
			lstrcpy(ContentType, @ContentTypesApplicationCertx509)
			
		Case ContentTypes.AudioAny
			lstrcpy(ContentType, @ContentTypesAudioAny)
			
		Case ContentTypes.AudioBasic
			lstrcpy(ContentType, @ContentTypesAudioBasic)
			
		Case ContentTypes.AudioL24
			lstrcpy(ContentType, @ContentTypesAudioL24)
			
		Case ContentTypes.AudioMp4
			lstrcpy(ContentType, @ContentTypesAudioMp4)
			
		Case ContentTypes.AudioAac
			lstrcpy(ContentType, @ContentTypesAudioAac)
			
		Case ContentTypes.AudioMpeg
			lstrcpy(ContentType, @ContentTypesAudioMpeg)
			
		Case ContentTypes.AudioOgg
			lstrcpy(ContentType, @ContentTypesAudioOgg)
			
		Case ContentTypes.AudioVorbis
			lstrcpy(ContentType, @ContentTypesAudioVorbis)
			
		Case ContentTypes.AudioXmswma
			lstrcpy(ContentType, @ContentTypesAudioXmswma)
			
		Case ContentTypes.AudioXmswax
			lstrcpy(ContentType, @ContentTypesAudioXmswax)
			
		Case ContentTypes.AudioRealaudio
			lstrcpy(ContentType, @ContentTypesAudioRealaudio)
			
		Case ContentTypes.AudioVndwave
			lstrcpy(ContentType, @ContentTypesAudioVndwave)
			
		Case ContentTypes.AudioWebm
			lstrcpy(ContentType, @ContentTypesAudioWebm)
			
		Case ContentTypes.MessageAny
			lstrcpy(ContentType, @ContentTypesMessageAny)
			
		Case ContentTypes.MessageHttp
			lstrcpy(ContentType, @ContentTypesMessageHttp)
			
		Case ContentTypes.MessageImdnxml
			lstrcpy(ContentType, @ContentTypesMessageImdnxml)
			
		Case ContentTypes.MessagePartial
			lstrcpy(ContentType, @ContentTypesMessagePartial)
			
		Case ContentTypes.MessageRfc822
			lstrcpy(ContentType, @ContentTypesMessageRfc822)
			
		Case ContentTypes.VideoAny
			lstrcpy(ContentType, @ContentTypesVideoAny)
			
		Case ContentTypes.VideoMpeg
			lstrcpy(ContentType, @ContentTypesVideoMpeg)
			
		Case ContentTypes.VideoOgg
			lstrcpy(ContentType, @ContentTypesVideoOgg)
			
		Case ContentTypes.VideoMp4
			lstrcpy(ContentType, @ContentTypesVideoMp4)
			
		Case ContentTypes.VideoQuicktime
			lstrcpy(ContentType, @ContentTypesVideoQuicktime)
			
		Case ContentTypes.VideoWebm
			lstrcpy(ContentType, @ContentTypesVideoWebm)
			
		Case ContentTypes.VideoXmswmv
			lstrcpy(ContentType, @ContentTypesVideoXmswmv)
			
		Case ContentTypes.VideoXflv
			lstrcpy(ContentType, @ContentTypesVideoXflv)
			
		Case ContentTypes.VideoXMatroska
			lstrcpy(ContentType, @ContentTypesVideoXMatroska)
			
		Case ContentTypes.VideoXMsvideo
			lstrcpy(ContentType, @ContentTypesVideoXMsvideo)
			
		Case ContentTypes.Video3gpp
			lstrcpy(ContentType, @ContentTypesVideo3gpp)
			
		Case ContentTypes.Video3gpp2
			lstrcpy(ContentType, @ContentTypesVideo3gpp2)
			
		Case ContentTypes.MultipartAny
			lstrcpy(ContentType, @ContentTypesMultipartAny)
			
		Case ContentTypes.MultipartMixed
			lstrcpy(ContentType, @ContentTypesMultipartMixed)
			
		Case ContentTypes.MultipartAlternative
			lstrcpy(ContentType, @ContentTypesMultipartAlternative)
			
		Case ContentTypes.MultipartRelated
			lstrcpy(ContentType, @ContentTypesMultipartRelated)
			
		Case ContentTypes.MultipartFormdata
			lstrcpy(ContentType, @ContentTypesMultipartFormdata)
			
		Case ContentTypes.MultipartSigned
			lstrcpy(ContentType, @ContentTypesMultipartSigned)
			
		Case ContentTypes.MultipartEncrypted
			lstrcpy(ContentType, @ContentTypesMultipartEncrypted)
			
		Case Else
			lstrcpy(ContentType, @ContentTypesApplicationOctetStream)
			
	End Select
	
	Select Case mt->Charset
		
		Case DocumentCharsets.Utf8BOM
			lstrcat(ContentType, @ParamSeparator)
			lstrcat(ContentType, @ContentCharsetUtf8)
			
		Case DocumentCharsets.Utf16LE
			lstrcat(ContentType, @ParamSeparator)
			lstrcat(ContentType, @ContentCharsetUtf16LE)
			
		Case DocumentCharsets.Utf16BE
			lstrcat(ContentType, @ParamSeparator)
			lstrcat(ContentType, @ContentCharsetUtf16BE)
			
	End Select
	
End Sub

Function GetMimeOfFileExtension( _
		ByVal mt As MimeType Ptr, _
		ByVal ext As WString Ptr _
	)As Boolean
	
	mt->IsTextFormat = False
	mt->Charset = DocumentCharsets.ASCII
	
	If lstrcmpi(ext, @ExtensionHtm) = 0 Then
		mt->ContentType = ContentTypes.TextHtml
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionXhtml) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXhtml
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionCss) = 0 Then
		mt->ContentType = ContentTypes.TextCss
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionPng) = 0 Then
		mt->ContentType = ContentTypes.ImagePng
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionGif) = 0 Then
		mt->ContentType = ContentTypes.ImageGif
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionJpg) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionIco) = 0 Then
		mt->ContentType = ContentTypes.ImageIco
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionXml) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXml
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionXsl) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXmlXslt
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionXslt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXmlXslt
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionTxt) = 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionRss) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRssXml
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionJs) = 0 Then
		mt->ContentType = ContentTypes.ApplicationJavascript
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionZip) = 0 Then
		mt->ContentType = ContentTypes.ApplicationZip
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionHtml) = 0 Then
		mt->ContentType = ContentTypes.TextHtml
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionSvg) = 0 Then
		mt->ContentType = ContentTypes.ImageSvg
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionJpe) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionJpeg) = 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionTif) = 0 Then
		mt->ContentType = ContentTypes.ImageTiff
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionTiff) = 0 Then
		mt->ContentType = ContentTypes.ImageTiff
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionAtom) = 0 Then
		mt->ContentType = ContentTypes.ApplicationAtom
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @Extension7z) = 0 Then
		mt->ContentType = ContentTypes.Application7z
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionRar) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRar
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionGz) = 0 Then
		mt->ContentType = ContentTypes.ApplicationGzip
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionTgz) = 0 Then
		mt->ContentType = ContentTypes.ApplicationXCompressed
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionRtf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationRtf
		mt->IsTextFormat = True
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMp3) = 0 Then
		mt->ContentType = ContentTypes.AudioMpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMpg) = 0 Then
		mt->ContentType = ContentTypes.VideoMpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMpeg) = 0 Then
		mt->ContentType = ContentTypes.VideoMpeg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMkv) = 0 Then
		mt->ContentType = ContentTypes.VideoXMatroska
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionAvi) = 0 Then
		mt->ContentType = ContentTypes.VideoXMsvideo
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOgv) = 0 Then
		mt->ContentType = ContentTypes.VideoOgg
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMp4) = 0 Then
		mt->ContentType = ContentTypes.VideoMp4
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionWebm) = 0 Then
		mt->ContentType = ContentTypes.VideoWebm
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionWmv) = 0 Then
		mt->ContentType = ContentTypes.VideoXmswmv
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionBin) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionExe) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionDll) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionDeb) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionDmg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionEot) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionIso) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionImg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMsi) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMsp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionMsm) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionSwf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationFlash
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionRam) = 0 Then
		mt->ContentType = ContentTypes.AudioRealaudio
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionCrt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationCertx509
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionCer) = 0 Then
		mt->ContentType = ContentTypes.ApplicationCertx509
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionPdf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationPdf
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentText
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOtt) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentTextTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphics
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOtg) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphicsTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentation
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOtp) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentationTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOds) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheet
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOts) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdc) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChart
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOtc) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChartTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdi) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImage
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOti) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImageTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormula
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOtf) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormulaTemplate
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOdm) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentMaster
		Return True
	End If
	
	If lstrcmpi(ext, @ExtensionOth) = 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentWeb
		Return True
	End If
	
	Return False
End Function

Function GetMimeOfStringContentType( _
		ByVal mt As MimeType Ptr, _
		ByVal ContentType As WString Ptr _
	)As Boolean
	
	mt->IsTextFormat = False
	
	If StrStrI(ContentType, @ContentCharsetUtf8) <> 0 Then
		mt->Charset = DocumentCharsets.Utf8BOM
	Else
		If StrStrI(ContentType, @ContentCharsetUtf16LE) <> 0 Then
			mt->Charset = DocumentCharsets.Utf16LE
		Else
			If StrStrI(ContentType, @ContentCharsetUtf16BE) <> 0 Then
				mt->Charset = DocumentCharsets.Utf16BE
			Else
				mt->Charset = DocumentCharsets.ASCII
			End If
		End If
	End If
	
	If StrStrI(ContentType, @ContentTypesAnyAny) <> 0 Then
		mt->ContentType = ContentTypes.AnyAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationAny) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplication7z) <> 0 Then
		mt->ContentType = ContentTypes.Application7z
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationAtom) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationAtom
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationCertx509) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationCertx509
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationFlash) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationFlash
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationFontwoff) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationFontwoff
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationGzip) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationGzip
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationJavascript) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationJavascript
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationJson) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationJson
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationMsword) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationMsword
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOctetStream) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOctetStream
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOgg) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOgg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentChart) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChart
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentChartTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentChartTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentFormula) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormula
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentFormulaTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentFormulaTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentGraphics) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphics
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentGraphicsTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentGraphicsTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentImage) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImage
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentImageTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentImageTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentMaster) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentMaster
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentPresentation) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentation
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentPresentationTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentPresentationTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentSpreadsheet) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheet
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentSpreadsheetTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentSpreadsheetTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentText) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentText
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentTextTemplate) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentTextTemplate
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationOpenDocumentWeb) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationOpenDocumentWeb
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationPdf) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationPdf
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationRar) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationRar
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationRssXml) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationRssXml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationRtf) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationRtf
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationSoapxml) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationSoapxml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationVndmsexcel) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationVndmsexcel
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationVndmspowerpoint) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationVndmspowerpoint
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXbittorrent) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXbittorrent
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXCompressed) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXCompressed
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXfontttf) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXfontttf
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXhtml) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXhtml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXJavascript) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXJavascript
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXml) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXmldtd) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXmldtd
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXmlXslt) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXmlXslt
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationXwwwformurlencoded) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationXwwwformurlencoded
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesApplicationZip) <> 0 Then
		mt->ContentType = ContentTypes.ApplicationZip
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioAny) <> 0 Then
		mt->ContentType = ContentTypes.AudioAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioAac) <> 0 Then
		mt->ContentType = ContentTypes.AudioAac
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioBasic) <> 0 Then
		mt->ContentType = ContentTypes.AudioBasic
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioBasic) <> 0 Then
		mt->ContentType = ContentTypes.AudioBasic
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioL24) <> 0 Then
		mt->ContentType = ContentTypes.AudioL24
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioMp4) <> 0 Then
		mt->ContentType = ContentTypes.AudioMp4
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioMpeg) <> 0 Then
		mt->ContentType = ContentTypes.AudioMpeg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioOgg) <> 0 Then
		mt->ContentType = ContentTypes.AudioOgg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioRealaudio) <> 0 Then
		mt->ContentType = ContentTypes.AudioRealaudio
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioVndwave) <> 0 Then
		mt->ContentType = ContentTypes.AudioVndwave
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioVorbis) <> 0 Then
		mt->ContentType = ContentTypes.AudioVorbis
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioWebm) <> 0 Then
		mt->ContentType = ContentTypes.AudioWebm
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioXmswma) <> 0 Then
		mt->ContentType = ContentTypes.AudioXmswma
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesAudioXmswax) <> 0 Then
		mt->ContentType = ContentTypes.AudioXmswax
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageAny) <> 0 Then
		mt->ContentType = ContentTypes.ImageAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageGif) <> 0 Then
		mt->ContentType = ContentTypes.ImageGif
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageIco) <> 0 Then
		mt->ContentType = ContentTypes.ImageIco
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageJpeg) <> 0 Then
		mt->ContentType = ContentTypes.ImageJpeg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImagePJpeg) <> 0 Then
		mt->ContentType = ContentTypes.ImagePjpeg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImagePng) <> 0 Then
		mt->ContentType = ContentTypes.ImagePng
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageSvg) <> 0 Then
		mt->ContentType = ContentTypes.ImageSvg
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageTiff) <> 0 Then
		mt->ContentType = ContentTypes.ImageTiff
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageWbmp) <> 0 Then
		mt->ContentType = ContentTypes.ImageWbmp
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesImageWebp) <> 0 Then
		mt->ContentType = ContentTypes.ImageWebp
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMessageAny) <> 0 Then
		mt->ContentType = ContentTypes.MessageAny
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMessageHttp) <> 0 Then
		mt->ContentType = ContentTypes.MessageHttp
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMessageImdnxml) <> 0 Then
		mt->ContentType = ContentTypes.MessageImdnxml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMessagePartial) <> 0 Then
		mt->ContentType = ContentTypes.MessagePartial
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMessageRfc822) <> 0 Then
		mt->ContentType = ContentTypes.MessageRfc822
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartAny) <> 0 Then
		mt->ContentType = ContentTypes.MultipartAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartAlternative) <> 0 Then
		mt->ContentType = ContentTypes.MultipartAlternative
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartEncrypted) <> 0 Then
		mt->ContentType = ContentTypes.MultipartEncrypted
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartFormdata) <> 0 Then
		mt->ContentType = ContentTypes.MultipartFormdata
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartMixed) <> 0 Then
		mt->ContentType = ContentTypes.MultipartMixed
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartRelated) <> 0 Then
		mt->ContentType = ContentTypes.MultipartRelated
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesMultipartSigned) <> 0 Then
		mt->ContentType = ContentTypes.MultipartSigned
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextAny) <> 0 Then
		mt->ContentType = ContentTypes.TextAny
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextCmd) <> 0 Then
		mt->ContentType = ContentTypes.TextCmd
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextCss) <> 0 Then
		mt->ContentType = ContentTypes.TextCss
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextCsv) <> 0 Then
		mt->ContentType = ContentTypes.TextCsv
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextHtml) <> 0 Then
		mt->ContentType = ContentTypes.TextHtml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextPlain) <> 0 Then
		mt->ContentType = ContentTypes.TextPlain
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextPhp) <> 0 Then
		mt->ContentType = ContentTypes.TextPhp
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesTextXml) <> 0 Then
		mt->ContentType = ContentTypes.TextXml
		mt->IsTextFormat = True
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoAny) <> 0 Then
		mt->ContentType = ContentTypes.VideoAny
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideo3gpp) <> 0 Then
		mt->ContentType = ContentTypes.Video3gpp
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideo3gpp2) <> 0 Then
		mt->ContentType = ContentTypes.Video3gpp2
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoQuicktime) <> 0 Then
		mt->ContentType = ContentTypes.VideoQuicktime
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoMp4) <> 0 Then
		mt->ContentType = ContentTypes.VideoMp4
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoMpeg) <> 0 Then
		mt->ContentType = ContentTypes.VideoMpeg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoOgg) <> 0 Then
		mt->ContentType = ContentTypes.VideoOgg
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoXflv) <> 0 Then
		mt->ContentType = ContentTypes.VideoXflv
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoWebm) <> 0 Then
		mt->ContentType = ContentTypes.VideoWebm
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoXMatroska) <> 0 Then
		mt->ContentType = ContentTypes.VideoXMatroska
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoXMsvideo) <> 0 Then
		mt->ContentType = ContentTypes.VideoXMsvideo
		Return True
	End If
	
	If StrStrI(ContentType, @ContentTypesVideoXmswmv) <> 0 Then
		mt->ContentType = ContentTypes.VideoXmswmv
		Return True
	End If
	
	Return False
End Function
