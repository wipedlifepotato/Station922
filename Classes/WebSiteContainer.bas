#include "WebSiteContainer.bi"
#include "ContainerOf.bi"
#include "CreateInstance.bi"
#include "HttpConst.bi"
#include "IConfiguration.bi"
#include "IMutableWebSite.bi"
#include "IniConst.bi"
#include "PrintDebugInfo.bi"
#include "StringConstants.bi"
#include "win\shlwapi.bi"

Extern GlobalWebSiteContainerVirtualTable As Const IWebSiteContainerVirtualTable

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Const MaxSectionsLength As Integer = 32000 - 1
Const MaxHostNameLength As Integer = 1024 - 1

Type WebSiteNode As _WebSiteNode

Type LPWebSiteNode As _WebSiteNode Ptr

Type _WebSiteNode
	Dim HostName As WString * (MaxHostNameLength + 1)
	Dim pExecutableDirectory As WString Ptr
	Dim PhysicalDirectory As WString * (MAX_PATH + 1)
	Dim VirtualPath As WString * (MaxHostNameLength + 1)
	Dim MovedUrl As WString * (MaxHostNameLength + 1)
	Dim LeftNode As WebSiteNode Ptr
	Dim RightNode As WebSiteNode Ptr
	Dim IsMoved As Boolean
End Type

Type _WebSiteContainer
	Dim lpVtbl As Const IWebSiteContainerVirtualTable Ptr
	Dim ReferenceCounter As Integer
	Dim pIMemoryAllocator As IMalloc Ptr
	#ifndef WITHOUT_CRITICAL_SECTIONS
		Dim crSection As CRITICAL_SECTION
	#endif
	Dim ExecutableDirectory As WString * (MAX_PATH + 1)
	Dim pDefaultNode As WebSiteNode Ptr
	Dim pTree As WebSiteNode Ptr
End Type

Declare Sub LoadWebSite( _
	ByVal pWebSiteContainer As WebSiteContainer Ptr, _
	ByVal pIConfig As IConfiguration Ptr, _
	ByVal HostName As WString Ptr _
)

Declare Function CreateWebSiteNode( _
	ByVal pIMemoryAllocator As IMalloc Ptr, _
	ByVal pIConfig As IConfiguration Ptr, _
	ByVal ExecutableDirectory As WString Ptr, _
	ByVal HostName As WString Ptr _
)As WebSiteNode Ptr

Declare Sub TreeAddNode( _
	ByVal pTree As WebSiteNode Ptr, _
	ByVal pNode As WebSiteNode Ptr _
)

Declare Function TreeFindNode( _
	ByVal pTree As WebSiteNode Ptr, _
	ByVal HostName As WString Ptr _
)As WebSiteNode Ptr

Extern CLSID_CONFIGURATION Alias "CLSID_CONFIGURATION" As Const CLSID

Sub InitializeWebSiteContainer( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalWebSiteContainerVirtualTable
	this->ReferenceCounter = 0
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	#ifndef WITHOUT_CRITICAL_SECTIONS
		InitializeCriticalSectionAndSpinCount( _
			@this->crSection, _
			MAX_CRITICAL_SECTION_SPIN_COUNT _
		)
	#endif
	this->ExecutableDirectory[0] = 0
	this->pDefaultNode = NULL
	this->pTree = NULL
	
End Sub

Sub UnInitializeWebSiteContainer( _
		ByVal this As WebSiteContainer Ptr _
	)
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		DeleteCriticalSection(@this->crSection)
	#endif
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateWebSiteContainer( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As WebSiteContainer Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"WebSiteContainer create\t")
	#endif
	
	Dim this As WebSiteContainer Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(WebSiteContainer) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeWebSiteContainer(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyWebSiteContainer( _
		ByVal this As WebSiteContainer Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeWebSiteContainer(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"WebSite destroyed\t")
	#endif
	
End Sub

Function WebSiteContainerQueryInterface( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IWebSiteContainer, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_IUnknown, riid) Then
			*ppv = @this->lpVtbl
		Else
			*ppv = NULL
			Return E_NOINTERFACE
		End If
	End If
	
	WebSiteContainerAddRef(this)
	
	Return S_OK
	
End Function

Function WebSiteContainerAddRef( _
		ByVal this As WebSiteContainer Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter += 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	Return 1
	
End Function

Function WebSiteContainerRelease( _
		ByVal this As WebSiteContainer Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter -= 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	If this->ReferenceCounter = 0 Then
		
		DestroyWebSiteContainer(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Sub SetMutableWebSite( _
		ByVal pIMutable As IMutableWebSite Ptr, _
		ByVal pNode As WebSiteNode Ptr _
	)
	
	IMutableWebSite_SetHostName(pIMutable, @pNode->HostName)
	IMutableWebSite_SetExecutableDirectory(pIMutable, pNode->pExecutableDirectory)
	IMutableWebSite_SetSitePhysicalDirectory(pIMutable, @pNode->PhysicalDirectory)
	IMutableWebSite_SetVirtualPath(pIMutable, @pNode->VirtualPath)
	IMutableWebSite_SetIsMoved(pIMutable, pNode->IsMoved)
	IMutableWebSite_SetMovedUrl(pIMutable, @pNode->MovedUrl)
	
End Sub

Function WebSiteContainerGetDefaultWebSite( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	
	Dim pIMutable As IMutableWebSite Ptr = Any
	Dim hr As HRESULT = IWebSite_QueryInterface( _
		pIWebSite, _
		@IID_IMutableWebSite, _
		@pIMutable _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	SetMutableWebSite(pIMutable, this->pDefaultNode)
	
	IMutableWebSite_Release(pIMutable)
	
	Return S_OK
	
End Function

Function WebSiteContainerFindWebSite( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal Host As WString Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	
	Dim pNode As WebSiteNode Ptr = TreeFindNode(this->pTree, Host)
	
	If pNode = NULL Then
		Return E_FAIL
	End If
	
	Dim pIMutable As IMutableWebSite Ptr = Any
	Dim hr As HRESULT = IWebSite_QueryInterface( _
		pIWebSite, _
		@IID_IMutableWebSite, _
		@pIMutable _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	SetMutableWebSite(pIMutable, pNode)
	
	IMutableWebSite_Release(pIMutable)
	
	Return S_OK
	
End Function

Function WebSiteContainerLoadWebSites( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal ExecutableDirectory As WString Ptr _
	)As HRESULT
	
	lstrcpy(@this->ExecutableDirectory, ExecutableDirectory)
	
	Dim SettingsFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@SettingsFileName, ExecutableDirectory, @WebSitesIniFileString)
	
	Dim pIConfig As IConfiguration Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		this->pIMemoryAllocator, _
		@CLSID_CONFIGURATION, _
		@IID_IConfiguration, _
		@pIConfig _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	IConfiguration_SetIniFilename(pIConfig, @SettingsFileName)
	
	Dim SectionsLength As Integer = Any
	
	Dim AllSections As WString * (MaxSectionsLength + 1) = Any
	
	IConfiguration_GetAllSections(pIConfig, MaxSectionsLength, @AllSections, @SectionsLength)
	
	Dim w As WString Ptr = @AllSections
	Dim wLength As Integer = lstrlen(w)
	
	Do While wLength > 0	
		
		LoadWebSite(this, pIConfig, w)

		w = @w[wLength + 1]
		wLength = lstrlen(w)
		
	Loop
	
	this->pDefaultNode = CreateWebSiteNode( _
		this->pIMemoryAllocator, _
		pIConfig, _
		@this->ExecutableDirectory, _
		@DefaultVirtualPath _
	)
	
	IConfiguration_Release(pIConfig)
	
	Return S_OK
	
End Function

Sub LoadWebSite( _
		ByVal this As WebSiteContainer Ptr, _
		ByVal pIConfig As IConfiguration Ptr, _
		ByVal HostName As WString Ptr _
	)
	
	Dim pNode As WebSiteNode Ptr = CreateWebSiteNode( _
		this->pIMemoryAllocator, _
		pIConfig, _
		@this->ExecutableDirectory, _
		HostName _
	)
	
	If this->pTree = NULL Then
		this->pTree = pNode
	Else
		TreeAddNode(this->pTree, pNode)
	End If
	
End Sub

Function CreateWebSiteNode( _
		ByVal pIMemoryAllocator As IMalloc Ptr, _
		ByVal pIConfig As IConfiguration Ptr, _
		ByVal ExecutableDirectory As WString Ptr, _
		ByVal Section As WString Ptr _
	)As WebSiteNode Ptr
	
	Dim pNode As WebSiteNode Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(WebSiteNode) _
	)
	If pNode = NULL Then
		Return NULL
	End If
	
	pNode->LeftNode = NULL
	pNode->RightNode = NULL
	lstrcpy(@pNode->HostName, Section)
	pNode->pExecutableDirectory = ExecutableDirectory
	
	Dim ValueLength As Integer = Any
	
	IConfiguration_GetStringValue(pIConfig, _
		Section, _
		@PhisycalDirKeyString, _
		pNode->pExecutableDirectory, _
		MAX_PATH, _
		@pNode->PhysicalDirectory, _
		@ValueLength _
	)
	
	IConfiguration_GetStringValue(pIConfig, _
		Section, _
		@VirtualPathKeyString, _
		@DefaultVirtualPath, _
		MaxHostNameLength, _
		@pNode->VirtualPath, _
		@ValueLength _
	)
	
	IConfiguration_GetStringValue(pIConfig, _
		Section, _
		@MovedUrlKeyString, _
		@EmptyString, _
		MaxHostNameLength, _
		@pNode->MovedUrl, _
		@ValueLength _
	)
	
	Dim IsMoved As Integer = Any
	IConfiguration_GetIntegerValue(pIConfig, _
		Section, _
		@IsMovedKeyString, _
		0, _
		@IsMoved _
	)
	
	If IsMoved = 0 Then
		pNode->IsMoved = False
	Else
		pNode->IsMoved = True
	End If
	
	' pNode->pIWebSite = InitializeWebSiteOfIWebSite(@pNode->objWebSite)
	
	' pNode->objWebSite.pHostName = @pNode->HostName
	' pNode->objWebSite.pPhysicalDirectory = @pNode->PhysicalDirectory
	' pNode->objWebSite.pExecutableDirectory = pNode->pExecutableDirectory
	' pNode->objWebSite.pVirtualPath = @pNode->VirtualPath
	' pNode->objWebSite.IsMoved = pNode->IsMoved
	' pNode->objWebSite.pMovedUrl = @pNode->MovedUrl
	
	Return pNode
	
End Function

Sub TreeAddNode( _
		ByVal pTree As WebSiteNode Ptr, _
		ByVal pNode As WebSiteNode Ptr _
	)
	
	Select Case lstrcmpi(pNode->HostName, pTree->HostName)
		
		Case Is > 0
			If pTree->RightNode = NULL Then
				pTree->RightNode = pNode
			Else
				TreeAddNode(pTree->RightNode, pNode)
			End If
			
		Case Is < 0
			If pTree->LeftNode = NULL Then
				pTree->LeftNode = pNode
			Else
				TreeAddNode(pTree->LeftNode, pNode)
			End If
			
	End Select
	
End Sub

Function TreeFindNode( _
		ByVal pNode As WebSiteNode Ptr, _
		ByVal HostName As WString Ptr _
	)As WebSiteNode Ptr
	
	Select Case lstrcmpi(HostName, pNode->HostName)
		
		Case Is > 0
			If pNode->RightNode = NULL Then
				Return NULL
			End If
			
			Return TreeFindNode(pNode->RightNode, HostName)
			
		Case 0
			Return pNode
			
		Case Is < 0
			If pNode->LeftNode = NULL Then
				Return NULL
			End If
			
			Return TreeFindNode(pNode->LeftNode, HostName)
			
	End Select
	
End Function

Function IWebSiteContainerQueryInterface( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return WebSiteContainerQueryInterface(ContainerOf(this, WebSiteContainer, lpVtbl), riid, ppvObject)
End Function

Function IWebSiteContainerAddRef( _
		ByVal this As IWebSiteContainer Ptr _
	)As ULONG
	Return WebSiteContainerAddRef(ContainerOf(this, WebSiteContainer, lpVtbl))
End Function

Function IWebSiteContainerRelease( _
		ByVal this As IWebSiteContainer Ptr _
	)As ULONG
	Return WebSiteContainerRelease(ContainerOf(this, WebSiteContainer, lpVtbl))
End Function

Function IWebSiteContainerFindWebSite( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal Host As WString Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	Return WebSiteContainerFindWebSite(ContainerOf(this, WebSiteContainer, lpVtbl), Host, pIWebSite)
End Function

Function IWebSiteContainerGetDefaultWebSite( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal pIWebSite As IWebSite Ptr _
	)As HRESULT
	Return WebSiteContainerGetDefaultWebSite(ContainerOf(this, WebSiteContainer, lpVtbl), pIWebSite)
End Function

Function IWebSiteContainerLoadWebSites( _
		ByVal this As IWebSiteContainer Ptr, _
		ByVal ExecutableDirectory As WString Ptr _
	)As HRESULT
	Return WebSiteContainerLoadWebSites(ContainerOf(this, WebSiteContainer, lpVtbl), ExecutableDirectory)
End Function

Dim GlobalWebSiteContainerVirtualTable As Const IWebSiteContainerVirtualTable = Type( _
	@IWebSiteContainerQueryInterface, _
	@IWebSiteContainerAddRef, _
	@IWebSiteContainerRelease, _
	@IWebSiteContainerFindWebSite, _
	@IWebSiteContainerGetDefaultWebSite, _
	@IWebSiteContainerLoadWebSites _
)
