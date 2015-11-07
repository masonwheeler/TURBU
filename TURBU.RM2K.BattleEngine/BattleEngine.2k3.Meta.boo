namespace TURBU.RM2K.BattleEngine

import Pythia.Runtime
import TURBU.BattleEngine

[Metaclass(T2k3BattleEngine)]
class T2k3BattleEngineClass(TBattleEngineClass):
	virtual def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TURBU.RM2K.BattleEngine.T2k3BattleEngine()
