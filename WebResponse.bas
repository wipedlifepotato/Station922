#ifndef unicode
#define unicode
#endif

#include once "WebResponse.bi"
#include once "windows.bi"

Sub WebResponse.Initialize()
	memset(@ResponseHeaders(0), 0, ResponseHeaderMaximum * SizeOf(WString Ptr))
	SendOnlyHeaders = False
	StatusDescription = 0
	ResponseZipMode = ZipModes.None
	StartResponseHeadersPtr = @ResponseHeaderBuffer
	StatusCode = 200
End Sub

Sub WebResponse.AddResponseHeader(ByVal HeaderName As WString Ptr, ByVal Value As WString Ptr)
	' TODO Если заголовок уже есть в списке, то может произойти переполнение буфера
	Dim HeaderIndex As Integer = GetKnownResponseHeaderIndex(HeaderName)
	If HeaderIndex >= 0 Then
		AddKnownResponseHeader(HeaderIndex, Value)
	End If
End Sub

Sub WebResponse.AddKnownResponseHeader(ByVal HeaderIndex As HttpResponseHeaderIndices, ByVal Value As WString Ptr)
	' TODO Избежать многократное добавление заголовка
	lstrcpy(StartResponseHeadersPtr, Value)
	ResponseHeaders(HeaderIndex) = StartResponseHeadersPtr
	StartResponseHeadersPtr += lstrlen(Value) + 2
End Sub

Sub WebResponse.SetStatusDescription(ByVal Description As WString Ptr)
	lstrcpy(StartResponseHeadersPtr, Description)
	StatusDescription = StartResponseHeadersPtr
	StartResponseHeadersPtr += lstrlen(Description) + 2
End Sub
