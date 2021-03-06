#include "PrivateHeapMemoryAllocator.bi"
#include "ContainerOf.bi"
#include "PrintDebugInfo.bi"

Extern GlobalPrivateHeapMemoryAllocatorVirtualTable As Const IPrivateHeapMemoryAllocatorVirtualTable

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Type _PrivateHeapMemoryAllocator
	Dim lpVtbl As Const IPrivateHeapMemoryAllocatorVirtualTable Ptr
	Dim ReferenceCounter As Integer
	#ifndef WITHOUT_CRITICAL_SECTIONS
		Dim crSection As CRITICAL_SECTION
	#endif
	Dim pIMemoryAllocator As IMalloc Ptr
	Dim pISpyObject As IMallocSpy Ptr
	Dim MemoryAllocations As Integer
	Dim hHeap As HANDLE
	Dim HeapFlags As DWORD
End Type

Sub InitializePrivateHeapMemoryAllocator( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalPrivateHeapMemoryAllocatorVirtualTable
	this->ReferenceCounter = 0
	#ifndef WITHOUT_CRITICAL_SECTIONS
		InitializeCriticalSectionAndSpinCount( _
			@this->crSection, _
			MAX_CRITICAL_SECTION_SPIN_COUNT _
		)
	#endif
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->pISpyObject = NULL
	this->MemoryAllocations = 0
	this->hHeap = NULL
	this->HeapFlags = 0
	
End Sub

Sub UnInitializePrivateHeapMemoryAllocator( _
		ByVal this As PrivateHeapMemoryAllocator Ptr _
	)
	If this->pISpyObject <> NULL Then
		IMallocSpy_Release(this->pISpyObject)
	End If
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		DeleteCriticalSection(@this->crSection)
	#endif
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreatePrivateHeapMemoryAllocator( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As PrivateHeapMemoryAllocator Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"PrivateHeapMemoryAllocator create\t")
	#endif
	
	Dim this As PrivateHeapMemoryAllocator Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(PrivateHeapMemoryAllocator) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializePrivateHeapMemoryAllocator(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyPrivateHeapMemoryAllocator( _
		ByVal this As PrivateHeapMemoryAllocator Ptr _
	)
	
	#ifndef WINDOWS_SERVICE
		If this->MemoryAllocations <> 0 Then
			DebugPrint(!"\t\t\t\t\tMemoryLeak\t")
		End If
	#endif
	
	Dim hHeap As HANDLE = this->hHeap
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializePrivateHeapMemoryAllocator(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	If hHeap <> NULL Then
		HeapDestroy(hHeap)
	End If
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"PrivateHeapMemoryAllocator destroyed\t")
	#endif
End Sub

Function PrivateHeapMemoryAllocatorQueryInterface( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IPrivateHeapMemoryAllocator, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IMalloc, riid) Then
			*ppv = @this->lpVtbl
		Else
			If IsEqualIID(@IID_IUnknown, riid) Then
				*ppv = @this->lpVtbl
			Else
				*ppv = NULL
				Return E_NOINTERFACE
			End If
		End If
	End If
	
	PrivateHeapMemoryAllocatorAddRef(this)
	
	Return S_OK
	
End Function

Function PrivateHeapMemoryAllocatorAddRef( _
		ByVal this As PrivateHeapMemoryAllocator Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter += 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"\tPrivateHeapMemoryAllocatorAddRef->ReferenceCounter += 1\t", this->ReferenceCounter)
	' #endif
	
	Return 1
	
End Function

Function PrivateHeapMemoryAllocatorRelease( _
		ByVal this As PrivateHeapMemoryAllocator Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter -= 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"\tPrivateHeapMemoryAllocatorAddRef->ReferenceCounter -= 1\t", this->ReferenceCounter)
	' #endif
	
	If this->ReferenceCounter = 0 Then
		
		DestroyPrivateHeapMemoryAllocator(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function PrivateHeapMemoryAllocatorAlloc( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PreAlloc\t", cb)
	' #endif
	this->MemoryAllocations += 1
	
	If this->pISpyObject <> NULL Then
		cb = IMallocSpy_PreAlloc(this->pISpyObject, cb)
	End If
	
	Dim pMemory As Any Ptr = Any
	' EnterCriticalSection(@this->crSection)
	Scope
		pMemory = HeapAlloc( _
			this->hHeap, _
			this->HeapFlags, _
			cb _
		)
	End Scope
	' LeaveCriticalSection(@this->crSection)
	' #ifndef WINDOWS_SERVICE
		' PrintPointer(!"PostAlloc\t", pMemory)
	' #endif
	If this->pISpyObject <> NULL Then
		pMemory = IMallocSpy_PostAlloc(this->pISpyObject, pMemory)
	End If
	
	Return pMemory
	
End Function

Function PrivateHeapMemoryAllocatorRealloc( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PreReAlloc\t", cb)
	' #endif
	Dim ppNewRequest As Any Ptr Ptr = pv
	If this->pISpyObject <> NULL Then
		cb = IMallocSpy_PreRealloc(this->pISpyObject, pv, cb, ppNewRequest, True)
	End If
	
	Dim pMemory As Any Ptr = HeapReAlloc(this->hHeap, this->HeapFlags, ppNewRequest, cb)
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PostReAlloc\t", pMemory)
	' #endif
	If this->pISpyObject <> NULL Then
		pMemory = IMallocSpy_PostRealloc(this->pISpyObject, pMemory, True)
	End If
	
	Return pMemory
	
End Function

Sub PrivateHeapMemoryAllocatorFree( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal pMemory As Any Ptr _
	)
	
	this->MemoryAllocations -= 1
	
	If this->pISpyObject <> NULL Then
		pMemory = IMallocSpy_PreFree(this->pISpyObject, pMemory, True)
	End If
	' #ifndef WINDOWS_SERVICE
		' PrintPointer(!"PreFree\t", pMemory)
	' #endif
	' EnterCriticalSection(@this->crSection)
	Scope
		HeapFree( _
			this->hHeap, _
			this->HeapFlags, _
			pMemory _
		)
	End Scope
	' LeaveCriticalSection(@this->crSection)
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PostFree\t")
	' #endif
	If this->pISpyObject <> NULL Then
		IMallocSpy_PostFree(this->pISpyObject, True)
	End If
	
End Sub

Function PrivateHeapMemoryAllocatorGetSize( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal pMemory As Any Ptr _
	)As SIZE_T_
	
	Dim Size As SIZE_T_ = Any
	
	If this->pISpyObject <> NULL Then
		pMemory = IMallocSpy_PreGetSize(this->pISpyObject, pMemory, True)
	End If
	' #ifndef WINDOWS_SERVICE
		' PrintPointer(!"PreGetSize\t", pMemory)
	' #endif
	' EnterCriticalSection(@this->crSection)
	Scope
		Size = HeapSize( _
			this->hHeap, _
			this->HeapFlags, _
			pMemory _
		)
	End Scope
	' LeaveCriticalSection(@this->crSection)
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PostGetSize\t", Size)
	' #endif
	If this->pISpyObject <> NULL Then
		Size = IMallocSpy_PostGetSize(this->pISpyObject, Size, True)
	End If
	
	Return Size
	
End Function

Function PrivateHeapMemoryAllocatorDidAlloc( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal pMemory As Any Ptr _
	)As Long
	
	' #ifndef WINDOWS_SERVICE
		' PrintPointer(!"PreDidAlloc\t", pMemory)
	' #endif
	Dim phe As PROCESS_HEAP_ENTRY = Any
	ZeroMemory(@phe, SizeOf(PROCESS_HEAP_ENTRY))
	
	If this->pISpyObject <> NULL Then
		pMemory = IMallocSpy_PreDidAlloc(this->pISpyObject, pMemory, True)
	End If
	
	Dim res As Long = 0
	Do While HeapWalk(this->hHeap, @phe)
		If phe.lpData = pMemory Then
			res = 1
			Exit Do
		End If
	Loop
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PostDidAlloc\t", CInt(res))
	' #endif
	If this->pISpyObject <> NULL Then
		res = IMallocSpy_PostDidAlloc(this->pISpyObject, pMemory, True, res)
	End If
	
	Return res
	
End Function

Sub PrivateHeapMemoryAllocatorHeapMinimize( _
		ByVal this As PrivateHeapMemoryAllocator Ptr _
	)
	
	If this->pISpyObject <> NULL Then
		IMallocSpy_PreHeapMinimize(this->pISpyObject)
	End If
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PreMinimize\t")
	' #endif
	HeapCompact(this->hHeap, this->HeapFlags)
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PostMinimize\t")
	' #endif
	If this->pISpyObject <> NULL Then
		IMallocSpy_PostHeapMinimize(this->pISpyObject)
	End If
	
End Sub

Function PrivateHeapMemoryAllocatorCreateHeap( _
		ByVal this As PrivateHeapMemoryAllocator Ptr, _
		ByVal NoSerialize As Boolean, _
		ByVal dwInitialSize As DWORD, _
		ByVal dwMaximumSize As DWORD _
	)As HRESULT
	
	' #ifndef WINDOWS_SERVICE
		' DebugPrint(!"PreCreateHeap\t")
	' #endif
	If NoSerialize Then
		this->HeapFlags = HEAP_NO_SERIALIZE
	Else
		this->HeapFlags = 0
	End If
	
	this->hHeap = HeapCreate( _
		this->HeapFlags, _
		dwInitialSize, _
		dwMaximumSize _
	)
	Dim dwError As DWORD = GetLastError()
	' #ifndef WINDOWS_SERVICE
		' PrintPointer(!"PostCreateHeap\t", this->hHeap)
	' #endif
	If this->hHeap = NULL Then
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

' Declare Function PrivateHeapMemoryAllocatorRegisterMallocSpy( _
	' ByVal this As PrivateHeapMemoryAllocator Ptr, _
	' ByVal pMallocSpy As LPMALLOCSPY _
' )As HRESULT

' Declare Function PrivateHeapMemoryAllocatorRevokeMallocSpy( _
	' ByVal this As PrivateHeapMemoryAllocator Ptr _
' )As HRESULT


Function IPrivateHeapMemoryAllocatorQueryInterface( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return PrivateHeapMemoryAllocatorQueryInterface(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), riid, ppvObject)
End Function

Function IPrivateHeapMemoryAllocatorAddRef( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)As ULONG
	Return PrivateHeapMemoryAllocatorAddRef(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl))
End Function

Function IPrivateHeapMemoryAllocatorRelease( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)As ULONG
	Return PrivateHeapMemoryAllocatorRelease(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl))
End Function

Function IPrivateHeapMemoryAllocatorAlloc( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	Return PrivateHeapMemoryAllocatorAlloc(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), cb)
End Function

Function IPrivateHeapMemoryAllocatorRealloc( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr, _
		ByVal cb As SIZE_T_ _
	)As Any Ptr
	Return PrivateHeapMemoryAllocatorRealloc(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), pv, cb)
End Function

Sub IPrivateHeapMemoryAllocatorFree( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)
	PrivateHeapMemoryAllocatorFree(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), pv)
End Sub

Function IPrivateHeapMemoryAllocatorGetSize( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)As SIZE_T_
	Return PrivateHeapMemoryAllocatorGetSize(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), pv)
End Function

Function IPrivateHeapMemoryAllocatorDidAlloc( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal pv As Any Ptr _
	)As Long
	Return PrivateHeapMemoryAllocatorDidAlloc(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), pv)
End Function

Sub IPrivateHeapMemoryAllocatorHeapMinimize( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr _
	)
	PrivateHeapMemoryAllocatorHeapMinimize(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl))
End Sub

Function IPrivateHeapMemoryAllocatorCreateHeap( _
		ByVal this As IPrivateHeapMemoryAllocator Ptr, _
		ByVal NoSerialize As Boolean, _
		ByVal dwInitialSize As DWORD, _
		ByVal dwMaximumSize As DWORD _
	)As HRESULT
	Return PrivateHeapMemoryAllocatorCreateHeap(ContainerOf(this, PrivateHeapMemoryAllocator, lpVtbl), NoSerialize, dwInitialSize, dwMaximumSize)
End Function

Dim GlobalPrivateHeapMemoryAllocatorVirtualTable As Const IPrivateHeapMemoryAllocatorVirtualTable = Type( _
	@IPrivateHeapMemoryAllocatorQueryInterface, _
	@IPrivateHeapMemoryAllocatorAddRef, _
	@IPrivateHeapMemoryAllocatorRelease, _
	@IPrivateHeapMemoryAllocatorAlloc, _
	@IPrivateHeapMemoryAllocatorRealloc, _
	@IPrivateHeapMemoryAllocatorFree, _
	@IPrivateHeapMemoryAllocatorGetSize, _
	@IPrivateHeapMemoryAllocatorDidAlloc, _
	@IPrivateHeapMemoryAllocatorHeapMinimize, _
	@IPrivateHeapMemoryAllocatorCreateHeap, _
	NULL, _
	NULL _
)
