namespace turbu.map.metadata

import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable
import Boo.Adt
import HighEnergy.Collections
import Pythia.Runtime
//import SDL2.SDL
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

	[Property(Bounds)]
	private FBounds as SDL2.SDL.SDL_Rect

	[Property(EncounterScript)]
	private FEncounterScript as string

	private def GetBattleCount() as int:
		return FBattles.Length

	[Property(Battles)]
	protected FBattles = array(int, 0)

	[Property(EncounterParams)]
	protected FEncounters as (int)

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
	private FBattleBGName as string

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

	def GetParent() as int:
		return FParent

	def GetTreeOpen() as bool:
		return FTreeOpen

	private def SetParent(Value as int):
		FParent = Value
		FOwner.NotifyMoved(self)

	[Property(Regions)]
	protected FRegions = TRpgDataList[of TMapRegion]()

	public def constructor():
		super()

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

	public class TMapMetadataEnumeratorI(IMapMetadataEnumerator):

		private FInternalEnumerator as IEnumerator[of TMapMetadata]

		public def constructor(tree as TMapTree):
			FInternalEnumerator = tree.GetEnumerator()

		def Dispose():
			FInternalEnumerator.Dispose()

		public def GetCurrent() as IMapMetadata:
			return FInternalEnumerator.Current

		public def MoveNext() as bool:
			return FInternalEnumerator.MoveNext()

		System.Collections.IEnumerator.Current:
			get: return GetCurrent()

		public Current as IMapMetadata:
			get:
				return GetCurrent()
		
		def Reset():
			FInternalEnumerator.Reset()

	public class TMapNode(TreeNode[of TMapMetadata]):
		def constructor(value as TMapMetadata):
			super(value)

	[Property(CurrentMap)]
	private FCurrentMap as int

	private FTree as TMapNode

	private FLoaded as bool

	private def getMap(value as int) as TMapMetadata:
		return lookup[value]

	private def getLookupCount() as int:
		return FTranslationTable.Count

	private def GetNewID() as short:
		found as (bool)
		enumerator as TMapNode
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
		node as TMapNode
		if not FLoaded:
			return
		node = FTranslationTable[map.ID]
		return if node.Parent.Value.ID == map.Parent
		node.Parent = FTranslationTable[map.Parent]

	private def GetEnumeratorI() as IMapMetadataEnumerator:
		return TMapMetadataEnumeratorI(self)

	def Get(x as int) as IMapMetadata:
		return self.lookup[x]

	private def GetCount() as int:
		return FTranslationTable.Count

	private def AddLookup(value as TMapMetadata) as TMapNode:
		result = TMapNode(value)
		FTranslationTable.Add(value.ID, result)
		return result

	def IMapTree.GetEnumerator():
		return GetEnumeratorI()

	[Getter(Location)]
	protected FStartLocs = Dictionary[of int, TLocation]()

	protected FTranslationTable = Dictionary[of short, TMapNode]()

	[Getter(MapEngines)]
	private FMapEngines = TStringList()

	public def constructor():
		super()
		TMapMetadata.FOwner = self

	public def Add(value as TMapMetadata):
		parent as TMapNode
		if self.Count == 0:
			assert value.ID == 0
			assert FTree == null
			FTree = AddLookup(value)
		else:
			assert FTranslationTable.ContainsKey(value.ID) == false
			parent = FTranslationTable[value.Parent]
			parent.Children.Add(AddLookup(value))

	public def Remove(value as TMapMetadata):
		node as TMapNode
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

	public def GetEnumerator() as IEnumerator[of TMapMetadata]:
		return TMapMetadataEnumeratorI(self)

	public lookup[x as short] as TMapMetadata:
		get: return FTranslationTable[x].Value
		set: FTranslationTable[x].Value = value

	public self[x as int] as IMapMetadata:
		get:
			return getMap(x)

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
