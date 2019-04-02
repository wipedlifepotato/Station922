#ifndef IWEBSITECONTAINER_BI
#define IWEBSITECONTAINER_BI

#include "IWebSite.bi"

' {9042F178-B211-478B-8FF6-9C4133984364}
Dim Shared IID_IWEBSITECONTAINER As IID = Type(&h9042f178, &hb211, &h478b, _
	{&h8f, &hf6, &h9c, &h41, &h33, &h98, &h43, &h64} _
)

Type LPIWEBSITECONTAINER As IWebSiteContainer Ptr

Type IWebSiteContainer As IWebSiteContainer_

Type IWebSiteContainerVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim FindWebSite As Function( _
		ByVal pIWebSiteContainer As IWebSiteContainer Ptr, _
		ByVal Host As WString Ptr, _
		ByVal ppIWebSite As IWebSite Ptr Ptr _
	)As HRESULT
	
	Dim GetDefaultWebSite As Function( _
		ByVal pIWebSiteContainer As IWebSiteContainer Ptr, _
		ByVal ppIWebSite As IWebSite Ptr Ptr _
	)As HRESULT
	
	Dim LoadWebSites As Function( _
		ByVal pIWebSiteContainer As IWebSiteContainer Ptr, _
		ByVal ExecutableDirectory As WString Ptr _
	)As HRESULT
	
End Type

Type IWebSiteContainer_
	Dim pVirtualTable As IWebSiteContainerVirtualTable Ptr
End Type

#define IWebSiteContainer_QueryInterface(pIWebSiteContainer, riid, ppv) (pIWebSiteContainer)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIWebSiteContainer), riid, ppv)
#define IWebSiteContainer_AddRef(pIWebSiteContainer) (pIWebSiteContainer)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIWebSiteContainer))
#define IWebSiteContainer_Release(pIWebSiteContainer) (pIWebSiteContainer)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIWebSiteContainer))
#define IWebSiteContainer_GetDefaultWebSite(pIWebSiteContainer, ppIWebSite) (pIWebSiteContainer)->pVirtualTable->GetDefaultWebSite(pIWebSiteContainer, ppIWebSite)
#define IWebSiteContainer_FindWebSite(pIWebSiteContainer, Host, ppIWebSite) (pIWebSiteContainer)->pVirtualTable->FindWebSite(pIWebSiteContainer, Host, ppIWebSite)
#define IWebSiteContainer_LoadWebSites(pIWebSiteContainer, ExecutableDirectory) (pIWebSiteContainer)->pVirtualTable->LoadWebSites(pIWebSiteContainer, ExecutableDirectory)

#endif
