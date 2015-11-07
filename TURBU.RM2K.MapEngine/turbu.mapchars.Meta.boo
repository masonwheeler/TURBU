namespace turbu.mapchars

import Pythia.Runtime
import turbu.map.metadata
import turbu.map.sprites

[Metaclass(TRpgCharacter)]
class TRpgCharacterClass(TClass):
	pass

[Metaclass(TRpgEvent)]
class TRpgEventClass(TRpgCharacterClass):

	virtual def create(base as TMapSprite) as turbu.mapchars.TRpgEvent:
		return turbu.mapchars.TRpgEvent(base)

[Metaclass(TRpgVehicle)]
class TRpgVehicleClass(TRpgCharacterClass):

	virtual def Create(mapTree as TMapTree, which as int) as turbu.mapchars.TRpgVehicle:
		return turbu.mapchars.TRpgVehicle(mapTree, which)

