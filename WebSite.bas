#include "WebSite.bi"
#include "win\shlwapi.bi"
#include "IniConst.bi"
#include "CharacterConstants.bi"
#include "StringConstants.bi"
#include "Configuration.bi"
#include "RequestedFile.bi"

Const DefaultFileNameDefaultXml = "default.xml"
Const DefaultFileNameDefaultXhtml = "default.xhtml"
Const DefaultFileNameDefaultHtm = "default.htm"
Const DefaultFileNameDefaultHtml = "default.html"
Const DefaultFileNameIndexXml = "index.xml"
Const DefaultFileNameIndexXhtml = "index.xhtml"
Const DefaultFileNameIndexHtm = "index.htm"
Const DefaultFileNameIndexHtml = "index.html"

Const MaxDefaultFileNameLength As Integer = 15

Declare Function OpenFileForReading( _
	ByVal PathTranslated As WString Ptr, _
	ByVal ForReading As FileAccess _
)As Handle

Declare Function GetDefaultFileName( _
	ByVal Buffer As WString Ptr, _
	ByVal Index As Integer _
)As Boolean

Declare Sub LoadWebSite( _
	ByVal pIConfig As IConfiguration Ptr, _
	ByVal www As WebSiteItem Ptr, _
	ByVal HostName As WString Ptr _
)

Function GetWebSitesArray( _
		ByVal ppWebSitesArray As WebSitesArray Ptr Ptr, _
		ByVal ExeDir As WString Ptr _
	)As Integer
	
	*ppWebSitesArray = 0
	
	Const MaxSectionsLength As Integer = 32000 - 1
	Dim AllSections As WString * (MaxSectionsLength + 1) = Any
	
	Dim SettingsFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@SettingsFileName, ExeDir, @WebSitesIniFileString)
	
	Dim Config As Configuration = Any
	Dim pIConfig As IConfiguration Ptr = InitializeConfigurationOfIConfiguration(@Config)
	
	Configuration_NonVirtualSetIniFilename(pIConfig, @SettingsFileName)
	
	Dim SectionsLength As Integer = Any
	
	Configuration_NonVirtualGetAllSections(pIConfig, MaxSectionsLength, @AllSections, @SectionsLength)
	
	' Определить количество сайтов
	Dim WebSitesCount As Integer = 0
	
	Dim Start As Integer = 0
	Dim w As WString Ptr = Any
	Do While Start < SectionsLength
		' Получить указатель на начало строки
		w = @AllSections[Start]
		' Измерить длину строки, прибавить это к указателю + 1
		Start += lstrlen(w) + 1
		' Увеличить счётчик сайтов
		WebSitesCount += 1
		If WebSitesCount > MaxWebSitesCount Then
			Exit Do
		End If
	Loop
	
	If WebSitesCount = 0 Then
		Return 0
	End If
	
	*ppWebSitesArray = CPtr(WebSitesArray Ptr, VirtualAlloc(0, SizeOf(WebSitesArray), MEM_COMMIT Or MEM_RESERVE, PAGE_READWRITE))
	If *ppWebSitesArray = 0 Then
		Dim dwError As DWORD = GetLastError()
		Return 0
	End If
	
	(*ppWebSitesArray)->WebSitesCount = WebSitesCount
	
	' Получить конфигурацию для каждого сайта
	Start = 0
	Dim i As Integer = 0
	Do While Start < SectionsLength
		' Получить указатель на начало строки
		w = @AllSections[Start]
		LoadWebSite(pIConfig, @((*ppWebSitesArray)->WebSites(i)), w)
		' Измерить длину строки, прибавить это к указателю + 1
		Start += lstrlen(w) + 1
		i += 1
		If i > MaxWebSitesCount Then
			Exit Do
		End If
	Loop
	
	Configuration_NonVirtualRelease(pIConfig)
	
	Dim lpflOldProtect As DWORD = Any
	If VirtualProtect(*ppWebSitesArray, SizeOf(WebSitesArray), PAGE_READONLY, @lpflOldProtect) = 0 Then
		Dim dwError As DWORD = GetLastError()
	End If
	
	Return WebSitesCount
End Function

Sub LoadWebSite( _
		ByVal pIConfig As IConfiguration Ptr, _
		ByVal www As WebSiteItem Ptr, _
		ByVal Section As WString Ptr _
	)
	
	Dim ValueLength As Integer = Any
	
	Configuration_NonVirtualGetStringValue(pIConfig, _
		Section, _
		@VirtualPathKeyString, _
		@EmptyString, _
		WebSiteItem.MaxHostNameLength, _
		@www->VirtualPath, _
		@ValueLength _
	)
	
	Configuration_NonVirtualGetStringValue(pIConfig, _
		Section, _
		@PhisycalDirKeyString, _
		@EmptyString, _
		MAX_PATH, _
		@www->PhysicalDirectory, _
		@ValueLength _
	)
	
	Dim IsMoved As Integer = Any
	Configuration_NonVirtualGetIntegerValue(pIConfig, _
		Section, _
		@IsMovedKeyString, _
		0, _
		@IsMoved _
	)
	
	If IsMoved = 0 Then
		www->IsMoved = False
	Else
		www->IsMoved = True
	End If
	
	Configuration_NonVirtualGetStringValue(pIConfig, _
		Section, _
		@MovedUrlKeyString, _
		@EmptyString, _
		WebSiteItem.MaxHostNameLength, _
		@www->MovedUrl, _
		@ValueLength _
	)
	
	lstrcpy(@www->HostName, Section)
	
End sub

Function WebSitesArray.FindSimpleWebSite( _
		ByVal www As SimpleWebSite Ptr, _
		ByVal HostName As WString Ptr _
	)As Boolean
	
	For i As Integer = 0 To WebSitesCount - 1
		If lstrcmpi(@WebSites(i).HostName, HostName) = 0 Then
			www->HostName = @WebSites(i).HostName
			www->PhysicalDirectory = @WebSites(i).PhysicalDirectory
			www->VirtualPath = @WebSites(i).VirtualPath
			www->IsMoved = WebSites(i).IsMoved
			www->MovedUrl = @WebSites(i).MovedUrl
			
			Return True
		End If
	Next
	
	www->HostName = HostName
	www->PhysicalDirectory = 0
	www->VirtualPath = @DefaultVirtualPath
	www->IsMoved = False
	www->MovedUrl = 0
	
	Return False
End Function

Function IsBadPath( _
		ByVal Path As WString Ptr _
	)As Boolean
	
	' TODO Звёздочка в пути допустима при методе OPTIONS
	Dim PathLen As Integer = lstrlen(Path)
	
	If PathLen = 0 Then
		Return True
	End If
	
	If Path[PathLen - 1] = Characters.FullStop Then
		Return True
	End If
	
	For i As Integer = 0 To PathLen - 1
		
		Dim c As Integer = Path[i]
		
		Select Case c
			Case Is < Characters.WhiteSpace
				Return True
			Case Characters.QuotationMark
				Return True
			Case Characters.DollarSign
				Return True
			Case Characters.PercentSign
				Return True
			Case Characters.LessThanSign
				Return True
			Case Characters.GreaterThanSign
				Return True
			Case Characters.QuestionMark
				Return True
			Case Characters.VerticalLine
				Return True
		End Select
	Next
	
	If StrStr(Path, DotDotString) > 0 Then
		Return True
	End If
	
	Return False
End Function

Function NeedCgiProcessing( _
		ByVal Path As WString Ptr _
	)As Boolean
	
	If StrStrI(Path, "/cgi-bin/") = Path Then
		Return True
	End If
	
	Return False
End Function

Function NeedDllProcessing( _
		ByVal Path As WString Ptr _
	)As Boolean
	
	If StrStrI(Path, "/cgi-dll/") = Path Then
		Return True
	End If
	
	Return False
End Function

Sub SimpleWebSite.MapPath( _
		ByVal Buffer As WString Ptr, _
		ByVal path As WString Ptr _
	)
	lstrcpy(Buffer, PhysicalDirectory)
	Dim BufferLength As Integer = lstrlen(Buffer)
	
	' Добавить \ если там его нет
	If Buffer[BufferLength - 1] <> Characters.ReverseSolidus Then
		Buffer[BufferLength] = Characters.ReverseSolidus
		BufferLength += 1
		Buffer[BufferLength] = 0
	End If
	
	' Объединение физической директории и пути
	If lstrlen(path) <> 0 Then
		If path[0] = Characters.Solidus Then
			lstrcat(Buffer, @path[1])
		Else
			lstrcat(Buffer, path)
		End If
	End If
	
	' замена / на \
	For i As Integer = 0 To lstrlen(Buffer) - 1
		If Buffer[i] = Characters.Solidus Then
			Buffer[i] = Characters.ReverseSolidus
		End If
	Next
End Sub

Function SimpleWebSite.GetRequestedFile( _
		ByVal Path As WString Ptr, _
		ByVal ForReading As FileAccess, _
		ByVal ppIFile As IRequestedFile Ptr Ptr _
	)As HRESULT
	
	Dim objRequestedFile As RequestedFile = Any
	Dim pIFile As IRequestedFile Ptr = InitializeRequestedFileOfIRequestedFile(@objRequestedFile)
	
	*ppIFile = pIFile
	
	If Path[lstrlen(Path) - 1] <> Characters.Solidus Then
		' Path содержит имя конкретного файла
		lstrcpy(@objRequestedFile.FilePath, Path)
		MapPath(@objRequestedFile.PathTranslated, @objRequestedFile.FilePath)
		
		objRequestedFile.FileHandle = OpenFileForReading(@objRequestedFile.PathTranslated, ForReading)
		
		Return S_OK
	End If
	
	Dim DefaultFilenameIndex As Integer = 0
	Dim DefaultFilename As WString * (MaxDefaultFileNameLength + 1) = Any
	
	Dim GetDefaultFileNameResult As Boolean = GetDefaultFileName(@DefaultFilename, DefaultFilenameIndex)
	
	Do
		lstrcpy(@objRequestedFile.FilePath, Path)
		lstrcat(@objRequestedFile.FilePath, DefaultFilename)
		
		MapPath(@objRequestedFile.PathTranslated, @objRequestedFile.FilePath)
		
		objRequestedFile.FileHandle = OpenFileForReading(@objRequestedFile.PathTranslated, ForReading)
		
		If objRequestedFile.FileHandle <> INVALID_HANDLE_VALUE Then
			Return S_OK
		End If
		
		DefaultFilenameIndex += 1
		GetDefaultFileNameResult = GetDefaultFileName(@DefaultFilename, DefaultFilenameIndex)
		
	Loop While GetDefaultFileNameResult
	
	' Файл по умолчанию не найден
	GetDefaultFileName(DefaultFilename, 0)
	lstrcpy(@objRequestedFile.FilePath, Path)
	lstrcat(@objRequestedFile.FilePath, @DefaultFilename)
	
	MapPath(@objRequestedFile.PathTranslated, @objRequestedFile.FilePath)
	
	objRequestedFile.FileHandle = INVALID_HANDLE_VALUE
	
	Return S_FALSE
	
End Function

Function GetDefaultFileName( _
		ByVal Buffer As WString Ptr, _
		ByVal Index As Integer _
	)As Boolean
	
	Select Case Index
		
		Case 0
			lstrcpy(Buffer, @DefaultFileNameDefaultXml)
			
		Case 1
			lstrcpy(Buffer, @DefaultFileNameDefaultXhtml)
			
		Case 2
			lstrcpy(Buffer, @DefaultFileNameDefaultHtm)
			
		Case 3
			lstrcpy(Buffer, @DefaultFileNameDefaultHtml)
			
		Case 4
			lstrcpy(Buffer, @DefaultFileNameIndexXml)
			
		Case 5
			lstrcpy(Buffer, @DefaultFileNameIndexXhtml)
			
		Case 6
			lstrcpy(Buffer, @DefaultFileNameIndexHtm)
			
		Case 7
			lstrcpy(Buffer, @DefaultFileNameIndexHtml)
			
		Case Else
			Buffer[0] = 0
			Return False
			
	End Select
	
	Return True
	
End Function

Function OpenFileForReading( _
		ByVal PathTranslated As WString Ptr, _
		ByVal ForReading As FileAccess _
	)As Handle
	
	Select Case ForReading
		
		Case FileAccess.ForPut
			Return INVALID_HANDLE_VALUE
			
		Case FileAccess.ForGetHead
			Return CreateFile( _
				PathTranslated, _
				GENERIC_READ, _
				FILE_SHARE_READ, _
				NULL, _
				OPEN_EXISTING, _
				FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, _
				NULL _
			)
			
		Case FileAccess.ForDelete
			Return CreateFile( _
				PathTranslated, _
				0, _
				0, _
				NULL, _
				OPEN_EXISTING, _
				FILE_ATTRIBUTE_NORMAL, _
				NULL _
			)
			
	End Select
End Function
