namespace turbu.sdl.image

import Pythia.Runtime
import System
import SG.defs
import SDL.ImageManager
import SDL2.SDL
import SDL2.SDL2_GPU

[Disposable(Destroy)]
class TRpgSdlImage(TSdlImage):

	[Getter(surface)]
	private FOrigSurface as IntPtr

	protected override def ProcessImage(image as IntPtr):
		FOrigSurface = image
		SDL_AcquireSurface(FOrigSurface)

	public def constructor(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(filename, imagename, container, spriteSize)

	private new def Destroy():
		SDL_FreeSurface(FOrigSurface)

	public Texture as GPU_Image_PTR:
		get: return FSurface
