namespace turbu.map.metadata

import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable

import Boo.Adt
import HighEnergy.Collections
import Newtonsoft.Json.Linq
import Pythia.Runtime
import SG.defs
import turbu.classes
import turbu.defs
import TURBU.MapInterface
import turbu.sounds

enum TInheritedDecision:
	Parent
	No
	Yes

class TMapRegion(TRpgDatafile):

	def constructor():
		super()

	def constructor(value as JObject, inherited as bool):
		super(value)
		value.CheckRead('EncounterScript', FEncounterScript)
		value.ReadArray('EncounterParams', FEncounterParams)
		value.ReadArray('Battles', FBattles)
		bounds as (int)
		if value.ReadArray('Bounds', bounds):
			assert bounds.Length == 4
			FBounds = SDL2.SDL.SDL_Rect(bounds[0], bounds[1], bounds[2], bounds[3])
		value.CheckEmpty() unless inherited

	[Property(Bounds)]
	private FBounds as SDL2.SDL.SDL_Rect

	[Property(EncounterScript)]
	private FEncounterScript as string

	private def GetBattleCount() as int:
		return FBattles.Length

	[Property(Battles)]
	protected FBattles = array(int, 0)

	[Property(EncounterParams)]
	private FEncounterParams as (int)

	public BattleCount as int:
		get:
			return GetBattleCount()

class TMapMetadata(TMapRegion, IMapMetadata):

	internal static FOwner as TMapTree

	private FParent as int

	[Property(ScrollPosition)]
	private FScrollPosition as TSgPoint

	[Property(TreeOpen)]
	private FTreeOpen as bool

	[Property(BgmState)]
	private FBgmState as TInheritedDecision

	[Property(BgmData)]
	private FBgmData = TRpgMusic()

	[Property(BattleBgState)]
	private FBattleBgState as TInheritedDecision

	[Property(BattleBgName)]
	private FBattleBgName as string

	[Property(CanPort)]
	private FCanPort as TInheritedDecision

	[Property(CanEscape)]
	private FCanEscape as TInheritedDecision

	[Property(CanSave)]
	private FCanSave as TInheritedDecision

	public InternalFilename:
		get:
			invalidChars = Path.GetInvalidFileNameChars()
			return string("$(Name)_$ID".Where({x | not invalidChars.Contains(x)}).ToArray())

	private FMapEngine as int

	private def SetParent(Value as int):
		FParent = Value
		FOwner.NotifyMoved(self)

	[Property(Regions)]
	protected FRegions = TRpgDataList[of TMapRegion]()

	public def constructor():
		super()
	
	public def constructor(value as JObject):
		super(value, true)
		value.CheckRead('TreeOpen', FTreeOpen)
		value.CheckRead('Parent', FParent)
		me as string
		value.CheckRead('MapEngine', me)
		self.MapEngine = me if assigned(me)
		value.CheckRead('ScrollPosition', FScrollPosition)
		song as JArray = value['Song']
		if assigned(song):
			value.Remove('Song')
			FBgmData = TRpgMusic(song)
		value.CheckReadEnum('BgmState', FBgmState)
		value.CheckReadEnum('BattleBgState', FBattleBgState)
		value.CheckReadEnum('CanPort', FCanPort)
		value.CheckReadEnum('CanEscape', FCanEscape)
		value.CheckReadEnum('CanSave', FCanSave)
		value.CheckRead('BattleBgName', FBattleBgName)
		regions as JArray = value['Regions']
		if assigned(regions):
			value.Remove('Regions')
			for rgn as JObject in regions:
				FRegions.Add(TMapRegion(rgn, false))
		value.CheckEmpty()

	public Parent as int:
		get:
			return FParent
		set:
			SetParent(value)

	public MapEngine as string:
		get: return FOwner.MapEngines[FMapEngine]
		set:
			FMapEngine = FOwner.MapEngines.IndexOf(value)
			assert FMapEngine != -1

[TableName('MapTree')]
class TMapTree(TRpgDatafile, IMapTree):

	[Getter(CurrentMap)]
	private FCurrentMap as int

	private FTree as TreeNode[of TMapMetadata]

	private FLoaded as bool

	private def getLookupCount() as int:
		return FTranslationTable.Count

	private def GetNewID() as short:
		found as (bool)
		enumerator as TreeNode[of TMapMetadata]
		data as TMapMetadata
		i as int
		Array.Resize[of bool](found, (self.Count + 1))
		for enumerator in FTranslationTable.Values:
			data = enumerator.Value
			continue if data.ID >= found.Length
			found[enumerator.Value.ID] = true
		for i in range(found.Length):
			return i unless found[i]
		raise Exception('New ID not available')

	internal def NotifyMoved(map as TMapMetadata):
		if not FLoaded:
			return
		node as TreeNode[of TMapMetadata] = FTranslationTable[map.ID]
		return if node.Parent.Value.ID == map.Parent
		node.Parent = FTranslationTable[map.Parent]

	private def GetEnumeratorI() as IEnumerator[of IMapMetadata]:
		return FTranslationTable.Values.Select({n | n.Value})

	def Get(x as int) as IMapMetadata:
		return self.lookup[x]

	private def GetCount() as int:
		return FTranslationTable.Count

	private def AddLookup(value as TMapMetadata) as TreeNode[of TMapMetadata]:
		result = TreeNode[of TMapMetadata](value)
		FTranslationTable.Add(value.ID, result)
		return result

	def System.Collections.IEnumerable.GetEnumerator():
		return GetEnumeratorI()

	[Getter(Location)]
	protected FStartLocs = Dictionary[of int, TLocation]()

	protected FTranslationTable = Dictionary[of short, TreeNode[of TMapMetadata]]()

	[Getter(MapEngines)]
	private FMapEngines = List[of string]()

	public def constructor():
		super()
		TMapMetadata.FOwner = self

	public def constructor(value as JObject):
		self()
		en as (string)
		assert value.ReadArray('MapEngines', en)
		FMapEngines.AddRange(en)
		elements as JArray = value['Elements']
		value.Remove('Elements')
		for elem in elements:
			Add(TMapMetadata(elem))
		value.CheckRead('CurrentMap', FCurrentMap)
		elements = value['StartPoints'] cast JArray
		value.Remove('StartPoints')
		for i in range(elements.Count):
			var loc = elements[i] cast JArray
			FStartLocs.Add(i, TLocation(loc[0] cast int, loc[1] cast int, loc[2] cast int))
		value.CheckEmpty()

	public def Add(value as TMapMetadata):
		parent as TreeNode[of TMapMetadata]
		if self.Count == 0:
			assert value.ID == 0
			assert FTree == null
			FTree = AddLookup(value)
		else:
			assert FTranslationTable.ContainsKey(value.ID) == false
			parent = FTranslationTable[value.Parent]
			parent.Children.Add(AddLookup(value))

	public def Remove(value as TMapMetadata):
		node as TreeNode[of TMapMetadata]
		id as short
		id = value.ID
		node = FTranslationTable[id]
		if (node.Children.Count > 0):
			raise "Can't delete a map tree node with children"
		FTranslationTable.Remove(id)
		if assigned(node.Parent):
			node.Parent.Children.Remove(node)

	public def ContainsMap(id as int) as bool:
		return FTranslationTable.ContainsKey(id)

	public def ChildrenOf(id as short) as List[of TMapMetadata]:
		node as TreeNode[of TMapMetadata]
		list as TreeNodeList[of TMapMetadata]
		node = FTranslationTable[id]
		result = List[of TMapMetadata]()
		list = node.Children
		result.Capacity = list.Count
		for node in list:
			result.Add(node.Value)
		return result

	public def AddNewMetadata(parent as short) as TMapMetadata:
		result = TMapMetadata()
		result.Name = 'NEW MAP'
		result.ID = GetNewID()
		result.Parent = parent
		self.Add(result)
		return result

	public def GetEnumerator() as IEnumerator[of IMapMetadata]:
		return GetEnumeratorI()

	public lookup[x as short] as TMapMetadata:
		get: return FTranslationTable[x].Value
		set: FTranslationTable[x].Value = value

	public self[x as int] as IMapMetadata:
		get: return lookup[x]

	public lookupCount as int:
		get:
			return getLookupCount()

	public Count as int:
		get:
			return GetCount()

let HERO_START_LOCATION = 0
let BOAT_START_LOCATION = 1
let SHIP_START_LOCATION = 2
let AIRSHIP_START_LOCATION = 3
