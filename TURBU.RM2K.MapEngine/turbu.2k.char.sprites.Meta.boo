namespace turbu.RM2K.CharSprites

import System
import Pythia.Runtime
import turbu.Heroes
import turbu.RM2K.map.tiles
import turbu.map.sprites
import turbu.mapchars
import sdl.sprite

[Metaclass(TVehicleTile)]
class TVehicleTileClass(TEventTileClass):
	pass

[Metaclass(TVehicleSprite)]
class TVehicleSpriteClass(TCharSpriteClass):

	virtual def Create(parent as TSpriteEngine, whichVehicle as TRpgVehicle, cleanup as Action) as turbu.RM2K.CharSprites.TVehicleSprite:
		return turbu.RM2K.CharSprites.TVehicleSprite(parent, whichVehicle, cleanup)

[Metaclass(THeroSprite)]
class THeroSpriteClass(TCharSpriteClass):

	virtual def create(AParent as TSpriteEngine, whichHero as TRpgHero, party as TRpgParty) as turbu.RM2K.CharSprites.THeroSprite:
		return turbu.RM2K.CharSprites.THeroSprite(AParent, whichHero, party)

