namespace TURBU.RM2K.CompiledDataReader

import System
import Pythia.Runtime
import TURBU.PluginInterface

class TRpgCompiledDataReader(ITurbuPlugin):
	def ListPlugins() as TEngineData*:
		return (TEngineData(TEngineStyle.Data, classOf(TDllReader)),)
