#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

#include once "WebSite.bi"
#include once "ReadHeadersResult.bi"

Enum HttpErrors
	HttpCreated
	HttpCreatedUpdated
	HttpError400BadRequest
	HttpError400BadPath
	HttpError400Host
	HttpError403File
	HttpError411LengthRequired
	HttpError413RequestEntityTooLarge
	HttpError414RequestUrlTooLarge
	HttpError431RequestRequestHeaderFieldsTooLarge
	HttpError500ThreadError
	HttpError500NotAvailable
	HttpError501MethodNotAllowed
	HttpError501ContentTypeEmpty
	HttpError501ContentEncoding
	HttpError502BadGateway
	HttpError503Memory
	HttpError504GatewayTimeout
	HttpError505VersionNotSupported
	NeedUsernamePasswordString
	NeedUsernamePasswordString1
	NeedUsernamePasswordString2
	NeedUsernamePasswordString3
	HttpError404FileNotFound
	HttpError410Gone
	MovedPermanently
End Enum

' Записывает ошибку ответа в поток
Declare Sub WriteHttpError(ByVal state As ReadHeadersResult Ptr, ByVal ClientSocket As SOCKET, ByVal MessageType As HttpErrors, ByVal VirtualPath As WString Ptr, ByVal hOutput As Handle)

' Отправляет клиенту перенаправление
Declare Sub WriteHttp301Error(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)

' Отправляет клиенту «Ресурс создан»
Declare Sub WriteHttp201(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)

' Заполняет буфер html страницей с ошибкой
' Возвращает длину буфера в символах
Declare Function FormatErrorMessageBody(ByVal Buffer As WString Ptr, ByVal StatusCode As Integer, ByVal VirtualPath As WString Ptr, ByVal strMessage As WString Ptr)As LongInt

' Проверка аутентификации
Declare Function HttpAuthUtil(ByVal ClientSocket As SOCKET, ByVal state As ReadHeadersResult Ptr, ByVal www As WebSite Ptr, ByVal hOutput As Handle)As Boolean
