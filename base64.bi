#ifndef BASE64_BI
#define BASE64_BI

' Кодирует массив байт в base64
' sOut — буфер под закодированную строку
' sEncodedB — указатель на массив байт, которые нужно закодировать
' BytesCount — количество байт в массиве
' Функция может записать за выделенный буфер, если он будет слишком мал
' Размер требуемого буфера под результирующую строку должен быть не менее ((BytesCount \ 3) + 1) * 4 символов + 1 символ под нулевой
' Функция записывает завершающий ноль
' Возвращает количество символов (без учёта завершающего нуля)
Declare Function Encode64( _
	ByVal sOut As WString Ptr, _
	ByVal sEncodedB As UByte Ptr, _
	ByVal BytesCount As Integer _
)As Integer

' Декодирует из base64 в массив байт
' b — указатель на массив байт, которые нужно заполнить
' s — строка, возможно, с символами vbCrLf
' Возвращает длину массива
Declare Function Decode64( _
	ByVal b As UByte Ptr, _
	ByVal s As WString Ptr _
)As Integer

#endif
