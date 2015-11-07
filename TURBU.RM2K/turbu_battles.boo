namespace turbu.battles

import Pythia.Runtime
import TURBU.BattleEngine
import turbu.defs

class TBattleConditions(TObject):

	[Getter(background)]
	private FBackground as string

	[Getter(results)]
	private FResults as TBattleResult

	[Getter(formation)]
	private FFormation as TBattleFormation

	public def constructor(background as string, formation as TBattleFormation, results as TBattleResult):
		FBackground = background
		FFormation = formation
		FResults = results

