namespace TURBU.PluginInterface

import Pythia.Runtime
import turbu.versioning

[Metaclass(TRpgPlugBase)]
class TPlugClass(TClass):

	virtual def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TURBU.PluginInterface.TRpgPlugBase()

[Metaclass(TRpgMetadata)]
class TRpgMetadataClass(TClass):

	virtual def Create(name as string, version as TVersion) as TURBU.PluginInterface.TRpgMetadata:
		return TURBU.PluginInterface.TRpgMetadata(name, version)

[Metaclass(TEngineData)]
class TEngineDataClass(TClass):

	virtual def Create(style as TEngineStyle, engine as TPlugClass) as TURBU.PluginInterface.TEngineData:
		return TURBU.PluginInterface.TEngineData(style, engine)
