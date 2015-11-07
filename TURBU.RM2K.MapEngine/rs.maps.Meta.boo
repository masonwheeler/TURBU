namespace TURBU.RM2K.RPGScript

import Pythia.Runtime
import turbu.mapchars

[Metaclass(TCharacterTarget)]
class TCharacterTargetClass(TClass):

	virtual def Create(target as TRpgCharacter) as TCharacterTarget:
		return TCharacterTarget(target)

