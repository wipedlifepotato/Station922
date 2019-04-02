#ifndef WITHOUTRUNTIME_BI
#define WITHOUTRUNTIME_BI

#ifdef withoutruntime
	#define BEGIN_MAIN_FUNCTION Function EntryPoint Alias "EntryPoint"()As Integer
	#define END_MAIN_FUNCTION End Function
	#define RetCode(Code) Return (Code)
#else
	#define BEGIN_MAIN_FUNCTION
	#define END_MAIN_FUNCTION
	#define RetCode(Code) End (Code)
#endif

#endif
