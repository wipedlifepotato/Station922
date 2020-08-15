#include "RequestedFile.bi"
#include "ContainerOf.bi"
#include "HttpConst.bi"
#include "PrintDebugInfo.bi"

Extern GlobalRequestedFileVirtualTable As Const IRequestedFileVirtualTable
Extern GlobalRequestedFileSendableVirtualTable As Const ISendableVirtualTable

Const REQUESTEDFILE_MAXPATHLENGTH As Integer = 4095 + 32
Const REQUESTEDFILE_MAXPATHTRANSLATEDLENGTH As Integer = 4095 + 32

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Type _RequestedFile
	Dim lpVtbl As Const IRequestedFileVirtualTable Ptr
	Dim lpSendableVtbl As Const ISendableVirtualTable Ptr
	Dim ReferenceCounter As Integer
	Dim crSection As CRITICAL_SECTION
	Dim pIMemoryAllocator As IMalloc Ptr
	
	Dim FilePath As WString * (REQUESTEDFILE_MAXPATHLENGTH + 1)
	Dim PathTranslated As WString * (REQUESTEDFILE_MAXPATHTRANSLATEDLENGTH + 1)
	
	Dim LastFileModifiedDate As FILETIME
	
	Dim FileHandle As Handle
	
End Type

Sub InitializeRequestedFile( _
		ByVal this As RequestedFile Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalRequestedFileVirtualTable
	this->lpSendableVtbl = @GlobalRequestedFileSendableVirtualTable
	this->ReferenceCounter = 0
	InitializeCriticalSectionAndSpinCount( _
		@this->crSection, _
		MAX_CRITICAL_SECTION_SPIN_COUNT _
	)
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	
	this->FilePath[0] = 0
	this->PathTranslated[0] = 0
	this->FileHandle = INVALID_HANDLE_VALUE
	
End Sub

Sub UnInitializeRequestedFile( _
		ByVal this As RequestedFile Ptr _
	)
	
	If this->FileHandle <> INVALID_HANDLE_VALUE Then
		If CloseHandle(this->FileHandle) = 0 Then
			#ifndef WINDOWS_SERVICE
				Dim dwError As DWORD = GetLastError()
				PrintErrorCode(!"RequestedFile Ошибка закрытия файла FileHandle\t", dwError)
			#endif
		End If
		this->FileHandle = INVALID_HANDLE_VALUE
	End If
	
	DeleteCriticalSection(@this->crSection)
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateRequestedFile( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As RequestedFile Ptr
	
	#ifndef WINDOWS_SERVICE
		PrintErrorCode(!"RequestedFile create\t", 0)
	#endif
	
	Dim this As RequestedFile Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(RequestedFile) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeRequestedFile(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyRequestedFile( _
		ByVal this As RequestedFile Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeRequestedFile(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		PrintErrorCode(!"RequestedFile destroyed\t", 0)
	#endif
	
End Sub

Function RequestedFileQueryInterface( _
		ByVal this As RequestedFile Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IRequestedFile, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_ISendable, riid) Then
			*ppv = @this->lpSendableVtbl
		Else
			If IsEqualIID(@IID_IUnknown, riid) Then
				*ppv = @this->lpVtbl
			Else
				*ppv = NULL
				Return E_NOINTERFACE
			End If
		End If
	End If
	
	RequestedFileAddRef(this)
	
	Return S_OK
	
End Function

Function RequestedFileAddRef( _
		ByVal this As RequestedFile Ptr _
	)As ULONG
	
	EnterCriticalSection(@this->crSection)
	Scope
		this->ReferenceCounter += 1
	End Scope
	LeaveCriticalSection(@this->crSection)
	
	Return 1
	
End Function

Function RequestedFileRelease( _
		ByVal this As RequestedFile Ptr _
	)As ULONG
	
	EnterCriticalSection(@this->crSection)
	Scope
		this->ReferenceCounter -= 1
	End Scope
	LeaveCriticalSection(@this->crSection)
	
	If this->ReferenceCounter = 0 Then
		
		DestroyRequestedFile(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function RequestedFileGetFilePath( _
		ByVal this As RequestedFile Ptr, _
		ByVal ppFilePath As WString Ptr Ptr _
	)As HRESULT
	
	*ppFilePath = @this->FilePath
	
	Return S_OK
	
End Function

Function RequestedFileSetFilePath( _
		ByVal this As RequestedFile Ptr, _
		ByVal FilePath As WString Ptr _
	)As HRESULT
	
	lstrcpyn(@this->FilePath, FilePath, REQUESTEDFILE_MAXPATHLENGTH + 1)
	
	Return S_OK
	
End Function

Function RequestedFileGetPathTranslated( _
		ByVal this As RequestedFile Ptr, _
		ByVal ppPathTranslated As WString Ptr Ptr _
	)As HRESULT
	
	*ppPathTranslated = @this->PathTranslated
	
	Return S_OK
	
End Function

Function RequestedFileSetPathTranslated( _
		ByVal this As RequestedFile Ptr, _
		ByVal PathTranslated As WString Ptr _
	)As HRESULT
	
	lstrcpyn(@this->PathTranslated, PathTranslated, REQUESTEDFILE_MAXPATHTRANSLATEDLENGTH + 1)
	
	Return S_OK
	
End Function

Function RequestedFileFileExists( _
		ByVal this As RequestedFile Ptr, _
		ByVal pResult As RequestedFileState Ptr _
	)As HRESULT
	
	If this->FileHandle = INVALID_HANDLE_VALUE Then
		' TODO Проверить код ошибки через GetLastError, могут быть не только File Not Found
		Dim buf410 As WString * (MAX_PATH + 1) = Any
		lstrcpy(@buf410, @this->PathTranslated)
		lstrcat(@buf410, @FileGoneExtension)
		
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
			*pResult = RequestedFileState.NotFound
		Else
			CloseHandle(hFile410)
			*pResult = RequestedFileState.Gone
		End If
		
	Else
		*pResult = RequestedFileState.Exist
	End If
	
	Return S_OK
	
End Function

Function RequestedFileGetFileHandle( _
		ByVal this As RequestedFile Ptr, _
		ByVal pResult As HANDLE Ptr _
	)As HRESULT
	
	*pResult = this->FileHandle
	
	Return S_OK
	
End Function

Function RequestedFileSetFileHandle( _
		ByVal this As RequestedFile Ptr, _
		ByVal hFile As HANDLE _
	)As HRESULT
	
	this->FileHandle = hFile
	
	Return S_OK
	
End Function

Function RequestedFileGetLastFileModifiedDate( _
		ByVal this As RequestedFile Ptr, _
		ByVal pResult As FILETIME Ptr _
	)As HRESULT
	
	Dim DateLastFileModified As FILETIME = Any
	
	If GetFileTime(this->FileHandle, NULL, NULL, @DateLastFileModified) = 0 Then
		Return HRESULT_FROM_WIN32(GetLastError())
	End If
	
	*pResult = DateLastFileModified
	
	Return S_OK
	
End Function

' Declare Function RequestedFileGetFileLength( _
	' ByVal this As RequestedFile Ptr, _
	' ByVal pResult As ULongInt Ptr _
' )As HRESULT

' Declare Function RequestedFileGetVaryHeaders( _
	' ByVal this As RequestedFile Ptr, _
	' ByVal pHeadersLength As Integer Ptr, _
	' ByVal ppHeaders As HttpRequestHeaders Ptr Ptr _
' )As HRESULT

Function RequestedFileSendableQueryInterface( _
		ByVal this As RequestedFile Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	Return RequestedFileQueryInterface(this, riid, ppv)
	
End Function

Function RequestedFileSendableAddRef( _
		ByVal this As RequestedFile Ptr _
	)As ULONG
	
	Return RequestedFileAddRef(this)
	
End Function

Function RequestedFileSendableRelease( _
		ByVal this As RequestedFile Ptr _
	)As ULONG
	
	Return RequestedFileRelease(this)
	
End Function

' Declare Function RequestedFileSendableSend( _
	' ByVal this As RequestedFile Ptr, _
	' ByVal pIStream As INetworkStream Ptr, _
	' ByVal pHeader As ZString Ptr, _
	' ByVal HeaderLength As DWORD _
' )As HRESULT

Function RequestedFileSendableBeginSend( _
		ByVal this As RequestedFile Ptr, _
		ByVal pIStream As INetworkStream Ptr, _
		ByVal pHeader As ZString Ptr, _
		ByVal HeaderLength As DWORD, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	*ppIAsyncResult = NULL
	
	Return S_OK
	
End Function

Function RequestedFileSendableEndSend( _
		ByVal this As RequestedFile Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	
	Return S_OK
	
End Function


Function IRequestedFileQueryInterface( _
		ByVal this As IRequestedFile Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return RequestedFileQueryInterface(ContainerOf(this, RequestedFile, lpVtbl), riid, ppvObject)
End Function

Function IRequestedFileAddRef( _
		ByVal this As IRequestedFile Ptr _
	)As ULONG
	Return RequestedFileAddRef(ContainerOf(this, RequestedFile, lpVtbl))
End Function

Function IRequestedFileRelease( _
		ByVal this As IRequestedFile Ptr _
	)As ULONG
	Return RequestedFileRelease(ContainerOf(this, RequestedFile, lpVtbl))
End Function

Function IRequestedFileGetFilePath( _
		ByVal this As IRequestedFile Ptr, _
		ByVal ppFilePath As WString Ptr Ptr _
	)As HRESULT
	Return RequestedFileGetFilePath(ContainerOf(this, RequestedFile, lpVtbl), ppFilePath)
End Function

Function IRequestedFileSetFilePath( _
		ByVal this As IRequestedFile Ptr, _
		ByVal FilePath As WString Ptr _
	)As HRESULT
	Return RequestedFileSetFilePath(ContainerOf(this, RequestedFile, lpVtbl), FilePath)
End Function

Function IRequestedFileGetPathTranslated( _
		ByVal this As IRequestedFile Ptr, _
		ByVal ppPathTranslated As WString Ptr Ptr _
	)As HRESULT
	Return RequestedFileGetPathTranslated(ContainerOf(this, RequestedFile, lpVtbl), ppPathTranslated)
End Function

Function IRequestedFileSetPathTranslated( _
		ByVal this As IRequestedFile Ptr, _
		ByVal PathTranslated As WString Ptr _
	)As HRESULT
	Return RequestedFileSetPathTranslated(ContainerOf(this, RequestedFile, lpVtbl), PathTranslated)
End Function

Function IRequestedFileFileExists( _
		ByVal this As IRequestedFile Ptr, _
		ByVal pResult As RequestedFileState Ptr _
	)As HRESULT
	Return RequestedFileFileExists(ContainerOf(this, RequestedFile, lpVtbl), pResult)
End Function

Function IRequestedFileGetFileHandle( _
		ByVal this As IRequestedFile Ptr, _
		ByVal pResult As HANDLE Ptr _
	)As HRESULT
	Return RequestedFileGetFileHandle(ContainerOf(this, RequestedFile, lpVtbl), pResult)
End Function

Function IRequestedFileSetFileHandle( _
		ByVal this As IRequestedFile Ptr, _
		ByVal hFile As HANDLE _
	)As HRESULT
	Return RequestedFileSetFileHandle(ContainerOf(this, RequestedFile, lpVtbl), hFile)
End Function

Function IRequestedFileGetLastFileModifiedDate( _
		ByVal this As IRequestedFile Ptr, _
		ByVal pResult As FILETIME Ptr _
	)As HRESULT
	Return RequestedFileGetLastFileModifiedDate(ContainerOf(this, RequestedFile, lpVtbl), pResult)
End Function

' Function IRequestedFileGetFileLength( _
		' ByVal this As IRequestedFile Ptr, _
		' ByVal pResult As ULongInt Ptr _
	' )As HRESULT
	' Return RequestedFileGetFileLength(ContainerOf(this, RequestedFile, lpVtbl), pResult)
' End Function

' Function IRequestedFileGetVaryHeaders( _
		' ByVal this As IRequestedFile Ptr, _
		' ByVal pHeadersLength As Integer Ptr, _
		' ByVal ppHeaders As HttpRequestHeaders Ptr Ptr _
	' )As HRESULT
	' Return RequestedFileGetVaryHeaders(ContainerOf(this, RequestedFile, lpVtbl), pHeadersLength, ppHeaders)
' End Function

Dim GlobalRequestedFileVirtualTable As Const IRequestedFileVirtualTable = Type( _
	@IRequestedFileQueryInterface, _
	@IRequestedFileAddRef, _
	@IRequestedFileRelease, _
	@IRequestedFileGetFilePath, _
	@IRequestedFileSetFilePath, _
	@IRequestedFileGetPathTranslated, _
	@IRequestedFileSetPathTranslated, _
	@IRequestedFileFileExists, _
	@IRequestedFileGetFileHandle, _
	@IRequestedFileSetFileHandle, _
	@IRequestedFileGetLastFileModifiedDate, _
	NULL, _
	NULL _
)

Function IRequestedFileSendableQueryInterface( _
		ByVal this As ISendable Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return RequestedFileSendableQueryInterface(ContainerOf(this, RequestedFile, lpSendableVtbl), riid, ppvObject)
End Function

Function IRequestedFileSendableAddRef( _
		ByVal this As ISendable Ptr _
	)As ULONG
	Return RequestedFileSendableAddRef(ContainerOf(this, RequestedFile, lpSendableVtbl))
End Function

Function IRequestedFileSendableRelease( _
		ByVal this As ISendable Ptr _
	)As ULONG
	Return RequestedFileSendableRelease(ContainerOf(this, RequestedFile, lpSendableVtbl))
End Function

' Function IRequestedFileSendableSend( _
		' ByVal this As ISendable Ptr, _
		' ByVal pIStream As INetworkStream Ptr, _
		' ByVal pHeader As ZString Ptr, _
		' ByVal HeaderLength As DWORD _
	' )As HRESULT
	' Return RequestedFileSendableSend(ContainerOf(this, RequestedFile, lpSendableVtbl), pIStream, pHeader, HeaderLength)
' End Function

Function IRequestedFileSendableBeginSend( _
		ByVal this As ISendable Ptr, _
		ByVal pIStream As INetworkStream Ptr, _
		ByVal pHeader As ZString Ptr, _
		ByVal HeaderLength As DWORD, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	Return RequestedFileSendableBeginSend(ContainerOf(this, RequestedFile, lpSendableVtbl), pIStream, pHeader, HeaderLength, callback, StateObject, ppIAsyncResult)
End Function

Function IRequestedFileSendableEndSend( _
		ByVal this As ISendable Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr _
	)As HRESULT
	Return RequestedFileSendableEndSend(ContainerOf(this, RequestedFile, lpSendableVtbl), pIAsyncResult)
End Function

' TODO Заполнить виртуальную таблицу RequestedFile
Dim GlobalRequestedFileSendableVirtualTable As Const ISendableVirtualTable = Type( _
	@IRequestedFileSendableQueryInterface, _
	@IRequestedFileSendableAddRef, _
	@IRequestedFileSendableRelease, _
	NULL, _ /' Send '/
	@IRequestedFileSendableBeginSend, _
	@IRequestedFileSendableEndSend _
)
