#include "ServerState.bi"
#include "WebUtils.bi"

Common Shared GlobalServerStateVirtualTable As IServerStateVirtualTable

Function ServerStateDllCgiGetRequestHeader( _
		ByVal objState As ServerState Ptr, _
		ByVal Value As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal HeaderIndex As HttpRequestHeaders _
	)As Integer
	
	Dim HeaderLength As Integer = lstrlen(objState->pRequest->RequestHeaders(HeaderIndex))
	If HeaderLength > BufferLength Then
		SetLastError(ERROR_INSUFFICIENT_BUFFER)
		Return -1
	End If
	
	SetLastError(ERROR_SUCCESS)
	lstrcpy(Value, objState->pRequest->RequestHeaders(HeaderIndex))
	Return HeaderLength
End Function

Function ServerStateDllCgiGetHttpMethod( _
		ByVal objState As ServerState Ptr _
	)As HttpMethods
	
	SetLastError(ERROR_SUCCESS)
	Return objState->pRequest->HttpMethod
End Function

Function ServerStateDllCgiGetHttpVersion( _
		ByVal objState As ServerState Ptr _
	)As HttpVersions
	
	SetLastError(ERROR_SUCCESS)
	Return objState->pRequest->HttpVersion
End Function

Sub ServerStateDllCgiSetStatusCode( _
		ByVal objState As ServerState Ptr, _
		ByVal Code As Integer _
	)
	objState->pResponse->StatusCode = Code
End Sub

Sub ServerStateDllCgiSetStatusDescription( _
		ByVal objState As ServerState Ptr, _
		ByVal Description As WString Ptr _
	)
	' TODO Устранить потенциальное переполнение буфера
	objState->pResponse->SetStatusDescription(Description)
End Sub

Sub ServerStateDllCgiSetResponseHeader( _
		ByVal objState As ServerState Ptr, _
		ByVal HeaderIndex As HttpResponseHeaders, _
		ByVal Value As WString Ptr _
	)
	' TODO Устранить потенциальное переполнение буфера
	objState->pResponse->AddKnownResponseHeader(HeaderIndex, Value)
End Sub

Function ServerStateDllCgiWriteData( _
		ByVal objState As ServerState Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal BytesCount As Integer _
	)As Boolean
	
	If BytesCount > MaxClientBufferLength - objState->BufferLength Then
		SetLastError(ERROR_BUFFER_OVERFLOW)
		Return False
	End If
	
	RtlCopyMemory(objState->ClientBuffer, Buffer, BytesCount)
	objState->BufferLength += BytesCount
	SetLastError(ERROR_SUCCESS)
	
	Return True
End Function

Function ServerStateDllCgiReadData( _
		ByVal objState As ServerState Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal BufferLength As Integer, _
		ByVal ReadedBytesCount As Integer Ptr _
	)As Boolean
	
	Return False
End Function

Function ServerStateDllCgiGetHtmlSafeString( _
		ByVal objState As IServerState Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal HtmlSafe As WString Ptr, _
		ByVal HtmlSafeLength As Integer Ptr _
	)As Boolean
	Return GetHtmlSafeString(Buffer, BufferLength, HtmlSafe, HtmlSafeLength)
End Function

Sub InitializeServerState( _
		ByVal objServerState As ServerState Ptr, _
		ByVal pStream As IBaseStream Ptr, _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal www As SimpleWebSite Ptr, _
		ByVal hMapFile As HANDLE, _
		ByVal ClientBuffer As Any Ptr _
	)
	objServerState->pVirtualTable = @GlobalServerStateVirtualTable
	objServerState->ReferenceCounter = 1
	objServerState->pStream = pStream
	objServerState->pRequest = pRequest
	objServerState->pResponse = pResponse
	objServerState->www = www
	objServerState->hMapFile = hMapFile
	objServerState->ClientBuffer = ClientBuffer
	objServerState->BufferLength = 0
End Sub
