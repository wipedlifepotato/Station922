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

' Сайт на сервере
Type WebSite
	Const MaxHostNameLength As Integer = 1023
	' Максимальная длина пути к файлу
	Const MaxFilePathLength As Integer = 4095 + 32
	' Максимальная длина пути к файлу
	Const MaxFilePathTranslatedLength As Integer = MaxFilePathLength + 256
	
	Dim HostName As WString * (MaxHostNameLength + 1)
	Dim PhysicalDirectory As WString * (MAX_PATH + 1)
	Dim VirtualPath As WString * (MaxHostNameLength + 1)
	Dim IsMoved As Boolean
	Dim MovedUrl As WString * (MaxHostNameLength + 1)
	
	' Путь к файлу
	Dim FilePath As WString * (MaxFilePathLength + 1)
	' Путь к файлу на диске
	Dim PathTranslated As WString * (MaxFilePathTranslatedLength + 1)
	
	' Получает путь к файлу на диске
	Declare Function GetFilePath(ByVal path As WString Ptr, ByVal ForReading As FileAccess)As Handle
	
	' Заполняет буфер путём к файлу
	Declare Sub MapPath(ByVal Buffer As WString Ptr, ByVal path As WString Ptr)
	
End Type

' Заполняет указатель на сайт
' При ошибке возвращает False
Declare Function GetWebSite(ByVal www As WebSite Ptr, ByVal HostName As WString Ptr)As Boolean

' Заполняет сайт по имени хоста
Declare Sub LoadWebSite(ByVal ExeDir As WString Ptr, ByVal www As WebSite Ptr, ByVal HostName As WString Ptr)

' Проверяет путь на запрещённые символы
Declare Function IsBadPath(ByVal Path As WString Ptr)As Boolean

' Заполняет список сайтов из конфигурации
Declare Function LoadWebSites(ByVal ExeDir As WString Ptr)As Integer

' Проверка на CGI
Declare Function NeedCGIProcessing(ByVal Path As WString Ptr)As Boolean

' Проверка на dll-cgi
Declare Function NeedDLLProcessing(ByVal Path As WString Ptr)As Boolean

#endif
