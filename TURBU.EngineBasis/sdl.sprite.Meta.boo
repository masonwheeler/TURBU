namespace sdl.sprite

import Pythia.Runtime
import sdl.canvas
import SDL2.SDL2_GPU
import SG.defs

[Metaclass(TSprite)]
class TSpriteClass(TClass):

	virtual def Create(AParent as TParentSprite) as sdl.sprite.TSprite:
		return sdl.sprite.TSprite(AParent)

[Metaclass(TParentSprite)]
class TParentSpriteClass(TSpriteClass):

	override def Create(AParent as TParentSprite):
		return sdl.sprite.TParentSprite(AParent)

[Metaclass(TAnimatedSprite)]
class TAnimatedSpriteClass(TParentSpriteClass):

	override def Create(AParent as TParentSprite):
		return sdl.sprite.TAnimatedSprite(AParent)

[Metaclass(TAnimatedRectSprite)]
class TAnimatedRectSpriteClass(TParentSpriteClass):

	virtual def Create(parent as TParentSprite, region as GPU_Rect, displacement as TSgPoint, length as int) as sdl.sprite.TAnimatedRectSprite:
		return sdl.sprite.TAnimatedRectSprite(parent, region, displacement, length)

[Metaclass(TTiledAreaSprite)]
class TTiledAreaSpriteClass(TAnimatedRectSpriteClass):

	override def Create(parent as TParentSprite, region as GPU_Rect, displacement as TSgPoint, length as int) as sdl.sprite.TAnimatedRectSprite:
		return sdl.sprite.TTiledAreaSprite(parent, region, displacement, length)

[Metaclass(TParticleSprite)]
class TParticleSpriteClass(TAnimatedSpriteClass):

	override def Create(AParent as TParentSprite):
		return sdl.sprite.TParticleSprite(AParent)

[Metaclass(TSpriteEngine)]
class TSpriteEngineClass(TParentSpriteClass):

	virtual def Create(AParent as TSpriteEngine, ACanvas as TSdlCanvas) as sdl.sprite.TSpriteEngine:
		return sdl.sprite.TSpriteEngine(AParent, ACanvas)

