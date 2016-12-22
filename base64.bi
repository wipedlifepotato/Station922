' Кодирование в Base64 и обратно
#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shlwapi.bi"

Const B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
Const Base64StringLength As Integer = 19

' Кодирует массив байт в base64
' sOut — буфер под закодированную строку
' sEncodedB — указатель на массив байт, которые нужно закодировать
' BytesCount — количество байт в массиве
' WithCrLf Добавлять ли новую строку после 80 символов
' Функция может записать за выделенный буфер, если он будет слишком мал
' Размер требуемого буфера для записи можно вычислять функцией GetBytesString
' Функция записывает завершающий ноль
' Возвращает количество символов (без учёта завершающего нуля)
Declare Function Encode64(ByVal sOut As WString Ptr, ByVal sEncodedB As UByte Ptr, ByVal BytesCount As Integer, ByVal WithCrLf As Boolean)As Integer

' Декодирует из base64 в массив байт
' b — указатель на массив байт, которые нужно заполнить
' s — строка, возможно, с символами vbCrLf
' Возвращает длину массива
Declare Function Decode64(ByVal b As UByte Ptr, ByVal s As WString Ptr)As Integer

Declare Function E0(v1 As UByte)As UByte
Declare Function E1(v1 As UByte, v2 As UByte)As UByte
Declare Function E2(v2 As UByte, v3 As UByte)As UByte
Declare Function E3(v3 As UByte)As UByte
' Возвращает индекс символа в массиве
Declare Function GetBase64Index(ByRef s As WString)As UByte
