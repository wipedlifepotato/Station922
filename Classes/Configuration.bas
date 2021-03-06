#include "Configuration.bi"
#include "ContainerOf.bi"
#include "PrintDebugInfo.bi"

Extern GlobalConfigurationVirtualTable As Const IConfigurationVirtualTable

Type _Configuration
	Dim lpVtbl As Const IConfigurationVirtualTable Ptr
	Dim ReferenceCounter As Integer
	Dim pIMemoryAllocator As IMalloc Ptr
	Dim IniFileName As WString * (MAX_PATH + 1)
End Type

Sub InitializeConfiguration( _
		ByVal this As Configuration Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalConfigurationVirtualTable
	this->ReferenceCounter = 0
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->IniFileName[0] = 0
	
End Sub

Sub UnInitializeConfiguration( _
		ByVal this As Configuration Ptr _
	)
	
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateConfiguration( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As Configuration Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"Configuration create\t")
	#endif
	
	Dim this As Configuration Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(Configuration) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeConfiguration(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyConfiguration( _
		ByVal this As Configuration Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeConfiguration(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"Configuration destroyed\t")
	#endif
	
End Sub

Function ConfigurationQueryInterface( _
		ByVal this As Configuration Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IConfiguration, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IUnknown, riid) Then
			*ppv = @this->lpVtbl
		Else
			*ppv = NULL
			Return E_NOINTERFACE
		End If
	End If
	
	ConfigurationAddRef(this)
	
	Return S_OK
	
End Function

Function ConfigurationAddRef( _
		ByVal this As Configuration Ptr _
	)As ULONG
	
	this->ReferenceCounter += 1
	
	Return 1
	
End Function

Function ConfigurationRelease( _
		ByVal this As Configuration Ptr _
	)As ULONG
	
	this->ReferenceCounter -= 1
	
	If this->ReferenceCounter = 0 Then
		
		DestroyConfiguration(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function ConfigurationSetIniFilename( _
		ByVal this As Configuration Ptr, _
		ByVal pFileName As WString Ptr _
	)As HRESULT
	
	lstrcpyn(@this->IniFileName, pFileName, MAX_PATH + 1)
	
	Return S_OK
	
End Function

Function ConfigurationGetStringValue( _
		ByVal this As Configuration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pValue As WString Ptr, _
		ByVal pValueLength As Integer Ptr _
	)As HRESULT
	
	*pValueLength = GetPrivateProfileString(Section, Key, DefaultValue, pValue, Cast(DWORD, BufferLength), @this->IniFileName)
	
	Return S_OK
	
End Function

Function ConfigurationGetIntegerValue( _
		ByVal this As Configuration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As Integer, _
		ByVal pValue As Integer Ptr _
	)As HRESULT
	
	*pValue = GetPrivateProfileInt(Section, Key, DefaultValue, @this->IniFileName)
	
	Return S_OK
	
End Function

Function ConfigurationGetAllSections( _
		ByVal this As Configuration Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pSections As WString Ptr, _
		ByVal pSectionsLength As Integer Ptr _
	)As HRESULT
	
	Dim DefaultValue As WString * 4 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	DefaultValue[2] = 0
	DefaultValue[3] = 0
	
	*pSectionsLength = GetPrivateProfileString(NULL, NULL, @DefaultValue, pSections, Cast(DWORD, BufferLength), @this->IniFileName)
	
	Return S_OK
	
End Function

Function ConfigurationGetAllKeys( _
		ByVal this As Configuration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pKeys As WString Ptr, _
		ByVal pKeysLength As Integer Ptr _
	)As HRESULT
	
	Dim DefaultValue As WString * 4 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	DefaultValue[2] = 0
	DefaultValue[3] = 0
	
	*pKeysLength = GetPrivateProfileString(Section, NULL, @DefaultValue, pKeys, Cast(DWORD, BufferLength), @this->IniFileName)
	
	Return S_OK
	
End Function

Function ConfigurationSetStringValue( _
		ByVal this As Configuration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal pValue As WString Ptr _
	)As HRESULT
	
	Dim Result As Integer = WritePrivateProfileString(Section, Key, pValue, @this->IniFileName)
	If Result = 0 Then
		Dim dwError As DWORD = GetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(dwError)
		Return hr
	End If
	
	Return S_OK
	
End Function

Function IConfigurationQueryInterface( _
		ByVal this As IConfiguration Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return ConfigurationQueryInterface(ContainerOf(this, Configuration, lpVtbl), riid, ppvObject)
End Function

Function IConfigurationAddRef( _
		ByVal this As IConfiguration Ptr _
	)As ULONG
	Return ConfigurationAddRef(ContainerOf(this, Configuration, lpVtbl))
End Function

Function IConfigurationRelease( _
		ByVal this As IConfiguration Ptr _
	)As ULONG
	Return ConfigurationRelease(ContainerOf(this, Configuration, lpVtbl))
End Function

Function IConfigurationSetIniFilename( _
		ByVal this As IConfiguration Ptr, _
		ByVal pFileName As WString Ptr _
	)As HRESULT
	Return ConfigurationSetIniFilename(ContainerOf(this, Configuration, lpVtbl), pFileName)
End Function

Function IConfigurationGetStringValue( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pValue As WString Ptr, _
		ByVal pValueLength As Integer Ptr _
	)As HRESULT
	Return ConfigurationGetStringValue(ContainerOf(this, Configuration, lpVtbl), Section, Key, DefaultValue, BufferLength, pValue, pValueLength)
End Function

Function IConfigurationGetIntegerValue( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal DefaultValue As Integer, _
		ByVal pValue As Integer Ptr _
	)As HRESULT
	Return ConfigurationGetIntegerValue(ContainerOf(this, Configuration, lpVtbl), Section, Key, DefaultValue, pValue)
End Function

Function IConfigurationGetAllSections( _
		ByVal this As IConfiguration Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pSections As WString Ptr, _
		ByVal pSectionsLength As Integer Ptr _
	)As HRESULT
	Return ConfigurationGetAllSections(ContainerOf(this, Configuration, lpVtbl), BufferLength, pSections, pSectionsLength)
End Function

Function IConfigurationGetAllKeys( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pKeys As WString Ptr, _
		ByVal pKeysLength As Integer Ptr _
	)As HRESULT
	Return ConfigurationGetAllKeys(ContainerOf(this, Configuration, lpVtbl), Section, BufferLength, pKeys, pKeysLength)
End Function

Function IConfigurationSetStringValue( _
		ByVal this As IConfiguration Ptr, _
		ByVal Section As WString Ptr, _
		ByVal Key As WString Ptr, _
		ByVal pValue As WString Ptr _
	)As HRESULT
	Return ConfigurationSetStringValue(ContainerOf(this, Configuration, lpVtbl), Section, Key, pValue)
End Function

Dim GlobalConfigurationVirtualTable As Const IConfigurationVirtualTable = Type( _
	@IConfigurationQueryInterface, _
	@IConfigurationAddRef, _
	@IConfigurationRelease, _
	@IConfigurationSetIniFilename, _
	@IConfigurationGetStringValue, _
	@IConfigurationGetIntegerValue, _
	@IConfigurationGetAllSections, _
	@IConfigurationGetAllKeys, _
	@IConfigurationSetStringValue _
)
