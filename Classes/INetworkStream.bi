#ifndef INETWORKSTREAM_BI
#define INETWORKSTREAM_BI

#include "IBaseStream.bi"

Type INetworkStream As INetworkStream_

Type INetworkStreamVirtualTable
	Dim VirtualTable As IBaseStreamVirtualTable
	
End Type

Type INetworkStream_
	Dim pVirtualTable As INetworkStreamVirtualTable Ptr
End Type

#endif
