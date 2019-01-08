#include "ProcessPostRequest.bi"
#include "HttpConst.bi"
#include "WriteHttpError.bi"
#include "Mime.bi"
#include "WebUtils.bi"
#include "CharacterConstants.bi"
#include "ProcessCgiRequest.bi"
#include "ProcessDllRequest.bi"
#include "SafeHandle.bi"

Function ProcessPostRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
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
		
		Dim hFile410 As HANDLE = CreateFile( _
			@buf410, _
			0, _
			FILE_SHARE_READ, _
			NULL, _
			OPEN_EXISTING, _
			FILE_ATTRIBUTE_NORMAL, _
			NULL _
		)
		Dim objHFile410 As SafeHandle = Type<SafeHandle>(hFile410)
		If hFile410 = INVALID_HANDLE_VALUE Then
			WriteHttpFileNotFound(pRequest, pResponse, pClientReader->pStream, pWebSite)
		Else
			WriteHttpFileGone(pRequest, pResponse, pClientReader->pStream, pWebSite)
		End If
		Return False
	End If
	
	If NeedCGIProcessing(pRequest->ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessCGIRequest(pRequest, pResponse, ClientSocket, pWebSite, pClientReader, pRequestedFile)
	End If
	
	If NeedDLLProcessing(pRequest->ClientUri.Path) Then
		CloseHandle(pRequestedFile->FileHandle)
		Return ProcessDllCgiRequest(pRequest, pResponse, ClientSocket, pWebSite, pClientReader, pRequestedFile->FileHandle)
	End If
	
	Dim objRequestedFile As SafeHandle = Type<SafeHandle>(pRequestedFile->FileHandle)
	
	pResponse->ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethodsForFile
	WriteHttpNotImplemented(pRequest, pResponse, pClientReader->pStream, pWebSite)
	
	Return False
End Function
