namespace turbu.RM2K.sprite.engine

import System
import System.Collections.Generic
import System.Math
import System.Linq.Enumerable

import Boo.Adt
import charset.data
import commons
import dm.shaders
import Pythia.Runtime
import SDL2
import SDL2.SDL2_GPU
import sdl.canvas
import SDL.ImageManager
import sdl.sprite
import SG.defs
import tiles
import timing
import turbu.constants
import turbu.containers
import turbu.defs
import TURBU.MapEngine
import TURBU.MapObjects
import turbu.maps
import turbu.map.sprites
import TURBU.Meta
import turbu.RM2K.environment
import turbu.RM2K.map.tiles
import TURBU.RM2K.Menus
import turbu.RM2K.sprite.list
import turbu.tilesets

let BASESPEED = 15.875
let SHAKE_MAX = 23
let MOVESPEED = (0, BASESPEED / 8.0, BASESPEED / 4.0, BASESPEED / 2.0, BASESPEED, BASESPEED * 2.0, BASESPEED * 4.0)

[Disposable(Destroy, true)]
class T2kSpriteEngine(SpriteEngine):

	static final LSineTable = array(double, SHAKE_MAX)

	static def constructor():
		for i in range(SHAKE_MAX):
			LSineTable[i] = Math.Sin((2 * PI * i) / SHAKE_MAX)

	[Getter(MapObj)]
	private FMap as TRpgMap

	private FBgImage as TBackgroundSprite

	private FTiles as List[of TMatrix[of TMapTile]]

	[Getter(Tileset)]
	private FTileset as TTileSet

	[Getter(Overlapping)]
	private FOverlapping as TFacing

	private FViewport as GPU_Rect

	private final _tileViewport as CompositeViewport

	[Getter(MapRect)]
	private FMapRect as GPU_Rect

	[Property(CurrentLayer)]
	private FCurrentLayer as int

	[Property(Blank)]
	private FBlank as bool

	[Getter(MapObjects)]
	private FMapObjects as TRpgObjectList[of TMapSprite]

	private FSpriteLocations as TSpriteLocations

	[DisposeParent]
	private FCurrentParty as TCharSprite

	[Getter(State)]
	private FGameState as TGameState

	private FSavedState as TGameState

	[Property(OnPartySpriteChanged)]
	private FPartySpriteChanged as Action of TCharSprite

	[Getter(ShaderEngine), DisposeParent]
	private FShaderEngine as TdmShaders

	private FFadeColor = array(single, 4)

	private FFadeTarget = array(single, 4)

	private FFadeTime as Timestamp

	[Getter(SystemGraphic)]
	private FSystemGraphic as TSystemImages

	private FFlashColor as SDL.SDL_Color

	private FFlashTime as Timestamp

	private FFlashDuration as int

	[Property(OnDrawWeather)]
	private FOnDrawWeather as Action

	private FErasing as bool

	private FPanSpeed as single

	[Getter(Displacing)]
	private FDisplacing as bool

	[Property(Returning)]
	private FReturning as bool

	private FDestination as SgPoint

	private FDispGoalX as single

	private FDispGoalY as single

	[Getter(DisplacementX)]
	private FDisplacementX as single

	[Getter(DisplacementY)]
	private FDisplacementY as single

	private FDisplacementTime as Timestamp

	private FScreenLocked as bool

	private FDispBaseX as single

	private FDispBaseY as single

	private FCenter as SgPoint

	private FShakePower as byte

	private FShakeSpeed as byte

	private FShakeCounter as byte

	private FShakeTime as int

	private def SetViewport(viewport as GPU_Rect):
		SetViewport(viewport, viewport.x * TILE_SIZE.x, viewport.y * TILE_SIZE.y)

	private def SetViewport(viewport as GPU_Rect, pixelX as int, pixelY as int):
		assert assigned(FMap)
		return if viewport == FViewport and self.Viewport.WorldX == pixelX and self.Viewport.WorldY == pixelY
		FViewport = viewport
		for i in range(FMap.TileMap.Length):
			LoadTileMatrix(FMap.TileMap[i], i, viewport)
		FOverlapping = TFacing.None
		if viewport.x < 0:
			FOverlapping |= TFacing.Left
		elif viewport.w > self.Width:
			FOverlapping |= TFacing.Right
		if viewport.y < 0:
			FOverlapping |= TFacing.Up
		elif viewport.h > self.Height:
			FOverlapping |= TFacing.Down
		var scaledViewport = GPU_MakeRect(
				pixelX,
				pixelY,
				viewport.w * TILE_SIZE.x,
				viewport.h * TILE_SIZE.y)
		_tileViewport.SetView(scaledViewport)
		self.Viewport.WorldX = pixelX
		self.Viewport.WorldY = pixelY
		ResizeCanvas()

	private static def NormalizeCoords(x as int, y as int, size as SgPoint, ref equivX as int, ref equivY as int):
		adjustedCoords as SgPoint = SgPoint(x, y)
		while (adjustedCoords.x < 0) or (adjustedCoords.y < 0):
			adjustedCoords = adjustedCoords + size
		adjustedCoords = adjustedCoords % size
		equivX = adjustedCoords.x
		equivY = adjustedCoords.y

	private static def GetIndex(x as int, y as int, size as SgPoint) as int:
		return (y * size.x) + x

	private def LoadTileMatrix(value as (TTileRef), index as int, viewport as GPU_Rect):
		equivX as int
		equivY as int
		matrix as TMatrix[of TMapTile] = FTiles[index]
		size as SgPoint = FMap.Size
		for y in range(viewport.y - 1, viewport.y + viewport.h + 1):
			for x in range(viewport.x - 1, viewport.x + viewport.w + 1):
				NormalizeCoords(x, y, size, equivX, equivY)
				continue if assigned(matrix[equivX, equivY])
				tileRef as TTileRef = value[GetIndex(equivX, equivY, size)]
				newTile as TMapTile = CreateNewTile(tileRef)
				matrix[equivX, equivY] = newTile
				if assigned(newTile):
					newTile.Place(equivX, equivY, index, tileRef, FTileset)

	private def CreateNewTile(value as TTileRef) as TMapTile:
		tileClass as TMapTileClass
		return null if (value.Value cast short) == -1
		tileGroup as TTileGroup = FTileset.Records[value.Group].Group
		tileType as TTileType = tileGroup.TileType
		if tileType == TTileType.None:
			tileClass = classOf(TMapTile)
		elif tileType == TTileType.Bordered:
			tileClass = classOf(TBorderTile)
		elif tileType == TTileType.Animated:
			tileClass = classOf(TAnimTile)
		elif tileType == TTileType.Animated | TTileType.Bordered:
			tileClass = (classOf(TOceanTile) if tileGroup.Ocean else classOf(TShoreTile))
		else:
			raise ESpriteError('Unknown tile type.')
		return tileClass.Create(self, tileGroup.Filename)

	private def FullCreateNewTile(x as int, y as int, layer as int) as TMapTile:
		tile as TTileRef = FMap.GetTile(x, y, layer)
		result = CreateNewTile(tile)
		if assigned(result):
			result.Place(x, y, layer, tile, FTileset)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def GetMaxLayer() as int:
		return (FTiles.Count - 1)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def GetDefTile(layer as int, x as int, y as int) as TMapTile:
		return GetTile(x, y, layer)

	private def DrawBG():
		FBgImage.Scroll()
		FBgImage.X = Viewport.WorldX
		until FBgImage.X + FBgImage.OffsetX > Viewport.WorldX + Canvas.Width:
			FBgImage.Y = Viewport.WorldY
			until FBgImage.Y + FBgImage.OffsetY > Viewport.WorldY + Canvas.Height:
				FRenderer.Reset()
				FBgImage.Draw()
				FRenderer.Render(FEngine.Canvas.RenderTarget)
				FBgImage.Y += FBgImage.PatternHeight
			FBgImage.X += FBgImage.PatternWidth

	private def GetMapID() as int:
		return MapObj.ID

	private def OverhangPassable(x as int, y as int) as bool:
		u as TTile = GetTile(x, y - 1, 0)
		return (assigned(u) and not (TTileAttribute.Overhang in u.Attributes))

	private def Tint():
		gla = array(single, 4)
		handle as int = FShaderEngine.ShaderProgram('default', 'tint', 'shift')
		FShaderEngine.UseShaderProgram(handle)
		FShaderEngine.SetUniformValue(handle, 'hShift', 0)
		FShaderEngine.SetUniformValue(handle, 'valMult', 1.0 cast single)
		Array.Copy(FFadeColor, gla, 4)
		gla[3] = 1
		FShaderEngine.SetUniformValue(handle, 'rgbValues', gla)
		FShaderEngine.SetUniformValue(handle, 'satMult', FFadeColor[3])

	private def AdjustCoords(ref x as int, ref y as int):
		halfwidth as int = Math.Min(round(Canvas.Width / 2.0), (Width + 1) * 8)
		halfheight as int = Math.Min(round(Canvas.Height / 2.0), (Height + 1) * 8)
		maxwidth as int = ((Width + 1) * TILE_SIZE.x) - halfwidth
		maxheight as int = ((Height + 1) * TILE_SIZE.y) - halfheight
		unless (TWraparound.Horizontal in FMap.Wraparound):
			if x < halfwidth:
				x = halfwidth
			if x > maxwidth:
				x = maxwidth
		unless (TWraparound.Vertical in FMap.Wraparound):
			if y < halfheight:
				y = halfheight
			if y > maxheight:
				y = maxheight
		x -= halfwidth
		x -= halfwidth % TILE_SIZE.x
		y -= halfheight
		y -= halfheight % TILE_SIZE.y
		unless (TWraparound.Horizontal in FMap.Wraparound):
			x = clamp(x, 0, (self.Width * TILE_SIZE.x) - Canvas.Width)
		unless (TWraparound.Vertical in FMap.Wraparound):
			y = clamp(y, 0, (self.Height * TILE_SIZE.y) - Canvas.Height)

	private def AdjustCoordsForDisplacement(ref x as int, ref y as int):
		halfwidth as int = Math.Min(round((Canvas.Width cast double) / 2.0), (Width + 1) * 8)
		halfheight as int = Math.Min(round((Canvas.Height cast double) / 2.0), (Height + 1) * 8)
		x -= halfwidth
		y -= halfheight

	private def SetCurrentParty(value as TCharSprite):
		FCurrentParty = value
		if assigned(value):
			value.Tiles[0].Parent = self
			value.Tiles[1].Parent = self
			value.Tiles[0].Engine = self
			value.Tiles[1].Engine = self
		if assigned(FPartySpriteChanged):
			FPartySpriteChanged(value)

	private def EndTransition():
		FGameState = FSavedState

	private def CheckDisplacement():
		delta as single
		panned as bool = false
		if FDispGoalX != FDisplacementX:
			delta = MoveTowards(FDisplacementTime.TimeRemaining, FDisplacementX, FDispGoalX)
			clamp(FDisplacementX, -FDispBaseX, (Width * TILE_SIZE.x) - Canvas.Width)
			panned = true
		if FDispGoalY != FDisplacementY:
			delta = MoveTowards(FDisplacementTime.TimeRemaining, FDisplacementY, FDispGoalY)
			clamp(FDisplacementY, -FDispBaseY, (Height * TILE_SIZE.y) - Canvas.Height)
			panned = true
		FDisplacing = panned
		if (not FDisplacing) and FReturning:
			FReturning = false
			self.ClearDisplacement()

	private def ClearDisplacement():
		FDestination.x += commons.round(FDisplacementX)
		FDisplacementX = 0
		FDestination.y += commons.round(FDisplacementY)
		FDisplacementY = 0
		FDispGoalX = 0
		FDispGoalY = 0
		FDisplacementTime = null
		Viewport.WorldX = commons.round(Viewport.WorldX)
		Viewport.WorldY = commons.round(Viewport.WorldY)
		MoveTo(Math.Truncate(FCurrentParty.BaseTile.X), Math.Truncate(FCurrentParty.BaseTile.Y))

	private def ApplyDisplacement():
		let SHAKE_AMP = 1.8
		if FShakeTime > 0:
			FShakeCounter = (FShakeCounter + FShakeSpeed) % SHAKE_MAX
			shakeBias as single = (FShakePower * LSineTable[FShakeCounter]) * SHAKE_AMP
			i = Math.Max(round(FShakeTime / 32.0), 1)
			FShakeTime -= FShakeTime / i
		else:
			shakeBias = 0
		Viewport.WorldX = (Viewport.WorldX + FDisplacementX) - shakeBias
		unless TWraparound.Horizontal in FMap.Wraparound:
			Viewport.WorldX = clamp(Math.Round(Viewport.WorldX), 0, (Width * TILE_SIZE.x) - Canvas.Width)
		Viewport.WorldY = Viewport.WorldY + FDisplacementY
		unless TWraparound.Vertical in FMap.Wraparound:
			Viewport.WorldY = clamp(Math.Round(Viewport.WorldY), 0, (Height * TILE_SIZE.y) - Canvas.Height)
		if ((FDisplacementX - shakeBias) != 0) or (FDisplacementY != 0):
			for i in range(FMap.TileMap.Length):
				LoadTileMatrix(FMap.TileMap[i], i,
					GPU_MakeRect(
						Math.Truncate(Viewport.WorldX / TILE_SIZE.x),
						Math.Truncate(Viewport.WorldY / TILE_SIZE.y),
						FViewport.w,
						FViewport.h))

	private def InternalCenterOn(px as int, py as int):
		AdjustCoords(px, py)
		FDestination.x = px
		FDestination.y = py
		aX as int = px / TILE_SIZE.x
		aY as int = py / TILE_SIZE.y
		self.SetViewport(GPU_MakeRect(aX, aY, Canvas.Width / TILE_SIZE.x, Canvas.Height / TILE_SIZE.y), px, py)
		FDispBaseX = Viewport.WorldX
		FDispBaseY = Viewport.WorldY

	private def SetScreenLocked(value as bool):
		halfWidth as int = Math.Min(round(Canvas.Width / 2.0), (Width + 1) * 8)
		halfHeight as int = Math.Min(round(Canvas.Height / 2.0), (Height + 1) * 8)
		FScreenLocked = value
		if value:
			FCenter = SgPoint(round(Viewport.WorldX - FDisplacementX) + halfWidth, round(Viewport.WorldY - FDisplacementY) + halfHeight)

	private def DrawNormal():
		if assigned(FCurrentParty) and not FScreenLocked:
			centerTile as TTile = FCurrentParty.Tiles[1]
			CenterOnWorldCoords(centerTile.X + ((centerTile.Width + TILE_SIZE.x) / 2), centerTile.Y + TILE_SIZE.y)
		elif FScreenLocked:
			CenterOnWorldCoords(FCenter.x, FCenter.y)
		ApplyDisplacement()
		if assigned(FBgImage):
			DrawBG()
		super.Draw()
		if assigned(FOnDrawWeather):
			FOnDrawWeather()

	protected override def GetHeight() as int:
		return MapObj.Size.y

	protected override def GetWidth() as int:
		return MapObj.Size.x

	protected override def CreateViewport() as Viewport:
		return CompositeViewport(self.Canvas.Width, self.Canvas.Height, FMap.Size.x * TILE_SIZE.x, FMap.Size.y * TILE_SIZE.y)

	public def constructor(map as TRpgMap, viewport as GPU_Rect, shaderEngine as TdmShaders, Canvas as SdlCanvas, \
			tileset as TTileSet, images as SdlImages):
		FMap = map
		super(null, Canvas)
		FShaderEngine = shaderEngine
		self.Images = images
		FTiles = List[of TMatrix[of TMapTile]]()
		FTileset = tileset
		size as SgPoint = FMap.Size
		_tileViewport = _viewport
		FMapRect = GPU_MakeRect(0, 0, size.x, size.y)
		FPanSpeed = BASESPEED
		for i in range(FMap.TileMap.Length):
			FTiles.Add(TMatrix[of TMapTile](size))
		self.SetViewport(viewport)
		unless string.IsNullOrEmpty(map.BgName):
			FBgImage = TBackgroundSprite(self, map)
			FBgImage.Image = images.EnsureBGImage("Backgrounds\\$(map.BgName).png", map.BgName)
		FMapObjects = TRpgObjectList[of TMapSprite]()
		for mapObj in map.MapObjects:
			AddMapObject(mapObj)
		FSpriteLocations = TSpriteLocations()
		for i in range(FFadeColor.Length):
			FFadeColor[i] = 1

	private new def Destroy():
		lock FMapObjects:
			for obj in FMapObjects:
				obj.Dispose()
		/*
		for layer in FTiles:
			for tile in layer:
				tile.Dispose() unless tile is null
		*/

	public def AssignTile(x as int, y as int, layer as int, tile as TTileRef):
		if (x >= FMap.Size.x) or (y >= FMap.Size.y):
			return
		FMap.AssignTile(x, y, layer, tile)
		if assigned(FTiles[layer][x, y]):
			FTiles[layer][x, y].Dead()
		newTile as TMapTile = CreateNewTile(tile)
		FTiles[layer][x, y] = newTile
		newTile.Place(x, y, layer, tile, FTileset)

	public def UpdateBorders(x as int, y as int, layer as int) as bool:
		tile as TBorderTile
		neighbors as TDirs8
		
		def TestInclude(x as int, y as int, neighbor as TDirs8):
			if NormalizePoint(x, y):
				if assigned(FTiles[layer][x, y]) and not tile.SharesBorder(FTiles[layer][x, y]):
					neighbors |= neighbor
			else:
				neighbors |= neighbor
		
		tileRef as TTileRef
		newTile as TMapTile
		result = false
		return result unless NormalizePoint(x, y)
		return result unless FTiles[layer][x, y] isa TBorderTile
		neighbors = TDirs8.None
		tile = FTiles[layer][x, y] cast TBorderTile
		TestInclude(x, y - 1, TDirs8.n)
		TestInclude(x + 1, y - 1, TDirs8.ne)
		TestInclude(x + 1, y, TDirs8.e)
		TestInclude(x + 1, y + 1, TDirs8.se)
		TestInclude(x, y + 1, TDirs8.s)
		TestInclude(x - 1, y + 1, TDirs8.sw)
		TestInclude(x - 1, y, TDirs8.w)
		TestInclude(x - 1, y - 1, TDirs8.nw)
		tileRef = FMap.GetTile(x, y, layer)
		if (neighbors cast byte) != tileRef.Tile:
			result = true
			tileRef.Tile = neighbors cast byte
			FMap.AssignTile(x, y, layer, tileRef)
			FTiles[layer][x, y].Dead()
			newTile = self.CreateNewTile(tileRef)
			FTiles[layer][x, y] = newTile
			newTile.Place(X, Y, layer, tileRef, FTileset)
		return result

	public def Process():
		self.Dead()
		var blocked = GMenuEngine.Value.State == TMenuState.ExclusiveShared
		lock FMapObjects:
			for sprite in FMapObjects:
				sprite.Place()
				sprite.MoveTick(blocked)
		if assigned(FCurrentParty):
			FCurrentParty.Place()
			FCurrentParty.MoveTick(blocked)
		CheckDisplacement()

	public def IsHeroIn(location as TMboxLocation) as bool:
		third as int = Canvas.Height / 3
		yPos as int = (FCurrentParty.Location.y * TILE_SIZE.y) - Math.Truncate(Viewport.WorldY)
		caseOf location:
			case TMboxLocation.Top: result = yPos <= third + TILE_SIZE.y
			case TMboxLocation.Middle: result = (yPos <= (third * 2) + TILE_SIZE.y) and (yPos > third)
			case TMboxLocation.Bottom: result = yPos > third * 2
			default: raise Exception("Invalid mbox location: $location")
		return result

	public def AdvanceFrame():
		TTile.Heartbeat()

	public def GetTile(x as int, y as int, layer as int) as TMapTile:
		if not NormalizePoint(x, y):
			return null
		if not assigned(FTiles[0][x, y]):
			for i in range(0, FTiles.Count):
				FTiles[i][x, y] = FullCreateNewTile(x, y, i)
		return FTiles[layer][x, y]

	public def TileInFrontOf(ref location as SgPoint, direction as TDirections) as TMapTile:
		caseOf direction:
			case TDirections.Up:
				location = SgPoint(location.x, location.y - 1)
			case TDirections.Right:
				location = SgPoint(location.x + 1, location.y)
			case TDirections.Down:
				location = SgPoint(location.x, location.y + 1)
			case TDirections.Left:
				location = SgPoint(location.x - 1, location.y)
		if NormalizePoint(location.x, location.y):
			result = self.Tiles[0, location.x, location.y]
		else:
			result = null
		return result

	public def RecreateTileMatrix():
		FTiles = List[of TMatrix[of TMapTile]]()
		for i in range(FMap.TileMap.Length):
			FTiles.Add(TMatrix[of TMapTile](FMap.Size))
		self.SetViewport(FViewport)

	public def AddMapObject(obj as TRpgMapObject) as TMapSprite:
		result as TMapSprite
		if obj.ID == 0:
			return null
		if obj.IsTile:
			result = TEventSprite(obj, self)
		else:
			result = TCharSprite(obj, self)
		GEnvironment.value.AddEvent(result)
		lock FMapObjects:
			FMapObjects.Add(result)
		return result

	public def ReloadMapObjects():
		lock FMapObjects:
			for sprite in FMapObjects:
				GEnvironment.value.AddEvent(sprite)

	public def DeleteMapObject(obj as TMapSprite):
		lock FMapObjects:
			FSpriteLocations.RemovePair(obj.Location, obj)
			FMapObjects.Remove(obj)

	public def SwapMapSprite(old as TMapSprite, aNew as TMapSprite):
		lock FMapObjects:
			var index = FMapObjects.IndexOf(old)
			if FSpriteLocations.KeyHasValue(old.Location, old):
				FSpriteLocations.RemovePair(old.Location, old)
			FMapObjects[index] = aNew

	public def Passable(x as int, y as int, direction as TDirections) as bool:
		TRANSLATE = (TTileAttribute.Up, TTileAttribute.Right, TTileAttribute.Down, TTileAttribute.Left)
		tile as TTile
		for i in range(MaxLayer, -1, -1):
			tile = GetTile(x, y, i)
			if assigned(tile):
				if (TTileAttribute.Ceiling in tile.Attributes) and (i > 0) and (TRANSLATE[direction] in tile.Attributes):
					continue
				if TTileAttribute.Overhang in tile.Attributes:
					return OverhangPassable(x, y)
				else:
					return TRANSLATE[direction] in tile.Attributes
		raise Exception("No tiles at location ($x, $y)!") //should not see this

	public def Passable(x as int, y as int) as bool:
		dir as TFacing
		result = false
		for dir in range(TDirections.Left + 1):
			result = result or Passable(x, y, dir)
		return result

	public def Passable(location as SgPoint, direction as TDirections, Character as TMapSprite) as bool:
		sprites as (TMapSprite) = self.SpritesAt(location, Character).ToArray()
		if sprites.Length > 0:
			var result = true
			for sprite in sprites:
				if Character isa TCharSprite and sprite isa TCharSprite and Character.Location == sprite.Location:
					result = true
				elif assigned(sprite.Event?.CurrentPage) and not sprite.SlipThrough:
					result = result and ((sprite.BaseTile.Z != Character.BaseTile.Z) \
											or ((Character isa TCharSprite) and (sprite isa TEventSprite) \
												and (sprite.Event.CurrentPage.ZOrder != 1)))
				elif sprite.Event == null:
					result = result and (sprite.BaseTile.Z != Character.BaseTile.Z)
		else: result = Passable(location, direction)
		return result

	public def Passable(location as SgPoint, direction as TDirections) as bool:
		return Passable(location.x, location.y, direction)

	public def EdgeCheck(x as int, y as int, direction as TDirections) as bool:
		caseOf direction:
			case TDirections.Up:
				result = (y > 0) or (TWraparound.Vertical in FMap.Wraparound)
			case TDirections.Right:
				result = (x < FMap.Width - 1) or (TWraparound.Horizontal in FMap.Wraparound)
			case TDirections.Down:
				result = (y < FMap.Height - 1) or (TWraparound.Vertical in FMap.Wraparound)
			case TDirections.Left:
				result = (x > 0) or (TWraparound.Horizontal in FMap.Wraparound)
			default:
				raise ESpriteError("Bad Direction value: $(ord(direction)) is out of bounds for TDirections")
		return result

	public def EnsureImage(filename as string):
		if (filename != '') and (not self.Images.Contains(filename)):
			self.Images.AddSpriteFromArchive("Sprites\\$filename.png", filename, SPRITE_SIZE, null)

	public override def Draw():
		caseOf self.State:
			case TGameState.Map, TGameState.Message:
				DrawNormal()
			case TGameState.Fading:
				if FErasing:
					self.Canvas.Clear(SDL_BLACK, 255)
				else: DrawNormal()
			case TGameState.Menu, TGameState.Battle, TGameState.Minigame, TGameState.Sleeping:
				raise 'Unsupported game State'

	public def CanExit(x as int, y as int, direction as TDirections, character as TMapSprite) as bool:
		result = false
		if Passable(SgPoint(x, y), direction, character):
			if EdgeCheck(x, y, direction):
				opposite as TDirections = opposite_facing(direction)
				result = Passable(character.InFront, opposite, character)
		return result

	public def SpritesAt(location as SgPoint, exceptFor as TMapSprite) as TMapSprite*:
		result as TMapSprite*
		if FSpriteLocations.ContainsKey(location):
			result = FSpriteLocations[location]
		if assigned(exceptFor) and assigned(result):
			result = result.Where({s | s != exceptFor})
		return ( result if result is not null else System.Linq.Enumerable.Empty[of TMapSprite]() )

	public def AddLocation(position as SgPoint, Character as TMapSprite):
		FSpriteLocations.Add(position, Character)

	public def LeaveLocation(position as SgPoint, Character as TMapSprite):
		if FSpriteLocations.KeyHasValue(position, Character):
			FSpriteLocations.RemovePair(position, Character)

	private static def SafeMod(big as int, small as int) as int:
		return ((big % small) + small) % small

	public def NormalizePoint(ref x as int, ref y as int) as bool:
		var result = true
		var newX = SafeMod(x, FTiles[0].Width)
		var newY = SafeMod(y, FTiles[0].Height)
		result = result and ((newX == x) or (TWraparound.Horizontal in FMap.Wraparound))
		result = result and ((newY == y) or (TWraparound.Vertical in FMap.Wraparound))
		x = newX
		y = newY
		return result

	public def ResizeCanvas():
		self.Canvas.Resize()
		self.Viewport.VisibleWidth = Canvas.Width
		self.Viewport.VisibleHeight = Canvas.Height

	public def OnMap(where as SgPoint) as bool:
		return (clamp(where.x, 0, Width) == where.x) and (clamp(where.y, 0, Height) == where.y)

	public def CenterOn(x as int, y as int):
		px = x * TILE_SIZE.x
		py = y * TILE_SIZE.y
		InternalCenterOn(px, py)

	public def CenterOnWorldCoords(x as single, y as single):
		InternalCenterOn(Math.Round(x), Math.Round(y))

	public def ScrollMap(newPosition as SgPoint):
		reducedPosition as SgPoint = newPosition / TILE_SIZE
		FViewport = GPU_MakeRect(reducedPosition.x, reducedPosition.y, FViewport.w, FViewport.h)
		self.Viewport.WorldX = newPosition.x
		self.Viewport.WorldY = newPosition.y

	public def SetBG(name as string, x as int, y as int, scrollX as TMapScrollType, scrollY as TMapScrollType):
		bgName as string = 'Background ' + name
		if assigned(FBgImage) and (FBgImage.ImageName != bgName):
			FBgImage.Dead()
			FBgImage = null
		return if string.IsNullOrEmpty(name)
		filename as string = name
		if not ArchiveUtils.GraphicExists(filename, 'Backgrounds'):
			raise System.IO.FileNotFoundException("Background image $name not found!")
		if not assigned(FBgImage):
			self.Images.EnsureBGImage('Backgrounds\\' + filename, bgName)
			FBgImage = TBackgroundSprite(FEngine, x, y, scrollX, scrollY)
		else:
			FBgImage.ScrollData.X = x
			FBgImage.ScrollData.Y = y
			FBgImage.ScrollData.ScrollX = scrollX
			FBgImage.ScrollData.ScrollY = scrollY
		FBgImage.ImageName = bgName

	public def ChangeTileset(value as TTileSet):
		if value == FTileset:
			return
		FTileset = value
		FTiles = List[of TMatrix[of TMapTile]]()
		size as SgPoint = FMap.Size
		for i in range(FMap.TileMap.Length):
			FTiles.Add(TMatrix[of TMapTile](size))
		oldViewport as GPU_Rect = FViewport
		FViewport.w = -1
		self.SetViewport(oldViewport)

	public def CopyState(base as T2kSpriteEngine):
		FFadeColor = base.FFadeColor
		FFadeTime = base.FFadeTime
		FFadeTarget = base.FFadeTarget

	public def FadeTo(r as int, g as int, b as int, s as int, time as int):
		FFadeTarget[0] = r / 255.0
		FFadeTarget[1] = g / 255.0
		FFadeTarget[2] = b / 255.0
		FFadeTarget[3] = s / 255.0
		FFadeTime = Timestamp(time * 100)

	public def Fade() as bool:
		var result = false
		if assigned(FFadeTime):
			time as uint = FFadeTime.TimeRemaining
			for i in range(FFadeTarget.Length):
				MoveTowards(time, FFadeColor[i], FFadeTarget[i])
			if time == 0:
				FFadeTime = null
				if FGameState == TGameState.Fading:
					EndTransition()
		for i in range(4):
			result = result or (FFadeColor[i] != 1)
		if result:
			self.Tint()
		return result

	public def FlashScreen(r as int, g as int, b as int, power as int, duration as int):
		FFlashColor.r = r
		FFlashColor.g = g
		FFlashColor.b = b
		FFlashColor.a = power
		duration = duration * 100
		FFlashTime = Timestamp(duration)
		FFlashDuration = duration

	public def FadeOut(time as int):
		FadeTo(0, 0, 0, 255, time)

	public def FadeIn(time as int):
		FadeTo(255, 255, 255, 255, time)

	public def BeginTransition(erasing as bool):
		FSavedState = FGameState
		FGameState = TGameState.Fading
		FBlank = false
		FErasing = erasing
		FFadeTime = null

	public def EndErase():
		EndTransition()
		FBlank = true

	public def EndShow():
		EndTransition()
		FBlank = false

	public def DrawFlash():
		flashTime as int
		alpha as byte
		return if FFlashTime == null
		flashTime = FFlashTime.TimeRemaining
		if flashTime == 0:
			FFlashTime = null
			return
		alpha = round(FFlashColor.a * ((flashTime cast double) / (FFlashDuration cast double)))
		color = FFlashColor
		color.a = alpha
		GPU_RectangleFilled(Canvas.RenderSurface.RenderTarget, 0, 0, Canvas.Width, Canvas.Height, color)

	public def DisplaceTo(x as int, y as int):
		AdjustCoordsForDisplacement(x, y)
		FDispGoalX = (FDispGoalX + x) - Viewport.WorldX
		FDispGoalY = (FDispGoalY + y) - Viewport.WorldY
		FDisplacing = true

	public def SetDispSpeed(speed as byte):
		if speed in range(MOVESPEED.Length) and speed > 0:
			var xDistance = Math.Abs(FDispGoalX)
			var yDistance = Math.Abs(FDispGoalY)
			var distance = Math.Max(xDistance, yDistance)
			var disptime = round(distance * MOVESPEED[speed])
			FDisplacementTime = Timestamp(disptime)

	public def ShakeScreen(power as int, Speed as int, duration as int):
		FShakePower = power
		FShakeSpeed = Speed
		FShakeTime = duration

	public def MoveTo(x as int, y as int):
		AdjustCoords(x, y)
		FDestination.x = x
		FDestination.y = y

	public def Wake():
		FGameState = TGameState.Map

	public def TileInViewport(tile as TTile):
		return self._tileViewport.SpriteInViewport(tile)

	internal def ReleaseMap():
		FMap = null
/*
	public Viewport as GPU_Rect:
		get: return FViewport
		set: SetViewport(value)
*/
	public MaxLayer as int:
		get: return GetMaxLayer()

	public CurrentParty as TCharSprite:
		get: return FCurrentParty
		set: SetCurrentParty(value)

	public Tiles[layer as int, x as int, y as int] as TMapTile:
		get: return GetDefTile(layer, x, y)

	public MapID as int:
		get: return GetMapID()

	public Height as int:
		get: return GetHeight()

	public Width as int:
		get: return GetWidth()

	public ScreenLocked as bool:
		get: return FScreenLocked
		set: SetScreenLocked(value)

static class GSpriteEngine:
	public value as T2kSpriteEngine
