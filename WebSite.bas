#ifndef unicode
#define unicode
#endif

#include once "WebSite.bi"
#include once "win\shlwapi.bi"
#include once "IniConst.bi"

Const DotDotString = ".."

Const DefaultFileNameString1 = "default.xml"
Const DefaultFileNameString2 = "default.xhtml"
Const DefaultFileNameString3 = "default.htm"
Const DefaultFileNameString4 = "default.html"
Const DefaultFileNameString5 = "index.xml"
Const DefaultFileNameString6 = "index.xhtml"
Const DefaultFileNameString7 = "index.htm"
Const DefaultFileNameString8 = "index.html"

Const WebSitesMapFileName = "FreeBASICWebServerSiteList"

Const MaxDefaultFileNameLength As Integer = 15

Type WebSiteArray
	Dim WebSitesCount As Integer
	Dim WebSites(MaxWebSitesCount - 1) As WebSite
End Type

' Открывает файл на чтение или для проверки существования
Declare Function OpenFileForReading(ByVal PathTranslated As WString Ptr, ByVal ForReading As FileAccess)As Handle
' Заполняем буфер именем файла по умолчанию
Declare Sub GetDefaultFileName(ByVal Buffer As WString Ptr, ByVal Index As Integer)
' Заполняет сайт по имени хоста
Declare Sub LoadWebSite( _
	ByVal ExeDir As WString Ptr, _
	ByVal www As WebSite Ptr, _
	ByVal HostName As WString Ptr _
)

Sub LoadWebSite(ByVal ExeDir As WString Ptr, ByVal www As WebSite Ptr, ByVal HostName As WString Ptr)
	' Имя файла настроек программы
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, ExeDir, @WebSitesIniFileString)
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	
	GetPrivateProfileString(HostName, @VirtualPathSectionString, @DefaultValue, @www->VirtualPath, WebSite.MaxHostNameLength, IniFileName)
	GetPrivateProfileString(HostName, @PhisycalDirSectionString, @DefaultValue, @www->PhysicalDirectory, MAX_PATH, IniFileName)
	Dim Result2 As UINT = GetPrivateProfileInt(HostName, @IsMovedSectionString, 0, IniFileName)
	If Result2 = 0 Then
		www->IsMoved = False
	Else
		www->IsMoved = True
	End If
	GetPrivateProfileString(HostName, @MovedUrlSectionString, @DefaultValue, @www->MovedUrl, WebSite.MaxHostNameLength, IniFileName)
	lstrcpy(@www->HostName, HostName)
End sub

Function LoadWebSites(ByVal ExeDir As WString Ptr)As Integer
	' Получение списка сайтов и сохранение информации в память
	
	Const SectionsLength As Integer = 32000 - 1
	Dim AllSections As WString * (SectionsLength + 1) = Any
	' Имя файла настроек программы
	Dim IniFileName As WString * (MAX_PATH + 1) = Any
	PathCombine(@IniFileName, ExeDir, @WebSitesIniFileString)
	
	Dim DefaultValue As WString * 2 = Any
	DefaultValue[0] = 0
	DefaultValue[1] = 0
	' Получить имена всех секций
	Dim Result As DWORD = GetPrivateProfileString(Null, Null, @DefaultValue, @AllSections, SectionsLength, @IniFileName)
	
	' Определить количество сайтов
	Dim WebSitesCount As Integer = 0
	
	Dim Start As Integer = 0
	Dim w As WString Ptr = Any
	Do While Start < Result
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
	
	' Выделить память под сайты
	Dim hMapFile As HANDLE = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, SizeOf(WebSiteArray), @WebSitesMapFileName)
	If hMapFile = 0 Then
		Return 0
	End If
	
	Dim pMemoryWebSites As WebSiteArray Ptr = CPtr(WebSiteArray Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(WebSiteArray)))
	If pMemoryWebSites = 0 Then
		CloseHandle(hMapFile)
		Return 0
	End If
	
	pMemoryWebSites->WebSitesCount = WebSitesCount
	
	' Получить имена всех секций
	Result = GetPrivateProfileString(Null, Null, @DefaultValue, @AllSections, SectionsLength, @IniFileName)
	
	' Получить конфигурацию для каждого сайта
	Start = 0
	Dim i As Integer = 0
	Do While Start < Result
		' Получить указатель на начало строки
		w = @AllSections[Start]
		LoadWebSite(ExeDir, @pMemoryWebSites->WebSites(i), w)
		' Измерить длину строки, прибавить это к указателю + 1
		Start += lstrlen(w) + 1
		i += 1
		If i > MaxWebSitesCount Then
			Exit Do
		End If
	Loop
	
	' Выгрузить
	UnmapViewOfFile(pMemoryWebSites)
	
	' Отображение файла не закрывается, 
	' Оно нужно для сохранения сайтов в памяти
	
	Return WebSitesCount
End Function

Function GetWebSite(ByVal www As WebSite Ptr, ByVal HostName As WString Ptr)As Boolean
	Dim WebSiteBytesCount As Integer = MaxWebSitesCount * SizeOf(WebSite)
	
	Dim hMapFile As HANDLE = OpenFileMapping(GENERIC_READ + GENERIC_WRITE, False, @WebSitesMapFileName)
	If hMapFile = 0 Then
		Return False
	End If
	
	Dim pMemoryWebSites As WebSiteArray Ptr = CPtr(WebSiteArray Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(WebSiteArray)))
	If pMemoryWebSites = 0 Then
		CloseHandle(hMapFile)
		Return False
	End If
	
	Dim SiteFindResult As Boolean = False
	
	For i As Integer = 0 To pMemoryWebSites->WebSitesCount - 1
		If lstrcmp(@pMemoryWebSites->WebSites(i).HostName, HostName) = 0 Then
			RtlCopyMemory(www, @pMemoryWebSites->WebSites(i), SizeOf(WebSite))
			SiteFindResult = True
			Exit For
		End If
	Next
	
	' Выгрузить
	UnmapViewOfFile(pMemoryWebSites)
	CloseHandle(hMapFile)
	
	Return SiteFindResult
End Function

Sub WebSite.MapPath(ByVal Buffer As WString Ptr, ByVal path As WString Ptr)
	lstrcpy(Buffer, @PhysicalDirectory)
	Dim BufferLength As Integer = lstrlen(Buffer)
	
	' Добавить \ если там его нет
	If Buffer[BufferLength - 1] <> &h5c Then
		Buffer[BufferLength] = &h5c
		BufferLength += 1
		Buffer[BufferLength] = 0
	End If
	
	' Объединение физической директории и пути
	If lstrlen(path) <> 0 Then
		If path[0] = &h2f Then
			lstrcat(Buffer, @path[1])
		Else
			lstrcat(Buffer, path)
		End If
	End If
	
	' замена / на \
	For i As Integer = 0 To lstrlen(Buffer) - 1
		If Buffer[i] = &h2f Then
			Buffer[i] = &h5c
		End If
	Next
End Sub

Function IsBadPath(ByVal Path As WString Ptr)As Boolean
	' TODO Звёздочка в пути допустима при методе OPTIONS
	Dim PathLen As Integer = lstrlen(Path)
	If PathLen = 0 Then
		Return True
	End If
	If Path[PathLen - 1] = &h2e Then ' .
		Return True
	End If
	For i As Integer = 0 To PathLen - 1
		Dim c As Integer = Path[i]
		Select Case c
			Case Is < 32
				Return True
			Case 34 ' "
				Return True
			Case 36 ' $
				Return True
			Case 37 ' %
				Return True
			Case 60 ' <
				Return True
			Case 62 ' >
				Return True
			Case 63 ' ?
				Return True
			Case 124 ' |
				Return True
		End Select
	Next
	If StrStr(Path, DotDotString) > 0 Then
		Return True
	End If
	Return False
End Function

Function OpenFileForReading(ByVal PathTranslated As WString Ptr, ByVal ForReading As FileAccess)As Handle
	Select Case ForReading
		Case FileAccess.ForPut
			Return INVALID_HANDLE_VALUE
			
		Case FileAccess.ForGetHead
			' Для GetHead
			Return CreateFile(PathTranslated, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_SEQUENTIAL_SCAN, NULL)
			
		Case FileAccess.ForDelete
			' Для Delete
			Return CreateFile(PathTranslated, 0, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
			
	End Select
End Function

Function WebSite.GetFilePath(ByVal path As WString Ptr, ByVal ForReading As FileAccess)As Handle
	' TODO Здесь можно внедрить перезапись Url
	' Если оканчивается на «/», значит, передали имя каталога
	If Path[lstrlen(Path) - 1] <> &h2f Then
		' Path содержит имя конкретного файла
		lstrcpy(@FilePath, Path)
		MapPath(@PathTranslated, @FilePath)
		Return OpenFileForReading(@PathTranslated, ForReading)
	End If
	
	' Получить имя файла по умолчанию
	Dim DefaultFilename As WString * (MaxDefaultFileNameLength + 1) = Any
	Dim DefaultFilenameIndex As Integer = 0
	
	GetDefaultFileName(@DefaultFilename, DefaultFilenameIndex)
	
	Do
		lstrcpy(@FilePath, Path)
		lstrcat(@FilePath, @DefaultFilename)
		
		MapPath(@PathTranslated, @FilePath)
		
		Dim hFile As Handle = OpenFileForReading(@PathTranslated, ForReading)
		If hFile <> INVALID_HANDLE_VALUE Then
			' Найден
			Return hFile
		End If
		
		DefaultFilenameIndex += 1
		GetDefaultFileName(@DefaultFilename, DefaultFilenameIndex)
	Loop While lstrlen(DefaultFilename) > 0
	
	' Файл по умолчанию не найден
	GetDefaultFileName(@DefaultFilename, 0)
	lstrcpy(@FilePath, Path)
	lstrcat(@FilePath, @DefaultFilename)
	
	MapPath(@PathTranslated, @FilePath)
	Return INVALID_HANDLE_VALUE
End Function

Sub GetDefaultFileName(ByVal Buffer As WString Ptr, ByVal Index As Integer)
	Select Case Index
		Case 0
			lstrcpy(Buffer, @DefaultFileNameString1)
		Case 1
			lstrcpy(Buffer, @DefaultFileNameString2)
		Case 2
			lstrcpy(Buffer, @DefaultFileNameString3)
		Case 3
			lstrcpy(Buffer, @DefaultFileNameString4)
		Case 4
			lstrcpy(Buffer, @DefaultFileNameString5)
		Case 5
			lstrcpy(Buffer, @DefaultFileNameString6)
		Case 6
			lstrcpy(Buffer, @DefaultFileNameString7)
		Case 7
			lstrcpy(Buffer, @DefaultFileNameString8)
		Case Else
			Buffer[0] = 0
	End Select
End Sub

Function NeedCgiProcessing(ByVal Path As WString Ptr)As Boolean
	' Проверка на CGI
	If StrStrI(Path, "/cgi-bin/") = Path Then
		Return True
	End If
	
	Return False
End Function

Function NeedDllProcessing(ByVal Path As WString Ptr)As Boolean
	' Проверка на dll-cgi
	If StrStrI(Path, "/cgi-dll/") = Path Then
		Return True
	End If
	
	Return False
End Function
