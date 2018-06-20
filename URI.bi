#ifndef URI_BI
#define URI_BI

Type URI
	Const MaxUrlLength As Integer = 4096 - 1
	
	Dim Url As WString Ptr
	Dim Path As WString * (MaxUrlLength + 1)
	Dim QueryString As WString Ptr
	
	Declare Sub PathDecode( _
		ByVal Buffer As WString Ptr _
	)
	
End Type

Declare Sub InitializeURI( _
	ByVal pURI As URI Ptr _
)

#endif
