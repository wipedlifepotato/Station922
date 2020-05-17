#ifndef ICLIENTCONTEXT_BI
#define ICLIENTCONTEXT_BI

#include "IClientRequest.bi"
#include "IHttpReader.bi"
#include "INetworkStream.bi"
#include "IRequestedFile.bi"
#include "IServerResponse.bi"
#include "IWebSiteContainer.bi"

Type IClientContext As IClientContext_

Type LPICLIENTCONTEXT As IClientContext Ptr

Extern IID_IClientContext Alias "IID_IClientContext" As Const IID

Type IClientContextVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IClientContext Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IClientContext Ptr _
	)As ULONG
	
	Dim GetRemoteAddress As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pRemoteAddress As SOCKADDR_IN Ptr _
	)As HRESULT
	
	Dim SetRemoteAddress As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal RemoteAddress As SOCKADDR_IN _
	)As HRESULT
	
	Dim GetRemoteAddressLength As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pRemoteAddressLength As Integer Ptr _
	)As HRESULT
	
	Dim SetRemoteAddressLength As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal RemoteAddressLength As Integer _
	)As HRESULT
	
	Dim GetThreadId As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pThreadId As DWORD Ptr _
	)As HRESULT
	
	Dim SetThreadId As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ThreadId As DWORD _
	)As HRESULT
	
	Dim GetThreadHandle As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pThreadHandle As HANDLE Ptr _
	)As HRESULT
	
	Dim SetThreadHandle As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ThreadHandle As HANDLE _
	)As HRESULT
	
	Dim GetClientContextHeap As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pHeap As HANDLE Ptr _
	)As HRESULT
	
	Dim SetClientContextHeap As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal hHeap As HANDLE _
	)As HRESULT
	
	Dim GetExecutableDirectory As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppExecutableDirectory As WString Ptr Ptr _
	)As HRESULT
	
	Dim SetExecutableDirectory As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pExecutableDirectory As WString Ptr _
	)As HRESULT
	
	Dim GetWebSiteContainer As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIWebSiteContainer As IWebSiteContainer Ptr Ptr _
	)As HRESULT
	
	Dim SetWebSiteContainer As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIWebSiteContainer As IWebSiteContainer Ptr _
	)As HRESULT
	
	Dim GetNetworkStream As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppINetworkStream As INetworkStream Ptr Ptr _
	)As HRESULT
	
	Dim SetNetworkStream As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr _
	)As HRESULT
	
	Dim GetFrequency As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pFrequency As LARGE_INTEGER Ptr _
	)As HRESULT
	
	Dim SetFrequency As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal Frequency As LARGE_INTEGER _
	)As HRESULT
	
	Dim GetStartTicks As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pStartTicks As LARGE_INTEGER Ptr _
	)As HRESULT
	
	Dim SetStartTicks As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal StartTicks As LARGE_INTEGER _
	)As HRESULT
	
	Dim GetClientRequest As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIRequest As IClientRequest Ptr Ptr _
	)As HRESULT
	
	Dim SetClientRequest As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIRequest As IClientRequest Ptr _
	)As HRESULT
	
	Dim GetServerResponse As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIResponse As IServerResponse Ptr Ptr _
	)As HRESULT
	
	Dim SetServerResponse As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIResponse As IServerResponse Ptr _
	)As HRESULT
	
	Dim GetHttpReader As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIHttpReader As IHttpReader Ptr Ptr _
	)As HRESULT
	
	Dim SetHttpReader As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIHttpReader As IHttpReader Ptr _
	)As HRESULT
	
	Dim GetRequestedFile As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIRequestedFile As IRequestedFile Ptr Ptr _
	)As HRESULT
	
	Dim SetRequestedFile As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As HRESULT
	
	Dim GetWebSite As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal ppIWebSite As IWebSite Ptr Ptr _
	)As HRESULT
	
	Dim SetWebSite As Function( _
		ByVal this As IClientContext Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	
End Type

Type IClientContext_
	Dim lpVtbl As IClientContextVirtualTable Ptr
End Type

#define IClientContext_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IClientContext_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IClientContext_Release(this) (this)->lpVtbl->Release(this)
#define IClientContext_GetRemoteAddress(this, pRemoteAddress) (this)->lpVtbl->GetRemoteAddress(this, pRemoteAddress)
#define IClientContext_SetRemoteAddress(this, RemoteAddress) (this)->lpVtbl->SetRemoteAddress(this, RemoteAddress)
#define IClientContext_GetRemoteAddressLength(this, pRemoteAddressLength) (this)->lpVtbl->GetRemoteAddressLength(this, pRemoteAddressLength)
#define IClientContext_SetRemoteAddressLength(this, RemoteAddressLength) (this)->lpVtbl->SetRemoteAddressLength(this, RemoteAddressLength)
#define IClientContext_GetThreadId(this, pThreadId) (this)->lpVtbl->GetThreadId(this, pThreadId)
#define IClientContext_SetThreadId(this, ThreadId) (this)->lpVtbl->SetThreadId(this, ThreadId)
#define IClientContext_GetThreadHandle(this, pThreadHandle) (this)->lpVtbl->GetThreadHandle(this, pThreadHandle)
#define IClientContext_SetThreadHandle(this, ThreadHandle) (this)->lpVtbl->SetThreadHandle(this, ThreadHandle)
#define IClientContext_GetClientContextHeap(this, pHeap) (this)->lpVtbl->GetClientContextHeap(this, pHeap)
#define IClientContext_SetClientContextHeap(this, hHeap) (this)->lpVtbl->SetClientContextHeap(this, hHeap)
#define IClientContext_GetExecutableDirectory(this, ppExecutableDirectory) (this)->lpVtbl->GetExecutableDirectory(this, ppExecutableDirectory)
#define IClientContext_SetExecutableDirectory(this, pExecutableDirectory) (this)->lpVtbl->SetExecutableDirectory(this, pExecutableDirectory)
#define IClientContext_GetWebSiteContainer(this, ppIWebSiteContainer) (this)->lpVtbl->GetWebSiteContainer(this, ppIWebSiteContainer)
#define IClientContext_SetWebSiteContainer(this, pIWebSiteContainer) (this)->lpVtbl->SetWebSiteContainer(this, pIWebSiteContainer)
#define IClientContext_GetNetworkStream(this, ppINetworkStream) (this)->lpVtbl->GetNetworkStream(this, ppINetworkStream)
' #define IClientContext_SetNetworkStream(this, pINetworkStream) (this)->lpVtbl->SetNetworkStream(this, pINetworkStream)
#define IClientContext_GetFrequency(this, pFrequency) (this)->lpVtbl->GetFrequency(this, pFrequency)
#define IClientContext_SetFrequency(this, Frequency) (this)->lpVtbl->SetFrequency(this, Frequency)
#define IClientContext_GetStartTicks(this, pStartTicks) (this)->lpVtbl->GetStartTicks(this, pStartTicks)
#define IClientContext_SetStartTicks(this, StartTicks) (this)->lpVtbl->SetStartTicks(this, StartTicks)
#define IClientContext_GetClientRequest(this, ppIRequest) (this)->lpVtbl->GetClientRequest(this, ppIRequest)
' #define IClientContext_SetClientRequest(this, pIRequest) (this)->lpVtbl->SetClientRequest(this, pIRequest)
#define IClientContext_GetServerResponse(this, ppIResponse) (this)->lpVtbl->GetServerResponse(this, ppIResponse)
' #define IClientContext_SetServerResponse(this, pIResponse) (this)->lpVtbl->SetServerResponse(this, pIResponse)
#define IClientContext_GetHttpReader(this, ppIHttpReader) (this)->lpVtbl->GetHttpReader(this, ppIHttpReader)
' #define IClientContext_SetHttpReader(this, pIHttpReader) (this)->lpVtbl->SetHttpReader(this, pIHttpReader)
#define IClientContext_GetRequestedFile(this, ppIRequestedFile) (this)->lpVtbl->GetRequestedFile(this, ppIRequestedFile)
' #define IClientContext_SetRequestedFile(this, pIRequestedFile) (this)->lpVtbl->SetRequestedFile(this, pIRequestedFile)
#define IClientContext_GetWebSite(this, ppIWebSite) (this)->lpVtbl->GetWebSite(this, ppIWebSite)
' #define IClientContext_SetWebSite(this, pIWebSite) (this)->lpVtbl->SetWebSite(this, pIWebSite)

#endif
