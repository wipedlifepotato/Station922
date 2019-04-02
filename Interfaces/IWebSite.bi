#ifndef IWEBSITE_BI
#define IWEBSITE_BI

#include "IRequestedFile.bi"

Enum FileAccess
	ForPut
	ForGetHead
	ForDelete
End Enum

' {DE416BE2-F7C8-40C6-81DF-44742D47F0F7}
Dim Shared IID_IWEBSITE As IID = Type(&hde416be2, &hf7c8, &h40c6, _
	{&h81, &hdf, &h44, &h74, &h2d, &h47, &hf0, &hf7} _
)

Type LPIWEBSITE As IWebSite Ptr

Type IWebSite As IWebSite_

Type IWebSiteVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim GetHostName As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal ppHost As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetExecutableDirectory As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal ppExecutableDirectory As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetSitePhysicalDirectory As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal ppPhysicalDirectory As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetVirtualPath As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal ppVirtualPath As WString Ptr Ptr _
	)As HRESULT
	
	Dim GetIsMoved As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal pIsMoved As Boolean Ptr _
	)As HRESULT
	
	Dim GetMovedUrl As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal ppMovedUrl As WString Ptr Ptr _
	)As HRESULT
	
	Dim MapPath As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal Path As WString Ptr, _
		ByVal pResult As WString Ptr _
	)As HRESULT
	
	Dim GetRequestedFile As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal FilePath As WString Ptr, _
		ByVal ForReading As FileAccess, _
		ByVal ppRequestedFile As IRequestedFile Ptr Ptr _
	)As HRESULT
	
	Dim NeedCgiProcessing As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal path As WString Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	Dim NeedDllProcessing As Function( _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal path As WString Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
End Type

Type IWebSite_
	Dim pVirtualTable As IWebSiteVirtualTable Ptr
End Type

#define IWebSite_QueryInterface(pIWebSite, riid, ppv) (pIWebSite)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIWebSite), riid, ppv)
#define IWebSite_AddRef(pIWebSite) (pIWebSite)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIWebSite))
#define IWebSite_Release(pIWebSite) (pIWebSite)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIWebSite))
#define IWebSite_GetHostName(pIWebSite, ppHost) (pIWebSite)->pVirtualTable->GetHostName(pIWebSite, ppHost)
#define IWebSite_GetExecutableDirectory(pIWebSite, ppExecutableDirectory) (pIWebSite)->pVirtualTable->GetExecutableDirectory(pIWebSite, ppExecutableDirectory)
#define IWebSite_GetSitePhysicalDirectory(pIWebSite, ppPhysicalDirectory) (pIWebSite)->pVirtualTable->GetSitePhysicalDirectory(pIWebSite, ppPhysicalDirectory)
#define IWebSite_GetVirtualPath(pIWebSite, ppVirtualPath) (pIWebSite)->pVirtualTable->GetVirtualPath(pIWebSite, ppVirtualPath)
#define IWebSite_GetIsMoved(pIWebSite, pIsMoved) (pIWebSite)->pVirtualTable->GetIsMoved(pIWebSite, pIsMoved)
#define IWebSite_GetMovedUrl(pIWebSite, ppMovedUrl) (pIWebSite)->pVirtualTable->GetMovedUrl(pIWebSite, ppMovedUrl)
#define IWebSite_MapPath(pIWebSite, Path, pResult) (pIWebSite)->pVirtualTable->MapPath(pIWebSite, Path, pResult)
#define IWebSite_GetRequestedFile(pIWebSite, FilePath, ForReading, ppRequestedFile) (pIWebSite)->pVirtualTable->GetRequestedFile(pIWebSite, FilePath, ForReading, ppRequestedFile)
#define IWebSite_NeedCgiProcessing(pIWebSite, Path, pResult) (pIWebSite)->pVirtualTable->NeedCgiProcessing(pIWebSite, Path, pResult)
#define IWebSite_NeedDllProcessing(pIWebSite, Path, pResult) (pIWebSite)->pVirtualTable->NeedDllProcessing(pIWebSite, Path, pResult)

#endif
