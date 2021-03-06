#include "HttpReader.bi"
#include "ContainerOf.bi"
#include "PrintDebugInfo.bi"
#include "FindNewLineIndex.bi"
#include "StringConstants.bi"

Extern GlobalHttpReaderVirtualTable As Const IHttpReaderVirtualTable

Const MAX_CRITICAL_SECTION_SPIN_COUNT As DWORD = 4000

Type _HttpReader
	
	Dim lpVtbl As Const IHttpReaderVirtualTable Ptr
	Dim ReferenceCounter As Integer
	#ifndef WITHOUT_CRITICAL_SECTIONS
		Dim crSection As CRITICAL_SECTION
	#endif
	Dim pIMemoryAllocator As IMalloc Ptr
	
	Dim pIStream As IBaseStream Ptr
	
	Dim Buffer As ZString * (HTTPREADER_MAXBUFFER_LENGTH + 1)
	Dim BufferLength As Integer
	
	Dim LinesBuffer As WString * (HTTPREADER_MAXBUFFER_LENGTH + 1)
	Dim LinesBufferLength As Integer
	
	Dim StartLineIndex As Integer
	
	Dim IsAllBytesReaded As Boolean
	
End Type

Declare Function HttpReaderConvertBytesToString( _
	ByVal this As HttpReader Ptr, _
	ByVal DoubleCrLfIndex As Integer _
)As HRESULT

Declare Function HttpReaderReadAllBytes( _
	ByVal this As HttpReader Ptr, _
	ByVal pDoubleCrLfIndex As Integer Ptr _
)As HRESULT

Sub InitializeHttpReader( _
		ByVal this As HttpReader Ptr, _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)
	
	this->lpVtbl = @GlobalHttpReaderVirtualTable
	this->ReferenceCounter = 0
	#ifndef WITHOUT_CRITICAL_SECTIONS
		InitializeCriticalSectionAndSpinCount( _
			@this->crSection, _
			MAX_CRITICAL_SECTION_SPIN_COUNT _
		)
	#endif
	IMalloc_AddRef(pIMemoryAllocator)
	this->pIMemoryAllocator = pIMemoryAllocator
	this->pIStream = NULL
	this->Buffer[0] = 0
	this->Buffer[HTTPREADER_MAXBUFFER_LENGTH] = 0
	this->BufferLength = 0
	this->LinesBuffer[0] = 0
	this->LinesBufferLength = 0
	this->IsAllBytesReaded = False
	this->StartLineIndex = 0
	
End Sub

Sub UnInitializeHttpReader( _
		ByVal this As HttpReader Ptr _
	)
	
	If this->pIStream <> NULL Then
		IBaseStream_Release(this->pIStream)
	End If
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		DeleteCriticalSection(@this->crSection)
	#endif
	IMalloc_Release(this->pIMemoryAllocator)
	
End Sub

Function CreateHttpReader( _
		ByVal pIMemoryAllocator As IMalloc Ptr _
	)As HttpReader Ptr
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"HttpReader create\t")
	#endif
	
	Dim this As HttpReader Ptr = IMalloc_Alloc( _
		pIMemoryAllocator, _
		SizeOf(HttpReader) _
	)
	If this = NULL Then
		Return NULL
	End If
	
	InitializeHttpReader(this, pIMemoryAllocator)
	
	Return this
	
End Function

Sub DestroyHttpReader( _
		ByVal this As HttpReader Ptr _
	)
	
	IMalloc_AddRef(this->pIMemoryAllocator)
	Dim pIMemoryAllocator As IMalloc Ptr = this->pIMemoryAllocator
	
	UnInitializeHttpReader(this)
	
	IMalloc_Free(pIMemoryAllocator, this)
	
	IMalloc_Release(pIMemoryAllocator)
	
	#ifndef WINDOWS_SERVICE
		DebugPrint(!"HttpReader destroyed\t")
	#endif
	
End Sub

Function HttpReaderQueryInterface( _
		ByVal this As HttpReader Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualIID(@IID_IHttpReader, riid) Then
		*ppv = @this->lpVtbl
	Else
		If IsEqualIID(@IID_ITextReader, riid) Then
			*ppv = @this->lpVtbl
		Else
			If IsEqualIID(@IID_IUnknown, riid) Then
				*ppv = @this->lpVtbl
			Else
				*ppv = NULL
				Return E_NOINTERFACE
			End If
		End If
	End If
	
	HttpReaderAddRef(this)
	
	Return S_OK
	
End Function

Function HttpReaderAddRef( _
		ByVal this As HttpReader Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter += 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	Return 1
	
End Function

Function HttpReaderRelease( _
		ByVal this As HttpReader Ptr _
	)As ULONG
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		EnterCriticalSection(@this->crSection)
	#endif
	
	this->ReferenceCounter -= 1
	
	#ifndef WITHOUT_CRITICAL_SECTIONS
		LeaveCriticalSection(@this->crSection)
	#endif
	
	If this->ReferenceCounter = 0 Then
		
		DestroyHttpReader(this)
		
		Return 0
	End If
	
	Return 1
	
End Function

Function HttpReaderReadLine( _
		ByVal this As HttpReader Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal ppLine As WString Ptr Ptr _
	)As HRESULT
	
	If this->IsAllBytesReaded = False Then
		
		Dim DoubleCrLfIndex As Integer = Any
		Dim hr As HRESULT = HttpReaderReadAllBytes(this, @DoubleCrLfIndex)
		If FAILED(hr) Then
			*pLineLength = 0
			*ppLine = @this->LinesBuffer
			Return hr
		End If
		
		hr = HttpReaderConvertBytesToString(this, DoubleCrLfIndex)
		If FAILED(hr) Then
			*pLineLength = 0
			*ppLine = @this->LinesBuffer
			Return hr
		End If
		
	End If
	
	' Найти CrLf
	Dim CrLfIndex As Integer = Any
	
	FindCrLfIndexW( _
		@this->LinesBuffer[this->StartLineIndex], _
		this->LinesBufferLength - this->StartLineIndex, _
		@CrLfIndex _
	)
	
	*pLineLength = CrLfIndex
	*ppLine = @this->LinesBuffer[this->StartLineIndex]
	
	this->LinesBuffer[this->StartLineIndex + CrLfIndex] = 0
	this->StartLineIndex += CrLfIndex + NewLineStringLength
	
	Return S_OK
	
	' TODO Проверить, начинается ли строка за CrLf с пробела
	' Если начинается — сдвинуть до начала непробела
	
	' If ppLine[0] = Characters.WhiteSpace Then
		' Do
			' pLine += 1
		' Loop While pLine[0] = Characters.WhiteSpace
		
		' lstrcat(pClientRequest->RequestHeaders(PreviousHeaderIndex), pLine)
		
	' End If
	
End Function

Function HttpReaderBeginReadLine( _
		ByVal this As HttpReader Ptr, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	
	Dim hr As HRESULT = IBaseStream_BeginRead( _
		this->pIStream, _
		@this->Buffer[this->BufferLength], _
		HTTPREADER_MAXBUFFER_LENGTH - this->BufferLength, _
		callback, _
		StateObject, _
		ppIAsyncResult _
	)
	If FAILED(hr) Then
		Return HTTPREADER_E_SOCKETERROR
	End If
	
	If hr = BASESTREAM_S_IO_PENDING Then
		Return TEXTREADER_S_IO_PENDING
	End If
	
	Return S_OK
	
End Function

Function HttpReaderEndReadLine( _
		ByVal this As HttpReader Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal ppLine As WString Ptr Ptr _
	)As HRESULT
	
	Dim ReceivedBytesCount As Integer = Any
	Dim hr As HRESULT = IBaseStream_EndRead( _
		this->pIStream, _
		pIAsyncResult, _
		@ReceivedBytesCount _
	)
	If FAILED(hr) Then
		Return HTTPREADER_E_SOCKETERROR
	End If
	
	If hr = BASESTREAM_S_IO_PENDING Then
		Return TEXTREADER_S_IO_PENDING
	End If
	
	If hr = S_FALSE Then
		Return S_FALSE
	End If
	
	this->BufferLength += ReceivedBytesCount
	this->Buffer[this->BufferLength] = 0
	
	If this->BufferLength >= HTTPREADER_MAXBUFFER_LENGTH Then
		Return HTTPREADER_E_INTERNALBUFFEROVERFLOW
	End If
	
	Dim DoubleCrLfIndex As Integer = Any
	Dim FindResult As Boolean = FindDoubleCrLfIndexA( _
		@this->Buffer, _
		this->BufferLength, _
		@DoubleCrLfIndex _
	)
	If FindResult = False Then
		Return TEXTREADER_S_IO_PENDING
	End If
	
	this->IsAllBytesReaded = True
	
	hr = HttpReaderConvertBytesToString(this, DoubleCrLfIndex)
	If FAILED(hr) Then
		*pLineLength = 0
		*ppLine = @this->LinesBuffer
		Return hr
	End If
	
	Dim CrLfIndex As Integer = Any
	
	FindCrLfIndexW( _
		@this->LinesBuffer[this->StartLineIndex], _
		this->LinesBufferLength - this->StartLineIndex, _
		@CrLfIndex _
	)
	
	*pLineLength = CrLfIndex
	*ppLine = @this->LinesBuffer[this->StartLineIndex]
	
	this->LinesBuffer[this->StartLineIndex + CrLfIndex] = 0
	this->StartLineIndex += CrLfIndex + NewLineStringLength
	
	Return S_OK
	
End Function

Function HttpReaderClear( _
		ByVal this As HttpReader Ptr _
	)As HRESULT
	
	If this->StartLineIndex <> 0 Then
		
		If this->BufferLength - this->StartLineIndex <= 0 Then
			this->Buffer[0] = 0
			this->BufferLength = 0
		Else
			RtlMoveMemory( _
				@this->Buffer, _
				@this->Buffer[this->StartLineIndex], _
				HTTPREADER_MAXBUFFER_LENGTH - this->StartLineIndex + 1 _
			)
			this->BufferLength -= this->StartLineIndex
		End If
		
		this->StartLineIndex = 0
	End If
	
	this->LinesBuffer[0] = 0
	this->LinesBufferLength = 0
	this->IsAllBytesReaded = False
	this->StartLineIndex = 0
	
	Return S_OK
	
End Function

Function HttpReaderGetBaseStream( _
		ByVal this As HttpReader Ptr, _
		ByVal ppResult As IBaseStream Ptr Ptr _
	)As HRESULT
	
	If this->pIStream = NULL Then
		*ppResult = NULL
		Return S_FALSE
	End If
	
	IBaseStream_AddRef(this->pIStream)
	*ppResult = this->pIStream
	
	Return S_OK
	
End Function

Function HttpReaderSetBaseStream( _
		ByVal this As HttpReader Ptr, _
		ByVal pIStream As IBaseStream Ptr _
	)As HRESULT
	
	If this->pIStream <> NULL Then
		IBaseStream_Release(this->pIStream)
	End If
	
	If pIStream <> NULL Then
		IBaseStream_AddRef(pIStream)
	End If
	
	this->pIStream = pIStream
	
	Return S_OK
	
End Function

Function HttpReaderGetPreloadedBytes( _
		ByVal this As HttpReader Ptr, _
		ByVal pPreloadedBytesLength As Integer Ptr, _
		ByVal ppPreloadedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	*pPreloadedBytesLength = this->BufferLength - this->StartLineIndex
	*ppPreloadedBytes = @this->Buffer[this->StartLineIndex]
	
	Return S_OK
	
End Function

Function HttpReaderGetRequestedBytes( _
		ByVal this As HttpReader Ptr, _
		ByVal pRequestedBytesLength As Integer Ptr, _
		ByVal ppRequestedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	*pRequestedBytesLength = this->BufferLength
	*ppRequestedBytes = @this->Buffer
	
	Return S_OK
	
End Function

Function HttpReaderIsCompleted( _
		ByVal this As HttpReader Ptr, _
		ByVal pCompleted As Boolean Ptr _
	)As HRESULT
	
	*pCompleted = this->IsAllBytesReaded
	
	Return S_OK
	
End Function

Function HttpReaderConvertBytesToString( _
		ByVal this As HttpReader Ptr, _
		ByVal DoubleCrLfIndex As Integer _
	)As HRESULT
	
	Const dwFlags As DWORD = 0
	
	Dim CharsLength As Integer = MultiByteToWideChar( _
		CP_UTF8, _
		dwFlags, _
		@this->Buffer, _
		DoubleCrLfIndex + 2 * NewLineStringLength, _
		@this->LinesBuffer, _
		HTTPREADER_MAXBUFFER_LENGTH _
	)
	
	this->LinesBufferLength = CharsLength
	this->LinesBuffer[CharsLength] = 0
	
	If CharsLength = 0 Then
		' Dim dwError As DWORD = GetLastError()
		Return HTTPREADER_E_BUFFERTOOSMALL
	End If
	
	Return S_OK
	
End Function

Function HttpReaderReadAllBytes( _
		ByVal this As HttpReader Ptr, _
		ByVal pDoubleCrLfIndex As Integer Ptr _
	)As HRESULT
	
	Dim DoubleCrLfIndex As Integer = Any
	Dim FindResult As Boolean = Any
	
	Do
		Dim ReceivedBytesCount As Integer = Any
		
		Dim hr As HRESULT = IBaseStream_Read( _
			this->pIStream, _
			@this->Buffer[this->BufferLength], _
			HTTPREADER_MAXBUFFER_LENGTH - this->BufferLength, _
			@ReceivedBytesCount _
		)
		
		If FAILED(hr) Then
			Return HTTPREADER_E_SOCKETERROR
		End If
		
		If hr = S_FALSE Then
			Return HTTPREADER_E_CLIENTCLOSEDCONNECTION
		End If
		
		this->BufferLength += ReceivedBytesCount
		this->Buffer[this->BufferLength] = 0
		
		If this->BufferLength >= HTTPREADER_MAXBUFFER_LENGTH Then
			Return HTTPREADER_E_INTERNALBUFFEROVERFLOW
		End If
		
		FindResult = FindDoubleCrLfIndexA( _
			@this->Buffer, _
			this->BufferLength, _
			@DoubleCrLfIndex _
		)
		
	Loop While FindResult = False
	
	*pDoubleCrLfIndex = DoubleCrLfIndex
	this->IsAllBytesReaded = True
	
	Return S_OK
	
End Function


Function IHttpReaderQueryInterface( _
		ByVal this As IHttpReader Ptr, _
		ByVal riid As REFIID, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	Return HttpReaderQueryInterface(ContainerOf(this, HttpReader, lpVtbl), riid, ppvObject)
End Function

Function IHttpReaderAddRef( _
		ByVal this As IHttpReader Ptr _
	)As ULONG
	Return HttpReaderAddRef(ContainerOf(this, HttpReader, lpVtbl))
End Function

Function IHttpReaderRelease( _
		ByVal this As IHttpReader Ptr _
	)As ULONG
	Return HttpReaderRelease(ContainerOf(this, HttpReader, lpVtbl))
End Function

Function IHttpReaderReadLine( _
		ByVal this As IHttpReader Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal pLine As WString Ptr Ptr _
	)As HRESULT
	Return HttpReaderReadLine(ContainerOf(this, HttpReader, lpVtbl), pLineLength, pLine)
End Function

Function IHttpReaderBeginReadLine( _
		ByVal this As IHttpReader Ptr, _
		ByVal callback As AsyncCallback, _
		ByVal StateObject As IUnknown Ptr, _
		ByVal ppIAsyncResult As IAsyncResult Ptr Ptr _
	)As HRESULT
	Return HttpReaderBeginReadLine(ContainerOf(this, HttpReader, lpVtbl), callback, StateObject, ppIAsyncResult)
End Function

Function IHttpReaderEndReadLine( _
		ByVal this As IHttpReader Ptr, _
		ByVal pIAsyncResult As IAsyncResult Ptr, _
		ByVal pLineLength As Integer Ptr, _
		ByVal ppLine As WString Ptr Ptr _
	)As HRESULT
	Return HttpReaderEndReadLine(ContainerOf(this, HttpReader, lpVtbl), pIAsyncResult, pLineLength, ppLine)
End Function

Function IHttpReaderClear( _
		ByVal this As IHttpReader Ptr _
	)As HRESULT
	Return HttpReaderClear(ContainerOf(this, HttpReader, lpVtbl))
End Function

Function IHttpReaderGetBaseStream( _
		ByVal this As IHttpReader Ptr, _
		ByVal ppResult As IBaseStream Ptr Ptr _
	)As HRESULT
	Return HttpReaderGetBaseStream(ContainerOf(this, HttpReader, lpVtbl), ppResult)
End Function

Function IHttpReaderSetBaseStream( _
		ByVal this As IHttpReader Ptr, _
		ByVal pIStream As IBaseStream Ptr _
	)As HRESULT
	Return HttpReaderSetBaseStream(ContainerOf(this, HttpReader, lpVtbl), pIStream)
End Function

Function IHttpReaderGetPreloadedBytes( _
		ByVal this As IHttpReader Ptr, _
		ByVal pPreloadedBytesLength As Integer Ptr, _
		ByVal ppPreloadedBytes As UByte Ptr Ptr _
	)As HRESULT
	Return HttpReaderGetPreloadedBytes(ContainerOf(this, HttpReader, lpVtbl), pPreloadedBytesLength, ppPreloadedBytes)
End Function

Function IHttpReaderGetRequestedBytes( _
		ByVal this As IHttpReader Ptr, _
		ByVal pRequestedBytesLength As Integer Ptr, _
		ByVal ppRequestedBytes As UByte Ptr Ptr _
	)As HRESULT
	Return HttpReaderGetRequestedBytes(ContainerOf(this, HttpReader, lpVtbl), pRequestedBytesLength, ppRequestedBytes)
End Function

Function IHttpReaderIsCompleted( _
		ByVal this As IHttpReader Ptr, _
		ByVal pCompleted As Boolean Ptr _
	)As HRESULT
	Return HttpReaderIsCompleted(ContainerOf(this, HttpReader, lpVtbl), pCompleted)
End Function

Dim GlobalHttpReaderVirtualTable As Const IHttpReaderVirtualTable = Type( _
	@IHttpReaderQueryInterface, _
	@IHttpReaderAddRef, _
	@IHttpReaderRelease, _
	NULL, _             /' IHttpReaderPeek '/
	NULL, _             /' IHttpReaderReadChar '/
	NULL, _             /' IHttpReaderReadCharArray '/ 
	@IHttpReaderReadLine, _
	NULL, _             /' IHttpReaderReadToEnd '/
	@IHttpReaderBeginReadLine, _
	@IHttpReaderEndReadLine, _
	NULL, _             /' BeginReadToEnd '/
	NULL, _             /' EndReadToEnd '/
	@IHttpReaderClear, _
	@IHttpReaderGetBaseStream, _
	@IHttpReaderSetBaseStream, _
	@IHttpReaderGetPreloadedBytes, _
	@IHttpReaderGetRequestedBytes, _
	@IHttpReaderIsCompleted _
)
