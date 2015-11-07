namespace turbu.tilesets

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Pythia.Runtime
import sdl.sprite
import SG.defs
//import TURBU.RM2K
import turbu.classes
import turbu.containers
import turbu.defs

[EnumSet]
enum TTileType:
	None = 0
	Bordered = 1
	Animated = 2

[EnumSet]
enum TTileAttribute:
	None
	Up = 1
	Down = 2
	Left = 4
	Right = 8
	Ceiling = 0x10
	Overhang = 0x20
	Countertop = 0x40

struct TTileRef:

	[System.Runtime.InteropServices.FieldOffset(0)]
	Value as short

	[System.Runtime.InteropServices.FieldOffset(0)]
	Group as byte

	[System.Runtime.InteropServices.FieldOffset(1)]
	Tile as byte

	def constructor(value as short):
		Value = value

[TableName('TileGroups')]
class TTileGroup(TRpgDatafile):

	[Property(LinkedFilename)]
	private FLinkedFileName as string

	[Property(Ocean)]
	private FOcean as bool

	[Property(TileType)]
	private FTileType as TTileType

	[Property(Dimensions)]
	private FDimensions as TSgPoint

	public Filename as string:
		get: return FName
		set: FName = value

class TTileGroupRecord(TRpgDatafile):

	[Property(Layers)]
	private FLayers = array(int, 0)

	[Property(Group)]
	private FGroup = TTileGroup()

	[Property(AnimDir)]
	private FAnimDir as TAnimPlayMode

	[Property(Attributes)]
	private FAttributes = List[of TTileAttribute]()

	[Property(Terrain)]
	private FTerrain = List[of int]()

	public def constructor():
		super()
		FAttributes.Capacity = 32
		FTerrain.Capacity = 32
	
	public GroupName as string:
		get: return (FGroup.Name if assigned(FGroup) else '')
		set: FGroup = LookupGroup(value)
	
	public static LookupGroup as Func[of string, TTileGroup]

[TableName('Tilesets')]
class TTileSet(TRpgDatafile):

	[Property(Records)]
	private FRecords = TRpgObjectList[of TTileGroupRecord]()

	[Property(HighSpeed)]
	private FHighSpeed as bool

	private FGroupMap = array(List[of byte], 8)

	private def TileCount(value as TTileGroupRecord) as byte:
		if TTileType.Bordered in value.Group.TileType:
			return 1
		elif TTileType.Animated in value.Group.TileType:
			return 3
		else: return 48

	protected def BuildGroupMap():
		for i in range(1, FRecords.Count):
			for j in range(1, TileCount(FRecords[i]) + 1):
				for layer in FRecords[i].Layers:
					FGroupMap[layer].Add(i)

	public def constructor():
		super()
		for i in range(8):
			FGroupMap[i] = List[of byte]()
			FGroupMap[i].Capacity = 256
		FRecords.Capacity = 32

	public def Tile(index as int, layer as byte) as TTileRef:
		result as TTileRef
		result.Group = FGroupMap[layer][index]
		result.Tile = 0
		--index
		while (index >= 0) and (FGroupMap[layer][index] == result.Group):
			++result.Tile
			--index
		return result

def UpperLayerFilter(value as TTileGroupRecord) as bool:
	return value.Layers.Where({b | b != 0}).Any()
