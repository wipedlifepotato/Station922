#include "HeapBSTR.bi"

' Type InternalHeapBSTR
	/'
	Declare Constructor()
	Declare Constructor(ByRef rhs As Const WString)
	Declare Constructor(ByRef rhs As Const WString, ByVal NewLength As Const Integer)
	Declare Constructor(ByRef rhs As Const ValueBSTR)
	Declare Constructor(ByRef rhs As Const BSTR)
	
	'Declare Destructor()
	
	Declare Operator Let(ByRef rhs As Const WString)
	Declare Operator Let(ByRef rhs As Const ValueBSTR)
	Declare Operator Let(ByRef rhs As Const BSTR)
	
	Declare Operator Cast()ByRef As Const WString
	Declare Operator Cast()As Const BSTR
	Declare Operator Cast()As Const Any Ptr
	
	Declare Operator &=(ByRef rhs As Const WString)
	Declare Operator &=(ByRef rhs As Const ValueBSTR)
	Declare Operator &=(ByRef rhs As Const BSTR)
	
	Declare Operator +=(ByRef rhs As Const WString)
	Declare Operator +=(ByRef rhs As Const ValueBSTR)
	Declare Operator +=(ByRef rhs As Const BSTR)
	
	Declare Sub Append(ByVal Ch As Const OLECHAR)
	Declare Sub Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Declare Function GetTrailingNullChar()As WString Ptr
	
	Declare Property Length(ByVal NewLength As Const Integer)
	Declare Property Length()As Const Integer
	'/
	' Dim BytesCount As UINT
	' Dim pWChars As OLECHAR
	
' End Type

/'
Declare Operator Len(ByRef lhs As Const ValueBSTR)As Integer

Constructor ValueBSTR()
	
	BytesCount = 0
	WChars(0) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const WString)
	
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const WString, ByVal NewLength As Const Integer)
	
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, NewLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const ValueBSTR)
	
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const BSTR)
	
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Operator ValueBSTR.Let(ByRef lhs As Const WString)
	
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Operator ValueBSTR.Let(ByRef lhs As Const ValueBSTR)
	
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Operator

Operator ValueBSTR.Let(ByRef lhs As Const BSTR)
	
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Operator ValueBSTR.Cast()ByRef As Const WString
	
	Return WChars(0)
	
End Operator

Operator ValueBSTR.Cast()As Const BSTR
	
	Return @WChars(0)
	
End Operator

Operator ValueBSTR.Cast()As Const Any Ptr
	
	Return CPtr(Any Ptr, @WChars(0))
	
End Operator

Operator ValueBSTR.&=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator &=(ByRef rhs As Const ValueBSTR)

Operator ValueBSTR.&=(ByRef rhs As Const BSTR)
	Append(*CPtr(WString Ptr, rhs), SysStringLen(rhs))
End Operator

Operator ValueBSTR.+=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator +=(ByRef rhs As Const ValueBSTR)
' Declare Operator +=(ByRef rhs As Const BSTR)

Sub ValueBSTR.Append(ByVal Ch As Const OLECHAR)
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = MAX_VALUEBSTR_BUFFER_LENGTH - meLength
	
	If UnusedChars > 0 Then
		BytesCount += SizeOf(OLECHAR)
		WChars(meLength) = Ch
		WChars(meLength + 1) = 0
	End If
	
End Sub

Sub ValueBSTR.Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = MAX_VALUEBSTR_BUFFER_LENGTH - meLength
	
	If UnusedChars > 0 Then
		
		Dim Chars As Integer = min(UnusedChars, rhsLength)
		
		BytesCount = (meLength + Chars) * SizeOf(OLECHAR)
		CopyMemory(@WChars(meLength), @rhs, Chars * SizeOf(OLECHAR))
		WChars(meLength + Chars) = 0
		
	End If

End Sub

Operator Len(ByRef b As Const ValueBSTR)As Integer
	
	Return b.BytesCount \ SizeOf(OLECHAR)
	' Return SysStringLen(b)
	
End Operator

Property ValueBSTR.Length(ByVal NewLength As Const Integer)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, NewLength)
	BytesCount = Chars * SizeOf(OLECHAR)
	WChars(Chars) = 0
End Property

Property ValueBSTR.Length()As Const Integer
	Return BytesCount \ SizeOf(OLECHAR)
End Property

Function ValueBSTR.GetTrailingNullChar()As WString Ptr
	Return CPtr(WString Ptr, @WChars(Len(this)))
End Function
'/

Function HeapSysAllocString( _
		ByVal hHeap As HANDLE, _
		byval psz As Const WString Ptr _
	)As HeapBSTR
	
	Dim pszlen As UINT = lstrlenW(psz)
	
	Return HeapSysAllocStringLen(hHeap, psz, pszlen)
	
End Function

Function HeapSysAllocStringLen( _
		ByVal hHeap As HANDLE, _
		byval psz As Const WString Ptr, _
		ByVal pszlen As UINT _
	)As HeapBSTR
	
	Dim BytesCount As UINT = pszlen * SizeOf(OLECHAR)
	
	Dim pStart As Byte Ptr = HeapAlloc( _
		hHeap, _
		HEAP_NO_SERIALIZE, _
		SizeOf(Integer) + BytesCount + SizeOf(OLECHAR) _
	)
	If pStart = NULL Then
		Return NULL
	End If
	
	Dim pWChars As OLECHAR Ptr = CPtr(OLECHAR Ptr, @pStart[SizeOf(Integer)])
	Dim pBytesCount As UINT Ptr = CPtr(UINT Ptr, @pStart[-SizeOf(UINT)])
	
	*pBytesCount = BytesCount
	memcpy(pWChars, psz, BytesCount + SizeOf(OLECHAR))
	
	Return pWChars
	
End Function

Sub HeapSysFreeString( _
		ByVal hHeap As HANDLE, _
		byval bstrString As HeapBSTR _ 
	)
	
	Dim pData As Byte Ptr = CPtr(Byte Ptr, bstrString)
	Dim pStart As Any Ptr = @pData[-SizeOf(Integer)]
	
	HeapFree(hHeap, HEAP_NO_SERIALIZE, pStart)
	
End Sub
