namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMTileset:
	hasID
	1    = Name as string
	2    = Filename as string
	3    = Terrain(null) as wordArray
	4    = BlockData(null) as byteArray
	5    = UBlockData(null) as byteArray
	0x0B = Animation(false) as bool
	0x0C = HighSpeed(false) as bool
