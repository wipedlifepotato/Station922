#include "ProcessTraceRequest.bi"
#include "Mime.bi"
#include "WebUtils.bi"

Function ProcessTraceRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pRequestedFile As RequestedFile Ptr _
	)As Boolean
	
	pResponse->Mime.ContentType = ContentTypes.MessageHttp
	pResponse->Mime.IsTextFormat = True
	pResponse->Mime.Charset = DocumentCharsets.ASCII
	
	Dim ContentLength As Integer = pClientReader->Start - 2
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + StreamSocketReader.MaxBufferLength) = Any
	Dim HeadersLength As Integer = AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, ContentLength)
	
	RtlCopyMemory(@SendBuffer + HeadersLength, @pClientReader->Buffer, ContentLength)
	
	If send(ClientSocket, @SendBuffer, HeadersLength + ContentLength, 0) = SOCKET_ERROR Then
		Return False
	End If
	
	Return True
End Function
