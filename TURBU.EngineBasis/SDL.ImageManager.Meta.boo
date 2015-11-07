namespace SDL.ImageManager

import Pythia.Runtime

[Metaclass]
class ESdlImageExceptionClass(ExceptionClass):
	pass

[Metaclass]
class TSdlImageClass(TClass):

	virtual def Create(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, filename, imagename, container)

	virtual def Create(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, surface, imagename, container)

	virtual def Create(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, rw, extension, imagename, container)

	virtual def CreateSprite(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, filename, imagename, container, spriteSize)

	virtual def CreateSprite(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, rw, extension, imagename, container, spriteSize)

	virtual def CreateSprite(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, surface, imagename, container, spriteSize)

	virtual def CreateBlankSprite(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int) as SDL.ImageManager.TSdlImage:
		return SDL.ImageManager.TSdlImage(renderer, imagename, container, spriteSize, count)

[Metaclass]
class TSdlOpaqueImageClass(TSdlImageClass):

	override def Create(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, filename, imagename, container)

	override def Create(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, surface, imagename, container)

	override def Create(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, rw, extension, imagename, container)

	override def Create(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, filename, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, rw, extension, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, surface, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		return SDL.ImageManager.TSdlOpaqueImage(renderer, imagename, container, spriteSize, count)

[Metaclass]
class TSdlImagesClass(TClass):

	virtual def Create(renderer as IntPtr, FreeOnClear as bool, loader as TArchiveLoader, callback as TArchiveCallback) as SDL.ImageManager.TSdlImages:
		return SDL.ImageManager.TSdlImages(renderer, FreeOnClear, loader, callback)

[Metaclass]
class TSdlBackgroundImageClass(TSdlImageClass):

	override def Create(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, filename, imagename, container)

	override def Create(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, surface, imagename, container)

	override def Create(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, rw, extension, imagename, container)

	override def Create(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, filename, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, rw, extension, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, surface, imagename, container, spriteSize)

	override def Create(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		return SDL.ImageManager.TSdlBackgroundImage(renderer, imagename, container, spriteSize, count)

