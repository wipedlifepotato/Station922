#include "EntryPoint.bi"
#include "Http.bi"
#include "win\winsock2.bi"

#ifdef WINDOWS_SERVICE
#include "WindowsServiceMain.bi"
#else
#include "ConsoleMain.bi"
#endif

#ifdef WITHOUT_RUNTIME
Function EntryPoint Alias "EntryPoint"()As Integer
#endif
	
	Dim RetCode As Integer = 0
	
	Scope
		If CreateRequestHeadersTree() = False Then
			RetCode = 2
			GoTo ExitLabel
		End If
	End Scope
	
	Scope
		Dim wsa As WSAData = Any
		If WSAStartup(MAKEWORD(2, 2), @wsa) <> NO_ERROR Then
			RetCode = 1
			GoTo ExitLabel
		End If
	End Scope
	
	Scope
		' Оконные функции: wWinMain() и winMain()
		' Консольные функции: wmain() и main()
		
		RetCode = ConsoleMain()
	End Scope
	
CleanUpLabel:

	WSACleanup()
	
ExitLabel:

	#ifdef WITHOUT_RUNTIME
		Return RetCode
	#else
		End(RetCode)
	#endif
	
#ifdef WITHOUT_RUNTIME
End Function
#endif
