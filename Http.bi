#ifndef HTTP_BI
#define HTTP_BI

' Все поддерживаемые методы
Const AllSupportHttpMethods = "CONNECT, DELETE, GET, HEAD, OPTIONS, POST, PUT, TRACE"
' Все поддерживаемые методы для файла
Const AllSupportHttpMethodsFile = "DELETE, GET, HEAD, OPTIONS, PUT, TRACE"
' Все поддерживаемые методы для скриптов
Const AllSupportHttpMethodsScript = "DELETE, GET, HEAD, OPTIONS, POST, PUT, TRACE"

' Требуемый размер буфера для описания кода состояния Http
Const MaxHttpStatusCodeBufferLength As Integer = 32 - 1

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
	HttpPost
	HttpPut
	HttpDelete
	HttpOptions
	HttpTrace
	HttpConnect
	HttpPatch
	HttpCopy
	HttpMove
	HttpPropfind
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
' Помечены заголовки, которые клиент не может переопределить черз файл *.headers
Enum HttpResponseHeaderIndices
	HeaderAcceptRanges
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
	HeaderServer                ' *
	HeaderSetCookie
	HeaderTrailer
	HeaderTransferEncoding      ' *
	HeaderUpgrade
	HeaderVary                  ' *
	HeaderVia
	HeaderWarning
	HeaderWwwAuthenticate
End Enum

' Возвращает метод http
Declare Function GetHttpMethod(ByVal s As WString Ptr)As HttpMethods

' Возвращает указатель на строку с именем метода Http
' Очищать память для строки не нужно
Declare Function GetHttpMethodString(ByVal HttpMethod As HttpMethods, ByRef BufferLength As Integer)As WString Ptr

' Возвращает индексный номер указанного заголовка HTTP запроса
' Если заголовок не распознан, то возвращает -1
Declare Function GetKnownRequestHeaderIndex(ByVal Header As WString Ptr)As Integer

' Возвращает указатель на строку с заголовком запроса
' Очищать память для строки не нужно
Declare Function GetKnownRequestHeaderName(ByVal HeaderIndex As HttpRequestHeaderIndices, ByRef BufferLength As Integer)As WString Ptr

' Возвращает индексный номер указанного заголовка HTTP ответа
' Если заголовок не распознан, то возвращает -1
Declare Function GetKnownResponseHeaderIndex(ByVal Header As WString Ptr)As Integer

' Возвращает указатель на строку с заголовком ответа по индексу
' Очищать память для строки не нужно
Declare Function GetKnownResponseHeaderName(ByVal HeaderIndex As HttpResponseHeaderIndices, ByRef BufferLength As Integer)As WString Ptr

' Возвращает указатель на строку с описанием кода состояния
' Очищать память для строки не нужно
Declare Function GetStatusDescription(ByVal StatusCode As Integer, ByRef BufferLength As Integer)As WString Ptr

' Возвращает заголовок HTTP для CGI
' Очищать память для строки не нужно
Declare Function GetKnownRequestHeaderNameCGI(ByVal HeaderIndex As HttpRequestHeaderIndices, ByRef BufferLength As Integer)As WString Ptr

#endif
