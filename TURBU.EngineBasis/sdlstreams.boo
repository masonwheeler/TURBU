namespace sdlstreams

import System
import System.IO
import System.Runtime.InteropServices
import SDL2.SDL
import TURBU.Meta

def SDLStreamSetup(stream as Stream) as IntPtr:
	result = SDL_AllocRW()
	if result == IntPtr.Zero:
		raise InvalidDataException('could not create SDLStream on null')
	rw as SDL_RWOps = Marshal.PtrToStructure(result, SDL_RWOps)
	
	rw.seek = do (rw as IntPtr, offset as Int64, whence as int) as Int64:
		origin as SeekOrigin
		caseOf whence:
			case 0: origin = SeekOrigin.Begin
			case 1: origin = SeekOrigin.Current
			case 2: origin = SeekOrigin.End
			default: origin = SeekOrigin.Begin
		return stream.Seek(offset, origin)
	
	rw.read = do (rw as IntPtr, Ptr as IntPtr, size as int, maxnum as int) as int:
		buffer = array(byte, size * maxnum)
		var count = stream.Read(buffer, 0, size * maxnum)
		Marshal.Copy(buffer, 0, Ptr, count)
		return count / size

	rw.write = do (rw as IntPtr, Ptr as IntPtr, size as int, num as int) as int:
		buffer = array(byte, size * num)
		Marshal.Copy(Ptr, buffer, 0, buffer.Length)
		stream.Write(buffer, 0, size * num)
		return num
		
	rw.close = do(rw as IntPtr) as int:
		stream.Dispose()
		return 1
		
	rw.type = 2 // TUnknown
	Marshal.StructureToPtr(rw, result, false)
	return result
