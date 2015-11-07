namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMAnimation:
	hasID
	1    = Name('') as string
	2    = Filename('') as string
	3    = LargeAnim(false) as bool
//	skipSec 4
//	skipSec 5
	6    = Timing as (AnimEffects)
	9    = HitsAll as bool
	0x0A = YTarget as int
	0x0C = Frames as (AnimFrame)

LCFObject AnimFrame:
	hasID
	1 = Cells as (AnimCell)

LCFObject AnimCell:
	hasID
	1    = IsNew(true) as bool
	2    = Index(0) as int
	3    = X(0) as int
	4    = Y(0) as int
	5    = Zoom(100) as int
	6    = Red(100) as int
	7    = Green(100) as int
	8    = Blue(100) as int
	9    = Sat(100) as int
	0x0A = Transparency(0) as int

LCFObject AnimEffects:
	hasID
	1 = Frame as int
	2 = Sound as RMMusic
	3 = FlashWhere as int
	4 = Red(31) as int
	5 = Green(31) as int
	6 = Blue(31) as int
	7 = Power(31) as int
	8 = ShakeWhere(0) as int
