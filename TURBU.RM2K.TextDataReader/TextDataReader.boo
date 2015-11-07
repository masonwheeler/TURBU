namespace TURBU.RM2K.TextDataReader

import System
import Pythia.Runtime
import TURBU.PluginInterface

class TRpgTextDataReader(ITurbuPlugin):
	def ListPlugins() as TEngineData*:
		return (TEngineData(TEngineStyle.Data, classOf(TBooReader)),)
