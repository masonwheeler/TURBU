namespace TURBU.BattleEngine

import Pythia.Runtime
import TURBU.PluginInterface
import turbu.versioning

[Metaclass(TBattleEngineData)]
class TBattleEngineDataClass(TRpgMetadataClass):

	virtual def Create(name as string, version as TVersion, view as TBattleView, timing as TBattleTiming) as TURBU.BattleEngine.TBattleEngineData:
		return TURBU.BattleEngine.TBattleEngineData(name, version, view, timing)

[Metaclass(TBattleEngine)]
class TBattleEngineClass(TPlugClass):
	pass