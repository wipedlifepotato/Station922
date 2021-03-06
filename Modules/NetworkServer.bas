#include "NetworkServer.bi"

#ifndef unicode

Function CreateSocketAndListenA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ServerSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindA(LocalAddress, LocalPort, @ServerSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	If listen(ServerSocket, SOMAXCONN) <> 0 Then
		
		closesocket(ServerSocket)
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	*pSocket = ServerSocket
	Return S_OK
	
End Function

#endif

#ifdef unicode

Function CreateSocketAndListenW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ServerSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindW(LocalAddress, LocalPort, @ServerSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	If listen(ServerSocket, SOMAXCONN) <> 0 Then
		
		closesocket(ServerSocket)
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	*pSocket = ServerSocket
	Return S_OK
	
End Function

#endif
