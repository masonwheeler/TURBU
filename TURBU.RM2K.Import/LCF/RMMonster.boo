namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMMonster:
	hasID
	1    = Name('') as string
	2    = Filename('') as string
	3    = ColorShift(0) as int
	4    = HP(10) as int
	5    = MP(10) as int
	6    = Attack(10) as int
	7    = Defense(10) as int
	8    = Mind(10) as int
	9    = Speed(10) as int
	0x0A = Transparent(false) as bool
	0x0B = Exp(0) as int
	0x0C = Money(0) as int
	0x0D = Item(0) as int
	0x0E = ItemChance(100) as int
	0x15 = CanCrit(false) as bool
	0x16 = CritChance(30) as int
	0x1A = OftenMiss(false) as bool
	0x1C = Flying(false) as bool
	0x1F = ConditionCount(0) as int
	0x20 = ConditionModifiers as byteArray
	0x21 = DTypeCount(0) as int
	0x22 = DTypeModifiers as byteArray
	0x2A = Behavior as (MonsterBehavior)

LCFObject MonsterBehavior:
	hasID
	1    = Action as int
	2    = Basic as int
	3    = Skill(1) as int
	4    = Transform(1) as int
	5    = Precondition as int
	6    = PreconditionP1(0) as int
	7    = PreconditionP2(0) as int
	8    = PreconditionSwitch(1) as int
	9    = SwitchOn(false) as bool
	0x0A = SwitchOnID(1) as int
	0x0B = SwitchOff(false) as bool
	0x0C = SwitchOffID(1) as int
	0x0D = Priority(50) as int
