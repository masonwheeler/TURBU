namespace TURBU.RM2K.CompiledDataReader

import Pythia.Runtime
import TURBU.PluginInterface

[Metaclass(TDllReader)]
class TDllReaderClass(TPlugClass):
	override def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TDllReader()
