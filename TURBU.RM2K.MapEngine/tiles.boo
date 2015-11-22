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
		FTerrainID = tileGroup.Terrain[tileData.Tile]
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
		FGridLoc = sgPoint(round((self.X cast double) / (TILE_SIZE.x cast double)), round((self.Y cast double) / (TILE_SIZE.y cast double)))

	public static def Heartbeat():
		proc as Action
		FHeartbeat = (FHeartbeat + 1) % ANIM_LCM
		for proc in FBroadcastList:
			proc()
	
	private static def DecodeZOrder(value as TTileAttribute) as byte:
		if TTileAttribute.Overhang in value:
			result = 10
		elif TTileAttribute.Ceiling in value:
			result = 6
		else: result = 1

class TEventTile(TTile, IDisposable):

	def Dispose():
		super.Dispose()

	[Property(Event)]
	private FEvent as TRpgMapObject

	[Property(OnMustFlash)]
	private FOnMustFlash as Func of bool

	[Property(OnFlashColor)]
	private FOnGetFlashColor as Func of (single)

	private def DrawFlash():
		PrepareShader(GSpriteEngine.value.ShaderEngine)
		Drawself(self.Image.SpriteRect[self.ImageIndex])
		GPU_DeactivateShaderProgram()
		
	private def Drawself(SpriteRect as GPU_Rect):
		left as int = Math.Truncate((self.X + OffsetX) - FEngine.WorldX)
		top as int = Math.Truncate((self.Y + OffsetY) - FEngine.WorldY)
		GPU_Blit(self.Image.Surface, SpriteRect, self.Engine.Canvas.RenderTarget, left, top)

	private def PrepareShader(shaders as TdmShaders):
		handle as int = shaders.ShaderProgram('default', 'Flash')
		shaders.UseShaderProgram(handle)
		shaders.SetUniformValue(handle, 'flashColor', FOnGetFlashColor())

	private MustFlash as bool:
		get: return (assigned(FOnMustFlash) and assigned(FOnGetFlashColor)) and FOnMustFlash()

	public def constructor(baseEvent as TRpgMapObject, AParent as TSpriteEngine):
		super(AParent, '')
		if assigned(baseEvent):
			self.X = baseEvent.Location.x * TILE_SIZE.x
			self.Y = baseEvent.Location.y * TILE_SIZE.y
			FEvent = baseEvent
			Update(baseEvent.CurrentPage)

	public def Assign(data as TEventTile):
		super.Assign(data)

	public def Update(newPage as TRpgEventPage):
		let Z_TABLE = (3, 4, 8)
		x as int
		y as int
		z as int
		engine as T2kSpriteEngine
		Name as string
		engine = FEngine cast T2kSpriteEngine
		if assigned(newPage):
			self.Visible = true
			z = Z_TABLE[newPage.ZOrder]
			x = Math.Truncate((self.X cast double) / (TILE_SIZE.x cast double))
			y = Math.Truncate((self.Y cast double) / (TILE_SIZE.y cast double))
			self.Z = z
			FGridLoc = sgPoint(x, y)
			self.Visible = true
		else:
			self.Z = 10
			self.Visible = false
		if assigned(FEvent) and assigned(FEvent.CurrentPage):
			self.ImageIndex = FEvent.CurrentPage.Frame
			if FEvent.CurrentPage.Tilegroup != -1:
				Name = engine.Tileset.Records[FEvent.CurrentPage.Tilegroup].Group.Name
			else: Name = FEvent.CurrentPage.Name
			engine.EnsureImage(Name)
		else: Name = ''
		self.ImageName = Name

	public override def Draw():
		if self.MustFlash:
			DrawFlash()
		else:
			super.Draw()

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

	public def Scroll():
		if (FScroll.ScrollX == TMapScrollType.Autoscroll) and (Engine.WorldX != FSavedOrigin.x):
			self.OffsetX += (Engine.WorldX - FSavedOrigin.x) / 2.0
		else:
			self.OffsetX += FScroll.X * BG_SCROLL_RATE
		if (FScroll.ScrollY == TMapScrollType.Autoscroll) and (Engine.WorldY != FSavedOrigin.y):
			self.OffsetY += (Engine.WorldY - FSavedOrigin.y) / 2.0
		else:
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
