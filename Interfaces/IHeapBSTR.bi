#ifndef IHEAPBSTR_BI
#define IHEAPBSTR_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type IHeapBSTR As IHeapBSTR_

Type LPIHEAPBSTR As IHeapBSTR Ptr

Extern IID_IHeapBSTR Alias "IID_IHeapBSTR" As Const IID

Type IHeapBSTRVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IHeapBSTR Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IHeapBSTR Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IHeapBSTR Ptr _
	)As ULONG
		
End Type

Type IHeapBSTR_
	Dim lpVtbl As IHeapBSTRVirtualTable Ptr
End Type

#define IHeapBSTR_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IHeapBSTR_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IHeapBSTR_Release(this) (this)->lpVtbl->Release(this)

#endif
