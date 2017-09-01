#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "win\shlwapi.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"
#include once "Http.bi"
#include once "WebSite.bi"
#include once "URI.bi"
#include once "IntegerToWString.bi"
#include once "WebRequest.bi"
#include once "StreamSocketReader.bi"
#include once "WebResponse.bi"

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

' Результат чтения заголовков запроса
Type ReadHeadersResult
	Dim ClientReader As StreamSocketReader
	
	Dim ClientRequest As WebRequest
	
	Dim ServerResponse As WebResponse
	
	' Инициализация объекта состояния в начальное значение
	Declare Sub Initialize()
	
	' Устанавливает сжатие данных для отправки и возвращает идентификатор сжатого файла
	' Заголовки сжатия нужно устанавливать раньше заголовков кэширования
	' так как заголовки кэширования учитывают метод сжатия
	Declare Function SetResponseCompression(ByVal PathTranslated As WString Ptr)As Handle
	
	' Добавляет заголовки кеширования для файла и проверяет совпадение на заголовки кэширования
	Declare Sub AddResponseCacheHeaders(ByVal hFile As HANDLE)
	
	' Проверяет авторизацию Http
	Declare Function HttpAuth(ByVal www As WebSite Ptr)As HttpAuthResult
	
	' Заполняет буфер строкой с заголовками ответа
	' Возвращает длину буфера в символах (без учёта нулевого)
	Declare Function GetResponseHeadersString(ByVal Buffer As ZString Ptr, ByVal ContentLength As LongInt, ByVal hOutput As Handle)As Integer
	
End Type
