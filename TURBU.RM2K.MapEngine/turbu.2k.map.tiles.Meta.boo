namespace turbu.RM2K.map.tiles

import Pythia.Runtime
import sdl.sprite
import tiles
import turbu.maps

[Metaclass(TMapTile)]
class TMapTileClass(TTileClass):
	virtual def Create(AParent as SpriteEngine, tileset as string) as TMapTile:
		return TMapTile(AParent, tileset)

[Metaclass(TAnimTile)]
class TAnimTileClass(TMapTileClass):
	override def Create(AParent as SpriteEngine, tileset as string) as TMapTile:
		return TAnimTile(AParent, tileset)

[Metaclass(TMiniTile)]
class TMiniTileClass(TSpriteClass):
	pass

[Metaclass(TBorderTile)]
class TBorderTileClass(TMapTileClass):
	override def Create(AParent as SpriteEngine, tileset as string) as TMapTile:
		return TBorderTile(AParent, tileset)

[Metaclass(TWaterTile)]
class TWaterTileClass(TBorderTileClass):
	pass

[Metaclass(TShoreTile)]
class TShoreTileClass(TWaterTileClass):
	override def Create(AParent as SpriteEngine, tileset as string) as TMapTile:
		return TShoreTile(AParent, tileset)

[Metaclass(TOceanTile)]
class TOceanTileClass(TWaterTileClass):
	override def Create(AParent as SpriteEngine, tileset as string) as TMapTile:
		return TOceanTile(AParent, tileset)


[Metaclass(TTile)]
class TTileClass(TParentSpriteClass):
	pass

[Metaclass(EventTile)]
class TEventTileClass(TTileClass):
	pass

[Metaclass(TScrollData)]
class TScrollDataClass(TClass):

	virtual def Create(input as TRpgMap) as tiles.TScrollData:
		return tiles.TScrollData(input)

	virtual def Create(x as int, y as int, autoX as TMapScrollType, autoY as TMapScrollType) as tiles.TScrollData:
		return tiles.TScrollData(x, y, autoX, autoY)

[Metaclass(TBackgroundSprite)]
class TBackgroundSpriteClass(TSpriteClass):
	pass

