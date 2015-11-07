namespace SDL.rwStream

import Boo.Adt
import Pythia.Runtime
import System
import SDL2.SDL
import System.IO

class TRWStream(Stream):

	[Getter(Ops)]
	private FOps as IntPtr

	[Property(OwnsRWOps)]
	private FOwnsOps as bool

	public def constructor(ops as IntPtr, owns as bool):
		super()
		if not assigned(ops):
			raise EStreamError.Create('No SDL_RWops available for TRWStream creation!')
		FOps = ops
		FOwnsOps = owns

	def destructor():
		if FOwnsOps:
			FOps.close(FOps)
			SDL_FreeRW(FOps)
		else:
			self.Seek(0, soFromBeginning)

	public override def Read(ref Buffer, Count as int) as int:
		return FOps.read(FOps, __addressof__(Buffer), 1, count)

	public override def Write(Buffer, Count as int) as int:
		return FOps.write(FOps, __addressof__(buffer), 1, count)

	public override def Seek(Offset as int, Origin as ushort) as int:
		return FOps.seek(FOps, offset, origin)

