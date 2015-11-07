namespace TURBU.MapEngine

import Pythia.Runtime
import TURBU.PluginInterface
import turbu.versioning

[Metaclass(TMapEngineData)]
class TMapEngineDataClass(TRpgMetadataClass):

	override def Create(name as string, version as TVersion):
		return TURBU.MapEngine.TMapEngineData(name, version)

[Metaclass(TMapEngine)]
class TMapEngineClass(TPlugClass):
	pass
