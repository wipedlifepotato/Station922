#include "WebServerService.bi"
#include "InitializeVirtualTables.bi"
#include "WebServer.bi"
#include "WithoutRuntime.bi"

Const MaxWaitHint As DWORD = 3000

BeginMainFunction
	InitializeVirtualTables()
	
	Dim DispatchTable(1) As SERVICE_TABLE_ENTRY = { _
		Type<SERVICE_TABLE_ENTRY>(@ServiceName, @SvcMain), _
		Type<SERVICE_TABLE_ENTRY>(0, 0) _
	}
	
	If StartServiceCtrlDispatcher(@DispatchTable(0)) = 0 Then
	
		RetCode(1)
	
	End If
	
	RetCode(0)

EndMainFunction

Sub SvcMain( _
		ByVal dwNumServicesArgs As DWORD, _
		ByVal lpServiceArgVectors As LPWSTR ptr _
	)
	
	Dim Context As ServiceContext
	
	Context.ServiceStatusHandle = RegisterServiceCtrlHandlerEx( _
		@ServiceName, _
		@SvcCtrlHandlerEx, _
		@Context _
	)
	If Context.ServiceStatusHandle = 0 Then
		Exit Sub
	End If
	
	Context.ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS
	Context.ServiceStatus.dwServiceSpecificExitCode = 0
	
	ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, MaxWaitHint)
	
	Dim objWebServer As WebServer = Any
	Context.pIWebServer = InitializeWebServerOfIRunnable(@objWebServer)
	
	ReportSvcStatus(@Context, SERVICE_RUNNING, NO_ERROR, 0)
	
	WebServer_NonVirtualRun(Context.pIWebServer)
	
	ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
	
End Sub

Function SvcCtrlHandlerEx( _
		ByVal dwCtrl As DWORD, _
		ByVal dwEventType As DWORD, _
		ByVal lpEventData As LPVOID, _
		ByVal lpContext As LPVOID _
	)As DWORD
	
	Dim pServiceContext As ServiceContext Ptr = lpContext
	
	Select Case dwCtrl
		
		Case SERVICE_CONTROL_INTERROGATE
			ReportSvcStatus(pServiceContext, _
				pServiceContext->ServiceStatus.dwCurrentState, _
				NO_ERROR, _
				0 _
			)
			
		Case SERVICE_CONTROL_STOP, SERVICE_CONTROL_SHUTDOWN
			ReportSvcStatus(pServiceContext, _
				SERVICE_STOP_PENDING, _
				NO_ERROR, _
				MaxWaitHint _
			)
			
			WebServer_NonVirtualStop(pServiceContext->pIWebServer)
			WebServer_NonVirtualRelease(pServiceContext->pIWebServer)
			
		Case Else
			Return ERROR_CALL_NOT_IMPLEMENTED
			
	End Select
	
	Return NO_ERROR
	
End Function
	
Sub ReportSvcStatus( _
		ByVal lpContext As ServiceContext Ptr, _
		ByVal dwCurrentState As DWORD, _
		ByVal dwWin32ExitCode As DWORD, _
		ByVal dwWaitHint As DWORD _
	)
	
	lpContext->ServiceStatus.dwCurrentState = dwCurrentState
	lpContext->ServiceStatus.dwWin32ExitCode = dwWin32ExitCode
	lpContext->ServiceStatus.dwWaitHint = dwWaitHint
	
	Select Case dwCurrentState
		
		Case SERVICE_STOPPED
			lpContext->ServiceStatus.dwCheckPoint = 0
			
		Case SERVICE_START_PENDING, SERVICE_STOP_PENDING
			lpContext->ServiceCheckPoint += 1
			lpContext->ServiceStatus.dwCheckPoint = lpContext->ServiceCheckPoint
			lpContext->ServiceStatus.dwControlsAccepted = 0
			
		Case SERVICE_RUNNING
			lpContext->ServiceStatus.dwCheckPoint = 0
			lpContext->ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP Or SERVICE_ACCEPT_SHUTDOWN
			
	End Select
	
	SetServiceStatus(lpContext->ServiceStatusHandle, @lpContext->ServiceStatus)
	
End Sub
