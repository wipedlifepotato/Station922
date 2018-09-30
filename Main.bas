#include once "Main.bi"
#include once "WebServer.bi"
#include once "Classes\InitializeVirtualTables.bi"

Function EntryPoint Alias "EntryPoint"()As Integer
	InitializeVirtualTables()
	
	Dim objWebServer As WebServer = Any
	
	Dim WebServerInitializeResult As Integer = InitializeWebServer(@objWebServer)
	If WebServerInitializeResult <> 0 Then
		Return WebServerInitializeResult
	End If
	
	WebServerMainLoop(@objWebServer)
	
	UninitializeWebServer(@objWebServer)
	
	Return 0
End Function

#if __FB_DEBUG__ <> 0
End(EntryPoint())
#endif