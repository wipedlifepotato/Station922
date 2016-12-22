#include once "base64.bi"

Function Decode64(ByVal b As UByte Ptr, ByVal s As WString Ptr)As Integer
	Dim BytesCount As Integer = 0
	Dim ww As WString * 2 = Any
	ww[1] = 0
	For i As Integer = 0 To lstrlen(s) - 1 Step 4
		' Необходимо каждый раз проверять на vbCrLf и пропускать это сочетание
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww[0] = s[i + 0]
		Dim w1 As UByte = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww[0] = s[i + 1]
		Dim w2 As UByte = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww[0] = s[i + 2]
		Dim w3 As UByte = GetBase64Index(ww)
		
		Do While s[i] = 13 OrElse s[i] = 10
			i += 1
		Loop
		ww[0] = s[i + 3]
		Dim w4 As UByte = GetBase64Index(ww)
		
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

Function GetBase64Index(ByRef s As WString)As UByte
	REM If Len(s) = 0 Then
		REM Return 255
	REM Else
		REM Return CUByte(InStr(B64, s) - 1)
	REM End If
	If lstrlen(s) = 0 Then
		Return 255
	Else
		Return CUByte(StrStr(B64, s) - @B64)
	End If
End Function
