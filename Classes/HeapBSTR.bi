#ifndef BATCHEDFILES_HEAPBSTR_BI
#define BATCHEDFILES_HEAPBSTR_BI

#include "windows.bi"
#include "win\ole2.bi"

Type _HeapBSTR As OLECHAR Ptr

Type HeapBSTR As _HeapBSTR

Type LPHEAPBSTR As _HeapBSTR Ptr

Declare Function HeapSysAllocString( _
	ByVal hHeap As HANDLE, _
	byval psz As Const WString Ptr _
)As HeapBSTR

Declare Function HeapSysAllocStringLen( _
	ByVal hHeap As HANDLE, _
	byval psz As Const WString Ptr, _
	ByVal ui As UINT _
)As HeapBSTR

Declare Sub HeapSysFreeString( _
	ByVal hHeap As HANDLE, _
	byval bstrString As HeapBSTR _ 
)

#endif
