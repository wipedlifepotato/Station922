#include "HttpReader.bi"
#include "WebUtils.bi"

Dim Shared GlobalHttpReaderVirtualTable As IHttpReaderVirtualTable

Sub InitializeHttpReaderVirtualTable()
	GlobalHttpReaderVirtualTable.InheritedTable.QueryInterface = Cast(Any Ptr, @HttpReaderQueryInterface)
	GlobalHttpReaderVirtualTable.InheritedTable.AddRef = Cast(Any Ptr, @HttpReaderAddRef)
	GlobalHttpReaderVirtualTable.InheritedTable.Release = Cast(Any Ptr, @HttpReaderRelease)
	GlobalHttpReaderVirtualTable.ReadLine = Cast(Any Ptr, @HttpReaderReadLine)
	GlobalHttpReaderVirtualTable.Clear = Cast(Any Ptr, @HttpReaderClear)
	GlobalHttpReaderVirtualTable.GetBaseStream = Cast(Any Ptr, @HttpReaderGetBaseStream)
	GlobalHttpReaderVirtualTable.SetBaseStream = Cast(Any Ptr, @HttpReaderSetBaseStream)
	GlobalHttpReaderVirtualTable.GetPreloadedBytes = Cast(Any Ptr, @HttpReaderGetPreloadedBytes)
	GlobalHttpReaderVirtualTable.GetRequestedBytes = Cast(Any Ptr, @HttpReaderGetRequestedBytes)
End Sub

Sub InitializeHttpReader( _
		ByVal pHttpReader As HttpReader Ptr _
	)
	
	pHttpReader->pVirtualTable = @GlobalHttpReaderVirtualTable
	pHttpReader->ReferenceCounter = 0
	pHttpReader->pIStream = NULL
	pHttpReader->BufferLength = 0
	pHttpReader->StartLineIndex = 0
	pHttpReader->Buffer[0] = 0
	
End Sub

Sub UnInitializeHttpReader( _
		ByVal pHttpReader As HttpReader Ptr _
	)
	
	If pHttpReader->pIStream <> NULL Then
		IBaseStream_Release(pHttpReader->pIStream)
	End If
	
End Sub

Function InitializeHttpReaderOfIHttpReader( _
		ByVal pHttpReader As HttpReader Ptr _
	)As IHttpReader Ptr
	
	InitializeHttpReader(pHttpReader)
	pHttpReader->ExistsInStack = True
	
	Dim pIHttpReader As IHttpReader Ptr = Any
	
	HttpReaderQueryInterface( _
		pHttpReader, @IID_IHTTPREADER, @pIHttpReader _
	)
	
	Return pIHttpReader
	
End Function

Function HttpReaderQueryInterface( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, @pHttpReader->pVirtualTable)
	End If
	
	If IsEqualIID(@IID_IHTTPREADER, riid) Then
		*ppv = CPtr(IHttpReader Ptr, @pHttpReader->pVirtualTable)
	End If
	
	If *ppv = 0 Then
		Return E_NOINTERFACE
	End If
	
	HttpReaderAddRef(pHttpReader)
	
	Return S_OK
	
End Function

Function HttpReaderAddRef( _
		ByVal pHttpReader As HttpReader Ptr _
	)As ULONG
	
	Return InterlockedIncrement(@pHttpReader->ReferenceCounter)
	
End Function

Function HttpReaderRelease( _
		ByVal pHttpReader As HttpReader Ptr _
	)As ULONG
	
	InterlockedDecrement(@pHttpReader->ReferenceCounter)
	
	If pHttpReader->ReferenceCounter = 0 Then
		
		UnInitializeHttpReader(pHttpReader)
		
		If pHttpReader->ExistsInStack = False Then
		
		End If
		
		Return 0
	End If
	
	Return pHttpReader->ReferenceCounter
	
End Function

Function HttpReaderReadLine( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal pBuffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pLineLength As Integer Ptr _
	)As HRESULT
	
	Dim CrLfIndex As Integer = Any
	
	Do While FindCrLfA(@pHttpReader->Buffer[pHttpReader->StartLineIndex], pHttpReader->BufferLength, 0, @CrLfIndex) = False
		
		If pHttpReader->BufferLength >= HttpReader.MaxBufferLength Then
			pBuffer[0] = 0
			*pLineLength = 0
			Return HTTPREADER_E_INTERNALBUFFEROVERFLOW
		End If
		
		Dim ReceivedBytesCount As Integer = Any
		
		Dim hr As HRESULT = IBaseStream_Read(pHttpReader->pIStream, _
			@pHttpReader->Buffer[pHttpReader->BufferLength], _
			0, _
			HttpReader.MaxBufferLength - pHttpReader->BufferLength, _
			@ReceivedBytesCount _
		)
		
		If FAILED(hr) Then
			pBuffer[0] = 0
			*pLineLength = 0
			Return HTTPREADER_E_SOCKETERROR
		End If
		
		If hr = S_FALSE Then
			pBuffer[0] = 0
			*pLineLength = 0
			Return HTTPREADER_E_CLIENTCLOSEDCONNECTION
		End If
		
		pHttpReader->BufferLength += ReceivedBytesCount
		pHttpReader->Buffer[pHttpReader->BufferLength] = 0
		
	Loop
	
	If CrLfIndex = 0 Then
		pBuffer[0] = 0
		*pLineLength = 0
	Else
		
		Dim CharsLength As Integer = MultiByteToWideChar( _
			CP_UTF8, _
			0, _
			@pHttpReader->Buffer[pHttpReader->StartLineIndex], _
			CrLfIndex, _
			pBuffer, _
			BufferLength _
		)
		
		If CharsLength = 0 Then
			Dim dwError As DWORD = GetLastError()
			pBuffer[0] = 0
			*pLineLength = 0
			Return HTTPREADER_E_BUFFERTOOSMALL
		End If
		
		pBuffer[CharsLength] = 0
		*pLineLength = CharsLength
		
	End If
	
	pHttpReader->StartLineIndex += CrLfIndex + 2
	
	Return S_OK
	
End Function

Function HttpReaderClear( _
		ByVal pHttpReader As HttpReader Ptr _
	)As HRESULT
	
	If pHttpReader->StartLineIndex <> 0 Then
		
		If pHttpReader->BufferLength - pHttpReader->StartLineIndex <= 0 Then
			pHttpReader->Buffer[0] = 0
			pHttpReader->BufferLength = 0
		Else
			RtlMoveMemory( _
				@pHttpReader->Buffer, _
				@pHttpReader->Buffer[pHttpReader->StartLineIndex], _
				HttpReader.MaxBufferLength - pHttpReader->StartLineIndex + 1 _
			)
			pHttpReader->BufferLength -= pHttpReader->StartLineIndex
		End If
		
		pHttpReader->StartLineIndex = 0
	End If
	
	Return S_OK
	
End Function

Function HttpReaderGetBaseStream( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal ppResult As IBaseStream Ptr Ptr _
	)As HRESULT
	
	If pHttpReader->pIStream = NULL Then
		*ppResult = NULL
		Return S_FALSE
	End If
	
	IBaseStream_AddRef(pHttpReader->pIStream)
	*ppResult = pHttpReader->pIStream
	
	Return S_OK
	
End Function

Function HttpReaderSetBaseStream( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal pIStream As IBaseStream Ptr _
	)As HRESULT
	
	If pHttpReader->pIStream <> NULL Then
		IBaseStream_Release(pHttpReader->pIStream)
	End If
	
	IBaseStream_AddRef(pIStream)
	pHttpReader->pIStream = pIStream
	
	Return S_OK
	
End Function

Function HttpReaderGetPreloadedBytes( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal pPreloadedBytesLength As Integer Ptr, _
		ByVal ppPreloadedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	*pPreloadedBytesLength = pHttpReader->BufferLength - pHttpReader->StartLineIndex
	*ppPreloadedBytes = @pHttpReader->Buffer[pHttpReader->StartLineIndex]
	
	Return S_OK
	
End Function

Function HttpReaderGetRequestedBytes( _
		ByVal pHttpReader As HttpReader Ptr, _
		ByVal pRequestedBytesLength As Integer Ptr, _
		ByVal ppRequestedBytes As UByte Ptr Ptr _
	)As HRESULT
	
	*pRequestedBytesLength = pHttpReader->BufferLength
	*ppRequestedBytes = @pHttpReader->Buffer
	
	Return S_OK
	
End Function
