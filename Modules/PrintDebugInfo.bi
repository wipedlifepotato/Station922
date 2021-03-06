#ifndef PRINTDEBUGINFO_BI
#define PRINTDEBUGINFO_BI

#include "Http.bi"
#include "HttpReader.bi"

Declare Sub DebugPrint Overload( _
	ByVal pIHttpReader As IHttpReader Ptr _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr, _
	ByVal StatusCode As HttpStatusCodes _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr, _
	ByVal hr As Integer _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr, _
	ByVal hr As HRESULT _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr, _
	ByVal dwError As DWORD _
)

Declare Sub DebugPrint Overload( _
	ByVal lpwsz As WString Ptr, _
	ByVal p As Any Ptr _
)

#ifdef PERFORMANCE_TESTING

Declare Sub DebugPrint Overload( _
	ByVal pFrequency As PLARGE_INTEGER, _
	ByVal pTicks As PLARGE_INTEGER _
)

#endif

#endif
