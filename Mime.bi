' Размер буфера для записи в него типа документа
Const MaxContentTypeLength As Integer = 127

' Миме‐типы
' При добавлении нового типа необходимо изменять функцию GetStringOfContentType чтобы не было неопределённого поведения
Enum ContentTypes
	None
	
	' Изображения
	ImageGif
	ImageJpeg
	ImagePjpeg
	ImagePng
	ImageSvg
	ImageTiff
	ImageIco
	ImageWbmp
	ImageWebp
	
	' Текст
	TextCmd
	TextCss
	TextCsv
	TextHtml
	TextPlain
	TextPhp
	TextXml
	
	' Xml как текст
	ApplicationXml
	ApplicationXmlXslt
	ApplicationXhtml
	ApplicationAtom
	ApplicationRssXml
	ApplicationJavascript
	ApplicationXJavascript
	ApplicationJson
	ApplicationSoapxml
	ApplicationXmldtd
	
	' Архивы
	Application7z
	ApplicationRar
	ApplicationZip
	ApplicationGzip
	ApplicationXCompressed
	
	' Документы
	ApplicationRtf
	ApplicationPdf
	ApplicationOpenDocumentText
	ApplicationOpenDocumentTextTemplate
	ApplicationOpenDocumentGraphics
	ApplicationOpenDocumentGraphicsTemplate
	ApplicationOpenDocumentPresentation
	ApplicationOpenDocumentPresentationTemplate
	ApplicationOpenDocumentSpreadsheet
	ApplicationOpenDocumentSpreadsheetTemplate
	ApplicationOpenDocumentChart
	ApplicationOpenDocumentChartTemplate
	ApplicationOpenDocumentImage
	ApplicationOpenDocumentImageTemplate
	ApplicationOpenDocumentFormula
	ApplicationOpenDocumentFormulaTemplate
	ApplicationOpenDocumentMaster
	ApplicationOpenDocumentWeb
	ApplicationVndmsexcel
	ApplicationVndopenxmlformatsofficedocumentspreadsheetmlsheet
	ApplicationVndmspowerpoint
	ApplicationVndopenxmlformatsofficedocumentpresentationmlpresentation
	ApplicationMsword
	ApplicationVndopenxmlformatsofficedocumentwordprocessingmldocument
	ApplicationFontwoff
	ApplicationXfontttf
	
	' Аудио
	AudioBasic
	AudioL24
	AudioMp4
	AudioAac
	AudioMpeg
	AudioOgg
	AudioVorbis
	AudioXmswma
	AudioXmswax
	AudioRealaudio
	AudioVndwave
	AudioWebm
	
	' Видео
	VideoMpeg
	VideoOgg
	VideoMp4
	VideoQuicktime
	VideoWebm
	VideoXmswmv
	VideoXflv
	Video3gpp
	Video3gpp2
	
	' Сообщения
	MessageHttp
	MessageImdnxml
	MessagePartial
	MessageRfc822
	
	' Данные формы
	MultipartMixed
	MultipartAlternative
	MultipartRelated
	MultipartFormdata
	MultipartSigned
	MultipartEncrypted
	ApplicationXwwwformurlencoded
	
	ApplicationFlash
	
	ApplicationOctetStream
	ApplicationXbittorrent
	ApplicationOgg
	
	ApplicationCertx509
End Enum

' Тип документа
Type MimeType
	Dim ContentType As ContentTypes
	Dim IsTextFormat As Boolean
End Type

' Возвращает тип документа в зависимости от расширения файла
Declare Function GetMimeTypeOfExtension(ByVal ext As WString Ptr)As MimeType

' TODO Реализовать функцию, возвращающую тип документа в зависимости от миме‐типа
Declare Function GetMimeTypeOfContentType(ByVal ContentType As WString Ptr)As MimeType

' Заполняет буфер строкой с типом документа
Declare Sub GetStringOfContentType(ByVal Buffer As WString Ptr, ByVal ContentType As ContentTypes)
