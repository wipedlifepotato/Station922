#include "ArrayStringWriter.bi"

Common Shared GlobalArrayStringWriterVirtualTable As ITextWriterVirtualTable

Declare Function itow cdecl Alias "_itow"( _
	ByVal Value As Long, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Declare Function i64tow cdecl Alias "_i64tow"( _
	ByVal Value As LongInt, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Declare Function ui64tow cdecl Alias "_ui64tow"( _
	ByVal Value As ULongInt, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Const NewLineString = !"\r\n"

Function ArrayStringWriterWriteLengthString( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	If this->BufferLength + Length > this->MaxBufferLength Then
		Return E_OUTOFMEMORY
	End If
	
	lstrcpyn(this->Buffer[this->BufferLength], w, Length + 1)
	this->BufferLength += Length
	
	Return S_OK
End Function

Function ArrayStringWriterWriteNewLine( _
		ByVal this As ArrayStringWriter Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthString(this, @NewLineString, 2)
	
End Function

Function ArrayStringWriterWriteString( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthString(this, w, lstrlen(w))
	
End Function

Function ArrayStringWriterWriteLengthStringLine( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As HRESULT
	
	If FAILED(ArrayStringWriterWriteLengthString(this, w, Length)) Then
		Return E_OUTOFMEMORY
	End If
	
	If FAILED(ArrayStringWriterWriteNewLine(this)) Then
		Return E_OUTOFMEMORY
	End If
	
	Return S_OK
End Function

Function ArrayStringWriterWriteStringLine( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal w As WString Ptr _
	)As HRESULT
	
	Return ArrayStringWriterWriteLengthStringLine(this, w, lstrlen(w))
	
End Function

Function ArrayStringWriterWriteChar( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal wc As Integer _
	)As HRESULT
	
	If this->BufferLength + 1 > this->MaxBufferLength Then
		Return E_OUTOFMEMORY
	End If
	
	this->Buffer[this->BufferLength] = wc
	this->Buffer[this->BufferLength + 1] = 0
	this->BufferLength += 1
	
	Return S_OK
End Function

Function ArrayStringWriterWriteInt32( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal Value As Long _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	itow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(this, @strValue)
	
End Function

Function ArrayStringWriterWriteInt64( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal Value As LongInt _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	i64tow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(this, @strValue)
	
End Function

Function ArrayStringWriterWriteUInt64( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal Value As ULongInt _
	)As HRESULT

	Dim strValue As WString * (64) = Any
	ui64tow(Value, @strValue, 10)
	
	Return ArrayStringWriterWriteString(this, @strValue)
	
End Function

Function ArrayStringWriterGetCodePage( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal CodePage As Integer Ptr _
	)As HRESULT
	
	*CodePage = this->CodePage
	
	Return S_OK
End Function

Function ArrayStringWriterSetCodePage( _
		ByVal this As ArrayStringWriter Ptr, _
		ByVal CodePage As Integer _
	)As HRESULT
	
	this->CodePage = CodePage
	
	Return S_OK
End Function

Function ArrayStringWriterCloseTextWriter( _
		ByVal this As ArrayStringWriter Ptr _
	)As HRESULT
	
	Return S_OK
End Function

Sub InitializeArrayStringWriter( _
		ByVal pArrayStringWriter As ArrayStringWriter Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal MaxBufferLength As Integer _
	)
	
	pArrayStringWriter->pVirtualTable = @GlobalArrayStringWriterVirtualTable
	pArrayStringWriter->ReferenceCounter = 1
	pArrayStringWriter->Buffer = Buffer
	pArrayStringWriter->BufferLength = 0
	pArrayStringWriter->MaxBufferLength = MaxBufferLength
	pArrayStringWriter->CodePage = 1200
	
End Sub
