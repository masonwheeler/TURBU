namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMSystemRecord:
	0x0A = RMVersion(2000) as int
	0x0B = BoatGraphic as string
	0x0C = ShipGraphic as string
	0x0D = AirshipGraphic as string
	0x0E = BoatIndex(0) as int
	0x0F = ShipIndex as int
	0x10 = AirshipIndex as int
	0x11 = TitleScreen as string
	0x12 = GameOverScreen as string
	0x13 = SystemGraphic as string
	0x14 = BattleSysGraphic as string
	0x15 = StartingHeroes(1) as int
	0x16 = StartingHero as wordArray
	0x1A = CommandCount as int
	0x1B = Commands as wordArray
	0x1F = TitleMusic as RMMusic
	0x20 = BattleMusic as RMMusic
	0x21 = VictoryMusic as RMMusic
	0x22 = InnMusic as RMMusic
	0x23 = BoatMusic as RMMusic
	0x24 = ShipMusic as RMMusic
	0x25 = AirshipMusic as RMMusic
	0x26 = GameOverMusic as RMMusic
	0x29 = CursorSound as RMMusic
	0x2A = AcceptSound as RMMusic
	0x2B = CancelSound as RMMusic
	0x2C = BuzzerSound as RMMusic
	0x2D = BattleStartSound as RMMusic
	0x2E = EscapeSound as RMMusic
	0x2F = EnemyAttackSound as RMMusic
	0x30 = EnemyDamageSound as RMMusic
	0x31 = AllyDamageSound as RMMusic
	0x32 = EvadeSound as RMMusic
	0x33 = EnemyDiesSound as RMMusic
	0x34 = ItemUsedSound as RMMusic
	0x3D = MapExitTransition as int
	0x3E = MapEnterTransition as int
	0x3F = BattleStartEraseTransition as int
	0x40 = BattleStartShowTransition as int
	0x41 = BattleEndEraseTransition as int
	0x42 = BattleEndShowTransition as int
	0x47 = WallpaperTiled(false) as bool
	0x48 = WhichFont as int
	0x51 = EditorCondition(0) as int
	0x52 = Hero as int
	0x54 = EditorBattleTestBG as string
	0x55 = BattleTestData as (RMBattleTest)
	0x5B = SaveCount as int
	0x5E = BattleTestTerrain(0) as int
	0x5F = BattleTestFormation(0) as int
	0x60 = BattleTestSpecialCondition as int
	skipSec range(0x61, 0x62)
	0x63 = UsesFrame(false) as bool
	0x64 = Frame('') as string
	0x65 = ReverseGraphics as bool

LCFObject RMBattleTest:
	hasID
	1    = HeroID(1) as int
	2    = Level(1) as int
	0x0B = WeaponID(0) as int
	0x0C = ShieldID(0) as int
	0x0D = ArmorID(0) as int
	0x0E = HelmetID(0) as int
	0x0F = RelicID(0) as int
