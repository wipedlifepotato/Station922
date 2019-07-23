#ifndef IASYNCRESULT_BI
#define IASYNCRESULT_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

' {01640F76-0385-43D3-8878-D6DED3B468D1}
Dim Shared IID_IASYNCRESULT As IID = Type(&h1640f76, &h385, &h43d3, _
	{&h88, &h78, &hd6, &hde, &hd3, &hb4, &h68, &hd1} _
)

Type LPIASYNCRESULT As IAsyncResult Ptr

Type IAsyncResult As IAsyncResult_

Type AsyncCallback As Sub(ByVal ar As IAsyncResult Ptr, ByVal ReadedBytes As Integer)

Type IAsyncResultVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim GetAsyncState As Function( _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal ppState As Any Ptr Ptr _
	)As HRESULT
	
	Dim SetAsyncState As Function( _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pState As Any Ptr _
	)As HRESULT
	
End Type

Type IAsyncResult_
	Dim pVirtualTable As IAsyncResultVirtualTable Ptr
End Type

#define IAsyncResult_QueryInterface(pIAsyncResult, riid, ppv) (pIAsyncResult)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIAsyncResult), riid, ppv)
#define IAsyncResult_AddRef(pIAsyncResult) (pIAsyncResult)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIAsyncResult))
#define IAsyncResult_Release(pIAsyncResult) (pIAsyncResult)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIAsyncResult))

#endif
