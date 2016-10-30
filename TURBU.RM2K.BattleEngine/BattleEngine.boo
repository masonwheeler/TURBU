namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import TURBU.PluginInterface

class TRpgBasicBattlePlugin(ITurbuPlugin):
	def ListPlugins() as TEngineData*:
		yield TEngineData(TEngineStyle.Battle, classOf(T2kBattleEngine))
		yield TEngineData(TEngineStyle.Battle, classOf(T2k3BattleEngine))

initialization:
	Jv.PluginManager.RegisterPlugin(TRpgBasicBattlePlugin())