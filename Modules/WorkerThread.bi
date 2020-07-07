#ifndef WORKERTHREAD_BI
#define WORKERTHREAD_BI

#include "IWebSiteContainer.bi"

Type WorkerThreadContext
	Dim hIOCompletionPort As HANDLE
	Dim pIWebSites As IWebSiteContainer Ptr
	Dim hThread As HANDLE
	Dim ThreadId As DWORD
	Dim ExeDir As WString * (MAX_PATH + 1)
End Type

Declare Function WorkerThread( _
	ByVal lpParam As LPVOID _
)As DWORD

#endif
