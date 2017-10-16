namespace TURBU.BattleEngine

import System
import System.Threading.Tasks
import Boo.Adt
import Pythia.Runtime
import TURBU.PluginInterface
import turbu.versioning
import TURBU.Engines

[EnumSet]
enum TBattleResult:
	None = 0
	Victory = 1
	Escaped = 2
	Defeated = 4

[EnumSet]
enum TBattleView:
	None = 0
	FirstPerson = 1
	Side = 2
	Top = 4

enum TBattleTiming:
	Turns = 1
	Atb
	Counter

struct TBattleResultData:
	result as TBattleResult
	data as TObject

interface IBattleEngine(ITurbuEngine):

	def StartBattle(party as TObject, foes as TObject, conditions as TObject) as TBattleResultData

	def Initialize(window as IntPtr)

	Data as TBattleEngineData:
		get

class TBattleEngineData(TRpgMetadata):

	[Getter(View)]
	private FView as TBattleView

	[Getter(Timing)]
	private FTiming as TBattleTiming

	public def constructor(name as string, version as TVersion, view as TBattleView, timing as TBattleTiming):
		super(name, version)
		FView = view
		FTiming = timing

abstract class TBattleEngine(TRpgPlugBase, IBattleEngine):

	private FData as TBattleEngineData

	protected FInitialized as bool

	protected abstract def Cleanup():
		pass

	def destructor():
		if FInitialized:
			self.Cleanup()

	public override def AfterConstruction():
		super.AfterConstruction()
		assert assigned(Data)
		assert Data.Name != ''
		assert Data.Version > TVersion(0, 0, 0)
		assert ord(Data.View) > 0
		assert ord(Data.Timing) > 0

	public abstract def Initialize(window as IntPtr):
		pass

	public abstract def StartBattle(party as TObject, foes as TObject, conditions as TObject) as TBattleResultData:
		pass

	public Data as TBattleEngineData:
		get: return FData
		set: FData = value

	def constructor():
		super()

	def Dispose() as Task:
		return Task.FromResult(true)


let NEED_BATTLE_SPRITES = (TBattleView.Side or TBattleView.Top)
