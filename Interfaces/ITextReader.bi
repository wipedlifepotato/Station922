#ifndef ITEXTREADER_BI
#define ITEXTREADER_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type LPITEXTREADER As ITextReader Ptr

Type ITextReader As ITextReader_

Extern IID_ITextReader Alias "IID_ITextReader" As Const IID

Type ITextReaderVirtualTable
	Dim InheritedTable As IUnknownVtbl
	
	Dim Peek As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal pChar As wchar_t Ptr _
	)As HRESULT
	
	Dim ReadChar As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal pChar As wchar_t Ptr _
	)As HRESULT
	
	Dim ReadCharArray As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal Index As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedChars As Integer Ptr _
	)As HRESULT
	
	Dim ReadLine As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pLineLength As Integer Ptr _
	)As HRESULT
	
	Dim ReadToEnd As Function( _
		ByVal this As ITextReader Ptr, _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pLineLength As Integer Ptr _
	)As HRESULT
	
End Type

Type ITextReader_
	Dim pVirtualTable As ITextReaderVirtualTable Ptr
End Type

#define ITextReader_QueryInterface(this, riid, ppv) (this)->pVirtualTable->InheritedTable.QueryInterface(CPtr(IUnknown Ptr, this), riid, ppv)
#define ITextReader_AddRef(this) (this)->pVirtualTable->InheritedTable.AddRef(CPtr(IUnknown Ptr, this))
#define ITextReader_Release(this) (this)->pVirtualTable->InheritedTable.Release(CPtr(IUnknown Ptr, this))
#define ITextReader_Peek(this, pChar) (this)->pVirtualTable->Peek(this, pChar)
#define ITextReader_ReadChar(this, pChar) (this)->pVirtualTable->ReadChar(this, pChar)
#define ITextReader_ReadCharArray(this, Buffer, Index, Count, pReadedChars) (this)->pVirtualTable->ReadCharArray(this, Buffer, Index, Count, pReadedChars)
#define ITextReader_ReadLine(this, Buffer, BufferLength, pLineLength) (this)->pVirtualTable->ReadLine(this, Buffer, BufferLength, pLineLength)
#define ITextReader_ReadToEnd(this, Buffer, BufferLength, pLineLength) (this)->pVirtualTable->ReadToEnd(this, Buffer, BufferLength, pLineLength)

#endif
