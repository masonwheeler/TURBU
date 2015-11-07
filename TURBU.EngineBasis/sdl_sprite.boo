namespace sdl.sprite

import Pythia.Runtime
import System
import System.Collections.Generic
import turbu.multimaps
import TURBU.Meta
import SDL.ImageManager
import sdl.canvas
import SG.defs
import dm.shaders
import SDL2
import SDL2.SDL2_GPU
import System.Drawing

enum TImageType:
	itSingleImage
	itSpriteSheet
	itRectSet

enum TAnimPlayMode:
	Forward
	Backward
	PingPong

class ESpriteError(Exception):
	def constructor(message as string):
		super(message)

class TSpriteList(List[of TSprite]):
	pass

class TFastSpriteList(List[of TSprite]):

	internal FSprites as (TSpriteList)

	private FSorted as bool

	public def constructor():
		i as int
		super()
		Array.Resize[of TSpriteList](FSprites, 11)
		for I in range(0, 11):
			FSprites[i] = TSpriteList()

	public new def Add(ASprite as TSprite) as int:
		z as int
		result = Count
		super.Add(ASprite)
		z = ASprite.Z
		if z >= FSprites.Length:
			Array.Resize[of TSpriteList](FSprites, (z + 1))
		if FSprites[z] == null:
			FSprites[z] = TSpriteList()
		FSprites[z].Add(ASprite)
		FSorted = false
		return result

	public new def Remove(ASprite as TSprite) as int:
		assert assigned(FSprites[ASprite.Z])
		FSprites[ASprite.Z].Remove(ASprite)
		result = super.IndexOf(ASprite)
		super.Remove(ASprite)
		return result

	public new def IndexOf(value as TSprite) as int:
		if not FSorted:
			self.Sort()
			FSorted = true
		return self.BinarySearch(value)

[Disposable(Destroy, true)]
class TSprite(TObject):

	protected FDead as bool

	protected FWidth as int

	protected FHeight as int
	
	public virtual Width as int:
		get: return FWidth
		set: FWidth = value

	public virtual Height as int:
		get: return FHeight
		set: FHeight = value

	protected FOrigin as TSgPoint

	[Property(Name)]
	protected FName as string

	[Property(X)]
	protected FX as Single

	[Property(Y)]
	protected FY as Single

	protected FZ as uint

	protected FZset as bool

	[Property(Visible)]
	protected FVisible as bool

	protected FImageName as string = ''

	protected FImageIndex as int

	[Property(ImageIndex)]
	protected FPatternIndex as int

	[Property(Moves)]
	protected FMoves as bool

	[Property(Tag)]
	protected FTag as int

	[DisposeParent]
	protected FImage as TSdlImage

	[Property(MirrorX)]
	protected FMirrorX as bool

	[Property(MirrorY)]
	protected FMirrorY as bool

	[Property(Red)]
	protected FRed as Byte

	[Property(Green)]
	protected FGreen as Byte

	[Property(Blue)]
	protected FBlue as Byte

	[Property(Alpha)]
	protected FAlpha as Byte

	[Property(Angle)]
	protected FAngle as Single

	[Property(DrawFx)]
	protected FDrawFX as int

	[Property(ScaleX)]
	protected FScaleX as Single

	[Property(ScaleY)]
	protected FScaleY as Single

	[Property(OffsetX)]
	protected FOffsetX as Single

	[Property(OffsetY)]
	protected FOffsetY as Single

	[Property(ImageType)]
	protected FImageType as TImageType

	[Property(Pinned)]
	protected FPinned as bool

	[Property(VisibleArea)]
	protected FVisibleArea as Rectangle

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetPatternWidth() as int:
		return (FImage.TextureSize.x if assigned(FImage) else 0)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetPatternHeight() as int:
		return (FImage.TextureSize.y if assigned(FImage) else 0)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetPatternCount() as int:
		return FImage.Count

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetBoundsRect() as GPU_Rect:
		return GPU_MakeRect(Math.Round(FX), Math.Round(FY), Width, Height)

	protected def SetParent(value as TParentSprite):
		return if FParent == value
		
		if assigned(FParent):
			FParent.UnDraw(self)
			FParent.List.Remove(self)
		FParent = value
		value.Add(self)

	protected def SetImage(value as TSdlImage):
		return if value is null
		
		FImage = value
		FImageName = FImage.Name
		if FImageType in (TImageType.itSingleImage, TImageType.itSpriteSheet):
			FWidth = FImage.TextureSize.x
			FHeight = FImage.TextureSize.y

	[Property(Engine), DisposeParent]
	protected FEngine as TSpriteEngine

	[DisposeParent]
	protected FParent as TParentSprite

	protected FRenderSpecial as bool

	protected virtual def GetDrawRect() as GPU_Rect:
		return GPU_MakeRect(FOrigin.x, FOrigin.y, FWidth, FHeight)

	protected virtual def SetDrawRect(Value as GPU_Rect):
		FOrigin = sgPoint(Value.x, Value.y)
		FWidth = Value.w
		FHeight = Value.h
		FImageType = TImageType.itRectSet

	internal def Render():
		followX as single
		followY as single
		if FPinned:
			followX = 0
			followY = 0
		else:
			followX = FEngine.WorldX
			followY = FEngine.WorldY
		var topleft = sgPoint(Math.Truncate(FX + FOffsetX - followX), Math.Truncate(FY + FOffsetY - followY))
		flip as SDL.SDL_RendererFlip = SDL.SDL_RendererFlip.SDL_FLIP_NONE
		flip |= SDL.SDL_RendererFlip.SDL_FLIP_HORIZONTAL if MirrorX
		flip |= SDL.SDL_RendererFlip.SDL_FLIP_VERTICAL if MirrorY
		caseOf FImageType:
			case TImageType.itSingleImage: FImage.Draw(topleft, flip)
			case TImageType.itSpriteSheet: FImage.DrawSprite(topleft, FPatternIndex, flip)
			case TImageType.itRectSet: FImage.DrawRect(topleft, self.DrawRect, flip)

	protected virtual def DoDraw():
		return if (not FVisible) or (FImage == null)
		img as TSdlImage = FEngine.Images[FImageIndex]
		if img is null or img.Name != FImageName:
			SetImageName(FImageName)
			return if FImage == null
		if FRenderSpecial:
			self.Render()
		else: FEngine.Renderer.Draw(self)

	protected virtual def DoMove(MoveCount as single):
		pass

	protected virtual def SetImageName(Value as string):
		if FImageName != Value:
			FImageName = Value
			if assigned(FEngine):
				SetImage(FEngine.Images.Image[FImageName])
			if assigned(FImage):
				if FImageType != TImageType.itRectSet:
					if FImage.Count > 1:
						FImageType = TImageType.itSpriteSheet
					else:
						FImageType = TImageType.itSingleImage
				FImageIndex = FEngine.Images.IndexOf(FImageName)
			else:
				System.Diagnostics.Debugger.Break()

	protected def SetZ(Value as uint):
		if (FZ != Value) or (not FZset):
			if assigned(FParent):
				if FZset:
					FParent.UnDraw(self)
				FZ = Value
				FParent.AddDrawList(self)
			else:
				FZ = Value
			FZset = true

	protected virtual def InVisibleRect() as bool:
		return X > (FEngine.WorldX - (Width * 2)) and \
		       Y > (FEngine.WorldY - (Height * 2)) and \
		       X < (FEngine.WorldX + FEngine.VisibleWidth) and \
		       Y < (FEngine.WorldY + FEngine.VisibleHeight)

	public def constructor(AParent as TParentSprite):
		if assigned(AParent):
			FParent = AParent
			FParent.Add(self)
			FEngine = ((AParent cast TSpriteEngine) if AParent isa TSpriteEngine else AParent.Engine)
			++FEngine.FAllCount
		FVisible = true

	private def Destroy():
		if assigned(FParent):
			--FEngine.FAllCount
			FParent.Remove(self)
			FEngine.FDeadList.Remove(self)

	public virtual def Assign(Value as TSprite):
		FName = Value.Name
		FImageName = Value.ImageName
		FX = Value.X
		FY = Value.Y
		FZ = Value.Z
		FPatternIndex = Value.FPatternIndex
		FVisible = Value.Visible
		FTag = Value.Tag

	public virtual def Move(MoveCount as single):
		if FMoves:
			DoMove(MoveCount)

	public def SetPos(X as Single, Y as Single):
		FX = X
		FY = Y

	public def SetPos(X as Single, Y as Single, Z as int):
		FX = X
		FY = Y
		FZ = Z

	public virtual def Draw():
		if FVisible and (not FDead) and self.InVisibleRect:
			DoDraw()

	public virtual def Dead():
		if assigned(FEngine) and (not FDead):
			FDead = true
			FEngine.FDeadList.Add(self)

	public def DrawTo(dest as GPU_Rect):
		caseOf FImageType:
			case TImageType.itSingleImage:
				FImage.DrawTo(dest)
			case TImageType.itSpriteSheet:
				FImage.DrawSpriteTo(dest, FPatternIndex)
			case TImageType.itRectSet:
				FImage.DrawRectTo(dest, self.DrawRect)

	public def SetSpecialRender():
		FRenderSpecial = true

	public Z as uint:
		get:
			return FZ
		set:
			SetZ(value)

	public ImageName as string:
		get:
			return FImageName
		set:
			SetImageName(value)

	public Image as TSdlImage:
		get:
			return FImage
		set:
			SetImage(value)

	public PatternWidth as int:
		get:
			return GetPatternWidth()

	public PatternHeight as int:
		get:
			return GetPatternHeight()

	public PatternCount as int:
		get:
			return GetPatternCount()

	public Parent as TParentSprite:
		get:
			return FParent
		set:
			SetParent(value)

	public BoundsRect as GPU_Rect:
		get:
			return GetBoundsRect()

	public DrawRect as GPU_Rect:
		get:
			return GetDrawRect()
		set:
			SetDrawRect(value)

[Disposable(Destroy, true)]
class TParentSprite(TSprite):

	internal def UnDraw(sprite as TSprite):
		if assigned(FSpriteList):
			FSpriteList.Remove(sprite)

	[Getter(List)]
	protected FList as TSpriteList

	[Getter(SpriteList)]
	protected FSpriteList as TFastSpriteList

	protected def GetCount() as int:
		if assigned(FList):
			result = FList.Count
		else:
			result = 0
		return result

	protected def GetItem(Index as int) as TSprite:
		if assigned(FList):
			result = FList[Index]
		else:
			raise ESpriteError("Index of the list exceeds the range. ($Index)")
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	internal def AddDrawList(Sprite as TSprite):
		if not assigned(FSpriteList):
			FSpriteList = TFastSpriteList()
		FSpriteList.Add(Sprite)

	protected def ClearSpriteList():
		if assigned(FSpriteList):
			FSpriteList.Clear()
		else:
			FSpriteList = TFastSpriteList()

	private new def Destroy():
		self.Clear()

	public override def Move(movecount as single):
		i as int
		super.Move(movecount)
		for i in range(0, Count):
			self[i].Move(movecount)

	public def Clear():
		if assigned(FSpriteList):
			FSpriteList.Clear()
		if assigned(FList):
			FList.Clear()

	public override def Draw():
		super.Draw()
		if self.Visible and assigned(FSpriteList):
			for i in range(0, FSpriteList.Count):
				FSpriteList[i].Draw()

	public def Add(Sprite as TSprite):
		if FList == null:
			FList = TSpriteList()
		FList.Add(Sprite)
		if Sprite.Z != 0:
			if FSpriteList == null:
				FSpriteList = TFastSpriteList()
			FSpriteList.Add(Sprite)

	public def Remove(Sprite as TSprite):
		if assigned(FList):
			FList.Remove(Sprite)
			if assigned(FSpriteList):
				FSpriteList.Remove(Sprite)
				if FSpriteList.Count == 0:
					FSpriteList = null

	public self[Index as int] as TSprite:
		get:
			return GetItem(Index)

	public Count as int:
		get:
			return GetCount()

	def constructor(AParent as TParentSprite):
		super(AParent)

class TAnimatedSprite(TParentSprite):

	[Property(DoAnimate)]
	private FDoAnimate as bool

	[Property(AnimLooped)]
	private FAnimLooped as bool

	private FAnimStart as int

	[Property(AnimCount)]
	private FAnimCount as int

	[Property(AnimSpeed)]
	private FAnimSpeed as Single

	[Property(AnimPos)]
	private FAnimPos as Single

	[Getter(AnimEnded)]
	private FAnimEnded as bool

	private FDoFlag1 as bool

	private FDoFlag2 as bool

	[Property(AnimPlayMode)]
	private FAnimPlayMode as TAnimPlayMode

	private def SetAnimStart(Value as int):
		if FAnimStart != Value:
			FAnimStart = Value
			FAnimPos = Value

	protected override def DoMove(MoveCount as Single):
		if not FDoAnimate:
			return
		caseOf FAnimPlayMode:
			case TAnimPlayMode.Forward:
				FAnimPos = (FAnimPos + (FAnimSpeed * MoveCount))
				if FAnimPos >= (FAnimStart + FAnimCount):
					if Math.Truncate(FAnimPos) == FAnimStart:
						OnAnimStart
					if Math.Truncate(FAnimPos) == (FAnimStart + FAnimCount):
						FAnimEnded = true
						OnAnimEnd
					if FAnimLooped:
						FAnimPos = FAnimStart
					else:
						FAnimPos = ((FAnimStart + FAnimCount) - 1)
						FDoAnimate = false
			case TAnimPlayMode.Backward:
				FAnimPos = (FAnimPos - (FAnimSpeed * MoveCount))
				if FAnimPos < FAnimStart:
					if FAnimLooped:
						FAnimPos = (FAnimStart + FAnimCount)
					else:
						FDoAnimate = false
			case TAnimPlayMode.PingPong:
				FAnimPos += FAnimSpeed * MoveCount
				if FAnimLooped:
					if (FAnimPos > ((FAnimStart + FAnimCount) - 1)) or (FAnimPos < FAnimStart):
						FAnimSpeed = (-FAnimSpeed)
				else:
					if (FAnimPos > (FAnimStart + FAnimCount)) or (FAnimPos < FAnimStart):
						FAnimSpeed = (-FAnimSpeed)
					if Math.Truncate(FAnimPos) == (FAnimStart + FAnimCount):
						FDoFlag1 = true
					if (Math.Truncate(FAnimPos) == FAnimStart) and FDoFlag1:
						FDoFlag2 = true
					if FDoFlag1 and FDoFlag2:
						FDoAnimate = false
						FDoFlag1 = false
						FDoFlag2 = false
		FPatternIndex = Math.Truncate(FAnimPos)

	public def constructor(AParent as TParentSprite):
		super(AParent)
		FAnimLooped = true

	public override def Assign(Value as TSprite):
		if Value isa TAnimatedSprite:
			DoAnimate = TAnimatedSprite(Value).DoAnimate
			AnimStart = TAnimatedSprite(Value).AnimStart
			AnimCount = TAnimatedSprite(Value).AnimCount
			AnimSpeed = TAnimatedSprite(Value).AnimSpeed
			AnimLooped = TAnimatedSprite(Value).AnimLooped
		super.Assign(Value)

	public virtual def SetAnim(AniImageName as string, AniStart as int, AniCount as int, AniSpeed as Single, AniLooped as bool, DoMirror as bool, DoAnimate as bool, PlayMode as TAnimPlayMode):
		ImageName = AniImageName
		FAnimStart = AniStart
		FAnimCount = AniCount
		FAnimSpeed = AniSpeed
		FAnimLooped = AniLooped
		MirrorX = DoMirror
		FDoAnimate = DoAnimate
		FAnimPlayMode = PlayMode
		if (FPatternIndex < FAnimStart) or (FPatternIndex >= (FAnimCount + FAnimStart)):
			FPatternIndex = (FAnimStart % FAnimCount)
			FAnimPos = FAnimStart

	public virtual def SetAnim(AniImageName as string, AniStart as int, AniCount as int, AniSpeed as Single, AniLooped as bool, PlayMode as TAnimPlayMode):
		ImageName = AniImageName
		FAnimStart = AniStart
		FAnimCount = AniCount
		FAnimSpeed = AniSpeed
		FAnimLooped = AniLooped
		FAnimPlayMode = PlayMode
		if (FPatternIndex < FAnimStart) or (FPatternIndex >= (FAnimCount + FAnimStart)):
			FPatternIndex = (FAnimStart % FAnimCount)
			FAnimPos = FAnimStart

	public virtual def OnAnimStart():
		pass

	public virtual def OnAnimEnd():
		pass

	public AnimStart as int:
		get:
			return FAnimStart
		set:
			SetAnimStart(value)

class TAnimatedRectSprite(TParentSprite):

	[Property(StartingPoint)]
	private FStartingPoint as TSgPoint

	[Property(Displacement)]
	private FDisplacement as TSgPoint

	[Property(SeriesLength)]
	private FSeriesLength as int

	private FAnimPos as int

	protected override def SetDrawRect(Value as GPU_Rect):
		FStartingPoint = sgPoint(Value.x, Value.y)
		FAnimPos = 0
		super.SetDrawRect(Value)

	public def constructor(parent as TParentSprite, region as GPU_Rect, displacement as TSgPoint, length as int):
		super(parent)
		self.DrawRect = region
		FDisplacement = displacement
		FSeriesLength = length - 1
		FStartingPoint = sgPoint(region.x, region.y)

	public override def Assign(value as TSprite):
		super.Assign(value)
		if value isa TAnimatedRectSprite:
			ar = value as TAnimatedRectSprite
			FStartingPoint = ar.FStartingPoint
			FDisplacement = ar.FDisplacement
			FSeriesLength = ar.FSeriesLength
			FAnimPos = ar.FAnimPos

class TTiledAreaSprite(TAnimatedRectSprite):

	[Property(FillArea)]
	private FFillArea as GPU_Rect

	[Property(Stretch)]
	private FStretch as bool

	protected override def DoDraw():
		drawpoint as TSgPoint
		endpoint as TSgPoint
		alphaSet as bool
		if self.Alpha != 0:
			GPU_SetRGBA(self.Image.Surface, 255, 255, 255, self.Alpha)
			alphaSet = true
		else: alphaSet = false
		if (FFillArea.h == 0) or (FFillArea.w == 0):
			super.DoDraw()
		elif (FStretch or (FFillArea.w < FWidth)) or (FFillArea.h < FHeight):
			FImage.DrawRectTo(FFillArea, self.DrawRect)
		else:
			drawpoint = sgPoint(FFillArea.x, FFillArea.y)
			endpoint = drawpoint + sgPoint(FFillArea.w, FFillArea.h)
			repeat :
				drawpoint.x = FFillArea.x
				repeat :
					self.X = drawpoint.x
					self.Y = drawpoint.y
					super.DoDraw()
					drawpoint.x += FWidth
					until drawpoint.x + FWidth > endpoint.x
				if drawpoint.x < endpoint.x:
					e as TSgPoint = endpoint - drawpoint
					FImage.DrawRectTo(
						GPU_MakeRect(drawpoint.x, drawpoint.y, e.x, e.y),
						GPU_MakeRect(DrawRect.x, DrawRect.y, endpoint.x - drawpoint.x, DrawRect.h))
				drawpoint.y += FHeight
				until drawpoint.y >= endpoint.y
			self.X = FFillArea.x
			self.Y = FFillArea.y
		GPU_UnsetColor(self.Image.Surface) if alphaSet

	public def constructor(parent as TParentSprite, region as GPU_Rect, displacement as TSgPoint, length as int):
		FFillArea = GPU_MakeRect(0, 0, region.w, region.h)
		super(parent, region, displacement, length)
		FRenderSpecial = true

class TParticleSprite(TAnimatedSprite):

	[Property(AccelX)]
	private FAccelX as single

	[Property(AccelY)]
	private FAccelY as single

	[Property(VelocityX)]
	private FVelocityX as single

	[Property(VelocityY)]
	private FVelocityY as single

	[Property(UpdateSpeed)]
	private FUpdateSpeed as Single

	[Property(Decay)]
	private FDecay as single

	[Property(LifeTime)]
	private FLifeTime as single

	public def constructor(AParent as TParentSprite):
		super(AParent)
		FLifeTime = 1

	public override def DoMove(MoveCount as Single):
		super.DoMove(MoveCount)
		X = (X + (FVelocityX * UpdateSpeed))
		Y = (Y + (FVelocityY * UpdateSpeed))
		FVelocityX = (FVelocityX + (FAccelX * UpdateSpeed))
		FVelocityY = (FVelocityY + (FAccelY * UpdateSpeed))
		FLifeTime = (FLifeTime - FDecay)
		if FLifeTime <= 0:
			self.Dead()

class TSpriteEngine(TParentSprite):

	[Getter(AllCount)]
	internal FAllCount as int

	internal FDeadList as TSpriteList

	[Property(WorldX)]
	private FWorldX as Single

	[Property(WorldY)]
	private FWorldY as Single

	[Property(VisibleWidth)]
	private FVisibleWidth as int

	[Property(VisibleHeight)]
	private FVisibleHeight as int

	[Property(Images)]
	private FImages as TSdlImages

	[Getter(Canvas)]
	private FCanvas as TSdlCanvas

	protected FRenderer as TSpriteRenderer

	internal Renderer:
		get: return FRenderer

	protected virtual def GetHeight() as int:
		return super.Height

	protected virtual def GetWidth() as int:
		return super.Width

	public def constructor(AParent as TSpriteEngine, ACanvas as TSdlCanvas):
		super(AParent)
		FDeadList = TSpriteList()
		FVisibleWidth = 800
		FVisibleHeight = 600
		FCanvas = ACanvas
		FEngine = self
		FRenderer = TSpriteRenderer(self)

	public override def Draw():
		return if FSpriteList == null
		for list in FSpriteList.FSprites:
			if assigned(list):
				FRenderer.Reset()
				for item in List:
					item.Draw()
				FRenderer.Render(FCanvas.RenderTarget)

	public def Dead():
		FDeadList.Clear()

	public override Width as int:
		get: return GetWidth()

	public override Height as int:
		get: return GetHeight()

class TSpriteRenderer(TObject):
	private static nullInt = 0
	private static nullUInt as uint = 0

	private class TDrawMap(TMultimap[of TSdlImage, TSprite]):
		pass

	private FDrawMap as TDrawMap

	private FEngine as TSpriteEngine

	private FVertexBuffer as uint

	private FTextureCoords as uint

	public def constructor(engine as TSpriteEngine):
		FDrawMap = TDrawMap()
		FEngine = engine

	public def Draw(sprite as TSprite):
		FDrawMap.Add(sprite.Image, sprite)

	public def Reset():
		FDrawMap.Clear()

	public def Render(target as GPU_Target_PTR):
		for image in FDrawMap.Keys:
			for sprite in FDrawMap[image]:
				sprite.Render()
	
private class TSpriteComparer(TObject, IComparer[of TSprite]):

	public def Compare(Left as TSprite, Right as TSprite) as int:
		result = (Left.Z - Right.Z)
		if result == 0:
			result = Left.GetHashCode() - Right.GetHashCode()
		return result

