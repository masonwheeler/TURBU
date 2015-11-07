namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMAttribute:
	hasID
	1    = Name('') as string
	2    = MagicAttribute as bool
	0x0B = RateA(300) as int
	0x0C = RateB(200) as int
	0x0D = RateC(100) as int
	0x0E = RateD(50) as int
	0x0F = RateE(0) as int
