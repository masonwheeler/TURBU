namespace tiles

import commons
import turbu.maps
import turbu.tilesets
import TURBU.MapObjects
import turbu.defs
import dm.shaders
import sdl.sprite
import SG.defs
import turbu.constants
import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import turbu.RM2K.sprite.engine
import SDL2.SDL2_GPU

abstract class TTile(TParentSprite):

	protected static FHeartbeat as int

	protected static FBroadcastList = List[of Action]()

	static def constructor():
		EnsureBroadcastList()

	protected static def EnsureBroadcastList():
		if FBroadcastList is null:
			FBroadcastList = List[of Action]()

	[Property(Location)]
	protected FGridLoc as TSgPoint

	[Property(Terrain)]
	private FTerrainID as int

	[Property(Attributes)]
	private FAttributes as TTileAttribute

	[Property(ID)]
	protected FTileID as ushort

	protected override def InVisibleRect() as bool:
		def NormalizePoint(aPoint as TSgPoint, aRect as GPU_Rect) as TSgPoint:
			right as int = aRect.x + aRect.w
			bottom as int = aRect.y + aRect.h
			if aPoint.x < aRect.x:
				aPoint.x += aRect.w
			elif aPoint.x >= right:
				aPoint.x -= aRect.w
			if aPoint.y < aRect.y:
				aPoint.y += aRect.h
			elif aPoint.y >= bottom:
				aPoint.y -= aRect.h
			return aPoint
		
		corrected as TSgPoint
		if (FEngine cast T2kSpriteEngine).Overlapping == TFacing.None:
			result = super.InVisibleRect()
		else:
			corrected = NormalizePoint(FGridLoc, (FEngine cast T2kSpriteEngine).MapRect) * TILE_SIZE
			result = corrected.x >= FEngine.WorldX - (Width * 2) and \
					corrected.y >= FEngine.WorldY - (Height * 2) and \
					corrected.x < FEngine.WorldX + FEngine.VisibleWidth + Width and \
					corrected.y < FEngine.WorldY + FEngine.VisibleHeight + Height
		return result

	protected override def DoDraw():
		lX as single
		lY as single
		overlap as TFacing
		overlap = (FEngine cast T2kSpriteEngine).Overlapping
		if overlap != TFacing.None:
			lX = self.X
			lY = self.Y
			AdjustOverlap(overlap)
		super.DoDraw()
		if overlap != TFacing.None:
			self.X = lX
			self.Y = lY

	protected def AdjustOverlap(overlap as TFacing):
		viewport as GPU_Rect
		mapSize as TSgFloatPoint
		viewport = (FEngine cast T2kSpriteEngine).Viewport
		mr = (FEngine cast T2kSpriteEngine).MapRect
		mapSize = sgPoint(mr.h, mr.w) * TILE_SIZE
		if TFacing.Left in overlap:
			if FGridLoc.x > viewport.x + viewport.w:
				self.X = (self.X - mapSize.x)
		elif TFacing.Right in overlap:
			if FGridLoc.x < viewport.x:
				self.X = (self.X + mapSize.x)
		if TFacing.Up in overlap:
			if FGridLoc.y > viewport.y + viewport.h:
				self.Y = (self.Y - mapSize.y)
		elif TFacing.Down in overlap:
			if FGridLoc.y < viewport.y:
				self.Y = (self.Y + mapSize.y)

	protected virtual def SetEngine(newEngine as TSpriteEngine):
		FEngine = newEngine

	public def constructor(AParent as TSpriteEngine, tileset as string):
		assert AParent isa T2kSpriteEngine
		super(AParent)
		ImageName = tileset

	public def Assign(value as TTile):
		self.FTileID = value.ID
		self.FGridLoc = value.Location
		self.FEngine = value.Engine
		self.FAttributes = value.FAttributes
		super.Assign(value)

	public virtual def Place(xCoord as int, yCoord as int, layer as int, tileData as TTileRef, tileset as TTileSet) as TTileAttribute:
		tileGroup as TTileGroupRecord
		X = TILE_SIZE.x * xCoord
		Y = TILE_SIZE.y * yCoord
		FGridLoc.x = xCoord
		FGridLoc.y = yCoord
		self.Width = TILE_SIZE.x
		self.Height = TILE_SIZE.y
		self.ImageIndex = tileData.Tile
		tileGroup = tileset.Records[tileData.Group]
		ImageName = tileGroup.Group.Filename
		var result = tileGroup.Attributes[tileData.Tile]
		FTerrainID = tileGroup.Terrain[tileData.Tile] if tileGroup.HasTerrain
		FAttributes = result
		Z = DecodeZOrder(result) + layer
		return result

	public virtual def Open(exceptFor as TObject) as bool:
		return self.CanEnter()

	public def CanEnter() as bool:
		result = false
		for i as TTileAttribute in (TTileAttribute.Up, TTileAttribute.Down, TTileAttribute.Left, TTileAttribute.Right):
			result = result or (i in FAttributes)
		return result

	public def UpdateGridLoc():
		FGridLoc = sgPoint(round(self.X / TILE_SIZE.x), round(self.Y / TILE_SIZE.y ))

	public static def Heartbeat():
		FHeartbeat = (FHeartbeat + 1) % ANIM_LCM
		for proc in FBroadcastList:
			proc()
	
	private static def DecodeZOrder(value as TTileAttribute) as byte:
		if TTileAttribute.Overhang in value:
			return 10
		elif TTileAttribute.Ceiling in value:
			return 6
		else: return 1

[Disposable]
class TEventTile(TTile, IDisposable):

	[Property(Event)]
	private FEvent as TRpgMapObject

	[Property(OnMustFlash)]
	private FOnMustFlash as Func of bool

	[Property(OnFlashColor)]
	private FOnGetFlashColor as Func of (single)

	private def DrawFlash():
		if self.Image is not null:
			PrepareShader(GSpriteEngine.value.ShaderEngine)
			super.Render()
			GPU_DeactivateShaderProgram()
		
	private def PrepareShader(shaders as TdmShaders):
		handle as int = shaders.ShaderProgram('default', 'flash')
		shaders.UseShaderProgram(handle)
		shaders.SetUniformValue(handle, 'flashColor', FOnGetFlashColor())

	private MustFlash as bool:
		get: return (assigned(FOnMustFlash) and assigned(FOnGetFlashColor)) and FOnMustFlash()

	public def constructor(baseEvent as TRpgMapObject, aParent as TSpriteEngine):
		super(aParent, '')
		if assigned(baseEvent):
			self.X = baseEvent.Location.x * TILE_SIZE.x
			self.Y = baseEvent.Location.y * TILE_SIZE.y
			FEvent = baseEvent
			Update(baseEvent.CurrentPage)

	public def Assign(data as TEventTile):
		super.Assign(data)

	public def Update(newPage as TRpgEventPage):
		engine as T2kSpriteEngine = FEngine cast T2kSpriteEngine
		if assigned(newPage):
			self.Visible = true
			var x = Math.Truncate(self.X / TILE_SIZE.x)
			var y = Math.Truncate(self.Y / TILE_SIZE.y)
			var Z_TABLE = (3, 4, 8)
			self.Z = Z_TABLE[newPage.ZOrder]
			FGridLoc = sgPoint(x, y)
			self.Visible = true
		else:
			self.Z = 10
			self.Visible = false
		name as string
		if assigned(FEvent) and assigned(FEvent.CurrentPage):
			self.ImageIndex = FEvent.CurrentPage.SpriteIndex
			if FEvent.CurrentPage.Tilegroup != -1:
				name = engine.Tileset.Records[FEvent.CurrentPage.Tilegroup].Group.Name
			else: name = FEvent.CurrentPage.PageName
			engine.EnsureImage(name)
		else: name = ''
		self.ImageName = name

	public override def Render():
		if self.MustFlash:
			DrawFlash()
		else:
			super.Render()

class TScrollData(TObject):

	[Property(X)]
	private FX as int

	[Property(Y)]
	private FY as int

	[Property(ScrollX)]
	private FScrollX as TMapScrollType

	[Property(ScrollY)]
	private FScrollY as TMapScrollType

	public def constructor(input as TRpgMap):
		FX = input.ScrollSpeed.x
		FY = input.ScrollSpeed.y
		FScrollX = input.HScroll
		FScrollY = input.VScroll

	public def constructor(x as int, y as int, autoX as TMapScrollType, autoY as TMapScrollType):
		FX = x
		FY = y
		FScrollX = autoX
		FScrollY = autoY

class TBackgroundSprite(TSprite):

	[Property(scrollData)]
	private FScroll as TScrollData

	private FSavedOrigin as TSgFloatPoint

	protected override def InVisibleRect() as bool:
		return true

	public def constructor(parent as TSpriteEngine, input as TRpgMap):
		super(parent)
		FScroll = TScrollData(input)

	public def constructor(parent as TSpriteEngine, x as int, y as int, autoX as TMapScrollType, autoY as TMapScrollType):
		super(parent)
		FScroll = TScrollData(x, y, autoX, autoY)

	public override def IsBackground() as bool:
		return true

	public def Scroll():
		if (FScroll.ScrollX == TMapScrollType.Autoscroll) and (Engine.WorldX != FSavedOrigin.x):
			self.OffsetX += (Engine.WorldX - FSavedOrigin.x) / 2.0
		elif FScroll.ScrollX != TMapScrollType.None:
			self.OffsetX += FScroll.X * BG_SCROLL_RATE
		if (FScroll.ScrollY == TMapScrollType.Autoscroll) and (Engine.WorldY != FSavedOrigin.y):
			self.OffsetY += (Engine.WorldY - FSavedOrigin.y) / 2.0
		elif FScroll.ScrollY != TMapScrollType.None:
			self.OffsetY += FScroll.Y * BG_SCROLL_RATE
		FSavedOrigin = sgPointF(Engine.WorldX, Engine.WorldY)
		while self.OffsetX > 0:
			self.OffsetX -= self.PatternWidth
		or:
			while self.OffsetX < -self.PatternWidth:
				self.OffsetX += self.PatternWidth
		while self.OffsetY > 0:
			self.OffsetY -= self.PatternHeight
		or:
			while self.OffsetY < -self.PatternHeight:
				self.OffsetY += self.PatternHeight

let BG_SCROLL_RATE = 0.1
let ANIM_LCM = 8 * 9 * 5 * 7 * 11
