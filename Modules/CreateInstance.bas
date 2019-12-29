﻿#include "CreateInstance.bi"
' #include "ArrayStringWriter.bi"
' #include "ClientRequest.bi"
#include "Configuration.bi"
' #include "HttpReader.bi"
' #include "NetworkStream.bi"
#include "RequestedFile.bi"
' #include "ServerResponse.bi"
' #include "ServerState.bi"
#include "WebServer.bi"
' #include "WebSite.bi"
#include "WebSiteContainer.bi"

Function CreateInstance( _
		ByVal hHeap As HANDLE, _
		ByVal rclsid As REFCLSID, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = NULL
	
	If IsEqualCLSID(@CLSID_WEBSITECONTAINER, rclsid) Then
		Dim pWebSites As WebSiteContainer Ptr = CreateWebSiteContainer()
		
		If pWebSites = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = WebSiteContainerQueryInterface(pWebSites, riid, ppv)
		
		If FAILED(hr) Then
			DestroyWebSiteContainer(pWebSites)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_REQUESTEDFILE, rclsid) Then
		Dim pRequestedFile As RequestedFile Ptr = CreateRequestedFile()
		
		If pRequestedFile = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = RequestedFileQueryInterface(pRequestedFile, riid, ppv)
		
		If FAILED(hr) Then
			DestroyRequestedFile(pRequestedFile)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_WEBSERVER, rclsid) Then
		Dim pWebServer As WebServer Ptr = CreateWebServer()
		
		If pWebServer = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = WebServerQueryInterface(pWebServer, riid, ppv)
		
		If FAILED(hr) Then
			DestroyWebServer(pWebServer)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_CONFIGURATION, rclsid) Then
		Dim pConfiguration As Configuration Ptr = CreateConfiguration()
		
		If pConfiguration = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ConfigurationQueryInterface(pConfiguration, riid, ppv)
		
		If FAILED(hr) Then
			DestroyConfiguration(pConfiguration)
		End If
		
		Return hr
	End If
	
	Return CLASS_E_CLASSNOTAVAILABLE
	
End Function
