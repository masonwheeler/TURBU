namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import TURBU.Meta
import TURBU.RM2K.Import.LCF

static class TItemConverter:
	
	def Convert(base as RMItem, db as LDB) as MacroStatement:
		caseOf base.ItemType:
			case 0: return ConvertJunkItem(base)
			case 1: return ConvertWeaponItem(base, db)
			case 2, 3, 4, 5: return ConvertArmorItem(base, db)
			case 6: return ConvertMedicineItem(base, db)
			case 7: return ConvertBookItem(base, db)
			case 8: return ConvertUpgradeItem(base, db)
			case 9: return ConvertSkillItem(base, db)
			case 10: return ConvertSwitchItem(base, db)
			default: raise "Unknown ItemType property $(base.ItemType)"
	
	private def ConvertItem(typeName as string, base as RMItem, db as LDB) as MacroStatement:
		result = [|
			Item $(base.ID):
				Name $(base.Name)
				Desc $(base.Desc)
				Cost $(base.Price)
		|]
		result.Name = typeName
		ConvertUsableItem(base, db, result) if db is not null
		return result
	
	private def ConvertUsableItem(base as RMItem, db as LDB, result as MacroStatement):
		result.Body.Add([|UsesLeft $(base.Uses)|])
		result.Body.Add([|Usable Both|])
		bub = base.UsableBy cast (bool)
		usable = bub.Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).ToArray()
		heroes = MacroStatement('UsableByHero')
		heroes.Arguments.AddRange(usable.Select({i | Expression.Lift(i)}))
		result.Body.Add(heroes)
		classes = MacroStatement('Classes')
		if assigned(base.UsableByClass) and base.UsableByClass.Length > 0:
			usable = (base.UsableByClass cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).ToArray()
			classes.Arguments.AddRange(usable.Select({i | Expression.Lift(i)}))
			i = db.Classes.Count
			for j in db.Heroes.Where({h | h.ClassNum == 0}).Select({h | h.ID}).Where({i | bub[i - 1]}):
				classes.Arguments.Add(Expression.Lift((j + i) - 1))
		else: classes.Arguments.AddRange(usable.Select({i | Expression.Lift(i)}))
		result.Body.Add(classes)
	
	private def ConvertJunkItem(base as RMItem) as MacroStatement:
		return ConvertItem('JunkItem', base, null)
	
	private def ConvertWeaponItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('WeaponItem', base, db)
		props = [|
			Evasion $(base.IgnoreEvasion)
			ToHit $(base.ToHit)
			CritChance $(base.CritChance)
			TwoHanded $(base.TwoHanded)
			AttackTwice $(base.AttackTwice)
			AreaHit $(base.AreaHit)
			BattleAnim $(base.BattleAnim)
			MpCost $(base.MPCost)
			ConditionChance $(base.ConditionInflictChance)
			Preemptive $((100 if base.Preemptive else 0))
			Animation $(base.WeaponAnimation)
			Trajectory $(base.RangedTrajectory)
			Target $(base.RangedTarget)
			Stats 0, 0, $(base.AttackModify), $(base.DefenseModify), $(base.MindModify), $(base.SpeedModify)
		|]
		result.Body.Add(props)
		attrs = (base.Attributes cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).Select({i | Expression.Lift(i)}).ToArray()
		if attrs.Length > 0:
			attributes = MacroStatement('Attributes')
			attributes.Arguments.AddRange(attrs)
			result.Body.Add(attributes)
		if base.AnimData.Count > 0:
			anims = MacroStatement('Animations')
			for animData in base.AnimData:
				continue if animData.WhichWeapon < 1
				anims.Body.Add(TItemAnimDataConverter.Convert(animData))
			result.Body.Add(anims) unless anims.Body.IsEmpty
		return result
	
	private def ConvertArmorItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('ArmorItem', base, db)
		props = [|
			Evasion $(base.BoostEvade)
			CritPrevent $((100 if base.PreventCrits else 0))
			MpReduction $((50 if base.HalfMP else 0))
			NoTerrainDamage $(base.NoTerrainDamage)
			Slot $(ReferenceExpression(Enum.GetName(turbu.defs.TSlot, base.ItemType - 1)))
			Stats 0, 0, $(base.AttackModify), $(base.DefenseModify), $(base.MindModify), $(base.SpeedModify)
		|]
		result.Body.Add(props)
		attrs = (base.Attributes cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).Select({i | Expression.Lift(i)}).ToArray()
		if attrs.Length > 0:
			attributes = MacroStatement('Attributes')
			attributes.Arguments.AddRange(attrs)
			result.Body.Add(attributes)
		return result
	
	private def ConvertMedicineItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('MedicineItem', base, db)
		props = [|
			HPHeal $(base.HPHeal)
			MPHeal $(base.MPHeal)
			HPPercent $(base.HPPercent)
			MPPercent $(base.MPPercent)
			DeadOnly $(base.DeadHeroesOnly)
			AreaEffect $(base.AreaMedicine)
		|]
		result.Body.Add(props)
		conds = (base.Conditions cast (bool)).Select({a, i | (i + 1 if a else 0)}).Where({i | i > 0}).ToArray()
		if conds.Length > 0:
			conditions = MacroStatement('Conditions')
			conditions.Arguments.AddRange(conds.Select({i | Expression.Lift(i)}))
			result.Body.Add(conditions)
		if base.OutOfBattleOnly:
			result.SubMacro('Usable').Arguments[0] = ReferenceExpression('Field')
		return result
	
	private def ConvertBookItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('BookItem', base, db)
		result.Body.Add([|Skill $(base.SkillToLearn)|])
		return result
	
	private def ConvertUpgradeItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('UpgradeItem', base, db)
		result.Body.Add([|Stats $(base.PermHPGain), $(base.PermMPGain), $(base.PermAttackGain), \
										$(base.PermDefenseGain), $(base.PermMindGain), $(base.PermSpeedGain)|])
		return result
	
	private def ConvertSkillItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('SkillItem', base, db)
		result.Body.Add([|Skill $(base.SkillToLearn)|])
		result.Body.Add([|SkillMessage $(base.DisplaySkillMessage)|])
		return result
	
	private def ConvertSwitchItem(base as RMItem, db as LDB) as MacroStatement:
		result = ConvertItem('SwitchItem', base, db)
		result.Body.Add([|Value Switch, $(base.Switch)|])
		usable = result.SubMacro('Usable')
		if base.OnField:
			unless base.InBattle:
				usable.Arguments[0] = ReferenceExpression('Field')
		elif base.InBattle:
			usable.Arguments[0] = ReferenceExpression('Battle')
		return result

static class TItemAnimDataConverter:
	
	def Convert(base as ItemAnimData) as MacroStatement:
		result = [|
			Anim $(base.ID):
				AnimType $(ReferenceExpression(Enum.GetName(turbu.items.TWeaponAnimType, base.AnimType)))
				Weapon $(base.WhichWeapon)
				MovementMode $(ReferenceExpression(Enum.GetName(turbu.items.TMovementMode, base.MovementMode)))
				AfterImage $(base.Afterimage)
				AttackNum $(base.AttackNum)
				Ranged $(base.Ranged)
				RangedProjectile $(base.RangedProjectile)
				RangedSpeed $(base.RangedSpeed)
				BattleAnim $(base.BattleAnim)
		|]
		return result
