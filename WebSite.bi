#ifndef WEBSITE_BI
#define WEBSITE_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"

Const SlashString = "/"

Const MaxWebSitesCount As Integer = 50

Enum FileAccess
	ForPut
	ForGetHead
	ForDelete
End Enum

Type WebSite
	Const MaxHostNameLength As Integer = 1023
	Const MaxFilePathLength As Integer = 4095 + 32
	Const MaxFilePathTranslatedLength As Integer = MaxFilePathLength + 256
	
	Dim HostName As WString * (MaxHostNameLength + 1)
	Dim PhysicalDirectory As WString * (MAX_PATH + 1)
	Dim VirtualPath As WString * (MaxHostNameLength + 1)
	Dim IsMoved As Boolean
	Dim MovedUrl As WString * (MaxHostNameLength + 1)
	
	Dim FilePath As WString * (MaxFilePathLength + 1)
	Dim PathTranslated As WString * (MaxFilePathTranslatedLength + 1)
	
	Declare Function GetFilePath( _
		ByVal path As WString Ptr, _
		ByVal ForReading As FileAccess _
	)As Handle
	
	Declare Sub MapPath( _
		ByVal Buffer As WString Ptr, _
		ByVal path As WString Ptr _
	)
	
End Type

' Заполняет указатель на сайт
' При ошибке возвращает False
Declare Function GetWebSite( _
	ByVal www As WebSite Ptr, _
	ByVal HostName As WString Ptr _
)As Boolean

' Проверяет путь на запрещённые символы
Declare Function IsBadPath( _
	ByVal Path As WString Ptr _
)As Boolean

' Заполняет список сайтов из конфигурации
Declare Function LoadWebSites( _
	ByVal ExeDir As WString Ptr _
)As Integer

' Проверка на CGI
Declare Function NeedCgiProcessing( _
	ByVal Path As WString Ptr _
)As Boolean

' Проверка на dll-cgi
Declare Function NeedDllProcessing( _
	ByVal Path As WString Ptr _
)As Boolean

#endif
