#include "CreateInstance.bi"
#include "ArrayStringWriter.bi"
#include "AsyncResult.bi"
#include "ClientContext.bi"
#include "ClientRequest.bi"
#include "Configuration.bi"
#include "HttpGetProcessor.bi"
#include "HttpReader.bi"
#include "NetworkStream.bi"
#include "PrivateHeapMemoryAllocator.bi"
#include "RequestedFile.bi"
#include "ServerResponse.bi"
#include "WebServer.bi"
#include "WebSite.bi"
#include "WebSiteContainer.bi"

Function CreateInstance( _
		ByVal pIMemoryAllocator As IMalloc Ptr, _
		ByVal rclsid As REFCLSID, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	*ppv = NULL
	
	If IsEqualCLSID(@CLSID_WEBSITE, rclsid) Then
		Dim pWebSite As WebSite Ptr = CreateWebSite(pIMemoryAllocator)
		
		If pWebSite = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = WebSiteQueryInterface(pWebSite, riid, ppv)
		
		If FAILED(hr) Then
			DestroyWebSite(pWebSite)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_HTTPREADER, rclsid) Then
		Dim pReader As HttpReader Ptr = CreateHttpReader(pIMemoryAllocator)
		
		If pReader = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = HttpReaderQueryInterface(pReader, riid, ppv)
		
		If FAILED(hr) Then
			DestroyHttpReader(pReader)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_SERVERRESPONSE, rclsid) Then
		Dim pResponse As ServerResponse Ptr = CreateServerResponse(pIMemoryAllocator)
		
		If pResponse = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ServerResponseQueryInterface(pResponse, riid, ppv)
		
		If FAILED(hr) Then
			DestroyServerResponse(pResponse)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_CLIENTREQUEST, rclsid) Then
		Dim pRequest As ClientRequest Ptr = CreateClientRequest(pIMemoryAllocator)
		
		If pRequest = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ClientRequestQueryInterface(pRequest, riid, ppv)
		
		If FAILED(hr) Then
			DestroyClientRequest(pRequest)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_NETWORKSTREAM, rclsid) Then
		Dim pStream As NetworkStream Ptr = CreateNetworkStream(pIMemoryAllocator)
		
		If pStream = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = NetworkStreamQueryInterface(pStream, riid, ppv)
		
		If FAILED(hr) Then
			DestroyNetworkStream(pStream)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_CLIENTCONTEXT, rclsid) Then
		Dim pContext As ClientContext Ptr = CreateClientContext(pIMemoryAllocator)
		
		If pContext = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ClientContextQueryInterface(pContext, riid, ppv)
		
		If FAILED(hr) Then
			DestroyClientContext(pContext)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_WEBSITECONTAINER, rclsid) Then
		Dim pWebSites As WebSiteContainer Ptr = CreateWebSiteContainer(pIMemoryAllocator)
		
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
		Dim pRequestedFile As RequestedFile Ptr = CreateRequestedFile(pIMemoryAllocator)
		
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
		Dim pWebServer As WebServer Ptr = CreateWebServer(pIMemoryAllocator)
		
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
		Dim pConfiguration As Configuration Ptr = CreateConfiguration(pIMemoryAllocator)
		
		If pConfiguration = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ConfigurationQueryInterface(pConfiguration, riid, ppv)
		
		If FAILED(hr) Then
			DestroyConfiguration(pConfiguration)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_ARRAYSTRINGWRITER, rclsid) Then
		Dim pWriter As ArrayStringWriter Ptr = CreateArrayStringWriter(pIMemoryAllocator)
		
		If pWriter = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = ArrayStringWriterQueryInterface(pWriter, riid, ppv)
		
		If FAILED(hr) Then
			DestroyArrayStringWriter(pWriter)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_ASYNCRESULT, rclsid) Then
		Dim pAsyncResult As AsyncResult Ptr = CreateAsyncResult(pIMemoryAllocator)
		
		If pAsyncResult = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = AsyncResultQueryInterface(pAsyncResult, riid, ppv)
		
		If FAILED(hr) Then
			DestroyAsyncResult(pAsyncResult)
		End If
		
		Return hr
	End If
	
	If IsEqualCLSID(@CLSID_HTTPGETPROCESSOR, rclsid) Then
		Dim pProcessor As HttpGetProcessor Ptr = CreateHttpGetProcessor(pIMemoryAllocator)
		
		If pProcessor = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = HttpGetProcessorQueryInterface(pProcessor, riid, ppv)
		
		If FAILED(hr) Then
			DestroyHttpGetProcessor(pProcessor)
		End If
		
		Return hr
	End If
	
	Return CLASS_E_CLASSNOTAVAILABLE
	
End Function

Function CoGetPrivateHeapMalloc( _
		ByVal dwMemContext As DWORD, _
		ByVal ppMalloc As LPMALLOC Ptr _
	)As HRESULT
	
	' Return CoGetMalloc(dwMemContext, ppMalloc)
	
	*ppMalloc = NULL
	
	Const CLIENTCONTEXT_HEAP_INITIALSIZE As DWORD = 256 * 1024
	Const CLIENTCONTEXT_HEAP_MAXIMUMSIZE As DWORD = 256 * 1024
	
	' Создать аллокатор
	Dim pIMemoryAllocator As IMalloc Ptr = Any
	Dim hr As HRESULT = CoGetMalloc(1, @pIMemoryAllocator)
	If FAILED(hr) Then
		Return hr
	End If
	
	Dim pAllocator As PrivateHeapMemoryAllocator Ptr = CreatePrivateHeapMemoryAllocator(pIMemoryAllocator)
	If pAllocator = NULL Then
		IMalloc_Release(pIMemoryAllocator)
		Return E_OUTOFMEMORY
	End If
	
	IMalloc_Release(pIMemoryAllocator)
	
	hr = PrivateHeapMemoryAllocatorQueryInterface(pAllocator, @IID_IPrivateHeapMemoryAllocator, ppMalloc)
	If FAILED(hr) Then
		DestroyPrivateHeapMemoryAllocator(pAllocator)
		Return E_OUTOFMEMORY
	End If
	
	hr = PrivateHeapMemoryAllocatorCreateHeap(pAllocator, True, CLIENTCONTEXT_HEAP_INITIALSIZE, CLIENTCONTEXT_HEAP_MAXIMUMSIZE)
	' hr = PrivateHeapMemoryAllocatorCreateHeap(pAllocator, False, CLIENTCONTEXT_HEAP_INITIALSIZE, CLIENTCONTEXT_HEAP_MAXIMUMSIZE)
	If FAILED(hr) Then
		DestroyPrivateHeapMemoryAllocator(pAllocator)
		*ppMalloc = NULL
		Return E_OUTOFMEMORY
	End If
	
	Return hr
	
End Function

/'
Function CreateClassFactoryInstance Alias "DllGetClassObject"( _
		ByVal rclsid As REFCLSID, _
		ByVal riid As REFIID, _
		ByVal ppv As Any Ptr Ptr _
	)As HRESULT
	
	If IsEqualCLSID(@CLSID_PRIVATEHEAPMEMORYALLOCATOR, rclsid) Then
		
		Dim pFactory As PrivateHeapMemoryAllocatorClassFactory Ptr = CreatePrivateHeapMemoryAllocatorClassFactory()
		If pFactory = NULL Then
			Return E_OUTOFMEMORY
		End If
		
		Dim hr As HRESULT = PrivateHeapMemoryAllocatorClassFactoryQueryInterface(pFactory, riid, ppv)
		If FAILED(hr) Then
			DestroyPrivateHeapMemoryAllocatorClassFactory(pFactory)
		End If
		
		Return hr
	End If
	
	Return CLASS_E_CLASSNOTAVAILABLE
	
End Function
'/
