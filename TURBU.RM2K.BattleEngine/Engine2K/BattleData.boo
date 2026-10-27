namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import Boo.Adt
import TURBU.Meta
import commons
import System.Linq.Enumerable
import SG.defs
import turbu.defs
import turbu.characters
import turbu.items
import turbu.monsters
import turbu.resists
import turbu.skills
import TURBU.RM2K

static class TBattleData:

	public DefaultAttributeRank = 2
	public DefaultHeroConditionRank = 2
	public DefaultMonsterConditionRank = 1

	public ConditionCount as int:
		get: return GDatabase.value.Conditions.Count

	public AttributeCount as int:
		get: return GDatabase.value.Attributes.Count

	//---- skills

	public def Skill(id as int) as TSkillTemplate:
		return GDatabase.value.Skill[id]

	public def NormalSkill(id as int) as TNormalSkillTemplate:
		return Skill(id) as TNormalSkillTemplate

	//0 for a normal skill, 1: teleport, 2: escape, 3: a switch skill
	public def SkillKind(skill as TSkillTemplate) as int:
		return 0 if skill isa TNormalSkillTemplate
		var teleport = skill as TTeleportSkillTemplate
		return clamp(teleport.TeleportTarget, 1, 2) if teleport is not null
		return 3

	public def SkillScope(skill as TNormalSkillTemplate) as TSkillScope:
		caseOf skill.Range:
			case TSkillRange.Self: return TSkillScope.Self
			case TSkillRange.Target: return (TSkillScope.OneEnemy if skill.Offensive else TSkillScope.OneAlly)
			default: return (TSkillScope.AllEnemies if skill.Offensive else TSkillScope.AllAllies)

	public def SkillUsableInBattle(skill as TSkillTemplate) as bool:
		return true if skill isa TNormalSkillTemplate
		return false unless SkillKind(skill) == 3
		return skill.Usable in (TUsableWhere.Battle, TUsableWhere.Both)

	public def SkillHasCondition(skill as TNormalSkillTemplate, id as int) as bool:
		return skill.Condition is not null and Array.IndexOf(skill.Condition, id) >= 0

	public def SkillHasAttribute(skill as TNormalSkillTemplate, id as int) as bool:
		return false if skill.Attributes is null
		return skill.Attributes.Any({pair | pair.x == id})

	public def SkillHasAnyCondition(skill as TNormalSkillTemplate) as bool:
		return skill.Condition is not null and skill.Condition.Length > 0

	public def SkillCost(skill as TSkillTemplate, maxMana as int) as int:
		return (maxMana * skill.Cost) / 100 if skill.CostAsPercentage
		return skill.Cost

	//---- items

	public def Item(id as int) as TItemTemplate:
		return GDatabase.value.Items[id]

	public def ItemUsableInBattle(item as TItemTemplate) as bool:
		var usable = item as TUsableItemTemplate
		return false if usable is null
		return false unless item isa TMedicineTemplate or item isa TSkillItemTemplate or item isa TVariableItemTemplate
		return usable.UsableWhere in (TUsableWhere.Battle, TUsableWhere.Both)

	public def ItemUsableBy(item as TItemTemplate, heroId as int) as bool:
		var usable = item as TUsableItemTemplate
		return true if usable is null or usable.UsableByHero is null or usable.UsableByHero.Length == 0
		return heroId in usable.UsableByHero

	public def ItemHasCondition(item as TMedicineTemplate, id as int) as bool:
		return item.Conditions is not null and id in item.Conditions

	public def EquipmentHasAttribute(item as TEquipmentTemplate, id as int) as bool:
		return item.Attributes is not null and id in item.Attributes

	public def EquipmentHasCondition(item as TEquipmentTemplate, id as int) as bool:
		return item.Condition is not null and id in item.Condition

	//---- attributes and conditions

	//the rank of a battler for the attribute or condition
	public def RankIn(ranks as (SgPoint), id as int, defaultRank as int) as int:
		return defaultRank if ranks is null
		for pair in ranks:
			return pair.y if pair.x == id
		return defaultRank

	public def AttributeRate(id as int, rank as int) as int:
		return TBattleMath.RateAt(GDatabase.value.Attributes[id].Standard, rank)

	public def IsMagicalAttribute(id as int) as bool:
		return GDatabase.value.Attributes[id].RequiredForSkills

	public def ConditionRate(id as int, rank as int) as int:
		return TBattleMath.RateAt(GDatabase.value.Conditions[id].Standard, rank)

	public def Condition(id as int) as TConditionTemplate:
		return GDatabase.value.Conditions[id]
