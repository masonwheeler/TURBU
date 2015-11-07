namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMMonsterParty:
	hasID
	1    = Name('') as string
	2    = Monsters as (MonsterElement)
	3    = AutoAlign(false) as bool
	4    = HabitatCount(0) as int
	5    = Habitats as boolArray
	6    = Random(false) as bool
	0x0B = Events as (BattleEventPage)

LCFObject MonsterElement:
	hasID
	1 = Monster(1) as int
	2 = X as int
	3 = Y as int
	4 = Invisible(false) as bool

LCFObject BattleEventPage:
	hasID
	2    = Conditions as BattleEventConditions
	0x0B = CommandCount as int
	0x0C = Commands as EventCommand*

LCFObject BattleEventConditions:
	1    = Conditions as LCFWord
	2    = Switch1(1) as int
	3    = Switch2(1) as int
	4    = Variable(1) as int
	5    = VarValue(0) as int
	6    = TurnsMultiple(0) as int
	7    = TurnsConst(0) as int
	8    = ExhaustionMin(0) as int
	9    = ExhaustionMax(100) as int
	0x0A = MonsterHPID(0) as int
	0x0B = MonsterHPMin(0) as int
	0x0C = MonsterHPMax(100) as int
	0x0D = HeroHP(1) as int
	0x0E = HeroHPMin(0) as int
	0x0F = HeroHPMax(100) as int
	0x10 = MonsterTurnID(0) as int
	0x11 = MonsterTurnsMultiple(0) as int
	0x12 = MonsterTurnsConst(0) as int
	0x13 = HeroTurn(1) as int
	0x14 = HeroTurnsMultiple(0) as int
	0x15 = HeroTurnsConst(0) as int
	0x16 = HeroCommandWho(1) as int
	0x17 = HeroCommandWhich(1) as int
