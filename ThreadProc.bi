#ifndef THREADPROC_BI
#define THREADPROC_BI

#ifndef unicode
#define unicode
#endif

#include once "windows.bi"

' Процедура потока
Declare Function ThreadProc(ByVal lpParam As LPVOID)As DWORD

#endif
