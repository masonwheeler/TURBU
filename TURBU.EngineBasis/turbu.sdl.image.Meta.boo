namespace turbu.sdl.image

import System
import Pythia.Runtime
import SDL.ImageManager
import SG.defs

[Metaclass(TRpgSdlImage)]
class TRpgSdlImageClass(TSdlImageClass):

	override def CreateSprite(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return turbu.sdl.image.TRpgSdlImage(filename, imagename, container, spriteSize)
