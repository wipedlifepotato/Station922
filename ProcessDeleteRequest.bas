#include "ProcessDeleteRequest.bi"
#include "HttpConst.bi"
#include "WriteHttpError.bi"
#include "WebUtils.bi"

Function ProcessDeleteRequest( _
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
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found
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
		
		If hFile410 = INVALID_HANDLE_VALUE Then
			WriteHttpFileNotFound(pRequest, pResponse, pINetworkStream, pWebSite)
		Else
			CloseHandle(hFile410)
			WriteHttpFileGone(pRequest, pResponse, pINetworkStream, pWebSite)
		End If
		
		Return False
	End If
	
	CloseHandle(FileHandle)
	
	' Проверка заголовка Authorization
	If HttpAuthUtil(pRequest, pResponse, pINetworkStream, pWebSite, False) = False Then
		Return False
	End If
	
	' TODO Узнать код ошибки и отправить его клиенту
	If DeleteFile(PathTranslated) = 0 Then
		WriteHttpFileNotAvailable(pRequest, pResponse, pINetworkStream, pWebSite)
		Return False
	End If
	
	' TODO Удалить возможные заголовочные файлы
	Dim sExtHeadersFile As WString * (MAX_PATH + 1) = Any
	lstrcpy(@sExtHeadersFile, PathTranslated)
	lstrcat(@sExtHeadersFile, @HeadersExtensionString)
	
	DeleteFile(@sExtHeadersFile)
	
	' Создать файл «.410», показывающий, что файл был удалён
	lstrcpy(@sExtHeadersFile, PathTranslated)
	lstrcat(@sExtHeadersFile, @FileGoneExtension)
	
	Dim hFile410 As HANDLE = CreateFile( _
		@sExtHeadersFile, _
		GENERIC_WRITE, _
		0, _
		NULL, _
		CREATE_NEW, _
		FILE_ATTRIBUTE_NORMAL, _
		NULL _
	)
	
	CloseHandle(hFile410)
	
	pResponse->StatusCode = 204
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	
	Dim WritedBytes As Integer = Any
	Dim hr As HRESULT = INetworkStream_Write(pINetworkStream, _
		@SendBuffer, 0, AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, 0), @WritedBytes _
	)
	
	If FAILED(hr) Then
		Return False
	End If
	
	Return True
End Function
