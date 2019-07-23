#include "Configuration.bi"

Common Shared GlobalConfigurationVirtualTable As IConfigurationVirtualTable

Sub InitializeConfigurationVirtualTable()
	GlobalConfigurationVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @ConfigurationQueryInterface)
	GlobalConfigurationVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @ConfigurationAddRef)
	GlobalConfigurationVirtualTable.InheritedTable.Release = Cast(Any Ptr, @ConfigurationRelease)
	GlobalConfigurationVirtualTable.SetIniFilename = Cast(Any Ptr, @ConfigurationSetIniFilename)
	GlobalConfigurationVirtualTable.GetStringValue = Cast(Any Ptr, @ConfigurationGetStringValue)
	GlobalConfigurationVirtualTable.GetIntegerValue = Cast(Any Ptr, @ConfigurationGetIntegerValue)
	GlobalConfigurationVirtualTable.GetAllSections = Cast(Any Ptr, @ConfigurationGetAllSections)
	GlobalConfigurationVirtualTable.GetAllKeys = Cast(Any Ptr, @ConfigurationGetAllKeys)
	GlobalConfigurationVirtualTable.SetStringValue = Cast(Any Ptr, @ConfigurationSetStringValue)
End Sub

Sub InitializeConfiguration( _
		ByVal pConfig As Configuration Ptr _
	)
	
	pConfig->pVirtualTable = @GlobalConfigurationVirtualTable
	pConfig->ReferenceCounter = 0
	pConfig->IniFileName[0] = 0
	
End Sub

Function InitializeConfigurationOfIConfiguration( _
		ByVal pConfig As Configuration Ptr _
	)As IConfiguration Ptr
	
	InitializeConfiguration(pConfig)
	pConfig->ExistsInStack = True
	
	Dim pIConfiguration As IConfiguration Ptr = Any
	
	ConfigurationQueryInterface( _
		pConfig, @IID_ICONFIGURATION, @pIConfiguration _
	)
	
	Return pIConfiguration
	
End Function

Function ConfigurationQueryInterface( _
		ByVal pConfiguration As Configuration Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, @pConfiguration->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_ICONFIGURATION, riid) Then
		*ppv = CPtr(IConfiguration Ptr, @pConfiguration->pVirtualTable)
	End If
	
	If *ppv = 0 Then
		Return E_NOINTERFACE
	End If
	
	ConfigurationAddRef(pConfiguration)
	
	Return S_OK
	
End Function

Function ConfigurationAddRef( _
		ByVal pConfiguration As Configuration Ptr _
	)As ULONG
	
	Return InterlockedIncrement(@pConfiguration->ReferenceCounter)
	
End Function

Function ConfigurationRelease( _
		ByVal pConfiguration As Configuration Ptr _
	)As ULONG
	
	InterlockedDecrement(@pConfiguration->ReferenceCounter)
	
	If pConfiguration->ReferenceCounter = 0 Then
		
		If pConfiguration->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pConfiguration->ReferenceCounter
	
End Function

Function ConfigurationSetIniFilename( _
		ByVal pConfiguration As Configuration Ptr, _
		ByVal pFileName As WString Ptr _
	)As HRESULT
	
	lstrcpyn(@pConfiguration->IniFileName, pFileName, MAX_PATH + 1)
	
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
	
	Return S_OK
	
End Function
