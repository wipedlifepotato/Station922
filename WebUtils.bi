#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "Http.bi"

Const NewLineString = !"\r\n"

' Кодировка документа
Enum DocumentCharsets
	ASCII
	Utf8BOM
	Utf16LE
	Utf16BE
End Enum

' Заполняет буфер экранированной строкой, безопасной для html
' Принимающий буфер должен быть в 6 раз длиннее строки
Declare Function GetSafeString(ByVal Buffer As WString Ptr, ByVal BufferLength As Integer, ByVal strSafe As WString Ptr)As Integer

' Определяет кодировку документа (массива байт)
Declare Function GetDocumentCharset(ByVal b As UByte Ptr)As DocumentCharsets

' Ищет символы CrLf в буфере
Declare Function FindCrLfA(ByVal Buffer As ZString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer

' Ищет символы CrLf в юникодном буфере
Declare Function FindCrLfW(ByVal Buffer As WString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer

' Заполняет буфер датой и временем в http формате
Declare Sub GetHttpDate Overload(ByVal Buffer As WString Ptr)
Declare Sub GetHttpDate Overload(ByVal Buffer As WString Ptr, ByVal dt As SYSTEMTIME Ptr)
