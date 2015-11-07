namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMCondition:
	hasID
	1    = Name('') as string
	2    = LastsOutsideBattle as bool
	3    = Color(6) as int
	4    = Priority(50) as int
	5    = Limitation as int
	0x0B = RateA(100) as int
	0x0C = RateB(80) as int
	0x0D = RateC(60) as int
	0x0E = RateD(30) as int
	0x0F = RateE(0) as int
	0x15 = HealTurns(0) as int
	0x16 = HealPercent(0) as int
	0x17 = HealShock(0) as int
	0x1E = StatEffect(0) as int
	0x1F = AttackStat(false) as bool
	0x20 = DefenseStat(false) as bool
	0x21 = MindStat(false) as bool
	0x22 = SpeedStat(false) as bool
	0x23 = ToHitChange(100) as int
	0x24 = Evade(false) as bool
	0x25 = Reflect(false) as bool
	0x26 = EqLock(false) as bool
	0x27 = StatusAnimation(6) as int
	0x29 = PhysBlock(false) as bool
	0x2A = PhysCutoff(0) as int
	0x2B = MagBlock(false) as bool
	0x2C = MagCutoff(0) as int
	0x2D = HpDot(0) as int
	0x2E = MpDot(0) as int
	0x33 = CondMessage1('') as string
	0x34 = CondMessage2('') as string
	0x35 = CondMessage3('') as string
	0x36 = CondMessage4('') as string
	0x37 = CondMessage5('') as string
	0x3D = HpTurnPercent(0) as int
	0x3E = HpTurnFixed(0) as int
	0x3F = HpStepCount(0) as int
	0x40 = HpStepQuantity(0) as int
	0x41 = MpTurnPercent(0) as int
	0x42 = MpTurnFixed(0) as int
	0x43 = MpStepCount(0) as int
	0x44 = MpStepQuantity(0) as int
