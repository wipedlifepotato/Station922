#ifndef IMUTABLEWEBSITE_BI
#define IMUTABLEWEBSITE_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type IMutableWebSite As IMutableWebSite_

Type LPIMUTABLEWEBSITE As IMutableWebSite Ptr

Extern IID_IMutableWebSite Alias "IID_IMutableWebSite" As Const IID

Type IMutableWebSiteVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IMutableWebSite Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IMutableWebSite Ptr _
	)As ULONG
	
	Dim SetHostName As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal pHost As WString Ptr _
	)As HRESULT
	
	Dim SetExecutableDirectory As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal pExecutableDirectory As WString Ptr _
	)As HRESULT
	
	Dim SetSitePhysicalDirectory As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal pPhysicalDirectory As WString Ptr _
	)As HRESULT
	
	Dim SetVirtualPath As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal pVirtualPath As WString Ptr _
	)As HRESULT
	
	Dim SetIsMoved As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal IsMoved As Boolean _
	)As HRESULT
	
	Dim SetMovedUrl As Function( _
		ByVal this As IMutableWebSite Ptr, _
		ByVal pMovedUrl As WString Ptr _
	)As HRESULT
	
End Type

Type IMutableWebSite_
	Dim lpVtbl As IMutableWebSiteVirtualTable Ptr
End Type

#define IMutableWebSite_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IMutableWebSite_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IMutableWebSite_Release(this) (this)->lpVtbl->Release(this)
#define IMutableWebSite_SetHostName(this, pHost) (this)->lpVtbl->SetHostName(this, pHost)
#define IMutableWebSite_SetExecutableDirectory(this, pExecutableDirectory) (this)->lpVtbl->SetExecutableDirectory(this, pExecutableDirectory)
#define IMutableWebSite_SetSitePhysicalDirectory(this, pPhysicalDirectory) (this)->lpVtbl->SetSitePhysicalDirectory(this, pPhysicalDirectory)
#define IMutableWebSite_SetVirtualPath(this, pVirtualPath) (this)->lpVtbl->SetVirtualPath(this, pVirtualPath)
#define IMutableWebSite_SetIsMoved(this, IsMoved) (this)->lpVtbl->SetIsMoved(this, IsMoved)
#define IMutableWebSite_SetMovedUrl(this, pMovedUrl) (this)->lpVtbl->SetMovedUrl(this, pMovedUrl)

#endif
