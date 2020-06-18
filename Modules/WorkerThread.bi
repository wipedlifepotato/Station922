#ifndef WORKERTHREAD_BI
#define WORKERTHREAD_BI

#include "IWebSiteContainer.bi"

Type WorkerThreadContext
	Dim hThread As HANDLE
	Dim ThreadId As DWORD
	Dim ExeDir As WString * (MAX_PATH + 1)
	Dim pIWebSites As IWebSiteContainer Ptr
	Dim hIOCompletionPort As HANDLE
End Type

Declare Function WorkerThread( _
	ByVal lpParam As LPVOID _
)As DWORD

#endif
