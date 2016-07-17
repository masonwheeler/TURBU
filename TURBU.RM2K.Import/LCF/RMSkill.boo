namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMSkill:
	hasID
	1    = Name('') as string
	2    = Desc('') as string
	3    = Usage('') as string
	4    = Usage2('') as string
	7    = Failure(-1) as int
	8    = SkillType as int
	9    = UsesPercentCost(false) as bool
	0x0A = PercentCost(0) as int
	0x0B = Cost(0) as int
	0x0C = Range as int
	0x0D = Switch(0) as int
	0x0E = Anim(0) as int
	0x10 = Sfx as RMMusic
	0x12 = Field(true) as bool
	0x13 = Battle(false) as bool
	0x14 = InflictReversed(false) as bool
	0x15 = StrengthBase(0) as int
	0x16 = MindBase(3) as int
	0x17 = Variance(4) as int
	0x18 = Base(0) as int
	0x19 = SuccessRate(100) as int
	0x1F = HP(false) as bool
	0x20 = MP(false) as bool
	0x21 = Attack(false) as bool
	0x22 = Defense(false) as bool
	0x23 = Mind(false) as bool
	0x24 = Speed(false) as bool
	0x25 = Vampire(false) as bool
	0x26 = Phased(false) as bool
	0x29 = ConditionCount(0) as int
	0x2A = Conditions as boolArray
	0x2B = AttributeCount(0) as int
	0x2C = Attributes as boolArray
	0x2D = ResistMod(false) as bool
	0x31 = DisplaySprite(1) as int
	0x32 = Animations as (RMBattleSkillAnim)

LCFObject RMBattleSkillAnim:
	hasID
	5    = Movement(0) as int
	6    = Afterimage(false) as bool
	0x0E = Animation(3) as int