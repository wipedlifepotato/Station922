#ifndef CONSOLECOLORS_BI
#define CONSOLECOLORS_BI

#include "windows.bi"

Enum ConsoleColors
	Black = 0
	DarkBlue = 1
	DarkGreen = 2
	DarkCyan = 3
	DarkRed = 4
	DarkMagenta = 5
	DarkYellow = 6
	Gray = 7
	DarkGray = 8
	Blue = 9
	Green = 10
	Cyan = 11
	Red = 12
	Magenta = 13
	Yellow = 14
	White = 15
End Enum

Declare Sub ConsoleWriteColorStringA Alias "ConsoleWriteColorStringA"( _
	ByVal s As LPCSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)

Declare Sub ConsoleWriteColorStringW Alias "ConsoleWriteColorStringW"( _
	ByVal s As LPCWSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)

#ifdef unicode
Declare Sub ConsoleWriteColorString Alias "ConsoleWriteColorStringW"( _
	ByVal s As LPCWSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)
#else
Declare Sub ConsoleWriteColorString Alias "ConsoleWriteColorStringA"( _
	ByVal s As LPCSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)
#endif

Declare Sub ConsoleWriteColorLineA Alias "ConsoleWriteColorLineA"( _
	ByVal s As LPCSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)

Declare Sub ConsoleWriteColorLineW Alias "ConsoleWriteColorLineW"( _
	ByVal s As LPCWSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)

#ifdef unicode
Declare Sub ConsoleWriteColorLine Alias "ConsoleWriteColorLineW"( _
	ByVal s As LPCWSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)
#else
Declare Sub ConsoleWriteColorLine Alias "ConsoleWriteColorLineA"( _
	ByVal s As LPCSTR, _
	ByVal pCharsWritten As Integer Ptr, _
	ByVal ForeColor As ConsoleColors, _
	ByVal BackColor As ConsoleColors _
)
#endif

#endif
