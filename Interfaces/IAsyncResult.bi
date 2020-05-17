#ifndef IASYNCRESULT_BI
#define IASYNCRESULT_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type IAsyncResult As IAsyncResult_

Type LPIASYNCRESULT As IAsyncResult Ptr

Type AsyncCallback As Sub(ByVal ar As IAsyncResult Ptr, ByVal ReadedBytes As Integer)

Extern IID_IAsyncResult Alias "IID_IAsyncResult" As Const IID

Type IAsyncResultVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IAsyncResult Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IAsyncResult Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IAsyncResult Ptr _
	)As ULONG
	
	Dim GetAsyncState As Function( _
		ByVal this As IAsyncResult Ptr, _
		ByVal ppState As IUnknown Ptr Ptr _
	)As HRESULT
	
	Dim SetAsyncState As Function( _
		ByVal this As IAsyncResult Ptr, _
		ByVal pState As IUnknown Ptr _
	)As HRESULT
	
End Type

Type IAsyncResult_
	Dim lpVtbl As IAsyncResultVirtualTable Ptr
End Type

#define IAsyncResult_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IAsyncResult_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IAsyncResult_Release(this) (this)->lpVtbl->Release(this)

#endif
