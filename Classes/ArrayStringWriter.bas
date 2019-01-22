#include "ArrayStringWriter.bi"
#include "IntegerToWString.bi"
#include "StringConstants.bi"

Common Shared GlobalArrayStringWriterVirtualTable As IArrayStringWriterVirtualTable

Sub InitializeArrayStringWriter( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)
	
	pArrayStringWriter->pVirtualTable = @GlobalArrayStringWriterVirtualTable
	pArrayStringWriter->ReferenceCounter = 0
	pArrayStringWriter->CodePage = 1200
	pArrayStringWriter->MaxBufferLength = 0
	pArrayStringWriter->BufferLength = 0
	pArrayStringWriter->Buffer = 0
	
End Sub

Function InitializeArrayStringWriterOfIArrayStringWriter( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)As IArrayStringWriter Ptr
	
	InitializeArrayStringWriter(pArrayStringWriter)
	pArrayStringWriter->ExistsInStack = True
	
	Dim pIWriter As IArrayStringWriter Ptr = Any
	
	ArrayStringWriterQueryInterface( _
		pArrayStringWriter, @IID_IARRAYSTRINGWRITER, @pIWriter _
	)
	
	Return pIWriter
	
End Function

Function ArrayStringWriterQueryInterface( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, @pArrayStringWriter->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_ITEXTWRITER, riid) Then
		*ppv = CPtr(ITextWriter Ptr, @pArrayStringWriter->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_IARRAYSTRINGWRITER, riid) Then
		*ppv = CPtr(IArrayStringWriter Ptr, @pArrayStringWriter->pVirtualTable)
	End If
	
	If *ppv = 0 Then
		Return E_NOINTERFACE
	End If
	
	ArrayStringWriterAddRef(pArrayStringWriter)
	
	Return S_OK
	
End Function

Function ArrayStringWriterAddRef( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)As ULONG
	
	Return InterlockedIncrement(@pArrayStringWriter->ReferenceCounter)
	
End Function

Function ArrayStringWriterRelease( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)As ULONG
	
	InterlockedDecrement(@pArrayStringWriter->ReferenceCounter)
	
	If pArrayStringWriter->ReferenceCounter = 0 Then
		
		If pArrayStringWriter->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pArrayStringWriter->ReferenceCounter
	
End Function

Function ArrayStringWriterWriteLengthString( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	If pArrayStringWriter->BufferLength + Length > pArrayStringWriter->MaxBufferLength Then
		Return E_OUTOFMEMORY
	End If
	
	lstrcpyn(@pArrayStringWriter->Buffer[pArrayStringWriter->BufferLength], w, Length + 1)
	pArrayStringWriter->BufferLength += Length
	
	Return S_OK
	
End Function

Function ArrayStringWriterWriteNewLine( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthString(pArrayStringWriter, @NewLineString, 2)
	
End Function

Function ArrayStringWriterWriteString( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthString(pArrayStringWriter, w, lstrlen(w))
	
End Function

Function ArrayStringWriterWriteLengthStringLine( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	If FAILED(ArrayStringWriterWriteLengthString(pArrayStringWriter, w, Length)) Then
		Return E_OUTOFMEMORY
	End If
	
	If FAILED(ArrayStringWriterWriteNewLine(pArrayStringWriter)) Then
		Return E_OUTOFMEMORY
	End If
	
	Return S_OK
	
End Function

Function ArrayStringWriterWriteStringLine( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthStringLine(pArrayStringWriter, w, lstrlen(w))
	
End Function

Function ArrayStringWriterWriteChar( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal wc As Integer _
	)As HRESULT
	
	If pArrayStringWriter->BufferLength + 1 > pArrayStringWriter->MaxBufferLength Then
		Return E_OUTOFMEMORY
	End If
	
	pArrayStringWriter->Buffer[pArrayStringWriter->BufferLength] = wc
	pArrayStringWriter->Buffer[pArrayStringWriter->BufferLength + 1] = 0
	pArrayStringWriter->BufferLength += 1
	
	Return S_OK
	
End Function

Function ArrayStringWriterWriteInt32( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal Value As Long _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	itow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(pArrayStringWriter, @strValue)
	
End Function

Function ArrayStringWriterWriteInt64( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal Value As LongInt _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	i64tow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(pArrayStringWriter, @strValue)
	
End Function

Function ArrayStringWriterWriteUInt64( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal Value As ULongInt _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	ui64tow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(pArrayStringWriter, @strValue)
	
End Function

Function ArrayStringWriterGetCodePage( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal CodePage As Integer Ptr _
	)As HRESULT
	
	*CodePage = pArrayStringWriter->CodePage
	
	Return S_OK
	
End Function

Function ArrayStringWriterSetCodePage( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal CodePage As Integer _
	)As HRESULT
	
	pArrayStringWriter->CodePage = CodePage
	
	Return S_OK
	
End Function

Function ArrayStringWriterCloseTextWriter( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function

Function ArrayStringWriterSetBuffer( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal MaxBufferLength As Integer _
	)As HRESULT
	
	pArrayStringWriter->MaxBufferLength = MaxBufferLength
	pArrayStringWriter->Buffer = Buffer
	pArrayStringWriter->BufferLength = 0
	pArrayStringWriter->Buffer[0] = 0
	
	Return S_OK
	
End Function
