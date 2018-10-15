namespace turbu.maps

import System
import System.Drawing
import System.Linq.Enumerable
import turbu.containers
import SG.defs
import Boo.Adt
import Pythia.Runtime
import turbu.classes
import TURBU.MapInterface
import TURBU.Meta
import turbu.tilesets
import turbu.map.metadata
import TURBU.MapObjects
import turbu.constants
import Newtonsoft.Json.Linq

enum TMapScrollType:
	None
	Scroll
	Autoscroll

enum TScriptFormat:
	sfEvents
	sfScripts
	sfCompiled
	sfLegacy

[EnumSet]
enum TWraparound:
	None = 0
	Vertical = 1
	Horizontal = 2
	Both = 3

[EnumSet]
enum TDirs8:
	None = 0
	n  = 1
	ne = 2
	e  = 4
	se = 8
	s  = 0x10
	sw = 0x20
	w  = 0x40
	nw = 0x80
	All = n | ne | e | se | s | sw | w | nw

enum TFuzzy:
	no
	yes
	either

[Disposable("Destroy")]
class TRpgMap(TRpgDatafile, IRpgMap):

	[Property(Tileset)]
	private FTileset as int = 1

	private FSize = SgPoint(x: 30, y: 25)

	private FDepth as byte

	[Property(Wraparound)]
	private FWraparound as TWraparound

	[Property(TileMap)]
	private FTileMap as ((TTileRef))

	[Property(HasBackground)]
	private FHasBG as bool

	[Property(BgName)]
	private FBgName as string

	[Property(HScroll)]
	private FHScroll as TMapScrollType

	[Property(VScroll)]
	private FVScroll as TMapScrollType

	[Property(ScrollSpeed)]
	private FScrollSpeed as SgPoint

	private FScriptFormat as TScriptFormat

	[Property(ScriptFile)]
	private FScriptFile as string

	[Property(EncounterScript)]
	private FEncounterScript as string

	[Property(Modified)]
	private FModified as bool

	private FScriptSignal as System.Threading.EventWaitHandle

	private FScriptError as string

	private def SetSize(value as SgPoint):
		FSize = value
		for i in range(FTileMap.Length):
			arr = FTileMap[i]
			Array.Resize[of TTileRef](arr, value.x * value.y)
			FTileMap[i] = arr

	private def SetDepth(value as byte):
		FDepth = value
		Array.Resize[of (TTileRef)](FTileMap, value)
		SetSize(FSize)

	private def SetScriptFormat(Value as TScriptFormat):
		FScriptFormat = Value

	private def GetBattleCount() as int:
		return FBattles.Length

	private def SetBattleCount(Value as int):
		Array.Resize[of ushort](FBattles, Value)

	private def BlitToGrid(ref grid as (((TTileRef))), bounds as Rectangle):
		lineLength as int = (bounds.Right - bounds.Left) * sizeof(TTileRef)
		for j in range(0, FDepth):
			for i in range(0, grid[j].Length):
				Array.Copy(self.FTileMap[j], ((i + bounds.Top) * FSize.x) + bounds.Left, grid[j][i], 0, lineLength)

	private def BlitFromGrid(grid as (((TTileRef))), bounds as Rectangle):
		lineLength as int = ((bounds.Right - bounds.Left) * sizeof(TTileRef))
		for j in range(0, FDepth):
			for i in range(grid[j].Length):
				Array.Copy(grid[j][i], 0, self.FTileMap[j], ((i + bounds.Top) * FSize.x) + bounds.Left, lineLength)

	private def CalcGridDelta(size as SgPoint, position as byte) as Rectangle:
		
		def CalcPoints(first as int, second as int, position as int) as SgPoint:
			midpoint as int
			result as SgPoint
			caseOf position:
				case 0:
					result.x = 0
					result.y = (first - second)
				case 1:
					midpoint = (second / 2)
					result.x = (midpoint - (first / 2))
					result.y = (midpoint + (first / 2))
				case 2:
					result.x = (first - second)
					result.y = result.x
					
		point = CalcPoints(FSize.x, size.x, position % 3)
		point2 = CalcPoints(FSize.x, size.x, position / 3)
		return Rectangle(point.x, point.y, point2.x - point.x, point2.y - point.y)

	def GetMapObjects() as IRpgMapObject*:
		return FMapObjects.Cast[of IRpgMapObject]()

	[Property(EncounterParams)]
	protected FEncounters = array(int, 4)

	[Property(Battles)]
	protected FBattles = array(ushort, 0)

	[Property(MapObjects)]
	protected FMapObjects = TRpgObjectList[of TRpgMapObject]()

	private FInitialized as bool

	public def constructor():
		super()
		self.SetDepth(turbu.constants.LAYERS)
		FModified = true

	public def LoadFromJSON(obj as JObject):
		obj.CheckRead('ID', FId)
		obj.CheckRead('Tileset', FTileset)
		obj.CheckRead('Size', FSize)
		obj.CheckReadEnum('Wraparound', FWraparound)
		var tm = obj['TileMap'] cast JArray
		obj.Remove('TileMap')
		SetDepth(tm.Count)
		for i in range(tm.Count):
			FTileMap[i] = (tm[i] cast JArray).Select({e | TTileRef(e cast int)}).ToArray()
		var mo = obj['MapObjects'] cast JArray
		obj.Remove('MapObjects')
		if mo is not null:
			for value in mo.Cast[of JObject]():
				FMapObjects.Add(TRpgMapObject(value, self.MapObjectValidPage))
		obj.CheckRead('HasBackground', FHasBG)
		obj.CheckRead('BgName', FBgName)
		obj.CheckReadEnum('HScroll', FHScroll)
		obj.CheckReadEnum('VScroll', FVScroll)
		obj.CheckRead('ScrollSpeed', FScrollSpeed)
		obj.CheckEmpty()

		Initialize()

	public def Initialize():
		assert not FInitialized
		for obj in FMapObjects:
			obj.Initialize()
		MapScripts()
		InitializeRoutes()
		FInitialized = true
	
	protected virtual def InitializeRoutes():
		pass
	
	protected virtual def MapScripts():
		pass
	
	public virtual def MapObjectValidPage(id as int) as Func of int:
		return null
	
	public def constructor(meta as TMapMetadata):
		self()
		FName = meta.Name
		FId = meta.ID

	public def AssignTile(x as int, y as int, layer as int, tile as TTileRef):
		FTileMap[layer][(y * FSize.x) + x] = tile

	public def GetTile(x as int, y as int, layer as int) as TTileRef:
		return FTileMap[layer][(y * FSize.x) + x]

	public def AdjustSize(size as SgPoint, position as byte):
		grid as (((TTileRef)))
		assert position in range(1, 10)
		return if size == FSize
		--position
		var gridSize = sgPoint(Math.Min(FSize.x, size.x), Math.Min(FSize.y, size.y))
		delta as Rectangle = CalcGridDelta(size, position)
		Array.Resize[of ((TTileRef))](grid, self.FDepth)
		for i in range(grid.Length):
			layer = grid[i]
			Array.Resize[of (TTileRef)](layer, gridSize.y)
			for j in range(layer.Length):
				row = layer[j]
				Array.Resize[of TTileRef](row, gridSize.x)
		BlitToGrid(grid, CalcBlitBounds(size, position))
		self.SetSize(size)
		for list in FTileMap:
			for tile as TTileRef in list:
				tile.Value = 0
		BlitFromGrid(grid, CalcBlitBounds(gridSize, position))
		RemoveInvalidEvents()

	public def CalcBlitBounds(size as SgPoint, position as byte) as Rectangle:
		
		def CalcBounds(first as int, second as int, mode as byte) as SgPoint:
			result as SgPoint
			midpoint as int
			minsize as int = Math.Min(first, second)
			caseOf mode:
				case 0:
					result.x = 0
					result.y = minsize
				case 1:
					if first > second:
						result = CalcBounds(first, second, 0)
					else:
						midpoint = second / 2
						result.x = midpoint - (first / 2)
						result.y = result.x + first
				case 2:
					result.x = Math.Max(0, second - first)
					result.y = result.x + minsize
				default :
					assert false
					
		let nullTile = TTileRef(Group: 0, Tile: 255)
		halfBounds = CalcBounds(size.x, FSize.x, position % 3)
		halfBoundsBR = CalcBounds(size.y, FSize.y, position / 3)
		result = Rectangle(halfBounds.x, halfBounds.y, halfBoundsBR.x - halfBounds.x, halfBoundsBR.y - halfBounds.y)
		assert result.Left >= 0
		assert result.Top >= 0
		assert result.Right <= FSize.x
		assert result.Bottom <= FSize.y
		assert result.Width == Math.Min(FSize.x, size.x)
		assert result.Height == Math.Min(FSize.y, size.y)
		return result

	public def RemoveInvalidEvents():
		pass

	public Size as SgPoint:
		get:
			return FSize
		set:
			SetSize(value)

	public Depth as byte:
		get:
			return FDepth
		set:
			SetDepth(value)

	public ScriptFormat as TScriptFormat:
		get:
			return FScriptFormat
		set:
			SetScriptFormat(value)

	public BattleCount as int:
		get:
			return GetBattleCount()
		set:
			SetBattleCount(value)

	public Width as int:
		get: return FSize.x

	public Height as int:
		get: return FSize.y
