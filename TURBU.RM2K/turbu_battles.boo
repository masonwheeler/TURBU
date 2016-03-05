namespace turbu.battles

import Pythia.Runtime
import TURBU.BattleEngine
import turbu.defs

class TBattleConditions(TObject):

	[Getter(Background)]
	private FBackground as string

	[Getter(Results)]
	private FResults as TBattleResult

	[Getter(Formation)]
	private FFormation as TBattleFormation

	public def constructor(background as string, formation as TBattleFormation, results as TBattleResult):
		FBackground = background
		FFormation = formation
		FResults = results

