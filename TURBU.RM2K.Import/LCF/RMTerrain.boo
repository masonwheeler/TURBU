namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMTerrain:
	hasID
	1    = Name('') as string
	2    = Damage(0) as int
	3    = EncounterMultiplier(100) as int
	4    = BattleBG('') as string
	5    = BoatPass(false) as bool
	6    = ShipPass(false) as bool
	7    = AirshipPass(true) as bool
	9    = AirshipLanding(true) as bool
	0x0B = Concealment as int
	0x0F = SoundEffect as RMMusic
	0x10 = DamageSound(false) as bool
	0x11 = BGAssociation(0) as int
	0x15 = Frame1('') as string
	0x16 = Frame1ScrollX(false) as bool
	0x17 = Frame1ScrollY(false) as bool
	0x18 = Frame1ScrollXSpeed(0) as int
	0x19 = Frame1ScrollYSpeed(0) as int
	0x1E = UseFrame2(false) as bool
	0x1F = Frame2('') as string
	0x20 = Frame2ScrollX(false) as bool
	0x21 = Frame2ScrollY(false) as bool
	0x22 = Frame2ScrollXSpeed(0) as int
	0x23 = Frame2ScrollYSpeed(0) as int
	0x28 = SpecialFlags(0) as int
	0x29 = Initiative(15) as int
	0x2A = BackAttack(10) as int
	0x2B = SideAttack(10) as int
	0x2C = PincerAttack(5) as int
	0x2D = GridPosition(0) as int
	0x2E = GridValue1(0) as int
	0x2F = GridValue2(0) as int
	0x30 = GridValue3(0) as int
