namespace turbu.tilesets

import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Runtime.InteropServices
import Newtonsoft.Json.Linq
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

[StructLayoutAttribute(LayoutKind.Explicit)]
struct TTileRef:

	[FieldOffset(0)]
	Value as short

	[FieldOffset(1)]
	Group as byte

	[FieldOffset(0)]
	Tile as byte

	def constructor(value as short):
		Value = value
	
	override def ToString():
		return "TTileRef(Value: $Value, Group: $Group, Tile: $Tile)"

[TableName('TileGroups')]
class TTileGroup(TRpgDatafile):

	[Getter(LinkedFilename)]
	private FLinkedFilename = ''

	[Getter(Ocean)]
	private FOcean as bool

	[Getter(TileType)]
	private FTileType as TTileType

	[Getter(Dimensions)]
	private FDimensions as TSgPoint

	public Filename as string:
		get: return FName
		set: FName = value
	
	def constructor():
		super()
	
	def constructor(obj as JObject):
		super(obj)
		obj.CheckRead('LinkedFilename', self.FLinkedFilename)
		subtypes as (string)
		if obj.ReadArray('TileType', subtypes):
			for subtype in subtypes:
				FTileType |= Enum.Parse(TTileType, subtype) cast TTileType
		obj.CheckRead('Ocean', self.FOcean)
		obj.CheckRead('Dimensions', FDimensions)
		fn as string
		obj.CheckRead('Filename', fn) //this can be safely discarded
		obj.CheckEmpty()

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

	public HasTerrain as bool:
		get: return FTerrain.Count > 0

	public def constructor():
		super()
		FAttributes.Capacity = 32
		FTerrain.Capacity = 32

	public def constructor(value as JObject):
		super(value)
		value.ReadArray('Layers', FLayers)
		terrains as (int)
		value.ReadArray('Terrain', terrains)
		FTerrain.AddRange(terrains) if terrains is not null
		gname as string
		value.CheckRead('GroupName', gname)
		GroupName = gname
		value.CheckReadEnum('AnimDir', FAnimDir)
		var attribs = value['Attributes'] cast JArray
		value.Remove('Attributes')
		for attr in attribs.Cast[of JArray]():
			var attrValue = TTileAttribute.None
			for attrName in attr:
				attrValue |= Enum.Parse(TTileAttribute, attrName cast string) cast TTileAttribute
			FAttributes.Add(attrValue)
		value.CheckEmpty()

	public GroupName as string:
		get: return (FGroup.Name if assigned(FGroup) else '')
		set: FGroup = LookupGroup(value)
	
	public static LookupGroup as Func[of string, TTileGroup]

[TableName('Tilesets')]
class TTileSet(TRpgDatafile):

	[Property(Records)]
	private FRecords = TRpgObjectList[of TTileGroupRecord](Capacity: 32)

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

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('HighSpeed', FHighSpeed)
		var recs = value['Records'] cast JArray
		value.Remove('Records')
		for rec in recs:
			FRecords.Add(TTileGroupRecord(rec))
		value.CheckEmpty()

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
