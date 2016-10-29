namespace TURBU.MapEngine

import Pythia.Runtime
import System.Collections.Generic
import System
import System.Windows.Forms
import TURBU.PluginInterface
import turbu.versioning
import TURBU.BattleEngine
import TURBU.DataReader
import TURBU.Engines
import TURBU.MapInterface
import SG.defs
import System.Drawing
import TURBU.Meta

class TMapEngineData(TRpgMetadata):

	def constructor(name as string, version as TVersion):
		super(name, version)

enum TDeleteMapMode:
	Tree
	Sibling
	Top
	None

interface IBreakable:

	def BreakSomething()

interface ITurbuController:

	def MapResize(size as TSgPoint) as TSgPoint

	def ScrollMap(TopLeft as TSgPoint) as TSgPoint

enum TButtonPosition:
	Layer
	Save
	Play
	Command

interface ITurbuControllerEx(ITurbuController):

	def TilesetChanged()

	def SetButton(button as ToolStripButton, position as TButtonPosition)

	def AddTileImage(il as ImageList, index as int) as int

	def setLayer(value as int)

	def UpdateEngine(filename as string)

	def SetMapMenuItem(item as ToolStripMenuItem)

	def ClearMapMenuItem(item as ToolStripMenuItem)

	def RebuildMapTree(id as int)

interface IMapEngine(ITurbuEngine):

	def Initialize(window as IntPtr, database as string) as IntPtr

	def RegisterBattleEngine(value as IBattleEngine)
	
	def RegisterDataReader(value as IDataReader)

	def SetDefaultBattleEngine(name as string) as bool

	def LoadMap(map as IMapMetadata)

	def Play()

	def Playing() as bool

	def MapTree() as IMapTree

	def Start()

	Data as TMapEngineData:
		get

enum TPaintMode:
	Pen
	Flood
	Rect
	Ellipse
	Select
	Erase

enum TShiftState:
	Shift
	Ctrl
	Alt

interface IDesignMapEngine(IMapEngine):

	def GetTilesetImage(index as byte) as IntPtr

	TilesetImage[index as byte] as IntPtr:
		get

	def SetCurrentLayer(value as byte)

	def GetCurrentLayer() as byte

	def GetTileSize() as TSgPoint

	CurrentLayer as byte:
		get
		set

	def MapPosition() as TSgPoint

	def SetController(value as ITurbuController)

	def ResizeWindow(rect as Rectangle)

	def ScrollMap(newPosition as TSgPoint)

	def SetPaletteList(value as (int))

	def SetPaintMode(value as TPaintMode)

	def SetExactDrawMode(value as bool)

	def Draw(position as TSgPoint, newDraw as bool)

	def DoneDrawing()

	def Undo()

	def Repaint()

	def DoubleClick()

	def RightClick(position as TSgPoint)

	def KeyDown(key as ushort, Shift as TShiftState)

	def KeyUp(key as ushort, Shift as TShiftState)

	AutosaveMaps as bool:
		get
		set

	def SaveCurrent()

	def SaveAll()

	def AddNewMap(parentID as int) as IMapMetadata

	def EditMapProperties(mapID as int)

	def DeleteMap(mapID as int, deleteResult as TDeleteMapMode)

	def ClearButtons()

	def Reset()

	def Pause()

	def Stop()

	def EditDatabase()

abstract class TMapEngine(TRpgPlugBase, IMapEngine):

	def Dispose():
		self.Cleanup() if FInitialized
		GC.SuppressFinalize(self)

	private FData as TMapEngineData

	protected FBattleEngines = Dictionary[of string, IBattleEngine]()

	[Getter(DefaultBattleEngine)]
	protected FDefaultBattleEngine as IBattleEngine

	protected FWindow as IntPtr

	protected FInitialized as bool

	protected virtual def Cleanup():
		for value in FBattleEngines.Values:
			value.Dispose()
		FBattleEngines.Clear()

	def destructor():
		assert false

	public override def AfterConstruction():
		super()
		assert assigned(Data)
		assert Data.Name != ''
		assert Data.Version > TVersion(0, 0, 0)

	public virtual def Initialize(window as IntPtr, database as string) as IntPtr:
		return IntPtr.Zero

	public def RegisterBattleEngine(value as IBattleEngine):
		unless FBattleEngines.ContainsValue(value):
			FBattleEngines.Add(value.Data.Name, value)
			if FBattleEngines.Count == 1:
				SetDefaultBattleEngine(value.Data.Name)

	public def SetDefaultBattleEngine(name as string) as bool:
		newEngine as IBattleEngine
		result = FBattleEngines.TryGetValue(name, newEngine)
		if result:
			FDefaultBattleEngine = newEngine
		return result

	public abstract def LoadMap(map as IMapMetadata):
		pass

	public abstract def Play():
		pass

	public abstract def Playing() as bool:
		pass

	public abstract def MapTree() as IMapTree:
		pass

	public abstract def NewGame():
		pass

	public abstract def Start():
		pass

	public Data as TMapEngineData:
		get: return FData
		set: FData = value

	def constructor():
		super()

class TMatrix[of T](TObject, IEnumerable[of T]):

	private FMatrix as (T)

	[Getter(Width)]
	private FWidth as int

	[Getter(Height)]
	private FHeight as int

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def GetValue(x as int, y as int) as T:
		return FMatrix[(y * FWidth) + x]

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def SetValue(x as int, y as int, value as T):
		FMatrix[(y * FWidth) + x] = value

	def GetEnumerator():
		return (FMatrix cast T*).GetEnumerator()
	
	def System.Collections.IEnumerable.GetEnumerator():
		return FMatrix.GetEnumerator()

	private def VerticalExpand(base as TMatrix[of T], position as int):
		start as int
		caseOf position / 3:
			case 0:
				start = 0
			case 1:
				start = ((FHeight - base.Height) / 2)
			case 2:
				start = (FHeight - base.Height)
		for i in range(0, base.Height):
			if base.Width <= self.Width:
				HorizontalExpand(base, i, (i + start), position)
			else:
				HorizontalContract(base, i, (i + start), position)

	private def VerticalContract(base as TMatrix[of T], position as int):
		start as int
		i as int
		caseOf position / 3:
			case 0:
				start = 0
			case 1:
				start = ((base.Height - FHeight) / 2)
			case 2:
				start = (base.Height - FHeight)
		for i in range(0, FHeight):
			if base.Width <= self.Width:
				HorizontalExpand(base, (i + start), i, position)
			else:
				HorizontalContract(base, (i + start), i, position)

	private def HorizontalContract(base as TMatrix[of T], fromRow as int, toRow as int, position as int):
		start as int
		i as int
		caseOf position % 3:
			case 0:
				start = 0
			case 1:
				start = ((base.Width - FWidth) / 2)
			case 2:
				start = (base.Width - FWidth)
		for i in range(0, FWidth):
			self[i, toRow] = base[(i + start), fromRow]

	private def HorizontalExpand(base as TMatrix[of T], fromRow as int, toRow as int, position as int):
		start as int
		i as int
		caseOf position % 3:
			case 0:
				start = (FWidth - base.Width)
			case 1:
				start = 0
			case 2:
				start = ((FWidth - base.Width) / 2)
		for i in range(0, base.Width):
			self[(i + start), toRow] = base[i, fromRow]

	public def constructor(size as TSgPoint):
		super()
		FMatrix = array(T, size.x * size.y)
		FWidth = size.x
		FHeight = size.y

	public def constructor(size as TSgPoint, base as TMatrix[of T], position as int):
		self(size)
		if (position < 1) or (position > 9):
			raise Exception("Invalid position value: $position; valid values are 1..9")
		try:
			if base.Height <= FHeight:
				VerticalExpand(base, position)
			else:
				VerticalContract(base, position)
		except E as IndexOutOfRangeException:
			raise IndexOutOfRangeException("TMatrix[of $T]: Range check error resizing a $(base.Width)X$(base.Height) matrix to $(size.x)X$(size.y), position $position", E)

	public self[X as int, Y as int] as T:
		get:
			return GetValue(X, Y)
		set:
			SetValue(X, Y, value)

