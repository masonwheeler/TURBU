namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMItem:
	hasID
	1    = Name('') as string
	2    = Desc('') as string
	3    = ItemType as int
	5    = Price(0) as int
	6    = Uses(1) as int
	0x0B = AttackModify(0) as int
	0x0C = DefenseModify(0) as int
	0x0D = MindModify(0) as int
	0x0E = SpeedModify(0) as int
	0x0F = TwoHanded(false) as bool
	0x10 = MPCost(0) as int
	0x11 = ToHit(90) as int
	0x12 = CritChance(0) as int
	0x14 = BattleAnim(1) as int
	0x15 = Preemptive(false) as bool
	0x16 = AttackTwice(false) as bool
	0x17 = AreaHit(false) as bool
	0x18 = IgnoreEvasion(false) as bool
	0x19 = PreventCrits(false) as bool
	0x1A = BoostEvade(false) as bool
	0x1B = HalfMP(false) as bool
	0x1C = NoTerrainDamage(false) as bool
	0x1D = Cursed(false) as bool
	0x1F = AreaMedicine as bool
	0x20 = HPPercent(0) as int
	0x21 = HPHeal(0) as int
	0x22 = MPPercent(0) as int
	0x23 = MPHeal(0) as int
	0x25 = OutOfBattleOnly(false) as bool
	0x26 = DeadHeroesOnly(false) as bool
	0x29 = PermHPGain(0) as int
	0x2A = PermMPGain(0) as int
	0x2B = PermAttackGain(0) as int
	0x2C = PermDefenseGain(0) as int
	0x2D = PermMindGain(0) as int
	0x2E = PermSpeedGain(0) as int
	0x33 = DisplaySkillMessage as bool
	0x35 = SkillToLearn(0) as int
	0x37 = Switch(0) as int
	0x39 = OnField(false) as bool
	0x3A = InBattle(false) as bool
	0x3D = UsableCount(0) as int
	0x3E = UsableBy as boolArray
	0x3F = ConditionCount(0) as int
	0x40 = Conditions as boolArray
	0x41 = AttributeCount(0) as int
	0x42 = Attributes as boolArray
	0x43 = ConditionInflictChance(0) as int
	0x44 = InflictReversed(false) as bool
	0x45 = WeaponAnimation(1) as int
	0x46 = AnimData as (ItemAnimData)
	0x47 = InvokeSkill(false) as bool
	0x48 = UsableClassCount(0) as int
	0x49 = UsableByClass as boolArray
	0x4B = RangedTrajectory(0) as int
	0x4C = RangedTarget(0) as int

LCFObject ItemAnimData:
	hasID
	3    = AnimType(0) as int
	4    = WhichWeapon(0) as int
	5    = MovementMode(0) as int
	6    = Afterimage(false) as bool
	7    = AttackNum(0) as int
	8    = Ranged(false) as bool
	9    = RangedProjectile(0) as int
	0x0C = RangedSpeed(0) as int
	0x0D = BattleAnim(0) as int
