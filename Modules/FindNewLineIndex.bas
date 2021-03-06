#include "FindNewLineIndex.bi"
#include "StringConstants.bi"

Function FindCrLfIndexA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	
	For i As Integer = 0 To BufferLength - NewLineStringLength
		
		If Buffer[i + 0] = 13 AndAlso Buffer[i + 1] = 10 Then
			*pFindIndex = i
			Return True
		End If
		
	Next
	
	*pFindIndex = 0
	
	Return False
	
End Function

Function FindCrLfIndexW( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	
	For i As Integer = 0 To BufferLength - NewLineStringLength
		
		If Buffer[i + 0] = 13 AndAlso Buffer[i + 1] = 10 Then
			*pFindIndex = i
			Return True
		End If
		
	Next
	
	*pFindIndex = 0
	
	Return False
	
End Function

Function FindDoubleCrLfIndexA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	
	For i As Integer = 0 To BufferLength - NewLineStringLength * 2
		
		If Buffer[i + 0] = 13 Then
			If Buffer[i + 1] = 10  Then
				If Buffer[i + 2] = 13 Then
					If Buffer[i + 3] = 10 Then
						
						*pFindIndex = i
						Return True
						
					End If
				End If
			End If
		End If
		
	Next
	
	*pFindIndex = 0
	Return False
	
End Function
