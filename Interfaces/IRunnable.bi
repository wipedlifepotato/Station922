#ifndef IRUNNABLE_BI
#define IRUNNABLE_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

' {6603A8F5-FB80-4CB9-BF80-CEADE4576F52}
Dim Shared IID_IRUNNABLE As IID = Type(&h6603a8f5, &hfb80, &h4cb9, _
	{&hbf, &h80, &hce, &had, &he4, &h57, &h6f, &h52} _
)

Type LPIRUNNABLE As IRunnable Ptr

Type IRunnable As IRunnable_

Type IRunnableVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim Run As Function( _
		ByVal pIRunnable As IRunnable Ptr _
	)As HRESULT
	
	Dim Stop As Function( _
		ByVal pIRunnable As IRunnable Ptr _
	)As HRESULT
	
End Type

Type IRunnable_
	Dim pVirtualTable As IRunnableVirtualTable Ptr
End Type

#define IRunnable_QueryInterface(pIRunnable, riid, ppv) (pIRunnable)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIRunnable), riid, ppv)
#define IRunnable_AddRef(pIRunnable) (pIRunnable)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIRunnable))
#define IRunnable_Release(pIRunnable) (pIRunnable)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIRunnable))
#define IRunnable_Run(pIRunnable) (pIRunnable)->pVirtualTable->Run(pIRunnable)
#define IRunnable_Stop(pIRunnable) (pIRunnable)->pVirtualTable->Stop(pIRunnable)

#endif
