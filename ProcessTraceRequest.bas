#include "ProcessTraceRequest.bi"
#include "Mime.bi"
#include "WebUtils.bi"

Function ProcessTraceRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As Boolean
	
	pResponse->Mime.ContentType = ContentTypes.MessageHttp
	pResponse->Mime.IsTextFormat = True
	pResponse->Mime.Charset = DocumentCharsets.ASCII
	
	Dim ContentLength As Integer = pClientReader->Start - 2
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer + StreamSocketReader.MaxBufferLength) = Any
	Dim HeadersLength As Integer = AllResponseHeadersToBytes(pRequest, pResponse, @SendBuffer, ContentLength)
	
	RtlCopyMemory(@SendBuffer + HeadersLength, @pClientReader->Buffer, ContentLength)
	
	Dim WritedBytes As Integer = Any
	Dim hr As HRESULT = INetworkStream_Write(pINetworkStream, _
		@SendBuffer, 0, HeadersLength + ContentLength, @WritedBytes _
	)
	
	If FAILED(hr) Then
		Return False
	End If
	
	Return True
End Function
