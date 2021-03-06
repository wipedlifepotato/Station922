#ifndef IPAUSEABLE_BI
#define IPAUSEABLE_BI

#include "IRunnable.bi"

Const PAUSEABLE_S_PAUSE_PENDING As HRESULT = MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_ITF, &h0206)
Const PAUSEABLE_S_PAUSED As HRESULT = MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_ITF, &h0207)
Const PAUSEABLE_S_CONTINUE_PENDING As HRESULT = MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_ITF, &h0205)

Type IPauseable As IPauseable_

Type LPIPAUSEABLE As IPauseable Ptr

Extern IID_IPauseable Alias "IID_IPauseable" As Const IID

Type IPauseableVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IPauseable Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IPauseable Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IPauseable Ptr _
	)As ULONG
	
	Dim Run As Function( _
		ByVal this As IPauseable Ptr _
	)As HRESULT
	
	Dim Stop As Function( _
		ByVal this As IPauseable Ptr _
	)As HRESULT
	
	Dim IsRunning As Function( _
		ByVal this As IPauseable Ptr _
	)As HRESULT
	
	Dim RegisterStatusHandler As Function( _
		ByVal this As IPauseable Ptr, _
		ByVal Context As Any Ptr, _
		ByVal StatusHandler As RunnableStatusHandler _
	)As HRESULT
	
	Dim Suspend As Function( _
		ByVal this As IPauseable Ptr _
	)As HRESULT
	
	Dim Resume As Function( _
		ByVal this As IPauseable Ptr _
	)As HRESULT
	
End Type

Type IPauseable_
	Dim lpVtbl As IPauseableVirtualTable Ptr
End Type

#define IPauseable_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IPauseable_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IPauseable_Release(this) (this)->lpVtbl->Release(this)
#define IPauseable_Run(this) (this)->lpVtbl->Run(this)
#define IPauseable_Stop(this) (this)->lpVtbl->Stop(this)
#define IPauseable_IsRunning(this) (this)->lpVtbl->IsRunning(this)
#define IPauseable_RegisterStatusHandler(this, Context, StatusHandler) (this)->lpVtbl->RegisterStatusHandler(this, Context, StatusHandler)
#define IPauseable_Suspend(this) (this)->lpVtbl->Suspend(this)
#define IPauseable_Resume(this) (this)->lpVtbl->Resume(this)

#endif
