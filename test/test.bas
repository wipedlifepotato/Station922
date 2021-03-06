#include "test.bi"
#include "CreateInstance.bi"
#include "PrintDebugInfo.bi"

Function ConsoleMain()As Integer
	
	Dim pIMalloc As IMalloc Ptr = Any
	Dim hr As HRESULT = CoGetPrivateHeapMalloc(1, @pIMalloc)
	If FAILED(hr) Then
		Return 1
	End If
	
	Dim Count As Integer = 1
	Do
		Dim pMem As Any Ptr = IMalloc_Alloc(pIMalloc, 512)
		If pMem = NULL Then
			Exit Do
		End If
		Count += 1
	Loop
	
	PrintErrorCode(!"Allocators Count", Count)
	
	IMalloc_Release(pIMalloc)
	
	Return 0
	
End Function
