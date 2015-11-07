namespace TURBU.RM2K.BattleEngine

import Pythia.Runtime
import TURBU.BattleEngine

[Metaclass(T2kBattleEngine)]
class T2kBattleEngineClass(TBattleEngineClass):
	override def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TURBU.RM2K.BattleEngine.T2kBattleEngine()
