#ifndef IWEBSITECONTAINER_BI
#define IWEBSITECONTAINER_BI

#include "IWebSite.bi"

' {9042F178-B211-478B-8FF6-9C4133984364}
Dim Shared IID_IWebSiteContainer As IID = Type(&h9042f178, &hb211, &h478b, _
	{&h8f, &hf6, &h9c, &h41, &h33, &h98, &h43, &h64} _
)

Type IWebSiteContainer As IWebSiteContainer_

Type LPIWEBSITECONTAINER As IWebSiteContainer Ptr

Type IWebSiteContainerVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim FindWebSite As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal Host As WString Ptr, _
		ByVal ppIWebSite As IWebSite Ptr Ptr _
	)As HRESULT
	
	Dim GetDefaultWebSite As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal ppIWebSite As IWebSite Ptr Ptr _
	)As HRESULT
	
	Dim LoadWebSites As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal ExecutableDirectory As WString Ptr _
	)As HRESULT
	
End Type

Type IWebSiteContainer_
	Dim pVirtualTable As IWebSiteContainerVirtualTable Ptr
End Type

#define IWebSiteContainer_QueryInterface(this, riid, ppv) (this)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, this), riid, ppv)
#define IWebSiteContainer_AddRef(this) (this)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, this))
#define IWebSiteContainer_Release(this) (this)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, this))
#define IWebSiteContainer_GetDefaultWebSite(this, ppIWebSite) (this)->pVirtualTable->GetDefaultWebSite(this, ppIWebSite)
#define IWebSiteContainer_FindWebSite(this, Host, ppIWebSite) (this)->pVirtualTable->FindWebSite(this, Host, ppIWebSite)
#define IWebSiteContainer_LoadWebSites(this, ExecutableDirectory) (this)->pVirtualTable->LoadWebSites(this, ExecutableDirectory)

#endif
