#include once "ProcessDeleteRequest.bi"
#include once "HttpConst.bi"
#include once "WriteHttpError.bi"
#include once "WebUtils.bi"

Function ProcessDeleteRequest( _
		ByVal This As IProcessRequest Ptr, _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr, _
		ByVal fileExtention As WString Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal hRequestedFile As Handle _
	)As Boolean
	If hRequestedFile = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		Dim buf410 As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, @pWebSite->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile410 = INVALID_HANDLE_VALUE Then
			WriteHttpFileNotFound(pState, ClientSocket, pWebSite)
		Else
			CloseHandle(hFile410)
			WriteHttpFileGone(pState, ClientSocket, pWebSite)
		End If
		Return False
	End If
	CloseHandle(hRequestedFile)
	
	' Проверка заголовка Authorization
	If HttpAuthUtil(pState, ClientSocket, pWebSite, False) = False Then
		Return False
	End If
	
	' TODO Узнать код ошибки и отправить его клиенту
	If DeleteFile(@pWebSite->PathTranslated) <> 0 Then
		' Удалить возможные заголовочные файлы
		Dim sExtHeadersFile As WString * (WebSite.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(@sExtHeadersFile, @pWebSite->PathTranslated)
		lstrcat(@sExtHeadersFile, @HeadersExtensionString)
		DeleteFile(@sExtHeadersFile)
		
		' Создать файл «.410», показывающий, что файл был удалён
		lstrcpy(@sExtHeadersFile, @pWebSite->PathTranslated)
		lstrcat(@sExtHeadersFile, @FileGoneExtension)
		Dim hRequestedFile As HANDLE = CreateFile(@sExtHeadersFile, GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
		CloseHandle(hRequestedFile)
	Else
		WriteHttpFileNotAvailable(pState, ClientSocket, pWebSite)
		Return False
	End If
	' Отправить заголовки, что нет содержимого
	pState->ServerResponse.StatusCode = 204
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	If send(ClientSocket, @SendBuffer, pState->AllResponseHeadersToBytes(@SendBuffer, 0), 0) = SOCKET_ERROR Then
		Return False
	End If
	
	Return True
End Function
