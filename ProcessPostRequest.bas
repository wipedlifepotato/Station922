#include once "ProcessPostRequest.bi"
#include once "HttpConst.bi"
#include once "WriteHttpError.bi"
#include once "Mime.bi"
#include once "WebUtils.bi"
#include once "CharConstants.bi"
#include once "ProcessCgiRequest.bi"
#include once "ProcessDllRequest.bi"
#include once "SafeHandle.bi"

Function ProcessPostRequest( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pRequestedFile As RequestedFile Ptr _
	)As Boolean
	
	If pRequestedFile->FileHandle = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		Dim buf410 As WString * (RequestedFile.MaxFilePathTranslatedLength + 1) = Any
		lstrcpy(buf410, pRequestedFile->PathTranslated)
		lstrcat(buf410, @FileGoneExtension)
		
		Dim hFile410 As HANDLE = CreateFile(@buf410, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
		Dim objHFile410 As SafeHandle = Type<SafeHandle>(hFile410)
		If hFile410 = INVALID_HANDLE_VALUE Then
			WriteHttpFileNotFound(pState, pClientReader->pStream, pWebSite)
		Else
			WriteHttpFileGone(pState, pClientReader->pStream, pWebSite)
		End If
		Return False
	End If
	
	If NeedCGIProcessing(pState->ClientRequest.ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessCGIRequest(pState, ClientSocket, pWebSite, pClientReader, pRequestedFile)
	End If
	
	If NeedDLLProcessing(pState->ClientRequest.ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessDllCgiRequest(pState, ClientSocket, pWebSite, pClientReader, pRequestedFile->FileHandle)
	End If
	
	Dim objRequestedFile As SafeHandle = Type<SafeHandle>(pRequestedFile->FileHandle)
	
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethodsForFile
	WriteHttpNotImplemented(pState, pClientReader->pStream, pWebSite)
	
	Return False
End Function
