namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.Meta
import TURBU.RM2K.Import.LCF

static class TSkillConverter:
	def Convert(skill as RMSkill) as MacroStatement:
		caseOf skill.SkillType:
			case 1, 2: return ConvertTeleportSkill(skill)
			case 3: return ConvertSwitchSkill(skill)
			default: return ConvertNormalSkill(skill) //case 0 or RM2K3 "skill group" skills
	
	private def ConvertSkill(skill as RMSkill, name as string) as MacroStatement:
		result = [|
			Skill $(skill.ID):
				Name $(skill.Name)
				Desc $(skill.Desc)
				Cost $((skill.PercentCost if skill.UsesPercentCost else skill.Cost)), $(skill.UsesPercentCost)
		|]
		result.Body.Add([|UseString $(skill.Usage)|]) unless string.IsNullOrEmpty(skill.Usage)
		result.Body.Add([|UseString2 $(skill.Usage2)|]) unless string.IsNullOrEmpty(skill.Usage2)
		result.Body.Add([|FailureMessage $(skill.Failure)|]) unless skill.Failure == -1
		if skill.Legacy.ContainsKey(0x32):
			l = [|Legacy 0x32|]
			l32 = ArrayLiteralExpression()
			l32.Items.AddRange(skill.Legacy[0x32].Select({i | Expression.Lift(i)}))
			l.Arguments.Add(l32)
			result.Body.Add(l)
		result.Name = name
		return result
	
	private def ConvertNormalSkill(base as RMSkill) as MacroStatement:
		result = ConvertSkill(base, 'Skill')
		props = [|
			Usable $((ReferenceExpression('Both') if base.Field else ReferenceExpression('Battle')))
			Animation $(base.Anim)
			SkillPower $(base.StrengthBase), $(base.MindBase), $(base.Variance), $(base.Base)
			SuccessRate $(base.SuccessRate)
			Stats $(base.HP), $(base.MP), $(base.Attack), $(base.Defense), $(base.Mind), $(base.Speed)
			Drain $(base.Vampire)
			Phased $(base.Phased)
			ResistMod $(base.ResistMod)
			InflictReversed $(base.InflictReversed)
			DisplaySprite $(base.DisplaySprite)
		|]
		result.Body.Add(props)
		caseOf base.Range:
			case 0, 3: skillRange = [|Target|]
			case 1, 4: skillRange = [|Area|]
			case 2: skillRange = [|Self|]
		result.Body.Add([|Range $skillRange|])
		result.Body.Add([|Offensive $(base.Range in (0, 1))|])
		conds = (base.Conditions cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).ToArray()
		if conds.Length > 0:
			conditions = MacroStatement('Condition')
			conditions.Arguments.AddRange(conds.Select({i | Expression.Lift(i)}))
			result.Body.Add(conditions)
		attrs = (base.Attributes cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).ToArray()
		runningTotal = 0.0
		if attrs.Length > 0:
			attributes = MacroStatement('Attributes')
			percentage = 100.0 / attrs.Length
			for item in attrs:
				runningTotal += percentage
				pct = (percentage cast int if runningTotal - Math.Floor(runningTotal) < 0.5 else (percentage + 1) cast int)
				attributes.Body.Add([|Attribute $item, $(pct)|])
			result.Body.Add(attributes)
		return result
	
	private def ConvertSpecialSkill(base as RMSkill, name as string) as MacroStatement:
		result = self.ConvertSkill(base, name)
		assert base.SkillType > 0
		result.Body.Add(TMusicConverter.Convert(base.Sfx, 'SFX'))
		return result
	
	private def ConvertTeleportSkill(base as RMSkill) as MacroStatement:
		result = ConvertSpecialSkill(base, 'TeleportSkill')
		assert base.SkillType in (1, 2)
		result.Body.Add([|TeleportTarget $(base.SkillType)|])
		usableWhere = ([|Field|] if base.SkillType == 1 else [|Battle|])
		result.Body.Add([|Usable $usableWhere|])
		return result
	
	private def ConvertSwitchSkill(base as RMSkill) as MacroStatement:
		result = ConvertSpecialSkill(base, 'VariableSkill')
		assert base.SkillType == 3
		result.Body.Add([|Which Switch, $(base.Switch)|])
		if base.Field and base.Battle:
			usableWhere = [|Both|]
		elif base.Field:
			usableWhere = [|Field|]
		elif base.Battle:
			usableWhere = [|Battle|]
		else: usableWhere = [|None|]
		result.Body.Add([|Usable $usableWhere|])
		return result
