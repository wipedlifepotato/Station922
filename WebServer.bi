#ifndef WEBSERVER_BI
#define WEBSERVER_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\shlwapi.bi"
#include once "ThreadProc.bi"

' Точка входа
Declare Function EntryPoint Alias "EntryPoint"()As Integer

' Функция сервисного потока
#ifdef service
Declare Function ServiceProc(ByVal lpParam As LPVOID)As DWORD
#endif

' Получение идентификатора лог‐файла
Declare Function GetLogFileHandle(ByVal dtCurrent As SYSTEMTIME Ptr, ByVal LogDir As WString Ptr)As Handle

#endif
