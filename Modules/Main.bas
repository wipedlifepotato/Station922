#include "InitializeVirtualTables.bi"
#include "WebServer.bi"
#include "WithoutRuntime.bi"

BEGIN_MAIN_FUNCTION
	InitializeVirtualTables()
	
	Dim objWebServer As WebServer = Any
	Dim pIWebServer As IRunnable Ptr = InitializeWebServerOfIRunnable(@objWebServer)
	
	WebServer_NonVirtualRun(pIWebServer)
	
	WebServer_NonVirtualStop(pIWebServer)
	
	WebServer_NonVirtualRelease(pIWebServer)
	
	RetCode(0)
	
END_MAIN_FUNCTION
