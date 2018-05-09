#ifndef ISERVERSTATE_BI
#define ISERVERSTATE_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "Http.bi"
#include once "ReadHeadersResult.bi"
#include once "WebSite.bi"

Type IServerState As IServerState_

Type IServerStateVirtualTable
	Dim GetRequestHeader As Function( _
		ByVal objState As IServerState Ptr, _
		ByVal Value As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal HeaderIndex As HttpRequestHeaders _
	)As Integer
	
	Dim GetHttpMethod As Function( _
		ByVal objState As IServerState Ptr _
	)As HttpMethods
	
	Dim GetHttpVersion As Function( _
		ByVal objState As IServerState Ptr _
	)As HttpVersions
	
	Dim SetStatusCode As Sub( _
		ByVal objState As IServerState Ptr, _
		ByVal Code As Integer _
	)
	
	Dim SetStatusDescription As Sub( _
		ByVal objState As IServerState Ptr, _
		ByVal Description As WString Ptr _
	)
	
	Dim SetResponseHeader As Sub( _
		ByVal objState As IServerState Ptr, _
		ByVal HeaderIndex As HttpResponseHeaders, _
		ByVal Value As WString Ptr _
	)
	
	Dim WriteData As Function( _
		ByVal objState As IServerState Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal BytesCount As Integer _
	)As Boolean
	
	Dim ReadData As Function( _
		ByVal objState As IServerState Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal BufferLength As Integer, _
		ByVal ReadedBytesCount As Integer Ptr _
	)As Boolean
	
	Dim GetHtmlSafeString As Function( _
		ByVal objState As IServerState Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal HtmlSafe As WString Ptr, _
		ByVal HtmlSafeLength As Integer Ptr _
	)As Boolean
	
End Type

Type IServerState_
	Dim VirtualTable As IServerStateVirtualTable Ptr
End Type

#endif
