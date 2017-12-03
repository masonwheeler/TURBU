namespace turbu.RM2K.images

import System
import System.Threading.Tasks

import turbu.defs
import commons
import SG.defs
import sdl.canvas
import sdl.sprite
import timing
import dm.shaders
import turbu.classes
import turbu.script.engine
import Boo.Adt
import Pythia.Runtime
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import SDL2.SDL2_GPU
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import TURBU.Meta

[Disposable(Destroy, true)]
class TRpgImageSprite(TSprite):

	private FRefPoint as TSgFloatPoint

	private FRefTarget as TSgFloatPoint

	private FAlphaTarget as int

	private FSaturation as int

	private FTransitionTimer as TRpgTimestamp

	private FColor as TSgColor

	private FColorTarget as TSgColor

	private FZoomTarget as single

	private FRotationPower as single

	private FWavePower as single

	private FRotation as single

	private FRotationTarget as single

	private FWaveTarget as single

	private FCenterX as single

	private FCenterY as single

	private FMasked as bool

	[DisposeParent]
	private FRpgImage as TRpgImage

	private FBaseWX as single

	private FBaseWY as single

	private def CenterOn(x as double, y as double):
		FRefPoint = sgPointF(x, y)
		FCenterX = x
		FCenterY = y

	private def ApplyColor():
		self.Red = Math.Min(commons.round((FColor.Rgba[1] * 2.55)), 255)
		self.Green = Math.Min(commons.round((FColor.Rgba[2] * 2.55)), 255)
		self.Blue = Math.Min(commons.round((FColor.Rgba[3] * 2.55)), 255)
		self.FSaturation = Math.Max(Math.Min(commons.round((FColor.Rgba[4] * 2.55)), 255), 0)

	private def Update():
		dummy as single
		TimeRemaining as int
		oldcolor as uint
		if assigned(FTransitionTimer):
			TimeRemaining = FTransitionTimer.TimeRemaining
		else:
			TimeRemaining = 0
		if (FRefPoint.x != FRefTarget.x) or (FRefPoint.y != FRefTarget.y):
			MoveTowards(TimeRemaining, FRefPoint.x, FRefTarget.x)
			MoveTowards(TimeRemaining, FRefPoint.y, FRefTarget.y)
			CenterOn(FRefPoint.x, FRefPoint.y)
		oldcolor = FColor.Color
		for i in range(1, 5):
			if FColor.Rgba[i]  != FColorTarget.Rgba[i]:
				tempEdit color = FColor.Rgba[i]:
					MoveTowards(TimeRemaining, color, FColorTarget.Rgba[i])
		if FColor.Color != oldcolor:
			self.ApplyColor()
		if self.ScaleX != FZoomTarget:
			tempEdit dummy = self.ScaleX:
				MoveTowards(TimeRemaining, dummy, FZoomTarget)
			self.ScaleY = self.ScaleX
		if self.Alpha != FAlphaTarget:
			tempEdit i = self.Alpha:
				MoveTowards(TimeRemaining, i, FAlphaTarget)
		if FRotation != FRotationTarget:
			MoveTowards(TimeRemaining, FRotation, FRotationTarget)
		if FRotation != 0:
			self.Angle += FRotation / ROTATE_FACTOR
		else:
			self.Angle = 0
		if FWavePower != FWaveTarget:
			MoveTowards(TimeRemaining, FWavePower, FWaveTarget)

	private def DrawQuad():
		return if self.Image is null
		shaders as TdmShaders = GSpriteEngine.value.ShaderEngine
		if FMasked:
			shaders.UseShaderProgram(shaders.ShaderProgram('default', 'defaultF'))
		else:
			shaders.UseShaderProgram(shaders.ShaderProgram('default', 'noAlpha'))
		var currentColor = GPU_GetColor(self.Image.Surface)
		GPU_SetRGBA(self.Image.Surface, self.Red, self.Green, self.Blue, /*FSaturation*/ self.Alpha)
		if Pinned:
			cx = (FCenterX + Engine.WorldX) - FBaseWX
			cy = (FCenterY + Engine.WorldY) - FBaseWY
		else:
			cx = FCenterX
			cy = FCenterY
		drawRect = self.GetDrawRect()
		GPU_BlitScale(
			self.Image.Surface,
			drawRect,
			currentRenderTarget().RenderTarget,
			round(cx),
			round(cy),
			self.ScaleX,
			self.ScaleY)
		GPU_SetColor(self.Image.Surface, currentColor)
		GPU_DeactivateShaderProgram()

	internal def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('Masked', FMasked, false)
			writer.CheckWrite('Pinned', self.Pinned, false)
			writeJsonProperty writer, 'Name', self.ImageName
			writer.CheckWrite('X', FRefPoint.x, 0)
			writer.CheckWrite('Y', FRefPoint.y, 0)
			writer.CheckWrite('WorldX', FBaseWX, 0)
			writer.CheckWrite('WorldY', FBaseWY, 0)
			writer.CheckWrite('TargetX', FRefTarget.x, FRefPoint.x)
			writer.CheckWrite('TargetY', FRefTarget.y, FRefPoint.y)
			writer.CheckWrite('Alpha', self.Alpha, 255)
			writer.CheckWrite('AlphaTarget', FAlphaTarget, self.Alpha)
			writer.CheckWrite('Saturation', FSaturation, 255)
			if assigned(FTransitionTimer):
				writer.CheckWrite('Transition', FTransitionTimer.TimeRemaining, 0)
			writer.CheckWrite('Color', FColor.Color, uint.MaxValue)
			writer.CheckWrite('ColorTarget', FColorTarget.Color, FColor.Color)
			writer.CheckWrite('Zoom', self.ScaleX, 1)
			writer.CheckWrite('ZoomTarget', FZoomTarget, self.ScaleX)
			writer.CheckWrite('RotationPower', FRotationPower, 0)
			writer.CheckWrite('WavePower', FWavePower, 0)
			writer.CheckWrite('Rotation', FRotation, 0)
			writer.CheckWrite('RotationTarget', FRotationTarget, 0)
			writer.CheckWrite('WaveTarget', FWaveTarget, 0)
			writer.CheckWrite('Tag', FTag, 0)

	internal def Deserialize(obj as JObject):
		Item as JToken
		obj.CheckRead('TargetX', FRefTarget.x)
		obj.CheckRead('TargetY', FRefTarget.y)
		obj.CheckRead('Alpha', self.FAlpha)
		obj.CheckRead('AlphaTarget', FAlphaTarget)
		obj.CheckRead('Saturation', FSaturation)
		obj.CheckRead('Color', FColor.Color)
		obj.CheckRead('ColorTarget', FColorTarget.Color)
		obj.CheckRead('ZoomTarget', FZoomTarget)
		obj.CheckRead('RotationPower', FRotationPower)
		obj.CheckRead('WavePower', FWavePower)
		obj.CheckRead('Rotation', FRotation)
		obj.CheckRead('RotationTarget', FRotationTarget)
		obj.CheckRead('WaveTarget', FWaveTarget)
		obj.CheckRead('Tag', FTag)
		if obj.TryGetValue('Transition', Item):
			FTransitionTimer = TRpgTimestamp(Item cast int)
			Item.Remove()

	protected override def Render():
		DrawQuad()
		if FWavePower != 0:
			++FTag
			FTag = 0 if FTag > 3141590

	protected override def InVisibleRect() as bool:
		return true

	public def constructor(engine as SpriteEngine, image as TRpgImage, Name as string, x as int, y as int, baseWX as single, baseWY as single, zoom as int, pinned as bool, masked as bool):
		super(engine)
		ImageName = Name
		self.Pinned = pinned
		self.ScaleX = ((zoom cast double) / 100.0)
		self.ScaleY = self.ScaleX
		FZoomTarget = ScaleX
		FRenderSpecial = true
		self.Z = 20
		self.CenterOn(x, y)
		FRefTarget = sgPointF(x, y)
		FMasked = masked
		self.ApplyImageColors(100, 100, 100, -1)
		for i in range(1, 5):
			FColor.Rgba[i] = FColorTarget.Rgba[i]
		ApplyColor()
		self.Alpha = 255
		FAlphaTarget = 255
		FRpgImage = image
		FBaseWX = baseWX
		FBaseWY = baseWY

	private new def Destroy():
		FRpgImage.ClearSprite()

	public def ApplyImageColors(r as int, g as int, b as int, sat as int):
		FColorTarget.R = Math.Min(r, 200)
		FColorTarget.G = Math.Min(g, 200)
		FColorTarget.B = Math.Min(b, 200)
		if FColor.A < 0:
			FColor.R = FColorTarget.R
			FColor.G = FColorTarget.G
			FColor.B = FColorTarget.B
			FColor.A = 100
		FColorTarget.A = Math.Max(Math.Min(sat, 200), 0)

	public def ApplyImageEffect(which as TImageEffects, power as int):
		power = Math.Min(power, 10)
		caseOf which:
			case TImageEffects.None:
				FRotationPower = 0
				FRotationTarget = 0
				FWavePower = 0
				FWaveTarget = 0
			case TImageEffects.Rotate:
				FRotationTarget = power
			case TImageEffects.Wave:
				FWaveTarget = power
			default :
				assert false

	public override def Draw():
		self.Update()
		super.Draw()

	public def MoveTo(x as int, y as int, zoom as int, opacity as int):
		FRefTarget = sgPointF(x, y)
		self.Zoom = zoom
		self.Opacity = 100 - Math.Min(opacity, 100)

	public override def Dead():
		if self != GEnvironment.value.Image[0].Base:
			super.Dead()

	public Zoom as int:
		get: return commons.round(ScaleX * 100)
		set: FZoomTarget = (value cast double) / 100.0

	public Opacity as int:
		get: return commons.round((self.Alpha cast double) / 2.55)
		set: FAlphaTarget = commons.round(value * 2.55)

	public Timer as int:
		get:
			if assigned(FTransitionTimer):
				result = FTransitionTimer.TimeRemaining
			else:
				result = 0
			return result
		set: FTransitionTimer = TRpgTimestamp(value)

[Disposable(Destroy, true)]
class TRpgImage(TObject):

	[Getter(Base)]
	private FSprite as TRpgImageSprite
	
	internal def ClearSprite():
		FSprite = null

	[NoImport]
	public def constructor(engine as SpriteEngine, Name as string, x as int, y as int, baseWX as single, baseWY as single, zoom as int, pinned as bool, masked as bool):
		FSprite = TRpgImageSprite(engine, self, Name, x, y, baseWX, baseWY, zoom, pinned, masked)

	[NoImport]
	public def constructor(engine as SpriteEngine, obj as JObject):
		name as string = ''
		wx as single
		wy as single
		zoom as int
		pinned as bool = false
		masked as bool = false
		x as int = 0
		y as int = 0
		obj.CheckRead('Masked', masked)
		obj.CheckRead('Pinned', pinned)
		obj.CheckRead('Name', name)
		obj.CheckRead('X', x)
		obj.CheckRead('Y', x)
		obj.CheckRead('Zoom', zoom)
		obj.CheckRead('WorldX', wx)
		obj.CheckRead('WorldY', wy)
		self(engine, name, x, y, wx, wy, zoom, pinned, masked)
		FSprite.Deserialize(obj)
		obj.CheckEmpty()

	def Destroy():
		GEnvironment.value.RemoveImage(self)

	[NoImport]
	public def Serialize(writer as JsonWriter):
		FSprite.Serialize(writer)

	public def ApplyImageColors(r as int, g as int, b as int, sat as int):
		FSprite.ApplyImageColors(r, g, b, sat)

	public def ApplyImageEffect(which as TImageEffects, power as int):
		FSprite.ApplyImageEffect(which, power)

	public def MoveTo(x as int, y as int, zoom as int, opacity as int, duration as int):
		FSprite.MoveTo(x, y, zoom, opacity)
		FSprite.Timer = duration * 100

	public def Erase():
		self.Dispose()

	[async]
	public def WaitFor() as Task:
		idx as int = GEnvironment.value.ImageIndex(self)
		if idx == -1:
			return
		def cond() as bool:
			var img = GEnvironment.value.Image[idx]
			return (img.Timer == 0 if assigned(img) else true)
		waitFor cond

	public Zoom as int:
		get: return FSprite.Zoom
		set: FSprite.Zoom = value

	public Opacity as int:
		get: return FSprite.Opacity
		set: FSprite.Opacity = value

	public Timer as int:
		get: return FSprite.Timer
		set: FSprite.Timer = value

let ROTATE_FACTOR = 30.0