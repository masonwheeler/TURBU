namespace turbu.map.sprites

import Pythia.Runtime
import TURBU.MapObjects
import sdl.sprite
import turbu.map.sprites

[Metaclass(TMapSprite)]
class TMapSpriteClass(TClass):

	abstract def Create(base as TRpgMapObject, parent as SpriteEngine) as turbu.map.sprites.TMapSprite:
		pass

[Metaclass(TEventSprite)]
class TEventSpriteClass(TMapSpriteClass):

	override def Create(base as TRpgMapObject, parent as SpriteEngine) as turbu.map.sprites.TMapSprite:
		return turbu.map.sprites.TEventSprite(base, parent)

[Metaclass(TCharSprite)]
class TCharSpriteClass(TMapSpriteClass):

	override def Create(base as TRpgMapObject, parent as SpriteEngine) as turbu.map.sprites.TMapSprite:
		return turbu.map.sprites.TCharSprite(base, parent)

