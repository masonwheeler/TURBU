namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import TURBU.Meta
import TURBU.RM2K.Import.LCF

static class TMonsterConverter:
	def Convert(base as RMMonster) as MacroStatement:
		result = [|
			Monster $(base.ID):
				Name $(base.Name)
				Filename $(base.Filename)
				Transparent $(base.Transparent)
				Flying $(base.Flying)
				ColorShift $(base.ColorShift)
				Exp $(base.Exp)
				Money $(base.Money)
				Item $(base.Item)
				ItemChance $(base.ItemChance)
				CanCrit $(base.CanCrit)
				CritChance $(base.CritChance)
				OftenMiss $(base.OftenMiss)
				Stats $(base.HP), $(base.MP), $(base.Attack), $(base.Defense), $(base.Mind), $(base.Speed)
		|]
		resists = MacroStatement('Attributes')
		resists.Arguments.AddRange((base.DTypeModifiers cast (byte)).Select({b | Expression.Lift(b)}))
		result.Body.Add(resists)
		conditions = MacroStatement('Condition')
		conditions.Arguments.AddRange((base.ConditionModifiers cast (byte)).Select({b | Expression.Lift(b)}))
		result.Body.Add(conditions)
		if assigned(base.Behavior) and base.Behavior.Count > 0:
			behavior = MacroStatement('Behavior')
			for bElem in base.Behavior:
				behavior.Body.Add(ConvertMonsterBehavior(bElem))
			result.Body.Add(behavior)
		return result
	
	private def ConvertMonsterBehavior(base as MonsterBehavior) as MacroStatement:
		result = [|
			MonsterBehavior $(base.ID):
				Priority $(base.Priority)
		|]
		if base.Precondition >= 1:
			result.Body.Add([|Requirement $(ConvertRequirement(base))|])
			//SubMacro('Requirement').Arguments.Add(Expression.Lift(base.PreconditionSwitch))
		elif base.Precondition > 1:
			req = result.SubMacro('Requirement')
			req.Arguments.Add(Expression.Lift(base.PreconditionP1))
			req.Arguments.Add(Expression.Lift(base.PreconditionP2))
		result.Body.Add([|SwitchOn $(base.SwitchOnID)|]) if base.SwitchOn
		result.Body.Add([|SwitchOff $(base.SwitchOffID)|]) if base.SwitchOff
		caseOf base.Action:
			case 0: result.Body.Add([|Action $(ReferenceExpression(Enum.GetName(turbu.monsters.TMonsterBehaviorAction, base.Action)))|])
			case 1: result.Body.Add([|Skill $(base.Skill)|])
			case 2: result.Body.Add([|Transform $(base.Transform)|])
			default: raise "Unexpected monster behavior action value: $(base.Action)"
		return result

	private def ConvertRequirement(base as MonsterBehavior) as Expression:
		caseOf base.Precondition:
			case 1: return [|Switch[$(base.PreconditionSwitch)]|]
			case 2: return [|BattleState.TurnsMatch($(base.PreconditionP1), $(base.PreconditionP2))|]
			case 3: return [|BattleState.MonstersPresent($(base.PreconditionP1), $(base.PreconditionP2))|]
			case 4: return [|BattleState.MonsterHPBetween($(base.PreconditionP1), $(base.PreconditionP2))|]
			case 5: return [|BattleState.MonsterMPBetween($(base.PreconditionP1), $(base.PreconditionP2))|]
			case 6: return [|BattleState.PartyLevelBetween($(base.PreconditionP1), $(base.PreconditionP2))|]
			case 7: return [|BattleState.PartyExhaustionBetween($(base.PreconditionP1), $(base.PreconditionP2))|]
			default: assert false
