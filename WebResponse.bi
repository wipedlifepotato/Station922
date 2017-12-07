#ifndef WEBRESPONSE_BI
#define WEBRESPONSE_BI

#include once "Http.bi"

Enum ZipModes
	None
	GZip
	Deflate
End Enum

Type WebResponse
	' Размер буфера для строки с заголовками ответа в символах (не включая нулевой)
	Const MaxResponseHeaderBuffer As Integer = 32 * 1024 - 1
	' Максимальное количество заголовков ответа
	Const ResponseHeaderMaximum As Integer = 30
	
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
	' Поддержка соединения с клиентом
	Dim KeepAlive As Boolean
	
	' Сжатие данных, поддерживаемое сервером
	Dim ResponseZipMode As ZipModes
	
	' Инициализация объекта состояния в начальное значение
	Declare Sub Initialize()
	
	' Добавляет заголовок к заголовкам ответа
	Declare Sub AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	
	' Добавляет известный заголовок к заголовкам ответа
	Declare Sub AddKnownResponseHeader(ByVal HeaderIndex As HttpResponseHeaderIndices, ByVal Value As WString Ptr)
	
	' Устанавливает описание кода ответа
	Declare Sub SetStatusDescription(ByVal Description As WString Ptr)
End Type

#endif
