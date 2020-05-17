#ifndef IREQUESTPROCESSOR_BI
#define IREQUESTPROCESSOR_BI

#include "IWebSite.bi"
#include "IClientRequest.bi"
#include "IHttpReader.bi"
#include "INetworkStream.bi"

Type IRequestProcessor As IRequestProcessor_

Type LPIREQUESTPROCESSOR As IRequestProcessor Ptr

Extern IID_IRequestProcessor Alias "IID_IRequestProcessor" As Const IID

Type IRequestProcessorVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IRequestProcessor Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IRequestProcessor Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IRequestProcessor Ptr _
	)As ULONG
	
	Dim Process As Function( _
		ByVal this As IRequestProcessor Ptr, _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal pIHttpReader As IHttpReader Ptr, _
		ByVal pIWriter As INetworkStream Ptr, _
		ByVal dwError As DWORD _
	)As HRESULT
	
End Type

Type IRequestProcessor_
	Dim lpVtbl As IRequestProcessorVirtualTable Ptr
End Type

#endif
