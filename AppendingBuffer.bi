Type AppendingBuffer
	Dim Buffer As WString Ptr
	Dim BufferLength As Integer
	
	Declare Sub AppendWString(ByVal w As WString Ptr)
	Declare Sub AppendWString(ByVal w As WString Ptr, ByVal Length As Integer)
	Declare Sub AppendWChar(ByVal wc As Integer)
End Type