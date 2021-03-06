#ifndef ICONFIGURATION_BI
#define ICONFIGURATION_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type IConfiguration As IConfiguration_

Type LPICONFIGURATION As IConfiguration Ptr

Extern IID_IConfiguration Alias "IID_IConfiguration" As Const IID

Type IConfigurationVirtualTable
	
	Dim QueryInterface As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IConfiguration Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IConfiguration Ptr _
	)As ULONG
	
	Dim SetIniFilename As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal pFileName As WString Ptr _
	)As HRESULT
	
	Dim GetStringValue As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pValue As WString Ptr, _
		ByVal pValueLength As Integer Ptr _
	)As HRESULT
	
	Dim GetIntegerValue As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As Integer, _
		ByVal pValue As Integer Ptr _
	)As HRESULT
	
	Dim GetAllSections As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pSections As WString Ptr, _
		ByVal pSectionsLength As Integer Ptr _
	)As HRESULT
	
	Dim GetAllKeys As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pKeys As WString Ptr, _
		ByVal pKeysLength As Integer Ptr _
	)As HRESULT
	
	Dim SetStringValue As Function( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal pValue As WString Ptr _
	)As HRESULT
	
End Type

Type IConfiguration_
	Dim lpVtbl As IConfigurationVirtualTable Ptr
End Type

#define IConfiguration_QueryInterface(this, riid, ppv) (this)->lpVtbl->QueryInterface(this, riid, ppv)
#define IConfiguration_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IConfiguration_Release(this) (this)->lpVtbl->Release(this)
#define IConfiguration_SetIniFilename(this, pFileName) (this)->lpVtbl->SetIniFilename(this, pFileName)
#define IConfiguration_GetStringValue(this, Section, Key, DefaultValue, BufferLength, pValue, pValueLength) (this)->lpVtbl->GetStringValue(this, Section, Key, DefaultValue, BufferLength, pValue, pValueLength)
#define IConfiguration_GetIntegerValue(this, Section, Key, DefaultValue, pValue) (this)->lpVtbl->GetIntegerValue(this, Section, Key, DefaultValue, pValue)
#define IConfiguration_GetAllSections(this, BufferLength, pSections, pSectionsLength) (this)->lpVtbl->GetAllSections(this, BufferLength, pSections, pSectionsLength)
#define IConfiguration_GetAllKeys(this, Section, BufferLength, pKeys, pKeysLength) (this)->lpVtbl->GetAllKeys(this, Section, BufferLength, pKeys, pKeysLength)
#define IConfiguration_SetStringValue(this, Section, Keys, pValue) (this)->lpVtbl->SetStringValue(this, Section, Keys, pValue)

#endif
