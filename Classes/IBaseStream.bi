#ifndef IBASESTREAM_BI
#define IBASESTREAM_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\objbase.bi"

Enum SeekOrigin
	SeekBegin
	SeekCurrent
	SeekEnd
End Enum

Type IBaseStream As IBaseStream_

Type IBaseStreamVirtualTable
	Dim VirtualTable As IUnknownVtbl
	
	Dim CanRead As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	Dim CanSeek As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	Dim CanWrite As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal pResult As Boolean Ptr _
	)As HRESULT
	
	Dim CloseStream As Function( _
		ByVal this As IBaseStream Ptr _
	)As HRESULT
	
	Dim Flush As Function( _
		ByVal this As IBaseStream Ptr _
	)As HRESULT
	
	Dim GetLength As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	Dim OpenStream As Function( _
		ByVal this As IBaseStream Ptr _
	)As HRESULT
	
	Dim Position As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal pResult As LongInt Ptr _
	)As HRESULT
	
	Dim Read As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pReadedBytes As Integer Ptr _
	)As HRESULT
	
	Dim Seek As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal offset As LongInt, _
		ByVal origin As SeekOrigin _
	)As HRESULT
	
	Dim SetLength As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal length As LongInt _
	)As HRESULT
	
	Dim Write As Function( _
		ByVal this As IBaseStream Ptr, _
		ByVal buffer As UByte Ptr, _
		ByVal offset As Integer, _
		ByVal Count As Integer, _
		ByVal pWritedBytes As Integer Ptr _
	)As HRESULT
	
End Type

Type IBaseStream_
	Dim pVirtualTable As IBaseStreamVirtualTable Ptr
End Type

#endif
