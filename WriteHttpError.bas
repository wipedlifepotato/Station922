#include once "WriteHttpError.bi"
#include once "WebUtils.bi"
#include once "IntegerToWString.bi"

' TODO Описания ошибок перевести на эсперанто

' Размер буфера в символах для записи в него кода html страницы с ошибкой
Const MaxHttpErrorBuffer As Integer = 16 * 1024 - 1

Const HttpErrorContentType = "text/html; charset=utf-8"
Const DefaultContentLanguage = "ru"
Const HttpErrorHead1 = "<!DOCTYPE html><html xmlns=""http://www.w3.org/1999/xhtml""><head><meta name=""viewport"" content=""width=device-width, initial-scale=1"" /><title>"
Const HttpErrorHead2 = "</title></head>"
Const HttpErrorBody1 = "<body><h1>"
Const HttpErrorBody3 = "</h1><h2>Код ответа HTTP "
Const HttpErrorBody4 = " — "
Const HttpErrorBody5 = "</h2><p>"
Const HttpErrorBody6 = "</p><p>Посетить <a href=""/"">главную страницу</a> сайта.</p></body></html>"

Const ClientCreatedString = "Ресурс создан"
Const ClientMovedString = "Ресурс перенаправлен"
Const ClientErrorString = "Клиентская ошибка"
Const ServerErrorString = "Серверная ошибка"
Const HttpErrorBody2 = " в приложении "

' TODO Исправить для ошибок HttpCreated и HttpCreatedUpdated, которые на самом деле не ошибки
Const HttpCreated201_1 = "Ресурс успешно создан."
Const HttpCreated201_2 = "Ресурс успешно обновлён."

Const HttpError400BadRequest = "Что за чушь ты несёшь?! Язык без костей — что хочет то и лопочет."
Const HttpError400BadPath = "Что за чушь ты запрашиваешь?! Язык без костей — что хочет, то и лопочет? Убирайся‐ка отсюда подобру‐поздорову, холоп."
Const HttpError400Host = "Холоп, при обращении к благородным господам этикет требует вежливо указывать заголовок Host."
Const HttpError403Forbidden = "У тебя нет привилегий доступа к этому файлу, простолюдин. Файлы такого типа предназначены только для благородных господ, а ты, как я вижу, простой холоп."
Const HttpError404FileNotFound = "Запрошенный тобою файл — это несуществующая, смешная и глупая фантазия. Отправляйся‐ка восвояси, холоп, и не докучай благородных господ своими вздорными просьбами."
Const HttpError410Gone = "По указанию благородных господ я удалил файл насовсем. Полностью. Он никогда не будет найден. А тебе, холоп, я приказываю удалить все ссылки на него. И больше не ходить по этому адресу."
Const HttpError411LengthRequired = "Холоп, когда ты мне отправляешь данные, то тебе следует вежливо указывать длину тела запроса."
Const HttpError413RequestEntityTooLarge = "Холоп, длина тела запроса слишком большая. Не утомляй благородных господ просьбами длиннее 4194304 байт."
Const HttpError414RequestUrlTooLarge = "Холоп, длина URL слишком большая. Больше не утомляй благородных господ досужими URL."
Const HttpError431RequestRequestHeaderFieldsTooLarge = "Холоп, длина заголовков слишком большая. Больше не утомляй благородных господ досужими заголовками."

Const HttpError500InternalServerError = "Внутренняя ошибка сервера."
Const HttpError500FileNotAvailable = "В данный момент слуги не могут получить доступ к файлу, так как его обрабатывают слуги по приказу благородных господ."
Const HttpError500CannotCreateChildProcess = "Не могу создать дочерний процесс."
Const HttpError500CannotCreatePipe = "Не могу создать трубу для чтения и записи данных дочернего процесса."
Const HttpError501MethodNotAllowed = "Благородные господы не хотят содержать крепостных, которые бы обрабатывали этот метод. Отправляйся‐ка восвояси."
Const HttpError501ContentTypeEmpty = "Холоп, ты не указал тип содержимого. Элементарная вежливость требует указывать что ты отправляешь на сервер."
Const HttpError501ContentEncoding = "Холоп, больше не отправляй сжатое содержимое. Благородные господы не хотят содержать крепостных, разжимающих твои смешные данные."
Const HttpError502BadGateway = "Удалённый сервер не отвечает."
Const HttpError503ThreadError = "Внутренняя ошибка сервера: не могу создать поток для обработки запроса."
Const HttpError503Memory = "В данный момент все крепостные заняты выполнением запросов, куча переполнена."
Const HttpError504GatewayTimeout = "Не могу соединиться с удалённым сервером"
Const HttpError505VersionNotSupported = "Холоп, ты используешь версию протокола, которую я не поддерживаю. Благородные господы поддерживают только версии HTTP/1.0 и HTTP/1.1."

Const NeedUsernamePasswordString = "Требуется логин и пароль для доступа"
Const NeedUsernamePasswordString1 = "Параметры авторизации неверны"
Const NeedUsernamePasswordString2 = "Требуется Basic‐авторизация"
Const NeedUsernamePasswordString3 = "Пароль не может быть пустым"

Const MovedPermanently = "Ресурс перекатился на другой адрес."

Const DefaultHeaderWwwAuthenticate = "Basic realm=""Need username and password"""
Const DefaultHeaderWwwAuthenticate1 = "Basic realm=""Authorization"""
Const DefaultHeaderWwwAuthenticate2 = "Basic realm=""Use Basic auth"""

Declare Sub WriteHttpResponse( _
	ByVal pState As ReadHeadersResult Ptr, _
	ByVal ClientSocket As SOCKET, _
	ByVal pWebSite As WebSite Ptr, _
	ByVal BodyText As WString Ptr _
)

Declare Function FormatErrorMessageBody( _
	ByVal Buffer As WString Ptr, _
	ByVal StatusCode As Integer, _
	ByVal VirtualPath As WString Ptr, _
	ByVal strMessage As WString Ptr _
)As LongInt

Sub WriteMovedPermanently( _
		ByVal state As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal www As WebSite Ptr _
	)
	
	state->ServerResponse.StatusCode = 301
	Dim buf As WString * (URI.MaxUrlLength * 2 + 1) = Any
	lstrcpy(@buf, www->MovedUrl)
	lstrcat(@buf, state->ClientRequest.ClientURI.Url)
	state->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderLocation) = @buf
	
	WriteHttpResponse(state, ClientSocket, www, @MovedPermanently)
End Sub

Sub WriteHttpBadRequest( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 400
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError400BadRequest)
End Sub

Sub WriteHttpPathNotValid( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 400
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError400BadPath)
End Sub

Sub WriteHttpHostNotFound( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 400
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError400Host)
End Sub

Sub WriteHttpNeedAuthenticate( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
	pState->ServerResponse.StatusCode = 401
	WriteHttpResponse(pState, ClientSocket, pWebSite, @NeedUsernamePasswordString)
End Sub

Sub WriteHttpBadAuthenticateParam( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate1
	pState->ServerResponse.StatusCode = 401
	WriteHttpResponse(pState, ClientSocket, pWebSite, @NeedUsernamePasswordString1)
End Sub

Sub WriteHttpNeedBasicAuthenticate( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate2
	pState->ServerResponse.StatusCode = 401
	WriteHttpResponse(pState, ClientSocket, pWebSite, @NeedUsernamePasswordString2)
End Sub

Sub WriteHttpEmptyPassword( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
	pState->ServerResponse.StatusCode = 401
	WriteHttpResponse(pState, ClientSocket, pWebSite, @NeedUsernamePasswordString3)
End Sub

Sub WriteHttpBadUserNamePassword( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderWwwAuthenticate) = @DefaultHeaderWwwAuthenticate
	pState->ServerResponse.StatusCode = 401
	WriteHttpResponse(pState, ClientSocket, pWebSite, @NeedUsernamePasswordString)
End Sub

Sub WriteHttpForbidden( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 403
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError403Forbidden)
End Sub

Sub WriteHttpFileNotFound( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 404
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError404FileNotFound)
End Sub

Sub WriteHttpFileGone( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 410
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError410Gone)
End Sub

Sub WriteHttpLengthRequired( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 411
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError411LengthRequired)
End Sub

Sub WriteHttpRequestEntityTooLarge( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 413
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError413RequestEntityTooLarge)
End Sub

Sub WriteHttpRequestUrlTooLarge( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 414
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError414RequestUrlTooLarge)
End Sub

Sub WriteHttpRequestHeaderFieldsTooLarge( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 431
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError431RequestRequestHeaderFieldsTooLarge)
End Sub

Sub WriteHttpInternalServerError( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 500
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError500InternalServerError)
End Sub

Sub WriteHttpFileNotAvailable( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 500
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError500FileNotAvailable)
End Sub

Sub WriteHttpCannotCreateChildProcess( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 500
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError500CannotCreateChildProcess)
End Sub

Sub WriteHttpCannotCreatePipe( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 500
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError500CannotCreatePipe)
End Sub

Sub WriteHttpMethodNotAllowed( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 501
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderAllow) = @AllSupportHttpMethods
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError501MethodNotAllowed)
End Sub

Sub WriteHttpContentTypeEmpty( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 501
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError501ContentTypeEmpty)
End Sub

Sub WriteHttpContentEncodingNotEmpty( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 501
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError501ContentEncoding)
End Sub

Sub WriteHttpBadGateway( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 502
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError502BadGateway)
End Sub

Sub WriteHttpNotEnoughMemory( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 503
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderRetryAfter) = @"Retry-After: 300"
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError503Memory)
End Sub

Sub WriteHttpCannotCreateThread( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 503
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderRetryAfter) = @"Retry-After: 300"
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError503ThreadError)
End Sub

Sub WriteHttpGatewayTimeout( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 504
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError504GatewayTimeout)
End Sub

Sub WriteHttpVersionNotSupported( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	pState->ServerResponse.StatusCode = 505
	WriteHttpResponse(pState, ClientSocket, pWebSite, @HttpError505VersionNotSupported)
End Sub

Sub WriteHttpCreated( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr _
	)
	
	Dim strMessage As WString Ptr = Any
	If pState->ServerResponse.StatusCode = 201 Then
		strMessage = @HttpCreated201_1
	Else
		strMessage = @HttpCreated201_2
	End If
	WriteHttpResponse(pState, ClientSocket, pWebSite, strMessage)
End Sub

Sub WriteHttpResponse( _
		ByVal pState As ReadHeadersResult Ptr, _
		ByVal ClientSocket As SOCKET, _
		ByVal pWebSite As WebSite Ptr, _
		ByVal BodyText As WString Ptr _
	)
	pState->ClientRequest.KeepAlive = False
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentType) = @HttpErrorContentType
	pState->ServerResponse.ResponseHeaders(HttpResponseHeaders.HeaderContentLanguage) = @DefaultContentLanguage
	
	Dim Body As WString * (MaxHttpErrorBuffer + 1) = Any
	Dim BodyLength As LongInt = Any
	Scope
		Dim VirtualPath As WString Ptr = Any
		If pWebSite = 0 Then
			VirtualPath = @SlashString
		Else
			VirtualPath = @pWebSite->VirtualPath
		End If
		BodyLength = FormatErrorMessageBody(@Body, pState->ServerResponse.StatusCode, VirtualPath, BodyText)
	End Scope
	
	Dim ContentBody As ZString * (WebResponse.MaxResponseHeaderBuffer + 1) = Any
	Dim ContentBodyLength As Integer = WideCharToMultiByte(CP_UTF8, 0, @Body, -1, @ContentBody, WebResponse.MaxResponseHeaderBuffer + 1, 0, 0) - 1
	
	Dim SendBuffer As ZString * (WebResponse.MaxResponseHeaderBuffer * 2 + 1) = Any
	Dim SendBufferLength As Integer = pState->AllResponseHeadersToBytes(@SendBuffer, ContentBodyLength)
	
	RtlCopyMemory(@SendBuffer + SendBufferLength, @ContentBody, ContentBodyLength)
	SendBufferLength += ContentBodyLength
	
	send(ClientSocket, @SendBuffer, SendBufferLength, 0)
	
End Sub

Function FormatErrorMessageBody( _
		ByVal Buffer As WString Ptr, _
		ByVal StatusCode As Integer, _
		ByVal VirtualPath As WString Ptr, _
		ByVal BodyText As WString Ptr _
	)As LongInt
	
	Dim strStatusCode As WString * 8 = Any
	itow(StatusCode, @strStatusCode, 10) ' Число в строку
	
	Dim DescriptionBuffer As WString Ptr = GetStatusDescription(StatusCode, 0)
	
	lstrcpy(Buffer, HttpErrorHead1)
	lstrcat(Buffer, DescriptionBuffer) ' тег <title>
	lstrcat(Buffer, HttpErrorHead2)
	
	lstrcat(Buffer, HttpErrorBody1)
	
	' Заголовок <h1>
	Select Case StatusCode
		Case 200 To 299
			lstrcat(Buffer, @ClientCreatedString)
			
		Case 300 To 399
			lstrcat(Buffer, @ClientMovedString)
			
		Case 400 To 499
			lstrcat(Buffer, @ClientErrorString)
			
		Case 500 To 599
			lstrcat(Buffer, @ServerErrorString)
			
	End Select
	
	lstrcat(Buffer, HttpErrorBody2)
	' Имя приложения в заголовке <h1>
	lstrcat(Buffer, VirtualPath)
	lstrcat(Buffer, HttpErrorBody3)
	' Код статуса в заголовке <h2>
	lstrcat(Buffer, @strStatusCode)
	lstrcat(Buffer, HttpErrorBody4)
	' Описание ошибки в заголовке <h2>
	lstrcat(Buffer, DescriptionBuffer)
	lstrcat(Buffer, HttpErrorBody5)
	' Текст сообщения между <p></p>
	lstrcat(Buffer, BodyText)
	lstrcat(Buffer, HttpErrorBody6)
	
	Return lstrlen(Buffer)
End Function
