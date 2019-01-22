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
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As Boolean
	
	Dim PathTranslated As WString Ptr = Any
	IRequestedFile_GetPathTranslated(pIRequestedFile, @PathTranslated)
	
	Dim FileHandle As HANDLE = Any
	IRequestedFile_GetFileHandle(pIRequestedFile, @FileHandle)
	
	If FileHandle = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found.
		Dim buf410 As WString * (MAX_PATH + 1) = Any
		lstrcpy(buf410, PathTranslated)
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
			WriteHttpFileNotFound(pRequest, pResponse, pINetworkStream, pWebSite)
		Else
			WriteHttpFileGone(pRequest, pResponse, pINetworkStream, pWebSite)
		End If
		
		Return False
	End If
	
	If NeedCGIProcessing(pRequest->ClientUri.Path) Then
		CloseHandle(FileHandle)
		Return ProcessCGIRequest(pRequest, pResponse, pINetworkStream, pWebSite, pClientReader, pIRequestedFile)
	End If
	
	If NeedDLLProcessing(pRequest->ClientUri.Path) Then
		CloseHandle(FileHandle)
		Return ProcessDllCgiRequest(pRequest, pResponse, pINetworkStream, pWebSite, pClientReader, pIRequestedFile)
	End If
	
	Dim objRequestedFile As SafeHandle = Type<SafeHandle>(FileHandle)
	
	pResponse->ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethodsForFile
	WriteHttpNotImplemented(pRequest, pResponse, pINetworkStream, pWebSite)
	
	Return False
End Function
