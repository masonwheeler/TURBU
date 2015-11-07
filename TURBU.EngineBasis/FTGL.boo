namespace FTGL

import System
import System.Runtime.InteropServices
import Boo.Adt

let LIBFTGL = 'ftgl.dll'

[DllImport(LIBFTGL, CallingConvention: CallingConvention.Cdecl)]
def ftglGetFontFaceSize(f as IntPtr) as uint:
	pass

[DllImport(LIBFTGL, CallingConvention: CallingConvention.Cdecl)]
def ftglCreateTextureFont([MarshalAs(UnmanagedType.CustomMarshaler, MarshalTypeRef: SDL2.LPUtf8StrMarshaler)] name as string) as IntPtr:
	pass

[DllImport(LIBFTGL, CallingConvention: CallingConvention.Cdecl)]
def ftglRenderFont(f as IntPtr,
	[MarshalAs(UnmanagedType.CustomMarshaler, MarshalTypeRef: SDL2.LPUtf8StrMarshaler)] text as string,
	mode as int):
	pass

def ftglRenderFont(f as IntPtr, text as string):
	ftglRenderFont(f, text, 1)

[DllImport(LIBFTGL, CallingConvention: CallingConvention.Cdecl)]
def ftglSetFontFaceSize(f as IntPtr, size as uint, res as uint) [MarshalAs(UnmanagedType.I4)] as bool:
	pass

[DllImport(LIBFTGL, CallingConvention: CallingConvention.Cdecl)]
def ftglDestroyFont(F as IntPtr):
	pass