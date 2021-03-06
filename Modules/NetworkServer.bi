#ifndef BATCHEDFILES_NETWORKSERVER_BI
#define BATCHEDFILES_NETWORKSERVER_BI

#include "Network.bi"

Declare Function CreateSocketAndListenA Alias "CreateSocketAndListenA"( _
	ByVal LocalAddress As PCSTR, _
	ByVal LocalPort As PCSTR, _
	ByVal pSocket As SOCKET Ptr _
)As HRESULT

Declare Function CreateSocketAndListenW Alias "CreateSocketAndListenW"( _
	ByVal LocalAddress As PCWSTR, _
	ByVal LocalPort As PCWSTR, _
	ByVal pSocket As SOCKET Ptr _
)As HRESULT

#ifdef UNICODE
	Declare Function CreateSocketAndListen Alias "CreateSocketAndListenW"( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
#else
	Declare Function CreateSocketAndListen Alias "CreateSocketAndListenA"( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
#endif

#endif
