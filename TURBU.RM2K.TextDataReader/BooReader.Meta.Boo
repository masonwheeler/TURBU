namespace TURBU.RM2K.TextDataReader

import Pythia.Runtime
import TURBU.PluginInterface

[Metaclass(TBooReader)]
class TBooReaderClass(TPlugClass):
	override def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TURBU.RM2K.TextDataReader.TBooReader()
