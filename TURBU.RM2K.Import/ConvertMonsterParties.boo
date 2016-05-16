namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import TURBU.RM2K.Import.LCF

[EnumSet]
private enum RMBattlePageConditions:
	None = 0
	Switch1 = 1
	Switch2 = 2
	Variable1 = 4
	Turns = 8
	HeroHP = 0x10
	MonsterHP = 0x20
	MonsterTime = 0x40
	HeroTime = 0x80
	Exhaustion = 0x100
	CommandUsed = 0x200

static class TMonsterPartyConverter:
	
	def Convert(base as RMMonsterParty, saveData as Action[of Node], \
			ScanScript as Action[of EventCommand*], progress as IConversionReport) as MacroStatement:
		baseID = base.ID
		result = [|
			MonsterParty $baseID:
				Name $(base.Name)
				AutoAlign $(base.AutoAlign)
				Random $(base.Random)
				Monsters
				Habitats
		|]
		result.SubMacro('Monsters').Body.Statements.AddRange(base.Monsters.Select({e | ConvertMonsterElement(e)}))
		result.SubMacro('Habitats').Arguments.AddRange((base.Habitats cast (bool)).Select({h | Expression.Lift(h)}))
		pages = base.Events.Where({e | e.Commands.Count > 0}).ToArray()
		if pages.Length > 0:
			eventPages = MacroStatement('Pages')
			eventPages.Body.Statements.AddRange(pages.Select({p, i | ConvertEventPage(p, baseID, i, saveData, ScanScript, progress)}))
			result.Body.Add(eventPages)
		return result
	
	private def ConvertEventPage(base as BattleEventPage, baseID as int, id as int, \
			saveScript as Action[of Node], ScanScript as Action[of EventCommand*], progress as IConversionReport) as MacroStatement:
		pageName = "mparty$(baseID.ToString('D4'))_$id"
		result = [|
			Page $(base.ID):
				Name $(pageName)
				PageConditions:
					$(ConvertConditions(base.Conditions))
		|]
		ConvertBattleScripts(baseID, base, ScanScript, saveScript,
			{msg, id, page | progress.MakeNotice("$msg at monster party #$baseID, script #$page.", 3)})
		return result
	
	private def ConvertConditions(value as BattleEventConditions) as Block:
		result = Block()
		cond as RMBattlePageConditions = value.Conditions cast int
		if cond == RMBattlePageConditions.None:
			result.Add([|true|])
			return result
		if RMBattlePageConditions.Switch1 in cond:
			result.Add([|Switch $(value.Switch1)|])
		if RMBattlePageConditions.Switch2 in cond:
			result.Add([|Switch $(value.Switch2)|])
		if RMBattlePageConditions.Variable1 in cond:
			be = BinaryExpression(BinaryOperatorType.GreaterThan, Expression.Lift(value.Variable), \
				Expression.Lift(value.VarValue))
			result.Add([|Variable $be|])
		if RMBattlePageConditions.Turns in cond:
			result.Add([|Turns $(value.TurnsMultiple), $(value.TurnsConst)|])
		if RMBattlePageConditions.MonsterTime in cond:
			result.Add([|MonsterTime $(value.MonsterTurnID), $(value.MonsterTurnsMultiple), $(value.MonsterTurnsConst)|])
		if RMBattlePageConditions.HeroTime in cond:
			result.Add([|HeroTime $(value.HeroTurn), $(value.HeroTurnsMultiple), $(value.HeroTurnsConst)|])
		if RMBattlePageConditions.Exhaustion in cond:
			result.Add([|Exhaustion $(value.ExhaustionMin), $(value.ExhaustionMax)|])
		if RMBattlePageConditions.MonsterHP in cond:
			result.Add([|MonsterHP $(value.MonsterHPID), $(value.MonsterHPMin), $(value.MonsterHPMax)|])
		if RMBattlePageConditions.HeroHP in cond:
			result.Add([|HeroHP $(value.HeroHP), $(value.HeroHPMin), $(value.HeroHPMax)|])
		if RMBattlePageConditions.CommandUsed in cond:
			result.Add([|CommandUsed $(value.HeroCommandWho), $(value.HeroCommandWhich)|])
		return result
	
	private def ConvertMonsterElement(base as MonsterElement) as MacroStatement:
		result = [|
			MonsterElement $(base.ID):
				Monster $(base.Monster)
				Position $(base.X), $(base.Y)
				Invisible $(base.Invisible)
		|]
		return result