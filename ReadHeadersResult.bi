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

Const ColonWithSpaceString = ": "
Const SpaceString = " "
Const ColonString = ":"
Const UsersIniFileString = "users.config"
Const AdministratorsSectionString = "admins"

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

Enum ZipModes
	None
	GZip
	Deflate
End Enum

' Результат чтения заголовков запроса
Type ReadHeadersResult
	' Размер буфера для строки с заголовками ответа в символах (не включая нулевой)
	Const MaxResponseHeaderBuffer As Integer = 32 * 1024 - 1
	' Максимальное количество заголовков ответа
	Const ResponseHeaderMaximum As Integer = 30
	
	' Читатель данных клиента
	Dim ClientReader As StreamSocketReader
	
	' Запрос клиента
	Dim ClientRequest As WebRequest
	
	' Буфер заголовков ответа
	Dim ResponseHeaderBuffer As WString * (MaxResponseHeaderBuffer + 1)
	' Указатель на свободное место в буфере заголовков ответа
	Dim StartResponseHeadersPtr As WString Ptr
	' Заголовки ответа
	Dim ResponseHeaders(ResponseHeaderMaximum - 1) As WString Ptr
	
	' Строка состояния
	Dim StatusDescription As WString Ptr
	
	' Код ответа клиенту
	Dim StatusCode As Integer
	' Отправлять клиенту только заголовки
	Dim SendOnlyHeaders As Boolean
	
	' Сжатие данных, поддерживаемое сервером
	Dim ResponseZipMode As ZipModes
	
	
	' Инициализация объекта состояния в начальное значение
	Declare Sub Initialize()
	
	' Устанавливает сжатие данных для отправки и возвращает идентификатор сжатого файла
	' Заголовки сжатия нужно устанавливать раньше заголовков кэширования
	' так как заголовки кэширования учитывают метод сжатия
	Declare Function SetResponseCompression(ByVal PathTranslated As WString Ptr)As Handle
	
	' Добавляет заголовки кеширования для файла и проверяет совпадение на заголовки кэширования
	Declare Sub AddResponseCacheHeaders(ByVal hFile As HANDLE)
	
	' Добавляет заголовок к заголовкам ответа
	Declare Sub AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	
	' Добавляет известный заголовок к заголовкам ответа
	Declare Sub AddKnownResponseHeader(ByVal HeaderIndex As HttpResponseHeaderIndices, ByVal Value As WString Ptr)
	
	' Устанавливает описание кода ответа
	Declare Sub SetStatusDescription(ByVal Description As WString Ptr)
	
	' Проверяет авторизацию Http
	Declare Function HttpAuth(ByVal www As WebSite Ptr)As HttpAuthResult
	
	' Заполняет буфер строкой с заголовками ответа
	' Возвращает длину буфера в символах (без учёта нулевого)
	Declare Function GetResponseHeadersString(ByVal Buffer As ZString Ptr, ByVal ContentLength As LongInt, ByVal hOutput As Handle)As Integer
	
End Type
