#ifndef ITEXTREADER_BI
#define ITEXTREADER_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\objbase.bi"

' {D46D4E27-B2CD-4594-96EA-5B8203D21439}
Dim Shared IID_ITEXTREADER = Type(&hd46d4e27, &hb2cd, &h4594, _
	{&h96, &hea, &h5b, &h82, &h3, &hd2, &h14, &h39})

Type LPITEXTREADER As ITextReader Ptr

Type ITextReader As ITextReader_

Type ITextReaderVirtualTable
	Dim VirtualTable As IUnknownVtbl
	
	Dim CloseTextReader As Function( _
		ByVal this As ITextReader Ptr _
	)As HRESULT
	
	Dim OpenTextReader As Function( _
		ByVal this As ITextReader Ptr _
	)As HRESULT
	
	Dim Peek As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal pChar As Integer Ptr _
	)As HRESULT
	
	Dim ReadChar As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal pChar As Integer Ptr _
	)As HRESULT
	
	Dim ReadCharArray As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal buffer As WString Ptr, _
		ByVal index As Integer, _
		ByVal Count As Integer, _
		ByVal ReadedChars As Integer Ptr _
	)As HRESULT
	
	Dim ReadLine As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal wLine As WString Ptr, _
		ByVal wLineLength As Integer, _
		ByVal ReadedChars As Integer Ptr _
	)As HRESULT
	
	Dim ReadToEnd As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal wLine As WString Ptr, _
		ByVal wLineLength As Integer, _
		ByVal ReadedChars As Integer Ptr _
	)As HRESULT
	
End Type

Type ITextReader_
	Dim pVirtualTable As ITextReaderVirtualTable Ptr
End Type

#endif
