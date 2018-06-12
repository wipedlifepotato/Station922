#ifndef INTEGERTOWSTRING_BI
#define INTEGERTOWSTRING_BI

Declare Function itow cdecl Alias "_itow" (ByVal Value As Long, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr
Declare Function ltow cdecl Alias "_ltow" (ByVal Value As Long, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr
Declare Function i64tow cdecl Alias "_i64tow" (ByVal Value As LongInt, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr
Declare Function ui64tow cdecl Alias "_ui64tow" (ByVal Value As ULongInt, ByVal src As WString Ptr, ByVal radix As Integer)As WString Ptr

#endif
