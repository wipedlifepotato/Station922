#include "ConsoleColors.bi"
#include "win\ole2.bi"

Const MaxConsoleCharsCount As Integer = 32000 - 1

Function GetWinAPIForeColor( _
		ByVal ForeColor As ConsoleColors _
	)As Integer
	
	Select Case ForeColor
		
		Case ConsoleColors.Black
			Return 0
			
		Case ConsoleColors.DarkBlue
			Return FOREGROUND_BLUE
			
		Case ConsoleColors.DarkGreen
			Return FOREGROUND_GREEN
			
		Case ConsoleColors.DarkCyan
			Return FOREGROUND_GREEN + FOREGROUND_BLUE
			
		Case ConsoleColors.DarkRed
			Return FOREGROUND_RED
			
		Case ConsoleColors.DarkMagenta
			Return FOREGROUND_RED + FOREGROUND_BLUE
			
		Case ConsoleColors.DarkYellow
			Return FOREGROUND_RED + FOREGROUND_GREEN
			
		Case ConsoleColors.Gray
			Return FOREGROUND_RED + FOREGROUND_GREEN + FOREGROUND_BLUE
			
		Case ConsoleColors.DarkGray
			Return FOREGROUND_INTENSITY
			
		Case ConsoleColors.Blue
			Return FOREGROUND_BLUE + FOREGROUND_INTENSITY
			
		Case ConsoleColors.Green
			Return FOREGROUND_GREEN + FOREGROUND_INTENSITY
			
		Case ConsoleColors.Cyan
			Return FOREGROUND_GREEN + FOREGROUND_BLUE + FOREGROUND_INTENSITY
			
		Case ConsoleColors.Red
			Return FOREGROUND_RED + FOREGROUND_INTENSITY
			
		Case ConsoleColors.Magenta
			Return FOREGROUND_RED + FOREGROUND_BLUE + FOREGROUND_INTENSITY
			
		Case ConsoleColors.Yellow
			Return FOREGROUND_RED + FOREGROUND_GREEN + FOREGROUND_INTENSITY
			
		Case ConsoleColors.White
			Return FOREGROUND_RED + FOREGROUND_GREEN + FOREGROUND_BLUE + FOREGROUND_INTENSITY
			
		Case Else
			Return 0
			
	End Select
	
End Function

Function GetWinAPIBackColor( _
		ByVal BackColor As ConsoleColors _
	)As Integer
	
	Select Case BackColor
		
		Case ConsoleColors.Black
			Return 0
			
		Case ConsoleColors.DarkBlue
			Return BACKGROUND_BLUE
			
		Case ConsoleColors.DarkGreen
			Return BACKGROUND_GREEN
			
		Case ConsoleColors.DarkCyan
			Return BACKGROUND_GREEN + BACKGROUND_BLUE
			
		Case ConsoleColors.DarkRed
			Return BACKGROUND_RED
			
		Case ConsoleColors.DarkMagenta
			Return BACKGROUND_RED + BACKGROUND_BLUE
			
		Case ConsoleColors.DarkYellow
			Return BACKGROUND_RED + BACKGROUND_GREEN
			
		Case ConsoleColors.Gray
			Return BACKGROUND_RED + BACKGROUND_GREEN + BACKGROUND_BLUE
			
		Case ConsoleColors.DarkGray
			Return BACKGROUND_INTENSITY
			
		Case ConsoleColors.Blue
			Return BACKGROUND_BLUE + BACKGROUND_INTENSITY
			
		Case ConsoleColors.Green
			Return BACKGROUND_GREEN + BACKGROUND_INTENSITY
			
		Case ConsoleColors.Cyan
			Return BACKGROUND_GREEN + BACKGROUND_BLUE + BACKGROUND_INTENSITY
			
		Case ConsoleColors.Red
			Return BACKGROUND_RED + BACKGROUND_INTENSITY
			
		Case ConsoleColors.Magenta
			Return BACKGROUND_RED + BACKGROUND_BLUE + BACKGROUND_INTENSITY
			
		Case ConsoleColors.Yellow
			Return BACKGROUND_RED + BACKGROUND_GREEN + BACKGROUND_INTENSITY
			
		Case ConsoleColors.White
			Return BACKGROUND_RED + BACKGROUND_GREEN + BACKGROUND_BLUE + BACKGROUND_INTENSITY
			
		Case Else
			Return 0
			
	End Select
	
End Function

Sub ConsoleWriteColorLineA( _
		ByVal s As LPCSTR, _
		ByVal pCharsWritten As Integer Ptr, _
		ByVal ForeColor As ConsoleColors, _
		ByVal BackColor As ConsoleColors _
	)
	Dim Length As Integer = lstrlenA(s)
	Dim lpsTemp As LPSTR = CoTaskMemAlloc((Length + 2 + 1) * SizeOf(ZString))
	If lpsTemp = NULL Then
		Exit Sub
	End If
	
	lstrcpyA(lpsTemp, s)
	lpsTemp[Length + 0] = 13
	lpsTemp[Length + 1] = 10
	lpsTemp[Length + 2] = 0
	
	Dim CharsWritten As Integer = Any
	
	ConsoleWriteColorStringA(lpsTemp, @CharsWritten, ForeColor, BackColor)
	
	CoTaskMemFree(lpsTemp)
	
	*pCharsWritten = *pCharsWritten + CharsWritten
	
End Sub

Sub ConsoleWriteColorLineW( _
		ByVal s As LPCWSTR, _
		ByVal pCharsWritten As Integer Ptr, _
		ByVal ForeColor As ConsoleColors, _
		ByVal BackColor As ConsoleColors _
	)
	Dim Length As Integer = lstrlenW(s)
	Dim lpsTemp As LPWSTR = CoTaskMemAlloc((Length + 2 + 1) * SizeOf(WString))
	If lpsTemp = NULL Then
		Exit Sub
	End If
	
	lstrcpyW(lpsTemp, s)
	lpsTemp[Length + 0] = 13
	lpsTemp[Length + 1] = 10
	lpsTemp[Length + 2] = 0
	
	Dim CharsWritten As Integer = Any
	
	ConsoleWriteColorStringW(lpsTemp, @CharsWritten, ForeColor, BackColor)
	
	CoTaskMemFree(lpsTemp)
	
	*pCharsWritten = *pCharsWritten + CharsWritten
	
End Sub

Sub ConsoleWriteColorStringA( _
		ByVal s As LPCSTR, _
		ByVal pCharsWritten As Integer Ptr, _
		ByVal ForeColor As ConsoleColors, _
		ByVal BackColor As ConsoleColors _
	)
	
	Dim OutHandle As HANDLE = GetStdHandle(STD_OUTPUT_HANDLE)
	
	SetConsoleTextAttribute(OutHandle, _
		GetWinAPIForeColor(ForeColor) + GetWinAPIBackColor(BackColor) _
	)
	
	Dim NumberOfBytesWritten As DWORD = Any
	
	If WriteFile(OutHandle, s, lstrlenA(s), @NumberOfBytesWritten, 0) = 0 Then
		' Ошибка
		*pCharsWritten = 0
		Return
	End If
	
	*pCharsWritten = NumberOfBytesWritten
	Return
	
End Sub

Sub ConsoleWriteColorStringW( _
		ByVal s As LPCWSTR, _
		ByVal pCharsWritten As Integer Ptr, _
		ByVal ForeColor As ConsoleColors, _
		ByVal BackColor As ConsoleColors _
	)
	
	Dim OutHandle As HANDLE = GetStdHandle(STD_OUTPUT_HANDLE)
	
	SetConsoleTextAttribute(OutHandle, _
		GetWinAPIForeColor(ForeColor) + GetWinAPIBackColor(BackColor) _
	)
	
	Dim NumberOfCharsWritten As DWORD = Any
	
	If WriteConsoleW(OutHandle, s, lstrlenW(s), @NumberOfCharsWritten, 0) = 0 Then
		
		Dim OutputCodePage As Integer = GetConsoleOutputCP()
		
		Dim Buffer As ZString * (MaxConsoleCharsCount + 1) = Any
		
		Dim BytesCount As Integer = WideCharToMultiByte( _
			OutputCodePage, _
			0, _
			s, _
			-1, _
			@Buffer, _
			MaxConsoleCharsCount, _
			NULL, _
			NULL _
		)
		
		Dim NumberOfBytesWritten As DWORD = Any
		
		If WriteFile(OutHandle, @Buffer, BytesCount - 1, @NumberOfBytesWritten, 0) = 0 Then
			' Ошибка
			*pCharsWritten = 0
			Return
		End If
		
		*pCharsWritten = NumberOfBytesWritten
		Return
	End If
	
	*pCharsWritten = NumberOfCharsWritten
	Return
	
End Sub
