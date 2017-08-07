#include once "WebUtils.bi"
#include once "HttpConst.bi"
#include once "URI.bi"
#include once "IntegerToWString.bi"

Const DateFormatString = "ddd, dd MMM yyyy "
Const TimeFormatString = "HH:mm:ss GMT"

Sub GetSafeString(ByVal Buffer As WString Ptr, ByVal strSafe As WString Ptr)
	Dim Counter As Integer = 0
	For i As Integer = 0 To lstrlen(strSafe) - 1
		Dim Number As Integer = strSafe[i]
		Select Case Number
			Case 34 ' "
				' &quot;
				Buffer[Counter] = 38        ' &
				Buffer[Counter + 1] = &h71  ' q
				Buffer[Counter + 2] = &h75  ' u
				Buffer[Counter + 3] = &h6f  ' o
				Buffer[Counter + 4] = &h74  ' t
				Buffer[Counter + 5] = &h3b  ' ;
				Counter += 6
			Case 38 ' &
				' &amp;
				Buffer[Counter] = 38        ' &
				Buffer[Counter + 1] = &h61  ' a
				Buffer[Counter + 2] = &h6d  ' m
				Buffer[Counter + 3] = &h70  ' p
				Buffer[Counter + 4] = &h3b  ' ;
				Counter += 5
			Case 39 ' '
				' &apos;
				Buffer[Counter] = 38        ' &
				Buffer[Counter + 1] = &h61  ' a
				Buffer[Counter + 2] = &h70  ' p
				Buffer[Counter + 3] = &h6f  ' o
				Buffer[Counter + 4] = &h73  ' s
				Buffer[Counter + 5] = &h3b  ' ;
				Counter += 6
			Case 60 ' <
				' &lt;
				Buffer[Counter] = 38        ' &
				Buffer[Counter + 1] = &h6c  ' l
				Buffer[Counter + 2] = &h74  ' t
				Buffer[Counter + 3] = &h3b  ' ;
				Counter += 4
			Case 62 ' >
				' &gt;
				Buffer[Counter] = 38        ' &
				Buffer[Counter + 1] = &h67  ' g
				Buffer[Counter + 2] = &h74  ' t
				Buffer[Counter + 3] = &h3b  ' ;
				Counter += 4
			Case Else
				Buffer[Counter] = Number
				Counter += 1
		End Select
	Next
	' Завершающий нулевой символ
	Buffer[Counter] = 0
End Sub

Function GetDocumentCharset(ByVal b As UByte Ptr)As DocumentCharsets
	If b[0] = 239 AndAlso b[1] = 187 AndAlso b[2] = 191 Then
		Return DocumentCharsets.Utf8BOM
	End If
	If b[0] = 255 AndAlso b[1] = 254 Then
		Return DocumentCharsets.Utf16LE
	End If
	If b[0] = 254 AndAlso b[1] = 255 Then
		Return DocumentCharsets.Utf16BE
	End If
	Return DocumentCharsets.ASCII
End Function

Sub GetHttpDate(ByVal Buffer As WString Ptr, ByVal dt As SYSTEMTIME Ptr)
	' Tue, 15 Nov 1994 12:45:26 GMT
	Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, dt, @DateFormatString, Buffer, 31) - 1
	GetTimeFormat(LOCALE_INVARIANT, 0, dt, @TimeFormatString, @Buffer[dtBufferLength], 31 - dtBufferLength)
End Sub

Sub GetHttpDate(ByVal Buffer As WString Ptr)
	Dim dt As SYSTEMTIME = Any
	GetSystemTime(@dt)
	GetHttpDate(Buffer, @dt)
End Sub

Function FindCrLfA(ByVal Buffer As ZString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer
	For i As Integer = Start To BufferLength - 2 ' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			Return i
		End If
	Next
	Return -1
End Function

Function FindCrLfW(ByVal Buffer As WString Ptr, ByVal Start As Integer, ByVal BufferLength As Integer)As Integer
	For i As Integer = Start To BufferLength - 2 ' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
		If Buffer[i] = 13 AndAlso Buffer[i + 1] = 10 Then
			Return i
		End If
	Next
	Return -1
End Function
