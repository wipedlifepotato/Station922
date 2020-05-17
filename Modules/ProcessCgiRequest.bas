#include "ProcessCgiRequest.bi"
#include "ArrayStringWriter.bi"
#include "CharacterConstants.bi"
#include "CreateInstance.bi"
#include "Http.bi"
#include "HttpConst.bi"
#include "StringConstants.bi"
#include "WriteHttpError.bi"
#include "win\shlwapi.bi"

Const MaxEnvironmentBlockBufferLength As Integer = 256 * 1024

Declare Function CreateEnvironmentBlock( _
	ByVal pIRequest As IClientRequest Ptr, _
	ByVal pIResponse As IServerResponse Ptr, _
	ByVal pIWebSite As IWebSite Ptr, _
	ByVal pIRequestedFile As IRequestedFile Ptr _
)As WString Ptr

Function ProcessCgiRequest( _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal pIResponse As IServerResponse Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal pIClientReader As IHttpReader Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As Boolean
	
	Const MaxBufferLength As Integer = 4096 - 1
	
	Dim Buffer As ZString * (MaxBufferLength + 1) = Any
	
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	IClientRequest_GetContentLength(pIRequest, @RequestBodyContentLength.QuadPart)
	
	' Длина содержимого по заголовку Content-Length слишком большая
	If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
		WriteHttpRequestEntityTooLarge(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	Dim pEnvironmentBlock As WString Ptr = CreateEnvironmentBlock( _
		pIRequest, _
		pIResponse, _
		pIWebSite, _
		pIRequestedFile _
	)
	
	If pEnvironmentBlock = 0 Then
		WriteHttpNotEnoughMemory(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	Dim PathTranslated As WString Ptr = Any
	IRequestedFile_GetPathTranslated(pIRequestedFile, @PathTranslated)
	
	Dim CurrentChildProcessDirectory As WString * (MAX_PATH + 1) = Any
	lstrcpy(@CurrentChildProcessDirectory, PathTranslated)
	PathRemoveFileSpec(@CurrentChildProcessDirectory)
	
	Dim ApplicationNameBuffer As WString * (MAX_PATH + 1) = Any
	lstrcpy(@ApplicationNameBuffer, PathTranslated)
	
	Dim saAttr As SECURITY_ATTRIBUTES = Any
	With saAttr
		.nLength = SizeOf(SECURITY_ATTRIBUTES)
		.lpSecurityDescriptor = NULL
		.bInheritHandle = TRUE
	End With
	
	Dim hChildStdInRead As Handle = NULL
	Dim hChildStdInWrite As Handle = NULL
	Dim hChildStdOutRead As Handle = NULL
	Dim hChildStdOutWrite As Handle = NULL
	
	' Каналы чтения‐записи
	If CreatePipe(@hChildStdOutRead, @hChildStdOutWrite, @saAttr, 0) = 0 Then
		Dim dwError As DWORD = GetLastError()
		VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
		WriteHttpCannotCreatePipe(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	If SetHandleInformation(hChildStdOutRead, HANDLE_FLAG_INHERIT, 0) = 0 Then
		Dim dwError As DWORD = GetLastError()
		VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
		WriteHttpCannotCreatePipe(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	If CreatePipe(@hChildStdInRead, @hChildStdInWrite, @saAttr, 0) = 0 Then
		Dim dwError As DWORD = GetLastError()
		VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
		WriteHttpCannotCreatePipe(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	If SetHandleInformation(hChildStdInWrite, HANDLE_FLAG_INHERIT, 0) = 0 Then
		Dim dwError As DWORD = GetLastError()
		VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
		WriteHttpCannotCreatePipe(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	Dim siStartInfo As STARTUPINFO
	With siStartInfo
		.cb = SizeOf(STARTUPINFO)
		.hStdInput = hChildStdInRead
		.hStdOutput = hChildStdOutWrite
		.hStdError = hChildStdOutWrite
		.dwFlags = STARTF_USESTDHANDLES
	End With
	
	Dim piProcInfo As PROCESS_INFORMATION
	
	Dim CreateProcessResult As Integer = CreateProcess( _
		@ApplicationNameBuffer, _
		NULL, _
		NULL, _
		NULL, _
		True, _
		CREATE_UNICODE_ENVIRONMENT, _
		pEnvironmentBlock, _
		@CurrentChildProcessDirectory, _
		@siStartInfo, _
		@piProcInfo _
	)
	
	If CreateProcessResult = 0 Then
		#if __FB_DEBUG__ <> 0
			Dim dwError As DWORD = GetLastError()
			Print "Не могу создать дочерний процесс", dwError
		#endif
		VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
		CloseHandle(hChildStdInRead)
		CloseHandle(hChildStdInWrite)
		CloseHandle(hChildStdOutRead)
		CloseHandle(hChildStdOutWrite)
		
		WriteHttpCannotCreateChildProcess(pIRequest, pIResponse, CPtr(IBaseStream Ptr, pINetworkStream), pIWebSite)
		Return False
	End If
	
	Dim HttpMethod As HttpMethods = Any
	IClientRequest_GetHttpMethod(pIRequest, @HttpMethod)
	
	If HttpMethod = HttpMethods.HttpPost Then
		
		Dim WriteBytesCount As DWORD = Any
		
		Dim pPreloadedContent As UByte  Ptr = Any
		Dim PreloadedContentLength As Integer = Any
		
		IHttpReader_GetPreloadedBytes(pIClientReader, @PreloadedContentLength, @pPreloadedContent)
		
		If PreloadedContentLength > 0 Then
			' TODO Проверить на ошибки записи
			WriteFile( _
				hChildStdInWrite, _
				pPreloadedContent, _
				PreloadedContentLength, _
				@WriteBytesCount, _
				NULL _
			)
			IHttpReader_Clear(pIClientReader)
		End If
		
		' Записать всё остальное
		Do While PreloadedContentLength < RequestBodyContentLength.QuadPart
			Dim ReadedBytes As Integer = Any
			Dim hr As HRESULT = INetworkStream_Read(pINetworkStream, _
				@Buffer, 0, MaxBufferLength, @ReadedBytes _
			)
			If FAILED(hr) Then
				Exit Do
			End If
			If ReadedBytes = 0 Then
				Exit Do
			End If
			
			PreloadedContentLength += ReadedBytes
			WriteFile(hChildStdInWrite, @Buffer, ReadedBytes, @WriteBytesCount, NULL)
			
		Loop
	End If
	
	If CloseHandle(hChildStdInWrite) = 0 Then
		Dim dwError As DWORD = GetLastError()
	End If
	
	If CloseHandle(hChildStdOutWrite) = 0 Then
		Dim dwError As DWORD = GetLastError()
	End If
	
	Do
		Dim ReadBytesCount As DWORD = Any
		
		If ReadFile(hChildStdOutRead, @Buffer, MaxBufferLength, @ReadBytesCount, NULL) = 0 Then
			Dim dwError As DWORD = GetLastError()
			Exit Do
		End If
		
		If ReadBytesCount = 0 Then
			Exit Do
		End If
		
		Buffer[ReadBytesCount] = 0
		
		Dim WritedBytes As Integer = Any
		Dim hr As HRESULT = INetworkStream_Write(pINetworkStream, _
			@Buffer, 0, ReadBytesCount, @WritedBytes _
		)
		If FAILED(hr) Then
			Exit Do
		End If
	Loop
	
	CloseHandle(hChildStdInRead)
	CloseHandle(hChildStdOutRead)
	
	CloseHandle(piProcInfo.hProcess)
	CloseHandle(piProcInfo.hThread)
	
	VirtualFree(pEnvironmentBlock, 0, MEM_RELEASE)
	
	Return True
	
End Function

Function CreateEnvironmentBlock( _
		ByVal pIRequest As IClientRequest Ptr, _
		ByVal pIResponse As IServerResponse Ptr, _
		ByVal pIWebSite As IWebSite Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As WString Ptr
	
	Dim pIWriter As IArrayStringWriter Ptr = Any
	Dim hr As HRESULT = CreateInstance( _
		GetProcessHeap(), _
		@CLSID_ARRAYSTRINGWRITER, _
		@IID_IArrayStringWriter, _
		@pIWriter _
	)
	If FAILED(hr) Then
		Return 0
	End If
	
	Dim pEnvironmentBlock As WString Ptr = VirtualAlloc( _
		0, _
		MaxEnvironmentBlockBufferLength, _
		MEM_COMMIT Or MEM_RESERVE, _
		PAGE_READWRITE _
	)
	
	If pEnvironmentBlock = 0 Then
		' TODO Узнать ошибку и вывести
		Dim dwError As DWORD = GetLastError()
		Return 0
	End If
	
	IArrayStringWriter_SetBuffer(pIWriter, pEnvironmentBlock, MaxEnvironmentBlockBufferLength)
	
	' pEnvironmentBlock[0] = 0
	' pEnvironmentBlock[1] = 0
	' pEnvironmentBlock[2] = 0
	' pEnvironmentBlock[3] = 0
	'
	' Dim wStart As WString Ptr = pEnvironmentBlock
	
	Dim PathTranslated As WString Ptr = Any
	IRequestedFile_GetPathTranslated(pIRequestedFile, @PathTranslated)
	
	IArrayStringWriter_WriteString(pIWriter, @"SCRIPT_FILENAME=")
	IArrayStringWriter_WriteString(pIWriter, PathTranslated)
	
	IArrayStringWriter_WriteString(pIWriter, "PATH_INFO=")
	IArrayStringWriter_WriteString(pIWriter, @EmptyString)
	
	IArrayStringWriter_WriteString(pIWriter, @"SCRIPT_NAME=")
	IArrayStringWriter_WriteString(pIWriter, @EmptyString)
	
	Dim ClientURI As Station922Uri = Any
	IClientRequest_GetUri(pIRequest, @ClientURI)
	
	IArrayStringWriter_WriteString(pIWriter, @"REQUEST_LINE=")
	IArrayStringWriter_WriteString(pIWriter, ClientURI.pUrl)
	
	IArrayStringWriter_WriteString(pIWriter, @"QUERY_STRING=")
	IArrayStringWriter_WriteString(pIWriter, ClientURI.pQueryString)
	
	IArrayStringWriter_WriteString(pIWriter, @"SERVER_PROTOCOL=")
	
	' TODO Указать правильную версию
	Dim HttpVersion As HttpVersions = Any
	IServerResponse_GetHttpVersion(pIResponse, @HttpVersion)
	
	IArrayStringWriter_WriteString(pIWriter, HttpVersionToString(HttpVersion, NULL))
	
	' TODO Указать правильный порт
	IArrayStringWriter_WriteString(pIWriter, @"SERVER_PORT=80")
	REM lstrcat(wStart, @pWebSite->HostName)
	
	IArrayStringWriter_WriteString(pIWriter, @"GATEWAY_INTERFACE=")
	IArrayStringWriter_WriteString(pIWriter, @"CGI/1.1")
	
	IArrayStringWriter_WriteString(pIWriter, @"REMOTE_ADDR=")
	IArrayStringWriter_WriteString(pIWriter, @EmptyString)
	
	IArrayStringWriter_WriteString(pIWriter, @"REMOTE_HOST=")
	IArrayStringWriter_WriteString(pIWriter, @EmptyString)
	
	IArrayStringWriter_WriteString(pIWriter, "REQUEST_METHOD=")
	Scope
		Dim HttpMethod As HttpMethods = Any
		IClientRequest_GetHttpMethod(pIRequest, @HttpMethod)
		
		Dim pHttpMethod As WString Ptr = HttpMethodToString(HttpMethod, 0)
		IArrayStringWriter_WriteString(pIWriter, pHttpMethod)
	End Scope
	
	For i As Integer = 0 To HttpRequestHeadersMaximum - 1
		
		IArrayStringWriter_WriteString(pIWriter, KnownRequestCgiHeaderToString(i, 0))
		IArrayStringWriter_WriteChar(pIWriter, Characters.EqualsSign)
		
		Dim pHeader As WString Ptr = Any
		IClientRequest_GetHttpHeader(pIRequest, i, @pHeader)
		
		If pHeader <> 0 Then
			IArrayStringWriter_WriteString(pIWriter, pHeader)
		End If
		
	Next
	
	IArrayStringWriter_WriteChar(pIWriter, Characters.NullChar)
	
	Dim lpflOldProtect As DWORD = Any
	If VirtualProtect(pEnvironmentBlock, MaxEnvironmentBlockBufferLength, PAGE_READONLY, @lpflOldProtect) = 0 Then
		Dim dwError As DWORD = GetLastError()
	End If
	
	IArrayStringWriter_Release(pIWriter)
	
	Return pEnvironmentBlock
	
End Function
