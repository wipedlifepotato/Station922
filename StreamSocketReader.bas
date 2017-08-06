#include once "StreamSocketReader.bi"

Sub StreamSocketReader.Initialize()
	Buffer[0] = 0
	BufferLength = 0
	Start = 0
End Sub

Function StreamSocketReader.ReadLine(ByVal wLine As WString Ptr, ByVal nLineBufferLength As Integer)As Integer
	
	Dim CrLfIndex As Integer = FindCrLfA()
	
	Do While CrLfIndex = -1
		
		If BufferLength >= MaxBufferLength Then
			wLine[0] = 0
			SetLastError(BufferOverflowError)
			Return 0
		End If
		
		Dim ReceivedBytesCount As Integer = recv(ClientSocket, @Buffer[BufferLength], MaxBufferLength - BufferLength, 0)
		
		Select Case ReceivedBytesCount
			
			Case SOCKET_ERROR
				wLine[0] = 0
				Buffer[0] = 0
				SetLastError(SocketError)
				Return 0
				
			Case 0
				wLine[0] = 0
				Buffer[BufferLength] = 0
				SetLastError(ClientClosedSocketError)
				Return 0
				
			Case Else
				BufferLength += ReceivedBytesCount
				Buffer[BufferLength] = 0
				
		End Select
		
		CrLfIndex = FindCrLfA()
	Loop
	
	' vbCrLf найдено, получить строку
	
	' На место CrLf записываем ноль
	' Теперь валидная строка для винапи
	Buffer[CrLfIndex] = 0
	
	' Преобразуем utf-8 в WString
	' Нулевой символ будет записан в буфер автоматически
	' Длина строки будет указывать на следующий символ после нулевого
	Dim LineLength As Integer = MultiByteToWideChar(CP_UTF8, 0, @Buffer[Start], -1, wLine, nLineBufferLength) - 1
	' Вернуть символ на место
	Buffer[CrLfIndex] = 13
	
	' Сдвинуть конец заголовков вправо на CrLfIndex + len(vbCrLf)
	Start = CrLfIndex + 2
	
	SetLastError(0)
	Return LineLength
End Function

Sub StreamSocketReader.Flush()
	If Start = 0 Then
		Exit Sub
	End If
	
	If MaxBufferLength - Start <= 0 Then
		Buffer[0] = 0
		BufferLength = 0
	Else
		memmove(@Buffer, @Buffer + Start, MaxBufferLength - Start + 1)
		BufferLength -= Start
	End If
	Start = 0
End Sub

Function StreamSocketReader.FindCrLfA()As Integer
	For i As Integer = Start To BufferLength - 1 - 1 ' Минус 1 под Lf и минус 1, чтобы не выйти за границу
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			Return i
		End If
	Next
	Return -1
End Function
