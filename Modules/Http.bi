#ifndef HTTP_BI
#define HTTP_BI

Const AllSupportHttpMethods =          "CONNECT,DELETE,GET,HEAD,OPTIONS,POST,PUT,TRACE"
Const AllSupportHttpMethodsForFile =   "CONNECT,DELETE,GET,HEAD,OPTIONS,PUT,TRACE"
Const AllSupportHttpMethodsForScript = "CONNECT,DELETE,GET,HEAD,OPTIONS,POST,PUT,TRACE"

' Требуемый размер буфера для описания кода состояния Http
Const MaxHttpStatusCodeBufferLength As Integer = 32 - 1

' Максимальное количество заголовков запроса
Const HttpRequestHeadersMaximum As Integer = 43

' Максимальное количество заголовков ответа
Const HttpResponseHeadersMaximum As Integer = 37

Const HttpZipModesMaximum As Integer = 2

Enum HttpVersions
	Http11
	Http10
	Http09
End Enum

Enum HttpStatusCodes
	CodeContinue = 100
	SwitchingProtocols = 101
	Processing = 102
	
	OK = 200
	Created = 201
	Accepted = 202
	NonAuthoritativeInformation = 203
	NoContent = 204
	ResetContent = 205
	PartialContent = 206
	MultiStatus = 207
	IAmUsed = 226
	
	MultipleChoices = 300
	MovedPermanently = 301
	Found = 302
	SeeOther = 303
	NotModified = 304
	UseProxy = 305
	TemporaryRedirect = 307
	
	BadRequest = 400
	Unauthorized = 401
	PaymentRequired = 402
	Forbidden = 403
	NotFound = 404
	MethodNotAllowed = 405
	NotAcceptable = 406
	ProxyAuthenticationRequired = 407
	RequestTimeout = 408
	Conflict = 409
	Gone = 410
	LengthRequired = 411
	PreconditionFailed = 412
	RequestEntityTooLarge = 413
	RequestURITooLarge = 414
	UnsupportedMediaType = 415
	RequestedRangeNotSatisfiable = 416
	ExpectationFailed = 417
	IAmTeapot = 418
	UnprocessableEntity = 422
	Locked = 423
	FailedDependency = 424
	UnorderedCollection = 425
	UpgradeRequired = 426
	PreconditionRequired = 428
	TooManyRequests = 429
	RequestHeaderFieldsTooLarge = 431
	RetryWith = 449
	UnavailableForLegalReasons = 451
	
	InternalServerError = 500
	NotImplemented = 501
	BadGateway = 502
	ServiceUnavailable = 503
	GatewayTimeout = 504
	HTTPVersionNotSupported = 505
	VariantAlsoNegotiates = 506
	InsufficientStorage = 507
	LoopDetected = 508
	BandwidthLimitExceeded = 509
	NotExtended = 510
	NetworkAuthenticationRequired = 511
	
End Enum

Enum HttpMethods
	HttpGet
	HttpHead
	HttpPost
	HttpPut
	HttpDelete
	HttpOptions
	HttpTrace
	HttpConnect
End Enum

Enum HttpRequestHeaders
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
	HeaderDNT
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
	HeaderOrigin
	HeaderPragma
	HeaderProxyAuthorization
	HeaderRange
	HeaderReferer
	HeaderSecWebSocketKey
	HeaderSecWebSocketKey1
	HeaderSecWebSocketKey2
	HeaderSecWebSocketVersion
	HeaderTe
	HeaderTrailer
	HeaderTransferEncoding
	HeaderUpgrade
	HeaderUpgradeInsecureRequests
	HeaderUserAgent
	HeaderVia
	HeaderWarning
	HeaderWebSocketProtocol
End Enum

' Помечены заголовки, которые клиент не может переопределить черз файл *.headers
Enum HttpResponseHeaders
	HeaderAcceptRanges          ' *
	HeaderAge
	HeaderAllow
	HeaderCacheControl
	HeaderConnection            ' *
	HeaderContentEncoding
	HeaderContentLanguage
	HeaderContentLength         ' *
	HeaderContentLocation
	HeaderContentMd5
	HeaderContentRange
	HeaderContentType
	HeaderDate                  ' *
	HeaderETag
	HeaderExpires
	HeaderKeepAlive             ' *
	HeaderLastModified
	HeaderLocation
	HeaderPragma
	HeaderProxyAuthenticate
	HeaderRetryAfter
	HeaderSecWebSocketAccept ' *
	HeaderSecWebSocketLocation ' *
	HeaderSecWebSocketOrigin ' *
	HeaderSecWebSocketProtocol ' *
	HeaderServer                ' *
	HeaderSetCookie
	HeaderTrailer
	HeaderTransferEncoding      ' *
	HeaderUpgrade
	HeaderVary                  ' *
	HeaderVia
	HeaderWarning
	HeaderWebSocketLocation ' *
	HeaderWebSocketOrigin ' *
	HeaderWebSocketProtocol ' *
	HeaderWwwAuthenticate
End Enum

Enum ZipModes
	GZip
	Deflate
End Enum

Declare Function CreateRequestHeadersTree( _
)As Boolean

Declare Function GetHttpMethod( _
	ByVal s As WString Ptr, _
	ByVal pHttpMethod As HttpMethods Ptr _
)As Boolean

' Возвращает указатель на строку с именем метода Http
' Очищать память для строки не нужно
Declare Function HttpMethodToString( _
	ByVal HttpMethod As HttpMethods, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

Declare Function GetHttpVersion( _
	ByVal s As WString Ptr, _
	ByVal pVersion As HttpVersions Ptr _
)As Boolean

Declare Function HttpVersionToString( _
	ByVal v As HttpVersions, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

Declare Function GetKnownRequestHeaderIndex( _
	ByVal wHeader As WString Ptr, _
	ByVal pHeader As HttpRequestHeaders Ptr _
)As Boolean

' Возвращает указатель на строку с заголовком запроса
' Очищать память для строки не нужно
Declare Function KnownRequestHeaderIndexToString( _
	ByVal Header As HttpRequestHeaders, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

Declare Function GetKnownResponseHeaderIndex( _
	ByVal wHeader As WString Ptr, _
	ByVal pHeader As HttpResponseHeaders Ptr _
)As Boolean

' Возвращает указатель на строку с заголовком ответа по индексу
' Очищать память для строки не нужно
Declare Function KnownResponseHeaderToString( _
	ByVal HeaderIndex As HttpResponseHeaders, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

' Возвращает указатель на строку с описанием кода состояния
' Очищать память для строки не нужно
Declare Function GetStatusDescription( _
	ByVal StatusCode As HttpStatusCodes, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

' Возвращает заголовок HTTP для CGI
' Очищать память для строки не нужно
Declare Function KnownRequestCgiHeaderToString( _
	ByVal Header As HttpRequestHeaders, _
	ByVal pBufferLength As Integer Ptr _
)As WString Ptr

#endif
