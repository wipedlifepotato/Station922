#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shlwapi.bi"
#include once "win\shellapi.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

#include once "Network.bi"
#include once "HttpConst.bi"
#include once "base64.bi"

/'
	
	Соглашение по коду
	В функциях строки передаются как ByVal As WString Ptr
	
'/

Declare Function itow cdecl Alias "_itow" (ByVal Value As Integer, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr
Declare Function ltow cdecl Alias "_ltow" (ByVal Value As Long, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr
Declare Function wtoi cdecl Alias "_wtoi" (ByVal src As WString Ptr)As Integer
Declare Function wtol cdecl Alias "_wtol" (ByVal src As WString Ptr)As Long
REM Declare Function memcpy cdecl Alias "_memcpy" (ByVal dest As Any Ptr, ByVal src As Any Ptr, ByVal count As Integer)As Any Ptr

Const NewLineString = !"\r\n"
Const SpaceString = " "
Const ColonString = ":"
Const ColonWithSpaceString = ": "
Const SlashString = "/"
Const DotDotString = ".."
Const DateFormatString = "ddd, dd MMM yyyy "
Const LogDateFormatString = "yyyy.MM.dd.LOG"
Const TimeFormatString = "HH:mm:ss GMT"
Const ServerErrorString = "Серверная"
Const ClientErrorString = "Клиентская"

Const UsersIniFileString = "users.config"
Const WebSitesIniFileString = "WebSites.ini"
Const WebServerIniFileString = "WebServer.ini"
Const LogDirectoryString = "logs"
Const WebServerSectionString = "WebServer"
Const ListenAddressSectionString = "ListenAddress"
Const PortSectionString = "Port"
Const DefaultAddressString = "localhost"
Const DefaultHttpPort = "80"
Const ConnectBindAddressSectionString = "ConnectBindAddress"
Const ConnectBindPortSectionString = "ConnectBindPort"
Const ConnectBindDefaultPort = "0"
Const VirtualPathSectionString = "VirtualPath"
Const PhisycalDirSectionString = "PhisycalDir"
Const IsMovedSectionString = "IsMoved"
Const MovedUrlSectionString = "MovedUrl"
Const AdministratorsSectionString = "admins"

Const ErrorInvalidSocket = !"Получил INVALID_SOCKET от клиента\r\n"

' Максимальное количество одновременно выполняющихся потоков
Const MaxThreadsCount As Integer = 4096

' Максимальный размер отправленного клиентом тела запроса
Const MaxRequestBodyContentLength As Long = 20 * 1024 * 1024
' Размер буфера в символах для записи в него кода html страницы с ошибкой
Const MaxHttpErrorBuffer As Integer = 16 * 1024 - 1
' Размер буфера для записи в него типа документа
Const MaxContentTypeBuffer As Integer = 127

' Версии протокола http
Enum HttpVersions
	Http11
	Http10
	Http09
End Enum

' Методы Http
Enum HttpMethods
	None
	HttpGet
	HttpHead
	HttpPut
	HttpDelete
	HttpOptions
	HttpTrace
	HttpConnect
	HttpPatch
	HttpPost
	HttpCopy
	HttpMove
	HttpPropfind
End Enum

' Миме‐типы
' При добавлении нового типа необходимо изменять функцию ContentTypesToString чтобы не было неопределённого поведения
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

' Кодировка документа
Enum DocumentCharsets
	ASCII
	Utf8BOM
	Utf16LE
	Utf16BE
End Enum

' Флаги сжатия содержимого
Enum ZipModes
	' Без сжатия
	None
	' Сжатие Deflate
	Deflate
	' Сжатие GZip
	GZip
End Enum

Enum ParseRequestLineResult
	' Ошибок нет
	Success
	' Версия протокола не поддерживается
	HTTPVersionNotSupported
	' Метод не поддерживается сервером
	MethodNotSupported
	' Нужен заголовок Host
	HostRequired
	' Фальшивый Host
	BadHost
	' Ошибка в запросе, синтаксисе запроса
	BadRequest
	' Плохой путь
	BadPath
	' Клиент закрыл соединение
	EmptyRequest
	' Url слишком длинный
	RequestUrlTooLong
	' Превышена допустимая длина заголовков
	RequestHeaderFieldsTooLarge 
End Enum

Enum HttpAuthResult
	' Аутентификация успешно пройдена
	Success
	' Требуется авторизация
	NeedAuth
	' Параметры авторизации неверны
	BadAuth
	' Необходимо использовать Basic‐авторизацию
	NeedBasicAuth
	' Пароль не может быть пустым
	EmptyPassword
	' Имя пользователя или пароль не подходят
	BadUserNamePassword
End Enum

' Индексы заголовков в массиве заголовков запроса
Enum HttpRequestHeaderIndices
	HeaderAccept
	HeaderAcceptCharset
	HeaderAcceptEncoding
	HeaderAcceptLanguage
	HeaderAuthorization
	HeaderCacheControl
	HeaderConnection
	HeaderContentEncoding
	HeaderContentLanguage
	HeaderContentLength
	HeaderContentMd5
	HeaderContentRange
	HeaderContentType
	HeaderCookie
	HeaderExpect
	HeaderFrom
	HeaderHost
	HeaderIfMatch
	HeaderIfModifiedSince
	HeaderIfNoneMatch
	HeaderIfRange
	HeaderIfUnmodifiedSince
	HeaderKeepAlive
	HeaderMaxForwards
	HeaderPragma
	HeaderProxyAuthorization
	HeaderRange
	HeaderReferer
	HeaderTe
	HeaderTrailer
	HeaderTransferEncoding
	HeaderUpgrade
	HeaderUserAgent
	HeaderVia
	HeaderWarning
End Enum

' Индексы заголовков в массиве заголовков ответа
Enum HttpResponseHeaderIndices
	HeaderAcceptRanges				'
	HeaderAge								'
	HeaderAllow							'
	HeaderCacheControl				'
	HeaderConnection
	HeaderContentEncoding			'
	HeaderContentLanguage			'
	HeaderContentLength
	HeaderContentLocation			'
	HeaderContentMd5					'
	HeaderContentRange				'
	HeaderContentType				'
	HeaderDate
	HeaderETag								'
	HeaderExpires						'
	HeaderKeepAlive
	HeaderLastModified				'
	HeaderLocation						'
	HeaderPragma							'
	HeaderProxyAuthenticate		'
	HeaderRetryAfter					'
	HeaderServer
	HeaderSetCookie					'
	HeaderTrailer							'
	HeaderTransferEncoding
	HeaderUpgrade						'
	HeaderVary
	HeaderVia								'
	HeaderWarning						'
	HeaderWwwAuthenticate		'
End Enum

' Параметр в процедуре потока
Type ThreadParam
	' Флаг занятости участка памяти
	Dim IsUsed As Boolean
	' Клиентский и серверный сокеты
	Dim ClientSocket As SOCKET
	Dim ServerSocket As SOCKET
	Dim RemoteAddress As SOCKADDR_IN
	Dim RemoteAddressLength As Integer
	' Идентификаторы ввода‐вывода
	Dim hOutput As Handle
	' Идентификатор потока
	Dim ThreadId As DWord
	Dim hThread As HANDLE
	' Папка с программой
	Dim ExeDir As WString Ptr
End Type

' Диапазон байт запроса
Type ByteRange
	Dim StartIndex As Integer
	Dim Count As Integer
End Type

' Результат чтения данных от клиента
Type ReadLineResult
	Dim wLine As WString Ptr
	Dim ErrorStatus As ParseRequestLineResult
End Type

' Сайт на сервере
Type WebSite
	Const MaxHostNameLength As Integer = 1023
	Dim HostName As WString * (MaxHostNameLength + 1)
	Dim PhysicalDirectory As WString * (MAX_PATH + 1)
	Dim VirtualPath As WString * (MaxHostNameLength + 1)
	Dim IsMoved As Boolean
	Dim MovedUrl As WString * (MaxHostNameLength + 1)
	REM Dim ServerCertificate As WString Ptr
End Type

' Тип документа
Type MimeType
	Dim ContentType As ContentTypes
	Dim IsTextFormat As Boolean
End Type

' Результат чтения заголовков запроса
Type ReadHeadersResult
	' Максимальное количество байт в запросе клиента
	Const MaxRequestHeaderBytes As Integer = 16 * 1024 - 1
	' Размер буфера для строки с заголовками запроса в символах (не включая нулевой)
	Const MaxRequestHeaderBuffer As Integer = 16 * 1024 - 1
	' Размер буфера для строки с заголовками ответа в символах (не включая нулевой)
	Const MaxResponseHeaderBuffer As Integer = 16 * 1024 - 1
	' Максимальное количество заголовков запроса
	Const RequestHeaderMaximum As Integer = 36
	' Максимальное количество заголовков ответа
	Const ResponseHeaderMaximum As Integer = 30
	' Максимальная длина Url
	Const MaxUrlLength As Integer = 4095
	' Максимальная длина пути к файлу
	Const MaxFilePathLength As Integer = MaxUrlLength + 32
	' Максимальная длина пути к файлу
	Const MaxFilePathTranslatedLength As Integer = MaxFilePathLength + 256
	
	' Буфер запроса клиента (заголовок + частично тело), с дополнительным местом для нулевого байта
	Dim HeaderBytes As ZString * (MaxRequestHeaderBytes + 1)
	' Количество байт запроса клиента
	Dim HeaderBytesLength As Integer
	' Индекс первого байта после конца заголовков HTTP (конец заголовков + пустая строка)
	' После чтения запроса клиента будет указывать на начало тела запроса (если оно есть)
	Dim EndHeadersOffset As Integer
	
	' Буфер заголовков запроса клиента
	Dim RequestHeaderBuffer As WString * (MaxRequestHeaderBuffer + 1)
	' Длина буфера запроса клиента
	Dim RequestHeaderBufferLength As Integer
	' Буфер дополнительных заголовков ответа
	Dim ResponseHeaderBuffer As WString * (MaxResponseHeaderBuffer + 1)
	' Указатель на свободное место в буфере заголовков ответа
	Dim StartResponseHeadersPtr As WString Ptr
	' Распознанные заголовки запроса
	Dim RequestHeaders(RequestHeaderMaximum - 1) As WString Ptr
	' Заголовки ответа
	Dim ResponseHeaders(ResponseHeaderMaximum - 1) As WString Ptr
	
	' Строка состояния
	Dim StatusDescription As WString Ptr
	
	' Версия http‐протокола
	Dim HttpVersion As HttpVersions
	' Метод HTTP
	Dim HttpMethod As HttpMethods
	' Запрошенный клиентом адрес
	Dim Url As WString Ptr
	
	' Путь, указанный клиентом (без строки запроса и раскодированный)
	Dim Path As WString * (MaxUrlLength + 1)
	' Строка запроса
	Dim QueryString As WString Ptr
	' Путь к файлу
	Dim FilePath As WString * (MaxFilePathLength + 1)
	' Путь к файлу на диске
	Dim PathTranslated As WString * (MaxFilePathTranslatedLength + 1)
	
	' Код ответа клиенту
	Dim StatusCode As Integer
	' Отправлять клиенту только заголовки
	Dim SendOnlyHeaders As Boolean
	' Поддерживать соединение с клиентом
	Dim KeepAlive As Boolean
	' Сжатие данных
	Dim ZipEnabled As ZipModes
	
	' Указатель на строку с папкой программы
	Dim ExeDir As WString Ptr
	
	' Добавляет заголовки компрессии gzip или deflate и возвращает идентификатор открытого файла
	Declare Function AddResponseCompressionMethodHeader(ByVal mt As MimeType Ptr)As Handle
	
	' Добавляет заголовки кеширования для файла и проверяет совпадение на заголовки кэширования
	Declare Sub AddResponseCacheHeaders(ByVal hFile As HANDLE)
	
	' Добавляет любой другой заголовок к заголовкам ответа
	Declare Sub AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	
	' Устанавливает описание кода ответа
	Declare Sub SetStatusDescription(ByVal Description As WString Ptr)
	
	' Добавляет заголовок в массив заголовков запроса клиента
	Declare Sub AddRequestHeader(ByVal Header As WString Ptr, ByVal Value As WString Ptr)
	
	' Читает строку от клиента
	Declare Sub ReadLine(ByVal wResult As ReadLineResult Ptr, ByVal ClientSocket As SOCKET)
	
	' Читает заголовки запроса
	Declare Function ReadAllHeaders(ByVal ClientSocket As SOCKET)As ParseRequestLineResult
	
	' Проверяет авторизацию Http
	Declare Function HttpAuth(ByVal PhysicalDirectory As WString Ptr)As HttpAuthResult
	
	' Заполняет буфер строкой с заголовками ответа
	' Возвращает длину буфера в символах (без учёта нулевого)
	Declare Function MakeResponseHeaders(ByVal Buffer As ZString Ptr, ByVal ContentLength As Long, ByVal hOutput As Handle)As Integer
	
	' Получает путь к файлу на диске
	Declare Sub GetFilePath(ByVal strPhysicalDirectory As WString Ptr)
	
End Type

' Инкапсуляция клиентского и серверного сокетов как параметр для процедуры потока
Type ClientServerSocket
	Dim OutSock As SOCKET
	Dim InSock As SOCKET
	Dim ThreadId As DWord
	Dim hThread As HANDLE
End Type

' Точка входа
Declare Function EntryPoint Alias "EntryPoint"()As Integer

' Функция сервисного потока
#ifdef service
Declare Function ServiceProc(ByVal lpParam As LPVOID)As DWORD
#endif

' Процедура потока
Declare Function ThreadProc(ByVal lpParam As LPVOID)As DWORD

' Проверяет существование сайта
Declare Function WebSiteExists(ByVal ExeDir As WString Ptr, ByVal wSiteName As WString Ptr)As Boolean

' Заполняет сайт по имени хоста
Declare Sub GetWebSite(ByVal ExeDir As WString Ptr, ByVal site As WebSite Ptr, ByVal HostName As WString Ptr)

' Проверяет путь на запрещённые символы
Declare Function IsBadPath(ByVal Path As WString Ptr)As Boolean

' Устанавливает текущий метод http из переменной RequestLine
Declare Function GetHttpMethod(ByVal s As WString Ptr)As HttpMethods

' Возвращает индексный номер указанного заголовка HTTP запроса
Declare Function GetKnownRequestHeaderIndex(ByVal Header As WString Ptr)As Integer

' Возвращает индексный номер указанного заголовка HTTP ответа
Declare Function GetKnownResponseHeaderIndex(ByVal Header As WString Ptr)As Integer

' Заполняет буфер заголовком ответа по индексу
Declare Function GetKnownResponseHeaderName(ByVal Buffer As WString Ptr, ByVal HeaderIndex As HttpResponseHeaderIndices)As Boolean

' Инициализация объекта состояния в начальное значение
Declare Sub InitializeState(ByVal state As ReadHeadersResult Ptr)

' Заполняет буфер html страницей с ошибкой
' Возвращает длину буфера в символах
Declare Function FormatErrorMessageBody(ByVal Buffer As WString Ptr, ByVal StatusCode As Integer, ByVal VirtualPath As WString Ptr, ByVal strMessage As WString Ptr)As Long

' Заполняет буфер описанием http кода
' Для буфера необходимо и достаточно выделить память под 31 символ (без учёта нулевого)
Declare Sub GetStatusDescription(ByVal Buffer As WString Ptr, ByVal StatusCode As Integer)

' Заполняет буфер датой и временем в http формате
Declare Sub GetHttpDate Overload(ByVal Buffer As WString Ptr)
Declare Sub GetHttpDate Overload(ByVal Buffer As WString Ptr, ByVal dt As SYSTEMTIME Ptr)

' Заполняет буфер именем метода Http
Declare Sub GetHttpMethodName(ByVal Buffer As WString Ptr, ByVal HttpMethod As HttpMethods)

' Заполняет буфер экранированной строкой, безопасной для html
' Принимающий буфер должен быть в 6 раз длиннее строки
Declare Sub GetSafeString(ByVal Buffer As WString Ptr, ByVal strSafe As WString Ptr)

' Выделяет память в импровизированной куче
' При ошибке возвращает 0
Declare Function MyHeapAlloc(ByVal hHeap As ThreadParam Ptr)As ThreadParam Ptr

' Подготавливает импровизированную кучу
Declare Sub MyHeapCreate(ByVal hHeap As ThreadParam Ptr)

' Уничтожает импровизированную кучу
Declare Sub MyHeapDestroy(ByVal hHeap As ThreadParam Ptr)

' Отправляет клиенту перенаправление
Declare Sub WriteHttp301Error(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)

' Заполняем буфер именем файла по умолчанию
Declare Sub GetDefaultFileName(ByVal Buffer As WString Ptr, ByVal Index As Integer)

' Обработка запроса CONNECT
Declare Function ProcessConnectRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean

' Обработка запроса OPTIONS
Declare Function ProcessOptionsRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean

' Обработка запросов GET и HEAD
Declare Function ProcessGetHeadRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean

' Обработка запроса PUT
Declare Function ProcessPutRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean

' Обработка запроса DELETE
Declare Function ProcessDeleteRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal fileExtention As WString Ptr, ByVal hOutput As Handle)As Boolean

' Обработка запроса TRACE
Declare Function ProcessTraceRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean

Declare Function ProcessPatchRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean

Declare Function ProcessPostRequest(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean

' Записывает ошибку ответа в поток
Declare Sub WriteHttpError(ByVal state As ReadHeadersResult Ptr, ByVal ClientSocket As SOCKET, ByVal strMessage As WString Ptr, ByVal VirtualPath As WString Ptr, ByVal hOutput As Handle)

Declare Sub GetMimeType(ByVal mt As MimeType Ptr, ByVal ext As WString Ptr)

' Заполняет буфер строкой с типом документа
Declare Sub ContentTypesToString(ByVal Buffer As WString Ptr, ByVal ContentType As ContentTypes)

' Определяет кодировку документа (массива байт)
Declare Function GetDocumentCharset(ByVal b As UByte Ptr)As DocumentCharsets

' Расшифровываем интернет-кодировку в юникод-строку
Declare Sub UrlDecode(ByVal Buffer As WString Ptr, ByVal strUrl As WString Ptr)

' Отправляет ошибку 404 или 410 клиенту
Declare Sub WriteNotFoundError(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)

' Отправляет файл клиенту
Declare Sub SendFileToClient(ByVal ClientSocket As SOCKET, ByVal hFile As Handle, ByVal hZipFile As Handle, ByVal b As UByte Ptr, ByVal state As ReadHeadersResult Ptr, ByVal IsTextFormat As Boolean, ByVal FileSize As LARGE_INTEGER, ByVal wContentType As WString Ptr, ByVal hOutput As Handle)

' Заполняет буфер путём к файлу
Declare Sub MapPath(ByVal Buffer As WString Ptr, ByVal path As WString Ptr, ByVal PhysicalPath As WString Ptr)

' Ищет символы CrLf в буфере
Declare Function FindCrLfA(ByVal Buffer As ZString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer

' Ищет символы CrLf в юникодном буфере
Declare Function FindCrLfW(ByVal Buffer As WString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer

' Получение идентификатора лог‐файла
Declare Function GetLogFileHandle(ByVal dtCurrent As SYSTEMTIME Ptr, ByVal LogDir As WString Ptr)As Handle

' Получение данных от входящего сокета и отправка на исходящий
Declare Sub SendReceiveData(ByVal OutSock As SOCKET, ByVal InSock As SOCKET)

' Процедура потока
Declare Function SendReceiveDataThreadProc(ByVal lpParam As LPVOID)As DWORD

' Проверка аутентификации
Declare Function HttpAuthUtil(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
