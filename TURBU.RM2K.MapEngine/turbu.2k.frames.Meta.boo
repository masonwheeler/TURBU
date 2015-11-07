namespace TURBU.RM2K.Menus

import Pythia.Runtime
import sdl.sprite
import SDL.ImageManager
import SDL2.SDL2_GPU

[Metaclass(TSystemTile)]
class TSystemTileClass(TTiledAreaSpriteClass):
	pass

[Metaclass(TSystemImages)]
class TSystemImagesClass(TClass):

	virtual def Create(images as TSdlImages, filename as string, stretch as bool, translucent as bool) as TURBU.RM2K.Menus.TSystemImages:
		return TURBU.RM2K.Menus.TSystemImages(images, filename, stretch, translucent)

[Metaclass(TSysFrame)]
class TSysFrameClass(TSystemTileClass):
	pass

[Metaclass(TMenuCursor)]
class TMenuCursorClass(TSysFrameClass):
	pass

[Metaclass(TCustomMessageBox)]
class TCustomMessageBoxClass(TSysFrameClass):
	abstract def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		pass

[Metaclass(TSystemTimer)]
class TSystemTimerClass(TParentSpriteClass):
	pass

