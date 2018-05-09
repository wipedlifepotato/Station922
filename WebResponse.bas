#ifndef unicode
#define unicode
#endif

#include once "WebResponse.bi"
#include once "windows.bi"

Sub InitializeWebResponse( _
		ByVal pWebResponse As WebResponse Ptr _
	)
	memset(@pWebResponse->ResponseHeaders(0), 0, WebResponse.ResponseHeaderMaximum * SizeOf(WString Ptr))
	pWebResponse->SendOnlyHeaders = False
	pWebResponse->StatusDescription = 0
	pWebResponse->ResponseZipMode = ZipModes.None
	pWebResponse->StartResponseHeadersPtr = @pWebResponse->ResponseHeaderBuffer
	pWebResponse->StatusCode = 200
End Sub

Sub WebResponse.AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	' TODO Если заголовок уже есть в списке, то может произойти переполнение буфера
	Dim HeaderIndex As HttpResponseHeaders = Any
	If GetKnownResponseHeader(HeaderName, @HeaderIndex) Then
		AddKnownResponseHeader(HeaderIndex, Value)
	End If
End Sub

Sub WebResponse.AddKnownResponseHeader(ByVal Header As HttpResponseHeaders, ByVal Value As WString Ptr)
	' TODO Избежать многократного добавления заголовка
	lstrcpy(StartResponseHeadersPtr, Value)
	ResponseHeaders(Header) = StartResponseHeadersPtr
	StartResponseHeadersPtr += lstrlen(Value) + 2
End Sub

Sub WebResponse.SetStatusDescription(ByVal Description As WString Ptr)
	lstrcpy(StartResponseHeadersPtr, Description)
	StatusDescription = StartResponseHeadersPtr
	StartResponseHeadersPtr += lstrlen(Description) + 2
End Sub
