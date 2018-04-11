#ifndef APPENDINGBUFFER_BI
#define APPENDINGBUFFER_BI

Type AppendingBuffer
	Dim Buffer As WString Ptr
	Dim BufferLength As Integer
	
	Declare Constructor( _
		ByVal wBuffer As WString Ptr _
	)
	
	Declare Sub AppendWLine( _
	)
	
	Declare Sub AppendWLine( _
		ByVal w As WString Ptr _
	)
	
	Declare Sub AppendWLine( _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)
	
	Declare Sub AppendWString( _
		ByVal w As WString Ptr _
	)
	
	Declare Sub AppendWString( _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)
	
	Declare Sub AppendWChar( _
		ByVal wc As Integer _
	)
End Type

#endif
