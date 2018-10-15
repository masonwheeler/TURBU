namespace sdl.sprite

import Pythia.Runtime
import System
import System.Collections.Generic
import turbu.multimaps
import TURBU.Meta
import SDL.ImageManager
import sdl.canvas
import SG.defs
import SDL2
import SDL2.SDL2_GPU
import System.Linq.Enumerable

enum TImageType:
	SingleImage
	SpriteSheet
	RectSet

enum TAnimPlayMode:
	Forward
	Backward
	PingPong

class ESpriteError(Exception):
	def constructor(message as string):
		super(message)

class TFastSpriteList(List[of TSprite]):

	internal FSprites as (List[of TSprite])

	private FSorted as bool

	public def constructor():
		super()
		Array.Resize[of List[of TSprite]](FSprites, 11)
		for i in range(11):
			FSprites[i] = List[of TSprite]()

	public new def Add(ASprite as TSprite) as int:
		result = Count
		super.Add(ASprite)
		z as int = ASprite.Z
		if z >= FSprites.Length:
			Array.Resize[of List[of TSprite]](FSprites, z + 1)
		if FSprites[z] == null:
			FSprites[z] = List[of TSprite]()
		FSprites[z].Add(ASprite)
		FSorted = false
		return result

	public new def Remove(ASprite as TSprite) as int:
		assert assigned(FSprites[ASprite.Z])
		FSprites[ASprite.Z].Remove(ASprite)
		result = super.IndexOf(ASprite)
		super.RemoveAt(result) if result >= 0
		return result

	public new def IndexOf(value as TSprite) as int:
		if not FSorted:
			self.Sort()
			FSorted = true
		return self.BinarySearch(value)

class TSprite(TObject):

	protected FDead as bool

	protected FWidth as int

	protected FHeight as int
	
	public virtual Width as int:
		get: return FWidth
		set: 
			System.Diagnostics.Debugger.Break() unless value >= 0
			FWidth = value

	public virtual Height as int:
		get: return FHeight
		set:
			System.Diagnostics.Debugger.Break() unless value >= 0
			FHeight = value

	protected FOrigin as SgPoint

	[Property(Name)]
	protected FName as string

	[Property(X)]
	protected FX as single

	[Property(Y)]
	protected FY as single

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
	protected FAngle as single

	[Property(ScaleX)]
	protected FScaleX as single

	[Property(ScaleY)]
	protected FScaleY as single

	[Property(OffsetX)]
	protected FOffsetX as single

	[Property(OffsetY)]
	protected FOffsetY as single

	[Property(ImageType)]
	protected FImageType as TImageType

	[Property(Pinned)]
	protected FPinned as bool

	[Property(Engine), DisposeParent]
	protected FEngine as SpriteEngine

	[DisposeParent]
	protected FParent as TParentSprite

	protected FRenderSpecial as bool

	protected _viewport as IViewport

	protected internal virtual def SetViewport(value as IViewport):
		_viewport = value

	override def ToString():
		return "$(self.GetType().Name): Image: $FImageName, Index: $FImageIndex"

	protected virtual def GetDrawRect() as GPU_Rect:
		return GPU_MakeRect(FOrigin.x, FOrigin.y, FWidth, FHeight)

	protected virtual def SetDrawRect(value as GPU_Rect):
		FOrigin = sgPoint(value.x, value.y)
		FWidth = value.w
		FHeight = value.h
		FImageType = TImageType.RectSet

	internal protected virtual def Render():
		followX as single
		followY as single
		if FPinned:
			followX = 0
			followY = 0
		else:
			followX = _viewport.WorldX
			followY = _viewport.WorldY
		var topleft = sgPoint(
				Math.Truncate(FX + _viewport.OffsetX + FOffsetX - followX),
				Math.Truncate(FY + _viewport.OffsetY + FOffsetY - followY))
		flip as SDL.SDL_RendererFlip = SDL.SDL_RendererFlip.SDL_FLIP_NONE
		flip |= SDL.SDL_RendererFlip.SDL_FLIP_HORIZONTAL if MirrorX
		flip |= SDL.SDL_RendererFlip.SDL_FLIP_VERTICAL if MirrorY
		alphaSet as bool
		if FAlpha > 0 and FAlpha < 255:
			GPU_SetRGBA(self.Image.Surface, 255, 255, 255, self.Alpha)
			alphaSet = true
		else: alphaSet = false
		caseOf FImageType:
			case TImageType.SingleImage: FImage.Draw(topleft, flip)
			case TImageType.SpriteSheet: FImage.DrawSprite(topleft, FPatternIndex, flip)
			case TImageType.RectSet: FImage.DrawRect(topleft, self.DrawRect, flip)
		GPU_UnsetColor(self.Image.Surface) if alphaSet

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

	protected virtual def SetImageName(value as string):
		if FImageName != value:
			FImageName = value
			if assigned(FEngine):
				self.Image = FEngine.Images.Image[FImageName] 
			if assigned(FImage):
				if FImageType != TImageType.RectSet:
					FImageType = (TImageType.SpriteSheet if FImage.Count > 1 else TImageType.SingleImage)
				FImageIndex = FEngine.Images.IndexOf(FImageName)
			else:
				System.Diagnostics.Debugger.Break()

	protected virtual def InVisibleRect() as bool:
		return X > _viewport.WorldX - (Width * 2) and \
		       Y > _viewport.WorldY - (Height * 2) and \
		       X < _viewport.WorldX + _viewport.VisibleWidth and \
		       Y < _viewport.WorldY + _viewport.VisibleHeight

	public def constructor(AParent as TParentSprite):
		if assigned(AParent):
			FParent = AParent
			FParent.Add(self)
			FEngine = (AParent cast SpriteEngine if AParent isa SpriteEngine else AParent.Engine)
		FVisible = true

/*
	private def Destroy():
		if assigned(FParent):
			try:
				FParent.Remove(self)
			except as ObjectDisposedException:
				pass
			FEngine.FDeadList.Remove(self)
*/

	public virtual def IsBackground() as bool:
		return false

	public virtual def Assign(value as TSprite):
		FName = value.Name
		FImageName = value.ImageName
		FX = value.X
		FY = value.Y
		FZ = value.Z
		FPatternIndex = value.FPatternIndex
		FVisible = value.Visible
		FTag = value.Tag

	public virtual def Move(MoveCount as single):
		if FMoves:
			DoMove(MoveCount)

	public def SetPos(X as single, Y as single):
		FX = X
		FY = Y

	public def SetPos(X as single, Y as single, Z as int):
		FX = X
		FY = Y
		FZ = Z

	public virtual def Draw():
		if FVisible and (not FDead) and self.InVisibleRect():
			DoDraw()

	public virtual def Dead():
		if assigned(FEngine) and (not FDead):
			FDead = true
			FEngine.FDeadList.Add(self)

	public def DrawTo(dest as GPU_Rect):
		caseOf FImageType:
			case TImageType.SingleImage:
				FImage.DrawTo(dest)
			case TImageType.SpriteSheet:
				FImage.DrawSpriteTo(dest, FPatternIndex)
			case TImageType.RectSet:
				FImage.DrawRectTo(dest, self.DrawRect)

	public def SetSpecialRender():
		FRenderSpecial = true

	public Z as uint:
		get: return FZ
		set:
			if (FZ != value) or not FZset:
				if assigned(FParent):
					FParent.UnDraw(self) if FZset
					FZ = value
					FParent.AddDrawList(self)
				else: FZ = value
				FZset = true

	public ImageName as string:
		get: return FImageName
		set: SetImageName(value)

	public Image as TSdlImage:
		get: return FImage
		set:
			return if value is null
			
			FImage = value
			FImageName = FImage.Name
			if FImageType in (TImageType.SingleImage, TImageType.SpriteSheet):
				FWidth = FImage.TextureSize.x
				FHeight = FImage.TextureSize.y

	public PatternWidth as int:
		get: return (FImage.TextureSize.x if assigned(FImage) else 0)

	public PatternHeight as int:
		get: return (FImage.TextureSize.y if assigned(FImage) else 0)

	public PatternCount as int:
		get: return FImage.Count

	public Parent as TParentSprite:
		get: return FParent
		set:
			return if FParent == value
			
			if assigned(FParent):
				FParent.UnDraw(self)
				FParent.List.Remove(self)
			FParent = value
			value.Add(self)

	public BoundsRect as GPU_Rect:
		get: return GPU_MakeRect(Math.Round(FX), Math.Round(FY), Width, Height)

	public DrawRect as GPU_Rect:
		get: return GetDrawRect()
		set: SetDrawRect(value)

//[Disposable(Destroy, true)]
class TParentSprite(TSprite):

	internal def UnDraw(sprite as TSprite):
		if assigned(FSpriteList):
			FSpriteList.Remove(sprite)

	[Getter(List)]
	protected FList as List[of TSprite]

	[Getter(SpriteList)]
	protected FSpriteList as TFastSpriteList

	internal def AddDrawList(Sprite as TSprite):
		FSpriteList = TFastSpriteList() unless assigned(FSpriteList)
		FSpriteList.Add(Sprite)

	protected def ClearSpriteList():
		if assigned(FSpriteList):
			FSpriteList.Clear()
		else: FSpriteList = TFastSpriteList()
/*
	private new def Destroy():
		Clear()
*/
	public override def Move(movecount as single):
		super.Move(movecount)
		for i in range(Count):
			self[i].Move(movecount)

	public def Clear():
		FSpriteList.Clear() if assigned(FSpriteList)
		FList.Clear() if assigned(FList)

	public override def Draw():
		super.Draw()
		if self.Visible and assigned(FSpriteList):
			for i in range(FSpriteList.Count):
				FSpriteList[i].Draw()

	public virtual def Add(sprite as TSprite):
		if FList == null:
			FList = List[of TSprite]()
		FList.Add(sprite)
		if sprite.Z != 0:
			if FSpriteList == null:
				FSpriteList = TFastSpriteList()
			FSpriteList.Add(sprite)

	public def Remove(sprite as TSprite):
		if assigned(FList):
			FList.Remove(sprite)
			if assigned(FSpriteList):
				FSpriteList.Remove(sprite)
				if FSpriteList.Count == 0:
					FSpriteList = null

	public self[Index as int] as TSprite:
		get:
			if assigned(FList):
				return FList[Index]
			else: raise ESpriteError("Index of the list exceeds the range. ($Index)")


	public Count as int:
		get: return ( FList.Count if assigned(FList) else 0 )

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
	private FAnimSpeed as single

	[Property(AnimPos)]
	private FAnimPos as single

	[Getter(AnimEnded)]
	private FAnimEnded as bool

	private FDoFlag1 as bool

	private FDoFlag2 as bool

	[Property(AnimPlayMode)]
	private FAnimPlayMode as TAnimPlayMode

	protected override def DoMove(MoveCount as single):
		return unless FDoAnimate
		
		caseOf FAnimPlayMode:
			case TAnimPlayMode.Forward:
				FAnimPos = FAnimPos + (FAnimSpeed * MoveCount)
				if FAnimPos >= FAnimStart + FAnimCount:
					if Math.Truncate(FAnimPos) == FAnimStart:
						OnAnimStart()
					if Math.Truncate(FAnimPos) == FAnimStart + FAnimCount:
						FAnimEnded = true
						OnAnimEnd()
					if FAnimLooped:
						FAnimPos = FAnimStart
					else:
						FAnimPos = (FAnimStart + FAnimCount) - 1
						FDoAnimate = false
			case TAnimPlayMode.Backward:
				FAnimPos = FAnimPos - (FAnimSpeed * MoveCount)
				if FAnimPos < FAnimStart:
					if FAnimLooped:
						FAnimPos = FAnimStart + FAnimCount
					else:
						FDoAnimate = false
			case TAnimPlayMode.PingPong:
				FAnimPos += FAnimSpeed * MoveCount
				if FAnimLooped:
					if (FAnimPos > (FAnimStart + FAnimCount) - 1) or (FAnimPos < FAnimStart):
						FAnimSpeed = (-FAnimSpeed)
				else:
					if (FAnimPos > FAnimStart + FAnimCount) or (FAnimPos < FAnimStart):
						FAnimSpeed = -FAnimSpeed
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

	public override def Assign(value as TSprite):
		var anim = value as TAnimatedSprite
		if assigned(anim):
			DoAnimate = anim.DoAnimate
			AnimStart = anim.AnimStart
			AnimCount = anim.AnimCount
			AnimSpeed = anim.AnimSpeed
			AnimLooped = anim.AnimLooped
		super.Assign(value)

	public virtual def SetAnim(AniImageName as string, AniStart as int, AniCount as int, 
			AniSpeed as single, AniLooped as bool, DoMirror as bool, DoAnimate as bool, PlayMode as TAnimPlayMode):
		ImageName = AniImageName
		FAnimStart = AniStart
		FAnimCount = AniCount
		FAnimSpeed = AniSpeed
		FAnimLooped = AniLooped
		MirrorX = DoMirror
		FDoAnimate = DoAnimate
		FAnimPlayMode = PlayMode
		if (FPatternIndex < FAnimStart) or (FPatternIndex >= FAnimCount + FAnimStart):
			FPatternIndex = FAnimStart % FAnimCount
			FAnimPos = FAnimStart

	public virtual def SetAnim(AniImageName as string, AniStart as int, AniCount as int,
			AniSpeed as single, AniLooped as bool, PlayMode as TAnimPlayMode):
		ImageName = AniImageName
		FAnimStart = AniStart
		FAnimCount = AniCount
		FAnimSpeed = AniSpeed
		FAnimLooped = AniLooped
		FAnimPlayMode = PlayMode
		if (FPatternIndex < FAnimStart) or (FPatternIndex >= FAnimCount + FAnimStart):
			FPatternIndex = FAnimStart % FAnimCount
			FAnimPos = FAnimStart

	public virtual def OnAnimStart():
		pass

	public virtual def OnAnimEnd():
		pass

	public AnimStart as int:
		get: return FAnimStart
		set:
			if FAnimStart != value:
				FAnimStart = value
				FAnimPos = value

class TAnimatedRectSprite(TParentSprite):

	[Property(StartingPoint)]
	private FStartingPoint as SgPoint

	[Property(Displacement)]
	private FDisplacement as SgPoint

	[Property(SeriesLength)]
	private FSeriesLength as int

	private FAnimPos as int

	protected override def SetDrawRect(value as GPU_Rect):
		FStartingPoint = sgPoint(value.x, value.y)
		FAnimPos = 0
		super.SetDrawRect(value)

	public def constructor(parent as TParentSprite, region as GPU_Rect, displacement as SgPoint, length as int):
		super(parent)
		self.DrawRect = region
		FDisplacement = displacement
		FSeriesLength = length - 1
		FStartingPoint = sgPoint(region.x, region.y)

	public override def Assign(value as TSprite):
		ar = value as TAnimatedRectSprite
		if assigned(ar):
			FStartingPoint = ar.FStartingPoint
			FDisplacement = ar.FDisplacement
			FSeriesLength = ar.FSeriesLength
			FAnimPos = ar.FAnimPos
		super.Assign(value)

class TTiledAreaSprite(TAnimatedRectSprite):

	[Property(FillArea)]
	private FFillArea as GPU_Rect

	[Property(Stretch)]
	private FStretch as bool

	protected override def DoDraw():
		drawpoint as SgPoint
		endpoint as SgPoint
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
			repeat:
				drawpoint.x = FFillArea.x
				repeat:
					self.X = drawpoint.x
					self.Y = drawpoint.y
					super.DoDraw()
					drawpoint.x += FWidth
					until drawpoint.x + FWidth > endpoint.x
				if drawpoint.x < endpoint.x:
					e as SgPoint = endpoint - drawpoint
					FImage.DrawRectTo(
						GPU_MakeRect(drawpoint.x, drawpoint.y, e.x, e.y),
						GPU_MakeRect(DrawRect.x, DrawRect.y, endpoint.x - drawpoint.x, DrawRect.h))
				drawpoint.y += FHeight
				until drawpoint.y >= endpoint.y
			self.X = FFillArea.x
			self.Y = FFillArea.y
		GPU_UnsetColor(self.Image.Surface) if alphaSet

	public def constructor(parent as TParentSprite, region as GPU_Rect, displacement as SgPoint, length as int):
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
	private FUpdateSpeed as single

	[Property(Decay)]
	private FDecay as single

	[Property(LifeTime)]
	private FLifeTime as single

	public def constructor(AParent as TParentSprite):
		super(AParent)
		FLifeTime = 1

	public override def DoMove(MoveCount as single):
		super.DoMove(MoveCount)
		X += FVelocityX * UpdateSpeed
		Y += FVelocityY * UpdateSpeed
		FVelocityX += FAccelX * UpdateSpeed
		FVelocityY += FAccelY * UpdateSpeed
		FLifeTime -= FDecay
		if FLifeTime <= 0:
			self.Dead()

[Disposable(Destroy, true)]
class SpriteEngine(TParentSprite):

	internal FDeadList = List[of TSprite]()

	[Property(Images), DisposeParent]
	private FImages as SdlImages

	[Getter(Canvas)]
	private FCanvas as SdlCanvas

	protected FRenderer = SpriteRenderer()

	internal Renderer:
		get: return FRenderer

	[Getter(Viewport)]
	private _engineViewport as Viewport

	protected virtual def GetHeight() as int:
		return super.Height

	protected virtual def GetWidth() as int:
		return super.Width

	protected virtual def CreateViewport() as Viewport:
		return Viewport(self.Canvas.Width, self.Canvas.Height)

	public def constructor(parent as SpriteEngine, canvas as SdlCanvas):
		super(parent)
		FCanvas = canvas
		FEngine = self
		_engineViewport = CreateViewport()
		_viewport = _engineViewport

	private new def Destroy():
		Dead()

	public override def Draw():
		return if FSpriteList == null
		FRenderer.Reset()
		for list in FSpriteList.FSprites:
			if assigned(list):
				for item in list:
					item.Draw()
		FRenderer.Render(FCanvas.RenderTarget)

	public def Dead():
		for sprite in FDeadList.ToArray():
			var disp = sprite as IDisposable
			if disp is not null:
				disp.Dispose()
			sprite.FParent.Remove(sprite)
		FDeadList.Clear()

	public override def Add(sprite as TSprite):
		super(sprite)
		SetViewport(sprite)

	protected def SetViewport(sprite as TSprite):
		sprite._viewport = self._viewport

	public override Width as int:
		get: return GetWidth()

	public override Height as int:
		get: return GetHeight()
		set: 
			super.Height = value

class SpriteRenderer:
	private FLastZ as int

	private FLastMap as Multimap[of TSdlImage, TSprite]

	private FDrawMap = Dictionary[of int, Multimap[of TSdlImage, TSprite]]()

	public def constructor():
		FLastZ = -1

	public def Draw(sprite as TSprite):
		map as Multimap[of TSdlImage, TSprite]
		if sprite.Z == FLastZ:
			map = FLastMap
		else:
			System.Diagnostics.Debugger.Break() if sprite.Z == 0 and not sprite.IsBackground()
			if not FDrawMap.TryGetValue(sprite.Z, map):
				map = Multimap[of TSdlImage, TSprite]()
				FDrawMap.Add(sprite.Z, map)
			FLastZ = sprite.Z
			FLastMap = map
		map.Add(sprite.Image, sprite)

	public def Reset():
		for value in FDrawMap.Values:
			value.Clear()

	private def RenderMap(map as Multimap[of TSdlImage, TSprite]):
		for list in map.Values:
			for sprite in list:
				System.Diagnostics.Debugger.Break() if sprite.X < -50 and not sprite.IsBackground()
				sprite.Render()

	public def Render(target as GPU_Target_PTR):
		for map in FDrawMap.OrderBy({e | e.Key}).Select({e | e.Value}):
			RenderMap(map)