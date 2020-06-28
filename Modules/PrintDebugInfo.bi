#ifndef PRINTDEBUGINFO_BI
#define PRINTDEBUGINFO_BI

#include "HttpReader.bi"

Declare Sub PrintRequestedBytes( _
	ByVal pIHttpReader As IHttpReader Ptr _
)

Declare Sub PrintResponseString( _
	ByVal wResponse As WString Ptr, _
	ByVal StatusCode As Integer _
)

Declare Sub PrintHresult( _
	ByVal pDescription As WString Ptr, _
	ByVal hr As HRESULT _
)

Declare Sub PrintErrorCode( _
	ByVal pDescription As WString Ptr, _
	ByVal dwError As DWORD _
)

Declare Sub PrintPointer( _
	ByVal pDescription As WString Ptr, _
	ByVal p As Any Ptr _
)

#ifdef PERFORMANCE_TESTING

Declare Sub PrintRequestElapsedTimes( _
	ByVal pFrequency As PLARGE_INTEGER, _
	ByVal pTicks As PLARGE_INTEGER _
)

Declare Sub PrintThreadSuspendedElapsedTimes( _
	ByVal pFrequency As PLARGE_INTEGER, _
	ByVal pTicks As PLARGE_INTEGER _
)

#endif

#endif
