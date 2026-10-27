namespace TURBU.RM2K.BattleEngine

import System
import System.Threading.Tasks
import Pythia.Runtime
import turbu.versioning
import turbu.battles
import turbu.monsters
import turbu.Heroes
import TURBU.BattleEngine

class T2kBattleEngine(TBattleEngine):
	public def constructor():
		self.Data = TBattleEngineData(
			'First-person battle engine',
			TVersion(0, 1, 1),
			TBattleView.FirstPerson,
			TBattleTiming.Turns)
	
	public override def Initialize(window as IntPtr):
		FInitialized = true
	
	[async]
	public override def StartBattle(party as TObject, foes as TObject, conditions as TObject) as Task of TBattleResultData:
		var scene = TBattleScene(party cast TRpgParty, foes cast TRpgMonsterParty, conditions cast TBattleConditions)
		result = await(scene.Run())
		return TBattleResultData(result: result)
	
	protected override def Cleanup():
		pass
	
