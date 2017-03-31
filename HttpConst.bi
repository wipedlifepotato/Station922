#ifndef unicode
	#define unicode
#endif

' Внимание! Этот .bi файл полон тонкой иронии и искромётного юмора.

Const HttpError400BadRequest = "Что за чушь ты несёшь?! Язык без костей — что хочет то и лопочет."
Const HttpError400BadPath = "Что за чушь ты запрашиваешь?! Язык без костей — что хочет, то и лопочет? Убирайся‐ка отсюда подобру‐поздорову, холоп."
Const HttpError400Host = "Холоп, при обращении к благородным господам этикет требует вежливо указывать заголовок Host."
Const HttpError403File = "У тебя нет привилегий доступа к этому файлу, простолюдин. Файлы такого типа предназначены только для благородных господ, а ты, как я вижу, простой холоп."
Const HttpError404FileNotFound1 = "Запрошенный тобою файл "
Const HttpError404FileNotFound2 = " — это несуществующая, смешная и глупая фантазия. Отправляйся‐ка восвояси, холоп, и не докучай благородных господ своими вздорными просьбами."
Const HttpError410Gone1 = "По указанию благородных господ я удалил файл "
Const HttpError410Gone2 = " насовсем. Полностью. Он никогда не будет найден. А тебе, холоп, я приказываю удалить все ссылки на него. И больше не ходить по этому адресу."
Const HttpError411LengthRequired = "Холоп, когда ты мне отправляешь данные, то тебе следует вежливо указывать длину тела запроса."
Const HttpError413RequestEntityTooLarge = "Холоп, длина тела запроса слишком большая. Не утомляй благородных господ просьбами длиннее 4194304 байт."
Const HttpError414RequestUrlTooLarge = "Холоп, длина URL слишком большая. Больше не утомляй благородных господ досужими URL."
Const HttpError431RequestRequestHeaderFieldsTooLarge = "Холоп, длина заголовков слишком большая. Больше не утомляй благородных господ досужими заголовками."
Const HttpError500ThreadError = "Внутренняя ошибка сервера: не могу создать поток для обработки запроса."
Const HttpError500NotAvailable = "В данный момент слуги не могут получить доступ к файлу, так как его обрабатывают слуги по приказу благородных господ."
Const HttpError501MethodNotAllowed = "Благородные господы не хотят содержать крепостных, которые бы обрабатывали этот метод. Отправляйся‐ка восвояси."
Const HttpError501ContentTypeEmpty = "Холоп, ты не указал тип содержимого. Элементарная вежливость требует указывать что ты отправляешь на сервер."
Const HttpError501ContentEncoding = "Холоп, больше не отправляй сжатое содержимое. Благородные господы не хотят содержать крепостных, разжимающих твои смешные данные."
Const HttpError502BadGateway = "Удалённый сервер не отвечает"
Const HttpError503Memory = "В данный момент все крепостные заняты выполнением запросов, куча переполнена."
Const HttpError504GatewayTimeout = "Не могу соединиться с удалённым сервером"
Const HttpError505VersionNotSupported = "Холоп, ты используешь версию протокола, которую я не поддерживаю. Благородные господы поддерживают только версии HTTP/1.0 и HTTP/1.1."

Const NeedUsernamePasswordString = "Требуется логин и пароль для доступа"
Const NeedUsernamePasswordString1 = "Параметры авторизации неверны"
Const NeedUsernamePasswordString2 = "Требуется Basic‐авторизация"
Const NeedUsernamePasswordString3 = "Пароль не может быть пустым"

Const MovedPermanently1 = "Ресурс перекатился на адрес <a href="""
Const MovedPermanently2 = """>"
Const MovedPermanently3 = "</a>. Тебе нужно идти туда."

Const HttpCreated201_1 = "Ресурс успешно создан."
Const HttpCreated201_2 = "Ресурс успешно обновлён."

Const HttpErrorHead1 = "<!DOCTYPE html><html xmlns=""http://www.w3.org/1999/xhtml""><head><meta name=""viewport"" content=""width=device-width, initial-scale=1"" /><title>"
Const HttpErrorHead2 = "</title></head>"
Const HttpErrorBody1 = "<body><h1>"
Const ServerErrorString = "Серверная"
Const ClientErrorString = "Клиентская"
Const HttpErrorBody2 = " ошибка в приложении «"
Const HttpErrorBody3 = "»</h1><h2>Ошибка HTTP "
Const HttpErrorBody4 = " — "
Const HttpErrorBody5 = "</h2><p>"
Const HttpErrorBody6 = "</p><p>Посетить <a href=""/"">главную страницу</a> сайта.</p></body></html>"

Const HttpVersion10 = "HTTP/1.0"
Const HttpVersion10Length As Integer = 8
Const HttpVersion11 = "HTTP/1.1"
Const HttpVersion11Length As Integer = 8

Const HttpErrorContentType = "text/html; charset=utf-16"
Const DefaultContentLanguage = "ru, ru-RU"
Const SecondsInOneMonths As LongInt = 2678400
Const DefaultCacheControl = "max-age=2678400"
Const DefaultHeaderWwwAuthenticate = "Basic realm=""Need username and password"""
Const DefaultHeaderWwwAuthenticate1 = "Basic realm=""Authorization"""
Const DefaultHeaderWwwAuthenticate2 = "Basic realm=""Use Basic auth"""

Const HttpServerNameString = "FreeBASIC/Web"
Const BytesString = "bytes"
Const CloseString = "Close"
Const DeflateString = "deflate"
Const GzipString = "gzip"
Const GzipExtensionString = ".gz"
Const DeflateExtensionString = ".deflate"
Const HeadersExtensionString = ".headers"
Const FileGoneExtension = ".410"
Const QuoteString = """"
Const ContentCharsetUtf8 = "; charset=utf-8"
Const ContentCharsetUtf16 = "; charset=utf-16"
Const ContentCharset8bit = "; charset=8bit"
Const BasicAuthorization = "Basic"
