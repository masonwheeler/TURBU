namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMHero:
	hasID
	1    = Name('') as string
	2    = Class('') as string
	3    = Sprite('') as string
	4    = SpriteIndex(0) as int
	5    = Transparent(false) as bool
	7    = StartLevel(1) as int
	8    = MaxLevel(99) as int
	9    = CanCrit(true) as bool
	0x0A = CritRate(30) as int
	0x0F = Portrait('') as string
	0x10 = PortraitIndex(0) as int
	0x15 = DualWield(false) as bool
	0x16 = StaticEq(false) as bool
	0x17 = ComputerControlled(false) as bool
	0x18 = StrongDefense(false) as bool
	0x1F = StatSection as wordArray
	0x29 = ExpStandard(30) as int
	0x2A = ExpAddition(30) as int
	0x2B = ExpCorrection(0) as int
	0x33 = InitialEq as wordArray
	0x38 = UnarmedAnim(1) as int
	0x39 = ClassNum(0) as int
	0x3B = BattleX as int
	0x3C = BattleY(0) as int
	0x3E = BattleChar(0) as int
	0x3F = SkillSection as (HeroSkillRecord)
	0x42 = SkillRenamed(false) as bool
	0x43 = SkillCategoryName('') as string
	skipSec 0x47
	0x48 = ConditionModifiers as byteArray
	skipSec 0x49
	0x4A = DTypeModifiers as byteArray
	0x50 = BattleCommands as intArray

LCFObject HeroSkillRecord:
	hasID
	1 = Level(1) as int
	2 = Skill(1) as int