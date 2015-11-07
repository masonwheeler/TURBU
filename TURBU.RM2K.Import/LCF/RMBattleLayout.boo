namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMBattleLayout:
	2    = AutoLineup(false) as bool
	4    = DeathEvent(false) as bool
	6    = Row(0) as int
	7    = BattleStyle as int
	9    = CommandCount(0) as int
	0x0A = Commands as (BattleCommand)
	0x0F = UsesDeathEventHandler(false) as bool
	0x10 = DeathEventHandler as int
	0x14 = SmallWindowSize as bool
	0x18 = WindowTrans as bool
	0x19 = TeleportOnDeath(false) as bool
	0x1A = EscapeMap(0) as int
	0x1B = EscapeX(0) as int
	0x1C = EscapeY(0) as int
	0x1D = EscapeFacing(0) as int

LCFObject BattleCommand:
	hasID
	1 = Name as string
	2 = Style(0) as int