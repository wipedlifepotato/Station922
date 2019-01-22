#include "ProcessPutRequest.bi"
#include "WebUtils.bi"
#include "WriteHttpError.bi"
#include "HttpConst.bi"
#include "win\shlwapi.bi"

Function ProcessPutRequest( _
		ByVal pRequest As WebRequest Ptr, _
		ByVal pResponse As WebResponse Ptr, _
		ByVal pINetworkStream As INetworkStream Ptr, _
		ByVal pWebSite As SimpleWebSite Ptr, _
		ByVal pClientReader As StreamSocketReader Ptr, _
		ByVal pIRequestedFile As IRequestedFile Ptr _
	)As Boolean
	
	If HttpAuthUtil(pRequest, pResponse, pINetworkStream, pWebSite, False) = False Then
		Return False
	End If
	
	' Если какой-то из переданных серверу заголовков Content-* не опознан или не может быть использован в данной ситуации
	' сервер возвращает статус ошибки 501 (Not Implemented).
	
	If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderContentType)) = 0 Then
		WriteHttpContentTypeEmpty(pRequest, pResponse, pINetworkStream, pWebSite)
		Return False
	End If
	
	' TODO Проверить тип содержимого
	
	' TODO Сохранить сжатое содержимое
	If lstrlen(pRequest->RequestHeaders(HttpRequestHeaders.HeaderContentEncoding)) <> 0 Then
		WriteHttpContentEncodingNotEmpty(pRequest, pResponse, pINetworkStream, pWebSite)
		Return False
	End If
	
	Dim RequestBodyContentLength As LARGE_INTEGER = Any
	
	' Требуется указание длины
	If StrToInt64Ex(pRequest->RequestHeaders(HttpRequestHeaders.HeaderContentLength), STIF_DEFAULT, @RequestBodyContentLength.QuadPart) = 0 Then
		WriteHttpLengthRequired(pRequest, pResponse, pINetworkStream, pWebSite)
		Return False
	End If
	
	' TODO Максимальная длина загружаемого содержимого
	' If RequestBodyContentLength.QuadPart > MaxRequestBodyContentLength Then
		' WriteHttpRequestEntityTooLarge(pState, pINetworkStream, pWebSite)
		' Return False
	' End If
	
	REM ' Может быть указана кодировка содержимого
	REM Dim contentType() As String = pState.RequestHeaders(HttpRequestHeaders.HeaderContentType).Split(";"c)
	REM Dim kvp = m_ContentTypes.Find(Function(x) x.ContentType = contentType(0))
	REM If kvp Is Nothing Then
		REM ' Такое содержимое нельзя загружать
		REM pState.StatusCode = 501
		REM pState.ResponseHeaders(HttpResponseHeaderIndices.HeaderAllow) = AllSupportHttpMethodsWithoutPut
		REM pState.WriteError(objStream, String.Format(MethodNotAllowed, pState.HttpMethod), pWebSite.VirtualPath)
		REM Exit Do
	REM End If
	
	Dim PathTranslated As WString Ptr = Any
	IRequestedFile_GetPathTranslated(pIRequestedFile, @PathTranslated)
	
	Dim HeaderLocation As WString * (MAX_PATH + 1) = Any
	
	' Открыть существующий файл для перезаписи
	Dim hFile As HANDLE = CreateFile( _
		PathTranslated, _
		GENERIC_READ + GENERIC_WRITE, _
		0, _
		NULL, _
		TRUNCATE_EXISTING, _
		FILE_ATTRIBUTE_NORMAL, _
		NULL _
	)
	
	If hFile = INVALID_HANDLE_VALUE Then
		' Создать каталог, если ещё не создан
		
		Select Case GetLastError()
			
			Case ERROR_PATH_NOT_FOUND
				Dim FileDir As WString * (MAX_PATH + 1) = Any
				lstrcpy(@FileDir, PathTranslated)
				PathRemoveFileSpec(@FileDir)
				CreateDirectory(@FileDir, Null)
				
		End Select
		
		hFile = CreateFile( _
			PathTranslated, _
			GENERIC_READ + GENERIC_WRITE, _
			0, _
			NULL, _
			OPEN_ALWAYS, _
			FILE_ATTRIBUTE_NORMAL, _
			NULL _
		)
		
		If hFile = INVALID_HANDLE_VALUE Then
			' TODO Узнать код ошибки и отправить его клиенту
			WriteHttpFileNotAvailable(pRequest, pResponse, pINetworkStream, pWebSite)
			Return False
		End If
		
		pResponse->StatusCode = 201
	End If
	
	Dim FilePath As WString Ptr = Any
	IRequestedFile_GetFilePath(pIRequestedFile, @FilePath)
	
	lstrcpy(@HeaderLocation, "http://")
	lstrcat(@HeaderLocation, pWebSite->HostName)
	lstrcat(@HeaderLocation, FilePath)
	
	Dim hFileMap As Handle = CreateFileMapping( _
		hFile, _
		0, _
		PAGE_READWRITE, _
		RequestBodyContentLength.HighPart, _
		RequestBodyContentLength.LowPart, _
		0 _
	)
	If hFileMap = 0 Then
		' TODO Узнать код ошибки и отправить его клиенту
		WriteHttpFileNotAvailable(pRequest, pResponse, pINetworkStream, pWebSite)
		
		CloseHandle(hFile)
		Return False
	End If
	
	Dim pFileBytes As Byte Ptr = CPtr(Byte Ptr, MapViewOfFile(hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, 0))
	If pFileBytes = 0 Then
		' TODO Узнать код ошибки и отправить его клиенту
		WriteHttpFileNotAvailable(pRequest, pResponse, pINetworkStream, pWebSite)
		
		CloseHandle(hFileMap)
		CloseHandle(hFile)
		Return False
	End If
	
	pResponse->ResponseHeaders(HttpResponseHeaders.HeaderLocation) = @HeaderLocation
	
	' TODO Заголовки записать в специальный файл
	REM HeaderContentEncoding
	REM HeaderContentLanguage
	REM HeaderContentLocation
	REM HeaderContentMd5
	REM HeaderContentType
	
	' Записать предварительно загруженные данные и удалить их из клиентского буфера
	Dim PreloadedContentLength As Integer = pClientReader->BufferLength - pClientReader->Start
	If PreloadedContentLength > 0 Then
		RtlCopyMemory(pFileBytes, @pClientReader->Buffer[pClientReader->Start], PreloadedContentLength)
		' TODO Проверить на ошибки записи
		pClientReader->Flush()
	End If
	
	' Записать всё остальное
	Do While PreloadedContentLength < RequestBodyContentLength.QuadPart
		Dim ReadedBytes As Integer = Any
		Dim hr As HRESULT = INetworkStream_Read(pINetworkStream, _
			pFileBytes, PreloadedContentLength, RequestBodyContentLength.QuadPart - PreloadedContentLength, @ReadedBytes _
		)
		If FAILED(hr) Then
			Exit Do
		End If
		If ReadedBytes = 0 Then
			Exit Do
		End If
		
		' Сколько байт получили, на столько и увеличили буфер
		PreloadedContentLength += ReadedBytes
		
	Loop
	
	UnmapViewOfFile(pFileBytes)
	CloseHandle(hFileMap)
	CloseHandle(hFile)
	
	' Удалить файл 410, если он был
	Dim PathTranslated410 As WString * (MAX_PATH + 4 + 1) = Any
	lstrcpy(@PathTranslated410, PathTranslated)
	lstrcat(@PathTranslated410, @FileGoneExtension)
	
	' TODO Проверить ошибку
	DeleteFile(@PathTranslated410)
	
	WriteHttpCreated(pRequest, pResponse, pINetworkStream, pWebSite)
	
	Return True
End Function
