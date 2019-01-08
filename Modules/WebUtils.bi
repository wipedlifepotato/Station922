#ifndef WEBUTILS_BI
#define WEBUTILS_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "WebRequest.bi"
#include "WebResponse.bi"
#include "Mime.bi"
#include "ITextWriter.bi"
#include "WebSite.bi"

Const NewLineString = !"\r\n"

' Заполняет буфер экранированной строкой, безопасной для html
' Принимающий буфер должен быть в 6 раз длиннее строки
Declare Function GetHtmlSafeString( _
	ByVal Buffer As WString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal HtmlSafe As WString Ptr, _
	ByVal pHtmlSafeLength As Integer Ptr _
)As Boolean

' Определяет кодировку документа (массива байт)
Declare Function GetDocumentCharset( _
	ByVal b As ZString Ptr _
)As DocumentCharsets

' Ищет символы CrLf в буфере
Declare Function FindCrLfA( _
	ByVal Buffer As ZString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal Start As Integer, _
	ByVal pFindedIndex As Integer Ptr _
)As Boolean

' Ищет символы CrLf в юникодном буфере
Declare Function FindCrLfW( _
	ByVal Buffer As WString Ptr, _
	ByVal BufferLength As Integer, _
	ByVal Start As Integer, _
	ByVal pFindedIndex As Integer Ptr _
)As Boolean

' Заполняет буфер датой и временем в http формате
Declare Sub GetHttpDate Overload( _
	ByVal Buffer As WString Ptr _
)

Declare Sub GetHttpDate Overload( _
	ByVal Buffer As WString Ptr, _
	ByVal dt As SYSTEMTIME Ptr _
)

' Проверка аутентификации
Declare Function HttpAuthUtil( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal pStream As IBaseStream Ptr, _
	ByVal www As SimpleWebSite Ptr, _
	ByVal ProxyAuthorization As Boolean _
)As Boolean

Declare Sub GetETag( _
	ByVal wETag As WString Ptr, _
	ByVal pDateLastFileModified As FILETIME Ptr, _
	ByVal ResponseZipMode As ZipModes _
)

Declare Sub MakeContentRangeHeader( _
	ByVal pIWriter As ITextWriter Ptr, _
	ByVal FirstBytePosition As ULongInt, _
	ByVal LastBytePosition As ULongInt, _
	ByVal TotalLength As ULongInt _
)

Declare Function Minimum( _
	ByVal a As ULongInt, _
	ByVal b As ULongInt _
)As ULongInt

Declare Function AllResponseHeadersToBytes( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal zBuffer As ZString Ptr, _
	ByVal ContentLength As ULongInt _
)As Integer

Declare Function SetResponseCompression( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal PathTranslated As WString Ptr, _
	ByVal pAcceptEncoding As Boolean Ptr _
)As Handle

Declare Sub AddResponseCacheHeaders( _
	ByVal pRequest As WebRequest Ptr, _
	ByVal pResponse As WebResponse Ptr, _
	ByVal hFile As HANDLE _
)

#endif
