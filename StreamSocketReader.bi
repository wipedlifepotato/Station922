#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

Enum StreamSocketReaderParseRequestLineResult
	' Ошибок нет
	Success
End Enum

Type StreamSocketReader
	' Максимальный размер буфера
	Const MaxBufferLength As Integer = 16 * 1024 - 1
	
	' Буфер заполнен
	Const BufferOverflowError As Integer = 1
	' Ошибка сети
	Const SocketError As Integer = 2
	' Клиент закрыл соединение
	Const ClientClosedSocketError As Integer = 3
	
	' Клиентский сокета
	Dim ClientSocket As SOCKET
	' Буфер данных
	Dim Buffer As ZString * (MaxBufferLength + 1)
	' Количество данных в буфере
	Dim BufferLength As Integer
	' Индекс начала необработанных данные в буфере
	Dim Start As Integer
	
	' Чтение данных из сокета и возвращение строки
	' Возвращает длину полученной строки без учёта нулевого символа
	Declare Function ReadLine(ByVal wLine As WString Ptr, ByVal nLineBufferLength As Integer)As Integer
	
	' Поиск символов CrLf в буфере
	Declare Function FindCrLfA()As Integer
	
	' Инициализация
	Declare Sub Initialize()
End Type
