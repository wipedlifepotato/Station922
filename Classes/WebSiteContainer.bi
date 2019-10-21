#ifndef WEBSITECONTAINER_BI
#define WEBSITECONTAINER_BI

#include "IWebSiteContainer.bi"
#include "WebSite.bi"

Type WebSiteNode
	Const MaxHostNameLength As Integer = 1024 - 1
	
	Dim HostName As WString * (MaxHostNameLength + 1)
	Dim pExecutableDirectory As WString Ptr
	Dim PhysicalDirectory As WString * (MAX_PATH + 1)
	Dim VirtualPath As WString * (MaxHostNameLength + 1)
	Dim MovedUrl As WString * (MaxHostNameLength + 1)
	Dim IsMoved As Boolean
	
	Dim LeftNode As WebSiteNode Ptr
	Dim RightNode As WebSiteNode Ptr
	Dim objWebSite As WebSite
	Dim pIWebSite As IWebSite Ptr
End Type

Type WebSiteContainer
	
	Dim pVirtualTable As IWebSiteContainerVirtualTable Ptr
	Dim ReferenceCounter As ULONG
	Dim ExistsInStack As Boolean
	
	Dim ExecutableDirectory As WString * (MAX_PATH + 1)
	Dim hTreeHeap As Handle
	Dim pDefaultNode As WebSiteNode Ptr
	Dim pTree As WebSiteNode Ptr
	
End Type

Declare Function CreateWebSiteContainerOfIWebSiteContainer( _
)As IWebSiteContainer Ptr

Declare Function InitializeWebSiteContainerOfIWebSiteContainer( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr _
)As IWebSiteContainer Ptr

Declare Function WebSiteContainerQueryInterface( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr, _
	ByVal riid As REFIID, _
	ByVal ppv As Any Ptr Ptr _
)As HRESULT

Declare Function WebSiteContainerAddRef( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr _
)As ULONG

Declare Function WebSiteContainerRelease( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr _
)As ULONG

Declare Function WebSiteContainerGetDefaultWebSite( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr, _
	ByVal ppIWebSite As IWebSite Ptr Ptr _
)As HRESULT

Declare Function WebSiteContainerFindWebSite( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr, _
	ByVal Host As WString Ptr, _
	ByVal ppIWebSite As IWebSite Ptr Ptr _
)As HRESULT

Declare Function WebSiteContainerLoadWebSites( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr, _
	ByVal ExecutableDirectory As WString Ptr _
)As HRESULT

#define WebSiteContainer_NonVirtualQueryInterface(pIWebSiteContainer, riid, ppv) WebSiteContainerQueryInterface(CPtr(WebSiteContainer Ptr, pIWebSiteContainer), riid, ppv)
#define WebSiteContainer_NonVirtualAddRef(pIWebSiteContainer) WebSiteContainerAddRef(CPtr(WebSiteContainer Ptr, pIWebSiteContainer))
#define WebSiteContainer_NonVirtualRelease(pIWebSiteContainer) WebSiteContainerRelease(CPtr(WebSiteContainer Ptr, pIWebSiteContainer))
#define WebSiteContainer_NonVirtualGetDefaultWebSite(pIWebSiteContainer, ppIWebSite) WebSiteContainerGetDefaultWebSite(CPtr(WebSiteContainer Ptr, pIWebSiteContainer), ppIWebSite)
#define WebSiteContainer_NonVirtualFindWebSite(pIWebSiteContainer, Host, ppIWebSite) WebSiteContainerFindWebSite(CPtr(WebSiteContainer Ptr, pIWebSiteContainer), Host, ppIWebSite)
#define WebSiteContainer_NonVirtualLoadWebSites(pIWebSiteContainer, ExecutableDirectory) WebSiteContainerLoadWebSites(CPtr(WebSiteContainer Ptr, pIWebSiteContainer), ExecutableDirectory)

#endif
