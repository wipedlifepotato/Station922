#ifndef INTEGERTOWSTRING_BI
#define INTEGERTOWSTRING_BI

Declare Function itow cdecl Alias "_itow"( _
	ByVal Value As Long, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Declare Function uitow cdecl Alias "_uitow"( _
	ByVal Value As Long, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Declare Function ltow cdecl Alias "_ltow"( _
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

#endif
