#ifndef IPRIVATEHEAPMEMORYALLOCATOR_BI
#define IPRIVATEHEAPMEMORYALLOCATOR_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type IPrivateHeapMemoryAllocator As IPrivateHeapMemoryAllocator_

Type LPIPRIVATEHEAPMEMORYALLOCATOR As IPrivateHeapMemoryAllocator Ptr

Extern IID_IPrivateHeapMemoryAllocator Alias "IID_IPrivateHeapMemoryAllocator" As Const IID

Type IPrivateHeapMemoryAllocatorVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)As ULONG
	
	Dim Alloc As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	
	Dim Realloc As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	
	Dim Free As Sub( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)
	
	Dim GetSize As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)As SIZE_T_
	
	Dim DidAlloc As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)As Long
	
	Dim HeapMinimize As Sub( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)
	
	Dim CreateHeap As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal NoSerialize As Boolean, _
		ByVal dwInitialSize As DWORD, _
		ByVal dwMaximumSize As DWORD _
	)As HRESULT
	
	Dim RegisterMallocSpy As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pMallocSpy As LPMALLOCSPY _
	)As HRESULT
	
	Dim RevokeMallocSpy As Function( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)As HRESULT
	
End Type

Type IPrivateHeapMemoryAllocatorVirtualTable_
	Dim lpVtbl As IPrivateHeapMemoryAllocatorVirtualTable Ptr
End Type

#define IPrivateHeapMemoryAllocator_QueryInterface(This, riid, ppvObject) (This)->lpVtbl->QueryInterface(This, riid, ppvObject)
#define IPrivateHeapMemoryAllocator_AddRef(This) (This)->lpVtbl->AddRef(This)
#define IPrivateHeapMemoryAllocator_Release(This) (This)->lpVtbl->Release(This)
#define IPrivateHeapMemoryAllocator_Alloc(This, cb) (This)->lpVtbl->Alloc(This, cb)
#define IPrivateHeapMemoryAllocator_Realloc(This, pv, cb) (This)->lpVtbl->Realloc(This, pv, cb)
#define IPrivateHeapMemoryAllocator_Free(This, pv) (This)->lpVtbl->Free(This, pv)
#define IPrivateHeapMemoryAllocator_GetSize(This, pv) (This)->lpVtbl->GetSize(This, pv)
#define IPrivateHeapMemoryAllocator_DidAlloc(This, pv) (This)->lpVtbl->DidAlloc(This, pv)
#define IPrivateHeapMemoryAllocator_HeapMinimize(This) (This)->lpVtbl->HeapMinimize(This)
#define IPrivateHeapMemoryAllocator_CreateHeap(This, NoSerialize, dwInitialSize, dwMaximumSize) (This)->lpVtbl->CreateHeap(This, NoSerialize, dwInitialSize, dwMaximumSize)
#define IPrivateHeapMemoryAllocator_RegisterMallocSpy(This, pMallocSpy) (This)->lpVtbl->RegisterMallocSpy(This, pMallocSpy)
#define IPrivateHeapMemoryAllocator_RevokeMallocSpy(This) (This)->lpVtbl->RevokeMallocSpy(This)

#endif
