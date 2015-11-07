namespace TURBU.RM2K.Import.LCF

import System

LCFObject RM2K3AttackAnimation:
	hasID
	1    = Name as string
	2    = Speed(20) as int
	0x0A = Poses as (RM2K3AttackData)
	0x0B = Weapons as (RM2K3AttackData)

LCFObject RM2K3AttackData:
	hasID
	1 = Name('') as string
	2 = Filename('') as string
	3 = Frame(0) as int
	4 = AnimType(0) as int
	5 = AnimNum(0) as int
