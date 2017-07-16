#include once "base64.bi"

Function GetBase64Index(ByVal sChar As Integer)As Integer
	If sChar = 0 Then
		Return 255
	Else
		Return StrChr(@B64, sChar) - @B64
	End If
End Function

Function Decode64(ByVal b As UByte Ptr, ByVal s As WString Ptr)As Integer
	Dim BytesCount As Integer = 0
	Dim ww As Integer = Any
	For i As Integer = 0 To lstrlen(s) - 1 Step 4
		' Необходимо каждый раз проверять на vbCrLf и пропускать это сочетание
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww = s[i + 0]
		Dim w1 As Integer = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww = s[i + 1]
		Dim w2 As Integer = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww = s[i + 2]
		Dim w3 As Integer = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww = s[i + 3]
		Dim w4 As Integer = GetBase64Index(ww)
		
		If w2 < 255 Then
			b[BytesCount] = (w1 * 4 + w2 \ 16) And 255
			BytesCount += 1
		End If
		If w3 < 255 Then
			b[BytesCount] = (w2 * 16 + w3 \ 4) And 255
			BytesCount += 1
		End If
		If w4 < 255 Then
			b[BytesCount] = (w3 * 64 + w4) And 255
			BytesCount += 1
		End If
	Next
	Return BytesCount - 2
End Function
