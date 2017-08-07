#ifndef unicode
#define unicode
#endif
#include once "URI.bi"
#include once "windows.bi"

Sub URI.Initialize()
	Url = 0
	QueryString = 0
	Path[0] = 0
End Sub

Sub URI.PathDecode(ByVal Buffer As WString Ptr)
	' TODO Исправить раскодирование неправильного запроса
	' Расшифровываем url-кодировку %XY
	Dim iAcc As UInteger = 0
	Dim iHex As UInteger = 0
	Dim j As Integer = 0
	
	Dim DecodedBytes As ZString * (URI.MaxUrlLength + 1) = Any
	
	For i As Integer = 0 To lstrlen(Path) - 1
		Dim c As UInteger = Path[i]
		If iHex <> 0 Then
			' 0 = 30 = 48 = 0
			' 1 = 31 = 49 = 1
			' 2 = 32 = 50 = 2
			' 3 = 33 = 51 = 3
			' 4 = 34 = 52 = 4
			' 5 = 35 = 53 = 5
			' 6 = 36 = 54 = 6
			' 7 = 37 = 55 = 7
			' 8 = 38 = 56 = 8
			' 9 = 39 = 57 = 9
			' A = 41 = 65 = 10
			' B = 42 = 66 = 11
			' C = 43 = 67 = 12
			' D = 44 = 68 = 13
			' E = 45 = 69 = 14
			' F = 46 = 70 = 15
			iHex += 1 ' раскодировать
			iAcc *= 16
			Select Case c
				Case &h30, &h31, &h32, &h33, &h34, &h35, &h36, &h37, &h38, &h39
					iAcc += c - &h30 ' 48
				Case &h41, &h42, &h43, &h44, &h45, &h46 ' Коды ABCDEF
					iAcc += c - &h37 ' 55
				Case &h61, &h62, &h63, &h64, &h65, &h66 ' Коды abcdef
					iAcc += c - &h57 ' 87
			End Select
			
			If iHex = 3 Then
				c = iAcc
				iAcc = 0
				iHex = 0
			End if
		End if
		If c = &h25 Then '37 % hex code coming?
			iHex = 1
			iAcc = 0
		End if
		If iHex = 0 Then
			DecodedBytes[j] = c
			j += 1
		End If
	Next
	' Завершающий ноль
	DecodedBytes[j] = 0
	' Преобразовать
	MultiByteToWideChar(CP_UTF8, 0, @DecodedBytes, -1, Buffer, URI.MaxUrlLength)
End Sub
