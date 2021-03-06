#include "PrintDebugInfo.bi"
#include "ConsoleColors.bi"
#include "IntegerToWString.bi"
#include "StringConstants.bi"

Const InformationForeground = ConsoleColors.Gray
Const InformationBackground = ConsoleColors.Black

Const RequestedBytesForeground = ConsoleColors.Green
Const RequestedBytesBackground = ConsoleColors.Black

Const ResponseBytesBackground = ConsoleColors.Black

Const MicroSeconds As LongInt = 1000 * 1000
Const IntegerToStringBufferLength As Integer = 128 - 1

Sub DebugPrint Overload( _
		ByVal pDescription As WString Ptr, _
		ByVal dwError As DWORD _
	)
	Dim wstrCode As WString * (2 * IntegerToStringBufferLength + 1) = Any
	i64tow(Clngint(dwError), @wstrCode, 10)
	
	Dim wstrTemp As WString * (5 * IntegerToStringBufferLength + 1) = Any
	lstrcpy(@wstrTemp, pDescription)
	lstrcat(@wstrTemp, @wstrCode)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		@wstrTemp, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
End Sub

Sub DebugPrint Overload( _
		ByVal pDescription As WString Ptr, _
		ByVal hr As HRESULT _
	)
	Dim wstrCode As WString * (2 * IntegerToStringBufferLength + 1) = Any
	i64tow(Clngint(hr), @wstrCode, 16)
	
	Dim wstrTemp As WString * (5 * IntegerToStringBufferLength + 1) = Any
	lstrcpy(@wstrTemp, pDescription)
	lstrcat(@wstrTemp, @wstrCode)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		@wstrTemp, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
End Sub

Sub DebugPrint Overload( _
		ByVal pDescription As WString Ptr, _
		ByVal p As Any Ptr _
	)
	Dim wstrPointer As WString * (2 * IntegerToStringBufferLength + 1) = Any
	#ifdef __FB_64BIT__
		i64tow(Cint(p), @wstrPointer, 10)
	#else
		itow(Cint(p), @wstrPointer, 10)
	#endif
	
	Dim wstrTemp As WString * (5 * IntegerToStringBufferLength + 1) = Any
	lstrcpy(@wstrTemp, pDescription)
	lstrcat(@wstrTemp, @wstrPointer)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		@wstrTemp, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
End Sub

Sub DebugPrint Overload( _
		ByVal pIHttpReader As IHttpReader Ptr _
	)
	Dim pRequestedBytes As UByte Ptr = Any
	Dim RequestedBytesLength As Integer = Any
	IHttpReader_GetRequestedBytes(pIHttpReader, @RequestedBytesLength, @pRequestedBytes)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineA(pRequestedBytes, _
		@CharsWritten, _
		RequestedBytesForeground, _
		RequestedBytesBackground _
	)
	
End Sub

Sub DebugPrint Overload( _
		ByVal wResponse As WString Ptr, _
		ByVal StatusCode As HttpStatusCodes _
	)
	Dim ForeColor As ConsoleColors = Any
	
	Select Case StatusCode
		
		Case 100 To 199
			ForeColor = ConsoleColors.Gray
			
		Case 200
			ForeColor = ConsoleColors.Blue
			
		Case 201 To 299
			ForeColor = ConsoleColors.Cyan
			
		Case 300 To 399
			ForeColor = ConsoleColors.Yellow
			
		Case 400 To 499
			ForeColor = ConsoleColors.Red
			
		Case Else
			ForeColor = ConsoleColors.Magenta
			
	End Select
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW(wResponse, @CharsWritten, ForeColor, ResponseBytesBackground)
	
End Sub

Sub DebugPrint Overload( _
		ByVal wResponse As WString Ptr _
	)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		wResponse, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
	
End Sub

#ifdef PERFORMANCE_TESTING

Sub ElapsedTimesToString( _
		ByVal wstrElapsedTimes As WString Ptr, _
		ByVal pFrequency As PLARGE_INTEGER, _
		ByVal pTicks As PLARGE_INTEGER _
	)
	Dim ElapsedTimes As LongInt = (pTicks->QuadPart * MicroSeconds) \ pFrequency->QuadPart
	
	i64tow(ElapsedTimes, wstrElapsedTimes, 10)
	
End Sub

Sub PrintRequestElapsedTimes( _
		ByVal pFrequency As PLARGE_INTEGER, _
		ByVal pTicks As PLARGE_INTEGER _
	)
	Dim wstrElapsedTimes As WString * (IntegerToStringBufferLength + 1) = Any
	ElapsedTimesToString(@wstrElapsedTimes, pFrequency, pTicks)
	
	Dim wstrTemp As WString * (2 * IntegerToStringBufferLength + 1) = Any
	lstrcpy(@wstrTemp, @!"Обработка запроса:\t")
	lstrcat(@wstrTemp, @wstrElapsedTimes)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		@wstrTemp, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
	
End Sub

Sub PrintThreadSuspendedElapsedTimes( _
		ByVal pFrequency As PLARGE_INTEGER, _
		ByVal pTicks As PLARGE_INTEGER _
	)
	Dim wstrElapsedTimes As WString * (IntegerToStringBufferLength + 1) = Any
	ElapsedTimesToString(@wstrElapsedTimes, pFrequency, pTicks)
	
	Dim wstrTemp As WString * (2 * IntegerToStringBufferLength + 1) = Any
	lstrcpy(@wstrTemp, @!"Пробуждение потока:\t")
	lstrcat(@wstrTemp, @wstrElapsedTimes)
	
	Dim CharsWritten As Integer = Any
	ConsoleWriteColorLineW( _
		@wstrTemp, _
		@CharsWritten, _
		InformationForeground, _
		InformationBackground _
	)
	
End Sub

#endif
