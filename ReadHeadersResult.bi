#ifndef READHEADERSRESULT_BI
#define READHEADERSRESULT_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "WebRequest.bi"
#include once "WebResponse.bi"
#include once "WebSite.bi"

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
	Dim ClientRequest As WebRequest
	Dim ServerResponse As WebResponse
	
	' Устанавливает сжатие данных для отправки и возвращает идентификатор сжатого файла
	' Заголовки сжатия нужно устанавливать раньше заголовков кэширования
	' так как заголовки кэширования учитывают метод сжатия
	Declare Function SetResponseCompression( _
		ByVal PathTranslated As WString Ptr, _
		ByVal pAcceptEncoding As Boolean Ptr _
	)As Handle
	
	' Добавляет заголовки кеширования для файла и проверяет совпадение на заголовки кэширования
	Declare Sub AddResponseCacheHeaders( _
		ByVal hFile As HANDLE _
	)
	
	' Проверяет авторизацию Http
	Declare Function HttpAuth( _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal ProxyAuthorization As Boolean _
	)As HttpAuthResult
	
	' Заполняет буфер строкой с заголовками ответа
	' Возвращает длину буфера в символах (без учёта нулевого)
	Declare Function AllResponseHeadersToBytes( _
		ByVal zBuffer As ZString Ptr, _
		ByVal ContentLength As ULongInt _
	)As Integer
	
End Type

' Инициализация объекта состояния в начальное значение
Declare Sub InitializeReadHeadersResult( _
	ByVal pState As ReadHeadersResult Ptr _
)

#endif
