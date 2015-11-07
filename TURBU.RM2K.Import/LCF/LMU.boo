namespace TURBU.RM2K.Import.LCF

import System

LCFObject LMU:
	header 'LcfMapUnit'
	1    = Terrain(1) as int
	2    = Width(20) as int
	3    = Height(15) as int
	0x0B = Wraparound as int
	0x1F = UsesPano(false) as bool
	0x20 = PanoName('') as string
	0x21 = HPan(false) as bool
	0x22 = VPan(false) as bool
	0x23 = HPanAutoscroll(false) as bool
	0x24 = HPanSpeed(0) as int
	0x25 = VPanAutoscroll(false) as bool
	0x26 = VPanSpeed(0) as int
	0x28 = UseGenerator(false) as bool
	0x29 = GeneratorStyle(0) as int
	skipSec 0x2A
	0x30 = GeneratorGranularity(0) as int
	0x31 = GeneratorRoomWidth(0) as int
	0x32 = GeneratorRoomHeight as int
	0x33 = GeneratorSurround(false) as bool
	0x34 = GeneratorUseUpperWall(false) as bool
	0x35 = GeneratorUseFloorB(false) as bool
	0x36 = GeneratorUseFloorC(false) as bool
	0x37 = GeneratorUseObstacleB(false) as bool
	0x38 = GeneratorUseObstacleC(false) as bool
	skipSec range(0x3C, 0x3E)
	0x47 = LowChip as wordArray
	0x48 = HighChip as wordArray
	0x51 = Events as (MapEvent)
	0x5b = Modified as int