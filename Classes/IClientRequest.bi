#ifndef ICLIENTREQUEST_BI
#define ICLIENTREQUEST_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\objbase.bi"

' {E998CAB4-5559-409C-93BC-97AFDF6A3921}
Dim Shared IID_ICLIENTREQUEST As IID = Type(0xe998cab4, 0x5559, 0x409c, _
	{&h93, &hbc, &h97, &haf, &hdf, &h6a, &h39, &h21})

Type LPICLIENTREQUEST As IClientRequest Ptr

Type IClientRequest As IClientRequest_

Type IClientRequestVirtualTable
	Dim VirtualTable As IUnknownVtbl
End Type

Type IClientRequest_
	Dim pVirtualTable As IClientRequestVirtualTable Ptr
End Type

#endif
