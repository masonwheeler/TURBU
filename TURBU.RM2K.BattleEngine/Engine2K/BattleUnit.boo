namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import Boo.Adt
import TURBU.Meta
import commons
import System.Collections.Generic
import System.Linq.Enumerable
import SG.defs
import turbu.defs
import turbu.characters
import turbu.items
import turbu.monsters
import turbu.resists
import turbu.skills
import turbu.constants
import turbu.Heroes
import TURBU.RM2K
import TURBU.RM2K.RPGScript
import turbu.RM2K.environment

class TBattleField:

	[Getter(Party)]
	private _party as TRpgParty

	property Heroes = List[of THeroUnit]()

	property Monsters = List[of TMonsterUnit]()

	property Turns as int

	property CurrentMonster as TBattleUnit

	public def constructor(party as TRpgParty):
		_party = party

	public AliveMonsterCount as int:
		get: return Monsters.Count({m | m.IsAlive})

	public AverageHeroAgility as int:
		get:
			result = Heroes.Average({h | h.Agility})
			return Math.Max(result, 1)

	public AverageMonsterAgility as int:
		get:
			result = Monsters.Average({m | m.Agility})
			return Math.Max(result, 1)

	public AverageLevel as int:
		get:
			result = Heroes.Average({h | h.Level})
			return Math.Max(result, 1)

	public HealthLoss as int:
		get:
			hp = 0
			maxHp = 0
			sp = 0
			maxSp = 0
			for hero in Heroes:
				hp += hero.Hp
				maxHp += hero.MaxHp
				sp += hero.Sp
				maxSp += hero.MaxSp
			return TBattleMath.HealthLoss(hp, maxHp, sp, maxSp)

	public AnyHeroCanChooseCommand as bool:
		get: return Heroes.Any({h | h.CanChooseCommand})

	public def LivingHero() as THeroUnit:
		living = Heroes.Where({h | h.IsAlive}).ToArray()
		return null if living.Length == 0
		return living[TBattleMath.Roll(living.Length)]

abstract class TBattleUnit:

	[Getter(Field)]
	protected _field as TBattleField

	property Present = true

	[Getter(Action)]
	private _action = TBattleAction()

	property Initiative as int

	property Charged as bool

	property Defending as bool

	property TurnsTaken as int

	property LastCommand = -1

	property AttackMod as int

	property DefenseMod as int

	property SpiritMod as int

	property AgilityMod as int

	private _conditionAge as (int)

	private _attributeShift as (int)

	public def constructor(field as TBattleField):
		_field = field
		_conditionAge = array(int, TBattleData.ConditionCount + 1)
		_attributeShift = array(int, TBattleData.AttributeCount + 1)

	public abstract Character as TRpgBattleCharacter:
		get

	public abstract Name as string:
		get

	protected abstract def BaseAttack() as int:
		pass

	protected abstract def BaseDefense() as int:
		pass

	protected abstract def BaseSpirit() as int:
		pass

	protected abstract def BaseAgility() as int:
		pass

	//0 to 4 for the ranks A to E
	public abstract def BaseAttributeRank(id as int) as int:
		pass

	public abstract def BaseConditionRank(id as int) as int:
		pass

	public abstract CriticalChance as double:
		get

	//percentage
	public abstract HitRate as int:
		get

	public abstract IsHero as bool:
		get

	public abstract def ChooseAction():
		pass

	public virtual def HasAttackAttribute(id as int) as bool:
		return false

	public virtual def WeaponConditionChance(id as int) as int:
		return 0

	public virtual def ArmorConditionChance(id as int) as int:
		return 0

	public virtual SuperGuard as bool:
		get: return false

	public virtual Preemptive as bool:
		get: return false

	public virtual DualAttack as bool:
		get: return false

	public def BasicAttack() as TBasicAction:
		return (TBasicAction.DoubleAttack if DualAttack else TBasicAction.Attack)

	public virtual AttackAll as bool:
		get: return false

	public virtual IgnoreEvasion as bool:
		get: return false

	public virtual PreventCritical as bool:
		get: return false

	public virtual RaiseEvasion as bool:
		get: return false

	public virtual HalfSkillCost as bool:
		get: return false

	public virtual AttackCost as int:
		get: return 0

	public virtual def CanUseItem(id as int) as bool:
		return false

	protected abstract def GetCondition(id as int) as bool:
		pass

	protected abstract def SetCondition(id as int, value as bool):
		pass

	public IsMonster as bool:
		get: return not IsHero

	public Hp as int:
		get: return Character.HP
		set: Character.HP = value

	public Sp as int:
		get: return Character.MP
		set: Character.MP = value

	public MaxHp as int:
		get: return Character.MaxHp

	public MaxSp as int:
		get: return Character.MaxMp

	public IsAlive as bool:
		get: return Present and Hp > 0

	public def ResetAction():
		_action.Reset()

	public def ConditionAge(id as int) as int:
		return (_conditionAge[id] if id > 0 and id < _conditionAge.Length else 0)

	public def SetConditionAge(id as int, value as int):
		_conditionAge[id] = value if id > 0 and id < _conditionAge.Length

	public def HasCondition(id as int) as bool:
		return ConditionAge(id) > 0

	public def LoadConditions():
		for id in range(1, _conditionAge.Length):
			if GetCondition(id):
				_conditionAge[id] = Math.Max(_conditionAge[id], 1)
			else: _conditionAge[id] = 0

	private def ActiveConditions() as TConditionTemplate*:
		for id in range(1, _conditionAge.Length):
			yield TBattleData.Condition(id) if _conditionAge[id] > 0

	public def AddCondition(id as int):
		SetConditionAge(id, 1)
		SetCondition(id, true)
		self.Hp = 0 if id == CTN_DEAD
		topPriority = 0
		for i in range(1, _conditionAge.Length):
			if _conditionAge[i] > 0:
				topPriority = Math.Max(topPriority, TBattleData.Condition(i).Priority)
		//remove conditions whose priority are 10 or more below the top one
		for i in range(1, _conditionAge.Length):
			if _conditionAge[i] > 0 and TBattleData.Condition(i).Priority <= topPriority - 10:
				RemoveCondition(i)
		if (AttacksEnemies or AttacksAllies) and _action.Kind != TBattleActionKind.Auto:
			Charged = false
			ChooseAction()
		unless CanAct:
			Charged = false
			_action.Kind = TBattleActionKind.Nothing
		if _action.Kind == TBattleActionKind.Skill and not CanUseSkill(_action.Skill):
			Charged = false
			_action.Kind = TBattleActionKind.Nothing
		if self.Hp == 0:
			AttackMod = 0
			DefenseMod = 0
			SpiritMod = 0
			AgilityMod = 0
			Array.Clear(_attributeShift, 0, _attributeShift.Length)
			Charged = false

	public def RemoveCondition(id as int):
		berserk = AttacksEnemies
		charmed = AttacksAllies
		SetConditionAge(id, 0)
		SetCondition(id, false)
		self.Hp = Math.Max(self.Hp, 1) if id == CTN_DEAD
		if (berserk and not AttacksEnemies) or (charmed and not AttacksAllies):
			_action.Kind = TBattleActionKind.Nothing

	public TopCondition as int:
		get:
			result = 0
			best = 0
			for id in range(1, _conditionAge.Length):
				if _conditionAge[id] > 0 and best <= TBattleData.Condition(id).Priority:
					best = TBattleData.Condition(id).Priority
					result = id
			return result

	public TopConditionName as string:
		get:
			top = TopCondition
			return (TBattleData.Condition(top).Name if top > 0 else TBattleText.Vocab(V_NORMAL_STATUS))

	public TopConditionColor as int:
		get:
			top = TopCondition
			return (TBattleData.Condition(top).Color if top > 0 else 0)

	public HpColor as int:
		get:
			return 5 if self.Hp == 0
			return (4 if self.Hp <= MaxHp / 4 else 0)

	public SpColor as int:
		get: return (4 if MaxSp > 0 and MaxSp / 4 >= self.Sp else 0)

	public HitRatio as int:
		get:
			result = 100
			for cond in ActiveConditions():
				result = Math.Min(result, cond.ToHitChange)
			return result

	public CanAct as bool:
		get: return not ActiveConditions().Any({c | c.AttackLimit == TAttackLimitation.Paralyze})

	public AttacksEnemies as bool:
		get: return ActiveConditions().Any({c | c.AttackLimit == TAttackLimitation.Berserk})

	public AttacksAllies as bool:
		get: return ActiveConditions().Any({c | c.AttackLimit == TAttackLimitation.Charm})

	public CanChooseAction as bool:
		get: return CanAct and not AttacksEnemies and not AttacksAllies

	public HasLockingCondition as bool:
		get: return ActiveConditions().Any({c | c.AttackLimit == TAttackLimitation.Paralyze and c.HealTurnPercent == 0})

	//---- stats

	private def StatChanged(value as int, which as int) as int:
		for cond in ActiveConditions():
			affected = false
			caseOf which:
				case 2: affected = cond.Attack
				case 3: affected = cond.Defense
				case 4: affected = cond.Mind
				default: affected = cond.Speed
			if affected:
				caseOf cond.StatEffect:
					case TStatEffect.Half: return Math.Max(value / 2, 1)
					case TStatEffect.Double: return Math.Min(value * 2, MAX_STAT)
					default: return value
		return value

	public Attack as int:
		get: return StatChanged(clamp(BaseAttack() + AttackMod, 1, MAX_STAT), 2)

	public Defense as int:
		get: return StatChanged(clamp(BaseDefense() + DefenseMod, 1, MAX_STAT), 3)

	public Spirit as int:
		get: return StatChanged(clamp(BaseSpirit() + SpiritMod, 1, MAX_STAT), 4)

	public Agility as int:
		get: return StatChanged(clamp(BaseAgility() + AgilityMod, 1, MAX_STAT), 5)

	//---- attribute ranks

	public def AttributeShift(id as int) as int:
		return (_attributeShift[id] if id > 0 and id < _attributeShift.Length else 0)

	public def AttributeRank(id as int) as int:
		return BaseAttributeRank(id) + AttributeShift(id)

	public def LowerAttributeRank(id as int) as bool:
		if BaseAttributeRank(id) > 0 and AttributeShift(id) + 1 > 0:
			_attributeShift[id] = AttributeShift(id) - 1
			return true
		return false

	public def RaiseAttributeRank(id as int) as bool:
		if BaseAttributeRank(id) < 4 and AttributeShift(id) - 1 < 0:
			_attributeShift[id] = AttributeShift(id) + 1
			return true
		return false

	//---- hit points and stats

	public def HealHp(amount as int) as int:
		return 0 if self.Hp == 0
		newValue = clamp(self.Hp + amount, 1, MaxHp)
		result = newValue - self.Hp
		self.Hp = newValue
		return result

	public def DamageHp(amount as int, canDie as bool) as int:
		old = self.Hp
		return 0 if old == 0
		self.Hp = clamp(old - amount, 0, MaxHp)
		if self.Hp == 0:
			if canDie:
				AddCondition(CTN_DEAD)
			else:
				self.Hp = 1
		return old - self.Hp

	public def HealSp(amount as int) as int:
		newValue = clamp(self.Sp + amount, 0, MaxSp)
		result = newValue - self.Sp
		self.Sp = newValue
		return result

	public def DamageSp(amount as int) as int:
		newValue = clamp(self.Sp - amount, 0, MaxSp)
		result = self.Sp - newValue
		self.Sp = self.Sp - result
		return result

	public def ChangeStat(which as int, delta as int) as int:
		caseOf which:
			case 2:
				old = AttackMod
				baseValue = BaseAttack()
				AttackMod = clamp(old + delta, -(baseValue / 2), baseValue)
				return AttackMod - old
			case 3:
				old = DefenseMod
				baseValue = BaseDefense()
				DefenseMod = clamp(old + delta, -(baseValue / 2), baseValue)
				return DefenseMod - old
			case 4:
				old = SpiritMod
				baseValue = BaseSpirit()
				SpiritMod = clamp(old + delta, -(baseValue / 2), baseValue)
				return SpiritMod - old
			case 5:
				old = AgilityMod
				baseValue = BaseAgility()
				AgilityMod = clamp(old + delta, -(baseValue / 2), baseValue)
				return AgilityMod - old
			default: return 0

	public def ReduceStat(which as int, delta as int) as int:
		return -ChangeStat(which, -delta)

	//---- the battle

	public def RollGauge():
		Initiative = TBattleMath.Initiative(Agility, Preemptive and _action.Kind == TBattleActionKind.Basic and _action.Basic in (TBasicAction.Attack, TBasicAction.DoubleAttack))

	public def AttackDamage(target as TBattleUnit) as int:
		result = TBattleMath.AttackBase(Attack, target.Defense)
		bestPhysical = BestAttributeRate(target, {id | HasAttackAttribute(id)}, false)
		bestMagical = BestAttributeRate(target, {id | HasAttackAttribute(id)}, true)
		return TBattleMath.ScaleByAttributes(result, bestPhysical, bestMagical)

	private def BestAttributeRate(target as TBattleUnit, has as Func[of int, bool], magical as bool) as int:
		best = -1
		for id in range(1, TBattleData.AttributeCount + 1):
			if TBattleData.IsMagicalAttribute(id) == magical and has(id):
				best = Math.Max(best, TBattleData.AttributeRate(id, target.AttributeRank(id)))
		return best

	public def SkillDamage(skillId as int, target as TBattleUnit) as int:
		skill = TBattleData.NormalSkill(skillId)
		scope = TBattleData.SkillScope(skill)
		offensive = scope in (TSkillScope.OneEnemy, TSkillScope.AllEnemies)
		result = TBattleMath.SkillBase(skill.Base, Attack, Spirit, skill.StrEffect, skill.MindEffect, offensive, \
				skill.Phased, target.Defense, target.Spirit)
		bestPhysical = BestAttributeRate(target, {id | TBattleData.SkillHasAttribute(skill, id)}, false)
		bestMagical = BestAttributeRate(target, {id | TBattleData.SkillHasAttribute(skill, id)}, true)
		result = TBattleMath.ScaleByAttributes(result, bestPhysical, bestMagical)
		return TBattleMath.SkillSpread(result, skill.Variance)

	public def SkillWorksOn(skillId as int) as bool:
		template = TBattleData.Skill(skillId)
		kind = TBattleData.SkillKind(template)
		return true if kind == 3
		return false unless kind == 0
		skill = template cast TNormalSkillTemplate
		scope = TBattleData.SkillScope(skill)
		return IsAlive if scope in (TSkillScope.OneEnemy, TSkillScope.AllEnemies)
		return true if not IsAlive and TBattleData.SkillHasCondition(skill, CTN_DEAD) // revival skill
		return false unless IsAlive
		return true if skill.HP or skill.MP or skill.Attack or skill.Defense or skill.Mind or skill.Speed
		for id in range(1, TBattleData.ConditionCount + 1):
			return true if TBattleData.SkillHasCondition(skill, id) and ConditionAge(id) > 0
		if skill.ResistMod:
			for id in range(1, TBattleData.AttributeCount + 1):
				return true if TBattleData.SkillHasAttribute(skill, id)
		return false

	public def SkillCostFor(skillId as int) as int:
		cost = TBattleData.SkillCost(TBattleData.Skill(skillId), MaxSp)
		return ((cost + 1) / 2 if HalfSkillCost else cost)

	public def CanUseSkill(skillId as int) as bool:
		return false if skillId <= 0
		template = TBattleData.Skill(skillId)
		return false if template is null
		return false if self.Sp < SkillCostFor(skillId)
		restrictSkill = 11
		restrictMagic = 11
		for cond in ActiveConditions():
			restrictSkill = Math.Min(restrictSkill, cond.PhysCutoff) if cond.PhysBlock
			restrictMagic = Math.Min(restrictMagic, cond.MagicCutoff) if cond.MagicReflect
		normal = template as TNormalSkillTemplate
		if normal is not null:
			return false if restrictSkill <= normal.StrEffect or restrictMagic <= normal.MindEffect
			if IsHero and not normal.ResistMod:
				for id in range(1, TBattleData.AttributeCount + 1):
					if TBattleData.SkillHasAttribute(normal, id) and not TBattleData.IsMagicalAttribute(id) and not HasAttackAttribute(id):
						return false
		return TBattleData.SkillUsableInBattle(template)

	public def ResetAfterBattle():
		_action.Reset()
		AttackMod = 0
		DefenseMod = 0
		SpiritMod = 0
		AgilityMod = 0
		for id in range(1, _conditionAge.Length):
			if _conditionAge[id] > 0:
				cond = TBattleData.Condition(id)
				continue if cond.OutOfBattle and cond.HealTurnPercent < 1 //lasts past the battle
				RemoveCondition(id)
		Array.Clear(_attributeShift, 0, _attributeShift.Length)
		Charged = false

let MAX_STAT = 9999

class THeroUnit(TBattleUnit):

	[Getter(Hero)]
	private _hero as TRpgHero

	public def constructor(field as TBattleField, hero as TRpgHero):
		super(field)
		_hero = hero
		LoadConditions()

	public override Character as TRpgBattleCharacter:
		get: return _hero

	public override Name as string:
		get: return _hero.Name

	public Level as int:
		get: return _hero.Level

	public ID as int:
		get: return _hero.Template.ID

	public Template as THeroTemplate:
		get: return _hero.Template cast THeroTemplate

	protected override def GetCondition(id as int) as bool:
		return _hero.Condition[id]

	protected override def SetCondition(id as int, value as bool):
		_hero.Condition[id] = value

	//---- equipment

	public def Equipped(slot as int) as TEquipmentTemplate:
		id = _hero.Equipment[slot cast TSlot]
		return null if id <= 0
		return TBattleData.Item(id) as TEquipmentTemplate

	private def Weapon(slot as int) as TWeaponTemplate:
		return Equipped(slot) as TWeaponTemplate

	private def Armor(slot as int) as TArmorTemplate:
		return Equipped(slot) as TArmorTemplate

	protected override def BaseAttack() as int:
		return clamp(_hero.Attack, 1, MAX_BASE_STAT)

	protected override def BaseDefense() as int:
		return clamp(_hero.Defense, 1, MAX_BASE_STAT)

	protected override def BaseSpirit() as int:
		return clamp(_hero.Mind, 1, MAX_BASE_STAT)

	protected override def BaseAgility() as int:
		return clamp(_hero.Agility, 1, MAX_BASE_STAT)

	public override def BaseAttributeRank(id as int) as int:
		result = TBattleData.RankIn(Template.Resist, id, TBattleData.DefaultAttributeRank)
		for slot in range(5):
			armor = Armor(slot)
			if armor is not null and TBattleData.EquipmentHasAttribute(armor, id):
				++result
				break
		return clamp(result, 0, 4)

	public override def BaseConditionRank(id as int) as int:
		return TBattleData.RankIn(Template.Condition, id, TBattleData.DefaultHeroConditionRank)

	public override def HasAttackAttribute(id as int) as bool:
		for slot in range(2):
			weapon = Weapon(slot)
			return true if weapon is not null and TBattleData.EquipmentHasAttribute(weapon, id)
		return false

	public override def WeaponConditionChance(id as int) as int:
		result = 0
		for slot in range(2):
			weapon = Weapon(slot)
			if weapon is not null and TBattleData.EquipmentHasCondition(weapon, id):
				result = Math.Max(result, weapon.ConditionChance)
		return result

	public override def ArmorConditionChance(id as int) as int:
		result = 0
		for slot in range(5):
			armor = Armor(slot)
			result = 100 if armor is not null and TBattleData.EquipmentHasCondition(armor, id)
		return result

	public override CriticalChance as double:
		get:
			template = Template
			result = 0.0
			result = 100.0 / template.CritRate if template.CanCrit and template.CritRate > 0
			best = 0
			for slot in range(2):
				weapon = Weapon(slot)
				best = Math.Max(best, weapon.CritChance) if weapon is not null
			return result + best

	public override HitRate as int:
		get:
			result = -1
			for slot in range(2):
				weapon = Weapon(slot)
				result = Math.Max(result, weapon.ToHit) if weapon is not null
			return (90 if result == -1 else result)

	public override IsHero as bool:
		get: return true

	public override SuperGuard as bool:
		get: return Template.StrongDef

	public override Preemptive as bool:
		get: return AnyWeapon({w | w.Preemptive > 0})

	public override DualAttack as bool:
		get: return AnyWeapon({w | w.AttackTwice})

	public override AttackAll as bool:
		get: return AnyWeapon({w | w.AreaHit})

	public override IgnoreEvasion as bool:
		get: return AnyWeapon({w | w.Evasion})

	public override PreventCritical as bool:
		get: return AnyArmor({a | a.CritPrevent > 0})

	public override RaiseEvasion as bool:
		get: return AnyArmor({a | a.Evasion})

	public override HalfSkillCost as bool:
		get: return AnyArmor({a | a.MpReduction > 0})

	public NoTerrainDamage as bool:
		get: return AnyArmor({a | a.NoTerrainDamage})

	public override AttackCost as int:
		get:
			result = 0
			for slot in range(2):
				weapon = Weapon(slot)
				result += weapon.MpCost if weapon is not null
			return result

	private def AnyWeapon(test as Func[of TWeaponTemplate, bool]) as bool:
		for slot in range(5):
			weapon = Weapon(slot)
			return true if weapon is not null and test(weapon)
		return false

	private def AnyArmor(test as Func[of TArmorTemplate, bool]) as bool:
		for slot in range(5):
			armor = Armor(slot)
			return true if armor is not null and test(armor)
		return false

	//---- hero's capabilities

	public def KnownSkills() as (int):
		result = List[of int]()
		for id in range(1, GDatabase.value.Skill.Count + 1):
			result.Add(id) if _hero.Skill[id]
		return result.ToArray()

	public AutoBattler as bool:
		get: return _hero.AIControlled

	public SkillCommandName as string:
		get: return _hero.SkillCommand

	public CanChooseCommand as bool:
		get: return CanAct and not AutoBattler and not AttacksEnemies and not AttacksAllies

	public override def CanUseItem(id as int) as bool:
		return false if id <= 0
		item = TBattleData.Item(id)
		return false if item is null
		return false unless item isa TMedicineTemplate or TBattleData.ItemUsableBy(item, ID)
		return false unless TBattleData.ItemUsableInBattle(item)
		skillItem = item as TSkillItemTemplate
		return TBattleData.SkillUsableInBattle(TBattleData.Skill(skillItem.Skill)) if skillItem is not null
		return true

	public BattleAnimation as int:
		get:
			first = Weapon(0)
			return first.BattleAnim if first is not null
			second = Weapon(1)
			return second.BattleAnim if Template.DualWield == TWeaponStyle.Dual and second is not null
			return Template.UnarmedAnim

	public SecondWeaponAnimation as int:
		get:
			second = Weapon(1)
			return second.BattleAnim if Template.DualWield == TWeaponStyle.Dual and Weapon(0) is not null and second is not null
			return 0

	public def GainExp(amount as int, messages as TMessagePool):
		oldLevel = _hero.Level
		known = KnownSkills()
		_hero.Exp += amount
		return unless _hero.Level > oldLevel
		if _field.Party.LevelNotify:
			messages.AddWrapped(TBattleText.Say('Character-Level Up', Name, TBattleText.NoValue, _hero.Level.ToString(), \
					TBattleText.Vocab(V_STAT_LV)), MESSAGE_COLUMNS)
		for id in KnownSkills():
			continue if Array.IndexOf(known, id) >= 0
			if _field.Party.LevelNotify:
				messages.AddWrapped(TBattleText.Say('Character-Learned Skill', Name, TBattleData.Skill(id).Name), MESSAGE_COLUMNS)
		messages.AddBreak() if _field.Party.LevelNotify

	//---- resolve autobattle

	private def SkillTargetScore(skillId as int, target as TBattleUnit) as double:
		skill = TBattleData.NormalSkill(skillId)
		scope = TBattleData.SkillScope(skill)
		result = 0.0
		if scope in (TSkillScope.OneEnemy, TSkillScope.AllEnemies):
			if target.IsAlive and skill.HP:
				damage = SkillDamage(skillId, target)
				effective = Math.Min(damage, target.Hp)
				result = (effective cast double) / target.Hp
				result = 1.5 if result == 1.0
				result = Math.Max(0.0, result - (((skill.Cost cast double) / MaxSp) / 4.0)) if MaxSp > 0
				for monster in _field.Monsters:
					if monster.IsAlive:
						result = (result * 1.5) + 0.5 if monster == target
						break
		elif target.Hp == 0:
			result = ((skill.Base cast double) / 1000.0) + 1.0 if TBattleData.SkillHasCondition(skill, CTN_DEAD)
		elif skill.HP:
			damage = SkillDamage(skillId, target)
			effective = Math.Min(damage, target.MaxHp - target.Hp)
			result = (effective cast double) / target.MaxHp
			result = Math.Max(0.0, result - (((skill.Cost cast double) / MaxSp) / 8.0)) if MaxSp > 0
		return result

	private def SkillScore(skillId as int) as double:
		skill = TBattleData.NormalSkill(skillId)
		return 0.0 if skill is null or not CanUseSkill(skillId)
		result = 0.0
		caseOf TBattleData.SkillScope(skill):
			case TSkillScope.OneEnemy:
				for monster in _field.Monsters:
					result = Math.Max(result, SkillTargetScore(skillId, monster))
			case TSkillScope.AllEnemies:
				for monster in _field.Monsters:
					result += SkillTargetScore(skillId, monster)
			case TSkillScope.Self:
				result = SkillTargetScore(skillId, self)
			case TSkillScope.OneAlly:
				for hero in _field.Heroes:
					result = Math.Max(result, SkillTargetScore(skillId, hero))
			case TSkillScope.AllAllies:
				for hero in _field.Heroes:
					result += SkillTargetScore(skillId, hero)
		result += TBattleMath.Roll(100) / 100.0 if result > 0.0
		return result

	private def AttackTargetScore(target as TBattleUnit) as double:
		return 0.0 unless target.IsAlive
		damage = AttackDamage(target)
		result = (Math.Min(damage, target.Hp) cast double) / target.Hp
		result = 1.5 if result == 1.0
		for monster in _field.Monsters:
			if monster.IsAlive:
				result = (result * 1.5) + 0.5 if monster == target
				break
		result = (TBattleMath.Roll(100) / 100.0) + (result * 1.5) if result > 0.0
		return result

	private def AttackScore() as double:
		return _field.Monsters.Max(AttackTargetScore)

	public override def ChooseAction():
		action = self.Action
		action.Reset()
		unless CanAct:
			action.Kind = TBattleActionKind.Nothing
			return
		if AttacksEnemies:
			action.Kind = TBattleActionKind.Basic
			action.Basic = BasicAttack()
			action.Targets = TTargetKind.OneMonster
			action.Target = TBattleMath.Roll(_field.Monsters.Count)
			return
		if AttacksAllies:
			action.Kind = TBattleActionKind.Basic
			action.Basic = BasicAttack()
			action.Targets = TTargetKind.OneHero
			action.Target = TBattleMath.Roll(_field.Heroes.Count)
			return
		skills = KnownSkills()
		scores = array(double, skills.Length)
		best = 0.0
		for i in range(skills.Length):
			scores[i] = SkillScore(skills[i])
			best = Math.Max(best, scores[i])
		if AttackScore() < best:
			for i in range(skills.Length):
				if scores[i] == best:
					action.Kind = TBattleActionKind.Skill
					action.Skill = skills[i]
					break
		if action.Kind == TBattleActionKind.Skill:
			skill = TBattleData.NormalSkill(action.Skill)
			caseOf TBattleData.SkillScope(skill):
				case TSkillScope.OneEnemy:
					action.Targets = TTargetKind.OneMonster
					best = 0.0
					for i in range(_field.Monsters.Count):
						score = SkillTargetScore(action.Skill, _field.Monsters[i])
						if best < score:
							best = score
							action.Target = i
				case TSkillScope.AllEnemies:
					action.Targets = TTargetKind.AllMonsters
				case TSkillScope.Self:
					action.Targets = TTargetKind.OneHero
					for i in range(_field.Heroes.Count):
						action.Target = i if _field.Heroes[i] == self
				case TSkillScope.OneAlly:
					action.Targets = TTargetKind.OneHero
					best = 0.0
					for i in range(_field.Heroes.Count):
						score = SkillTargetScore(action.Skill, _field.Heroes[i])
						if best < score:
							best = score
							action.Target = i
				case TSkillScope.AllAllies:
					action.Targets = TTargetKind.AllHeroes
		else:
			action.Kind = TBattleActionKind.Basic
			action.Basic = BasicAttack()
			if AttackAll:
				action.Targets = TTargetKind.AllMonsters
			else:
				action.Targets = TTargetKind.OneMonster
				best = 0.0
				for i in range(_field.Monsters.Count):
					score = AttackTargetScore(_field.Monsters[i])
					if best < score:
						best = score
						action.Target = i

let MAX_BASE_STAT = 999
let MESSAGE_COLUMNS = 50

class TMonsterUnit(TBattleUnit):

	[Getter(Body)]
	private _body as TBattleMonster

	[Getter(Index)]
	private _index as int

	public def constructor(field as TBattleField, body as TBattleMonster, index as int):
		super(field)
		_body = body
		_index = index
		LoadConditions()

	public override Character as TRpgBattleCharacter:
		get: return _body

	public override Name as string:
		get: return _body.Name

	public Template as TRpgMonster:
		get: return _body.Monster

	protected override def GetCondition(id as int) as bool:
		return _body.Condition[id]

	protected override def SetCondition(id as int, value as bool):
		_body.Condition[id] = value

	protected override def BaseAttack() as int:
		return Math.Max(_body.Attack, 1)

	protected override def BaseDefense() as int:
		return Math.Max(_body.Defense, 1)

	protected override def BaseSpirit() as int:
		return Math.Max(_body.Mind, 1)

	protected override def BaseAgility() as int:
		return Math.Max(_body.Agility, 1)

	public override def BaseAttributeRank(id as int) as int:
		return TBattleData.RankIn(Template.Resist, id, TBattleData.DefaultAttributeRank)

	public override def BaseConditionRank(id as int) as int:
		return TBattleData.RankIn(Template.Condition, id, TBattleData.DefaultMonsterConditionRank)

	public override CriticalChance as double:
		get: return (100.0 / Template.CritChance if Template.CanCrit and Template.CritChance > 0 else 0.0)

	public override HitRate as int:
		get: return (70 if Template.OftenMiss else 90)

	public override IsHero as bool:
		get: return false

	public Exp as int:
		get: return Template.Exp

	public Gold as int:
		get: return Template.Money

	public DropItem as int:
		get: return Template.Item

	public DropChance as int:
		get: return Template.ItemChance

	//---- tactics

	private def PickLivingHero() as int:
		living = List[of int](_field.Heroes.Where({h | h.IsAlive}))
		return (living[TBattleMath.Roll(living.Count)] if living.Count > 0 else 0)

	private def IsSkillBehavior(behavior as TMonsterBehavior) as bool:
		return behavior.Skill > 0

	private def IsTransformBehavior(behavior as TMonsterBehavior) as bool:
		return behavior.Transform > 0 and behavior.Skill <= 0

	private def Applies(behavior as TMonsterBehavior) as bool:
		return true if behavior.Requirement is null and behavior.RequirementName is null
		_field.CurrentMonster = self
		try:
			return (behavior.Requirement() if behavior.Requirement is not null else BattleState.Evaluate(behavior.RequirementName, behavior.RequirementArgs))
		ensure:
			_field.CurrentMonster = null

	public override def ChooseAction():
		action = self.Action
		action.Reset()
		return unless CanAct
		if (not AttacksEnemies) and (not Charged):
			if AttacksAllies:
				action.Kind = TBattleActionKind.Basic
				action.Basic = TBasicAction.Attack
				action.Targets = TTargetKind.OneMonster
				action.Target = TBattleMath.Roll(_field.Monsters.Count)
				return
			behaviors = Template.Behavior
			return if behaviors is null or behaviors.Length == 0
			ratings = array(int, behaviors.Length)
			best = 0
			for i in range(behaviors.Length):
				behavior = behaviors[i]
				if Applies(behavior) and ((not IsSkillBehavior(behavior)) or CanUseSkill(behavior.Skill)):
					ratings[i] = behavior.Priority
					best = Math.Max(best, behavior.Priority)
			return if best == 0
			for i in range(ratings.Length):
				if ratings[i] > 0:
					ratings[i] = Math.Max(ratings[i] - (best - 10), 0)
			for i in range(ratings.Length):
				continue unless ratings[i] > 0 and IsSkillBehavior(behaviors[i])
				template = TBattleData.Skill(behaviors[i].Skill)
				continue unless TBattleData.SkillKind(template) == 0
				scope = TBattleData.SkillScope(template cast TNormalSkillTemplate)
				usable = true
				if scope == TSkillScope.Self:
					usable = SkillWorksOn(behaviors[i].Skill)
				elif scope in (TSkillScope.OneAlly, TSkillScope.AllAllies):
					usable = _field.Monsters.Any({m | m.SkillWorksOn(behaviors[i].Skill)})
				ratings[i] = 0 unless usable
			var sum = ratings.Sum()
			return if sum == 0
			pick = TBattleMath.Roll(sum)
			chosen = -1
			accumulated = 0
			for i in range(ratings.Length):
				if accumulated <= pick and pick < ratings[i] + accumulated:
					chosen = i
					break
				accumulated += ratings[i]
			return if chosen < 0
			chosenBehavior = behaviors[chosen]
			if IsSkillBehavior(chosenBehavior):
				action.Kind = TBattleActionKind.Skill
				action.Skill = chosenBehavior.Skill
				skill = TBattleData.Skill(action.Skill)
				if TBattleData.SkillKind(skill) == 0:
					caseOf TBattleData.SkillScope(skill cast TNormalSkillTemplate):
						case TSkillScope.OneEnemy:
							action.Targets = TTargetKind.OneHero
							action.Target = PickLivingHero()
						case TSkillScope.AllEnemies:
							action.Targets = TTargetKind.AllHeroes
						case TSkillScope.Self:
							action.Targets = TTargetKind.OneMonster
							action.Target = _index
						case TSkillScope.OneAlly:
							action.Targets = TTargetKind.OneMonster
							for tries in range(100):
								candidate = TBattleMath.Roll(_field.Monsters.Count)
								if _field.Monsters[candidate].SkillWorksOn(action.Skill):
									action.Target = candidate
									break
						case TSkillScope.AllAllies:
							action.Targets = TTargetKind.AllMonsters
			elif IsTransformBehavior(chosenBehavior):
				action.Kind = TBattleActionKind.Transform
				action.Transform = chosenBehavior.Transform
			else:
				action.Kind = TBattleActionKind.Basic
				action.Basic = cast(TBasicAction, ord(chosenBehavior.Action))
				if action.Basic in (TBasicAction.Attack, TBasicAction.DoubleAttack):
					action.Targets = TTargetKind.OneHero
					action.Target = PickLivingHero()
				action.Targets = TTargetKind.AllHeroes if action.Basic == TBasicAction.SelfDestruct
			action.SwitchOn = chosenBehavior.SwitchOn
			action.SwitchOff = chosenBehavior.SwitchOff
		else:
			action.Kind = TBattleActionKind.Basic
			action.Basic = TBasicAction.Attack
			action.Targets = TTargetKind.OneHero
			action.Target = PickLivingHero()
