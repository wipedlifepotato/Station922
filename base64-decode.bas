#include once "base64.bi"

Function GetBase64Index(ByVal sChar As Integer)As Integer
	If sChar = 0 Then
		Return -1
	End If
	Dim w As WString Ptr = StrChr(@B64, sChar)
	If w = 0 Then
		Return -1
	End If
	Return w - @B64
End Function

' Пропускаем все символы не из набора
Function SkipWrongChar(ByVal s As WString Ptr)As Integer
	Dim i As Integer = 0
	Dim schar As Integer = s[i]
	Do Until schar = 0
		If GetBase64Index(schar) <> -1 Then
			Exit Do
		End If
		i += 1
		schar = s[i]
	Loop
	Return i
End Function

Function CalculateString(ByVal b As UByte Ptr, ByVal BytesCount As Integer, ByVal w1 As Integer, ByVal w2 As Integer, ByVal w3 As Integer, ByVal w4 As Integer)As Integer
	If w2 > -1 Then
		b[BytesCount] = (w1 * 4 + w2 \ 16) And 255
		BytesCount += 1
	End If
	If w3 > -1 Then
		b[BytesCount] = (w2 * 16 + w3 \ 4) And 255
		BytesCount += 1
	End If
	If w4 > -1 Then
		b[BytesCount] = (w3 * 64 + w4) And 255
		BytesCount += 1
	End If
	Return BytesCount
End Function

Function Decode64(ByVal b As UByte Ptr, ByVal s As WString Ptr)As Integer
	Dim BytesCount As Integer = 0
	Dim length As Integer = lstrlen(s)
	For i As Integer = 0 To length - 1 Step 4
		Dim ww As Integer = Any
		' Необходимо пропустить все символы не из набора
		i += SkipWrongChar(s[i + 0])
		If i >= length - 0 Then
			Return BytesCount
		End If
		ww = s[i + 0]
		Dim w1 As Integer = GetBase64Index(ww)
		
		i += SkipWrongChar(s[i + 1])
		If i >= length - 1 Then
			Return CalculateString(b, BytesCount, w1, 0, 0, 0)
		End If
		ww = s[i + 1]
		Dim w2 As Integer = GetBase64Index(ww)
		
		i += SkipWrongChar(s[i + 2])
		If i >= length - 2 Then
			Return CalculateString(b, BytesCount, w1, w2, 0, 0)
		End If
		ww = s[i + 2]
		Dim w3 As Integer = GetBase64Index(ww)
		
		i += SkipWrongChar(s[i + 3])
		If i >= length - 3 Then
			Return CalculateString(b, BytesCount, w1, w2, w3, 0)
		End If
		ww = s[i + 3]
		Dim w4 As Integer = GetBase64Index(ww)
		
		BytesCount = CalculateString(b, BytesCount, w1, w2, w3, w4)
	Next
	Return BytesCount
End Function
