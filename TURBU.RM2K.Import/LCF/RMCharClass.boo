namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMCharClass:
	hasID
	1    = Name as string
	4    = SpriteIndex(1) as int
	0x15 = DualWield(false) as bool
	0x16 = StaticEq(false) as bool
	0x17 = ComputerControlled(false) as bool
	0x18 = StrongDefense(false) as bool
	0x1F = StatSection as wordArray
	0x29 = ExpStandard(30) as int
	0x2A = ExpAddition(30) as int
	0x2B = ExpCorrection as int
	//??? Duplicate assignment here in RM
	//0x3E = GraphicIndex as int 
	skipSec 0x3E
	0x3F = SkillSection as (HeroSkillRecord)
	skipSec 0x47
	0x48 = ConditionModifiers as byteArray
	skipSec 0x49
	0x4A = DTypeModifiers as byteArray
	0x50 = BattleCommands as intArray
