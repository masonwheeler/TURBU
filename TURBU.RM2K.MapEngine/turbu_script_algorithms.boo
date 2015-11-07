namespace turbu.script.algorithms

import Boo.Adt
import Pythia.Runtime
import turbu.Heroes
import System

private class DesignNameAttribute(System.Attribute):

	public def constructor(Name as string):
		pass

[DesignName('RM2K level algorithm')]
private def CalcExp2k(currentLevel as int, stdIncrease as int, addIncrease as int, correction as int, dummy as int) as int:
	standard as double
	additional as double
	result = 0
	standard = stdIncrease
	additional = 1.5 + (addIncrease * 0.1)
	for i in range(currentLevel - 1, 0, -1):
		result += correction + Math.Truncate(standard)
		standard *= additional
		additional = (((currentLevel * 0.2) + 0.8) * (additional - 1)) + 1
	result = Math.Min(result, MAXEXP2K)

[DesignName('RM2K3 level algorithm')]
private def CalcExp2k3(level as int, primary as int, secondary as int, tertiary as int, dummy as int) as int:
	result = 0
	for i in range(1, level):
		result += i
	result = (result * secondary) + ((level - 1) * (primary + tertiary))
	result = Math.Min(result, MAXEXP2K3)

//these should be moved to a design-time assembly, when I can make those
/*
private def SkillSelectByLevel_display(level as int, unused2 as int, unused3 as int, unused4 as int) as string:
	return "Lv. $level"

private def SkillSelectByEq_display(item1 as int, Item2 as int, Item3 as int, Item4 as int) as string:
	return 'Eq.'

private def SkillSelectByBoolean_display(which as int, unused2 as int, unused3 as int, unused4 as int) as string:
	result = "Switch $which"
	if which > 0:
		result = result + ' ON'
	else:
		result = result + ' OFF'
	return result

private def SkillSelectByVar_display(which as int, value as int, unused3 as int, unused4 as int) as string:
	whichvar as int
	whichvar = Math.Truncate(Math.Abs(which))
	result = 'Var $whichvar'
	if which > 0:
		result = result + ' >= '
	else:
		result = result + ' <= '
	result = result + value.ToString()
*/

let MAXEXP2K  =  1000000
let MAXEXP2K3 = 10000000

initialization :
	TRpgHero.RegisterExpFunc('CalcExp2k', CalcExp2k)
	TRpgHero.RegisterExpFunc('CalcExp2k3', CalcExp2k3)
