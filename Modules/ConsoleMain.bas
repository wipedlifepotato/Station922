#include "ConsoleMain.bi"
#include "CreateInstance.bi"
#include "PrintDebugInfo.bi"
#include "WebServer.bi"

Type ServerContext
	Dim hStopEvent As HANDLE
	Dim pIWebServer As IRunnable Ptr
End Type

Function RunnableStatusHandler( _
		ByVal Context As Any Ptr, _
		ByVal Status As HRESULT _
	)As HRESULT
	
	Dim pContext As ServerContext Ptr = Context
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"RunnableStatusHandler\t", Status)
	#endif
	
	If FAILED(Status) Then
		SetEvent(pContext->hStopEvent)
	End If
	
	If Status = RUNNABLE_S_STOPPED Then
		SetEvent(pContext->hStopEvent)
	End If
	
	Return S_OK
	
End Function

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
	
	Dim hStopEvent As HANDLE = CreateEvent( _
		NULL, _
		TRUE, _
		FALSE, _
		NULL _
	)
	If hStopEvent = NULL Then
		IRunnable_Release(pIWebServer)
		Return 4
	End If
	
	Dim Context As ServerContext = Any
	With Context
		.hStopEvent = hStopEvent
		.pIWebServer = pIWebServer
	End With
	
	IRunnable_RegisterStatusHandler(pIWebServer, @Context, @RunnableStatusHandler)
	
	hr = IRunnable_Run(pIWebServer)
	If FAILED(hr) Then
		Return 2
	End If
	
	Scope
		' Const BufferLength As Integer = 7
		' Dim Buffer As WString * (BufferLength + 1) = Any
		' Dim NumberOfCharsRead As DWORD = Any
		' ReadConsole( _
			' GetStdHandle(STD_INPUT_HANDLE), _
			' @Buffer, _
			' BufferLength, _
			' @NumberOfCharsRead, _
			' NULL _
		' )
		
		WaitForSingleObject(hStopEvent, INFINITE)
		
	End Scope
	
	hr = IRunnable_Stop(pIWebServer)
	If FAILED(hr) Then
		Return 3
	End If
	
	IRunnable_Release(pIWebServer)
	
	Return 0
	
End Function
