namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import turbu.versioning
import TURBU.BattleEngine

class T2k3BattleEngine(TBattleEngine):
	public def constructor():
		self.Data = TBattleEngineData(
			'Active-time battle engine',
			TVersion(0, 1, 1),
			TBattleView.Side,
			TBattleTiming.Atb)
	
	public override def Initialize(window as IntPtr):
		FInitialized = true
	
	public override def StartBattle(party as TObject, foes as TObject, conditions as TObject) as TBattleResultData:
		return TBattleResultData(result: TBattleResult.Victory)
	
	protected override def Cleanup():
		pass
	
	def Dispose():
		pass
