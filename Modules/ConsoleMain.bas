#ifndef WINDOWS_SERVICE

#include "ConsoleMain.bi"
#include "CreateInstance.bi"
#include "WebServer.bi"

Function ConsoleMain()As Integer
	
	Dim pIMemoryAllocator As IMalloc Ptr = Any
	Dim hr As HRESULT = CoGetMalloc(1, @pIMemoryAllocator)
	If FAILED(hr) Then
		Return 1
	End If
	
	Dim pIWebServer As IRunnable Ptr = Any
	hr = CreateInstance( _
		pIMemoryAllocator, _
		@CLSID_WEBSERVER, _
		@IID_IRunnable, _
		@pIWebServer _
	)
	If FAILED(hr) Then
		IMalloc_Release(pIMemoryAllocator)
		Return 1
	End If
	
	IMalloc_Release(pIMemoryAllocator)
	
	hr = IRunnable_Run(pIWebServer)
	If FAILED(hr) Then
		Return 2
	End If
	
	Const BufferLength As Integer = 7
	Dim Buffer As WString * (BufferLength + 1) = Any
	Dim NumberOfCharsRead As DWORD = Any
	ReadConsole(GetStdHandle(STD_INPUT_HANDLE), @Buffer, BufferLength, @NumberOfCharsRead, NULL)
	
	hr = IRunnable_Stop(pIWebServer)
	
	IRunnable_Release(pIWebServer)
	
	Return 0
	
End Function

#endif
