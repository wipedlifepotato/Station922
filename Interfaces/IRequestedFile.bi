#ifndef IREQUESTEDFILE_BI
#define IREQUESTEDFILE_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"
#include "Http.bi"
#include "Uri.bi"

Enum RequestedFileState
	Exist
	NotFound
	Gone
End Enum

' {A44A1AB3-A0D5-42E6-A4FF-ADBAE8CE3682}
Dim Shared IID_IREQUESTEDFILE As IID = Type(&ha44a1ab3, &ha0d5, &h42e6, _
	{&ha4, &hff, &had, &hba, &he8, &hce, &h36, &h82} _
)

Type LPIREQUESTEDFILE As IRequestedFile Ptr

Type IRequestedFile As IRequestedFile_

Type IRequestedFileVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim ChoiseFile As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pUri As Uri Ptr _
	)As HRESULT
	
	Dim GetFilePath As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal ppFilePath As WString Ptr Ptr _
	)As HRESULT
	
	Dim SetFilePath As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal FilePath As WString Ptr _
	)As HRESULT
	
	Dim GetPathTranslated As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal ppPathTranslated As WString Ptr Ptr _
	)As HRESULT
	
	Dim SetPathTranslated As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal PathTranslated As WString Ptr _
	)As HRESULT
	
	Dim FileExists As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pResult As RequestedFileState Ptr _
	)As HRESULT
	
	Dim GetFileHandle As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pResult As HANDLE Ptr _
	)As HRESULT
	
	Dim GetLastFileModifiedDate As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pResult As FILETIME Ptr _
	)As HRESULT
	
	Dim GetFileLength As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pResult As ULongInt Ptr _
	)As HRESULT
	
	Dim GetVaryHeaders As Function( _
		ByVal pIRequestedFile As IRequestedFile Ptr, _
		ByVal pHeadersLength As Integer Ptr, _
		ByVal ppHeaders As HttpRequestHeaders Ptr Ptr _
	)As HRESULT
	
End Type

Type IRequestedFile_
	Dim pVirtualTable As IRequestedFileVirtualTable Ptr
End Type

#define IRequestedFile_QueryInterface(pIRequestedFile, riid, ppv) (pIRequestedFile)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, pIRequestedFile), riid, ppv)
#define IRequestedFile_AddRef(pIRequestedFile) (pIRequestedFile)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, pIRequestedFile))
#define IRequestedFile_Release(pIRequestedFile) (pIRequestedFile)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, pIRequestedFile))
#define IRequestedFile_ChoiseFile(pIRequestedFile, pResult) (pIRequestedFile)->pVirtualTable->ChoiseFile(pIRequestedFile, pUri)
#define IRequestedFile_GetFilePath(pIRequestedFile, ppFilePath) (pIRequestedFile)->pVirtualTable->GetFilePath(pIRequestedFile, ppFilePath)
#define IRequestedFile_SetFilePath(pIRequestedFile, FilePath) (pIRequestedFile)->pVirtualTable->SetFilePath(pIRequestedFile, FilePath)
#define IRequestedFile_GetPathTranslated(pIRequestedFile, ppPathTranslated) (pIRequestedFile)->pVirtualTable->GetPathTranslated(pIRequestedFile, ppPathTranslated)
#define IRequestedFile_SetPathTranslated(pIRequestedFile, PathTranslated) (pIRequestedFile)->pVirtualTable->SetPathTranslated(pIRequestedFile, PathTranslated)
#define IRequestedFile_FileExists(pIRequestedFile, pResult) (pIRequestedFile)->pVirtualTable->FileExists(pIRequestedFile, pResult)
#define IRequestedFile_GetFileHandle(pIRequestedFile, pResult) (pIRequestedFile)->pVirtualTable->GetFileHandle(pIRequestedFile, pResult)
#define IRequestedFile_GetLastFileModifiedDate(pIRequestedFile, pResult) (pIRequestedFile)->pVirtualTable->GetLastFileModifiedDate(pIRequestedFile, pResult)
#define IRequestedFile_GetVaryHeaders(pIRequestedFile, pHeadersLength, ppHeaders) (pIRequestedFile)->pVirtualTable->GetVaryHeaders(pIRequestedFile, pHeadersLength, ppHeaders)

#endif
