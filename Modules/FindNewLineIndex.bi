#ifndef BATCHEDFILES_FINDCRLFINDEX_BI
#define BATCHEDFILES_FINDCRLFINDEX_BI

Declare Function FindCrLfIndexA Alias "FindCrLfIndexA"( _
	ByVal Buffer As ZString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal pFindIndex As Integer Ptr _
)As Boolean

Declare Function FindCrLfIndexW Alias "FindCrLfIndexW"( _
	ByVal Buffer As WString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal pFindIndex As Integer Ptr _
)As Boolean

#ifdef UNICODE
	Declare Function FindCrLfIndex Alias "FindCrLfIndexW"( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
#else
	Declare Function FindCrLfIndex Alias "FindCrLfIndexA"( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
#endif

Declare Function FindDoubleCrLfIndexA Alias "FindDoubleCrLfIndexA"( _
	ByVal Buffer As ZString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal pFindIndex As Integer Ptr _
)As Boolean

Declare Function FindDoubleCrLfIndexW Alias "FindDoubleCrLfIndexW"( _
	ByVal Buffer As WString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal pFindIndex As Integer Ptr _
)As Boolean

#ifdef UNICODE
	Declare Function FindDoubleCrLfIndex Alias "FindDoubleCrLfIndexW"( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
#else
	Declare Function FindDoubleCrLfIndex Alias "FindDoubleCrLfIndexA"( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
#endif

#endif
