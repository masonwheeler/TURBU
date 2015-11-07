namespace sdl.canvas

import Pythia.Runtime

[Metaclass]
class TSdlRenderSurfaceClass(TClass):
	pass

[Metaclass]
class TSdlRenderTargetClass(TSdlRenderSurfaceClass):

	virtual def Create(size as TSgPoint) as sdl.canvas.TSdlRenderTarget:
		return sdl.canvas.TSdlRenderTarget(size)

[Metaclass]
class TSdlCanvasClass(TSdlRenderSurfaceClass):

	virtual def Create(title as string, size as Rectangle, flags as SDL_WindowFlags) as sdl.canvas.TSdlCanvas:
		return sdl.canvas.TSdlCanvas(title, size, flags)

	virtual def CreateFrom(value as IntPtr) as sdl.canvas.TSdlCanvas:
		return sdl.canvas.TSdlCanvas(value)

[Metaclass]
class ECanvasClass(ExceptionClass):
	pass

