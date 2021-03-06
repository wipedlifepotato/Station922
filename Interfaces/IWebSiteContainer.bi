#ifndef IWEBSITECONTAINER_BI
#define IWEBSITECONTAINER_BI

#include "IWebSite.bi"

Type IWebSiteContainer As IWebSiteContainer_

Type LPIWEBSITECONTAINER As IWebSiteContainer Ptr

Extern IID_IWebSiteContainer Alias "IID_IWebSiteContainer" As Const IID

Type IWebSiteContainerVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IWebSiteContainer Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IWebSiteContainer Ptr _
	)As ULONG
	
	Dim FindWebSite As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal Host As WString Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	
	Dim GetDefaultWebSite As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	
	Dim LoadWebSites As Function( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal ExecutableDirectory As WString Ptr _
	)As HRESULT
	
End Type

Type IWebSiteContainer_
	Dim lpVtbl As IWebSiteContainerVirtualTable Ptr
End Type

#define IWebSiteContainer_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IWebSiteContainer_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IWebSiteContainer_Release(this) (this)->lpVtbl->Release(this)
#define IWebSiteContainer_FindWebSite(this, Host, pIWebSite) (this)->lpVtbl->FindWebSite(this, Host, pIWebSite)
#define IWebSiteContainer_GetDefaultWebSite(this, pIWebSite) (this)->lpVtbl->GetDefaultWebSite(this, pIWebSite)
#define IWebSiteContainer_LoadWebSites(this, ExecutableDirectory) (this)->lpVtbl->LoadWebSites(this, ExecutableDirectory)

#endif
