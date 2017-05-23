namespace turbu.RM2K.animations

import System
import System.Linq.Enumerable
import commons
import timing
import turbu.animations
import dm.shaders
import turbu.defs
import SG.defs
import sdl.sprite
import Pythia.Runtime
import turbu.RM2K.sprite.engine
import SDL2.SDL2_GPU
import System.Threading
import TURBU.Meta
import TURBU.RM2K.RPGScript

interface IAnimTarget:

	def Position(sign as int) as TSgPoint

	def Flash(r as int, g as int, b as int, power as int, time as int)

class TAnimSpriteCell(TSprite):

	public def constructor(AParent as TParentSprite):
		super(AParent)
		FImageType = TImageType.SpriteSheet

	[Property(Sat)]
	private FSaturation as int

	private def PrepareShader(shaders as TdmShaders):
		handle as int
		handle = shaders.ShaderProgram('default', 'tint', 'shift')
		shaders.UseShaderProgram(handle)
		shaders.SetUniformValue(handle, 'hShift', 0)
		shaders.SetUniformValue(handle, 'valMult', 1.0 cast single)
		gla = (of single: self.Red / 128.0, self.Green / 128.0, self.Blue / 128.0, 1.0)
		shaders.SetUniformValue(handle, 'rgbValues', gla)
		shaders.SetUniformValue(handle, 'satMult', (self.Sat / 128.0) cast single)
		GPU_SetRGBA(self.Image.Surface, 255, 255, 255, Math.Min(self.Alpha * 2, 255))

	private def Drawself(center as TSgFloatPoint, halfWidth as single, halfHeight as single, spriteRect as GPU_Rect):
		GPU_BlitScale(
			self.Image.Surface,
			spriteRect,
			sdl.canvas.currentRenderTarget().RenderTarget,
			center.x - (halfWidth * self.ScaleX),
			center.y - (halfHeight * self.ScaleY),
			self.ScaleX,
			self.ScaleY)

	protected override def DoDraw():
		var color = GPU_GetColor(self.Image.Surface)
		PrepareShader(GSpriteEngine.value.ShaderEngine)
		halfWidth as single = self.PatternWidth / 2.0
		halfHeight as single = self.PatternHeight / 2.0
		var center = sgPointF(self.X + halfWidth, self.Y + halfHeight)
		spriteRect as GPU_Rect = self.Image.SpriteRect[self.ImageIndex]
		Drawself(center, halfWidth, halfHeight, spriteRect)
		GPU_DeactivateShaderProgram()
		GPU_SetColor(self.Image.Surface, color)

[Disposable(Destroy, true)]
class TAnimSprite(TParentSprite):

	private FBase as TAnimTemplate

	private FTimer as TRpgTimestamp

	private FTarget as IAnimTarget

	private FLastFrame as int

	private FLastEffect as int

	private FFullScreen as bool

	private FFrameCount as int

	[DisposeParent]
	private FSignal as EventWaitHandle

	public def constructor(parent as TSpriteEngine, base as TAnimTemplate, target as IAnimTarget, fullscreen as bool, signal as EventWaitHandle):
		super(parent)
		FBase = base
		self.Z = 19
		self.Pinned = true
		FFrameCount = FBase.Frames.Last.Frame
		FTimer = TRpgTimestamp(0)
		FTarget = target
		FFullScreen = fullscreen
		FSignal = signal

	private new def Destroy():
		if assigned(FSignal):
			FSignal.Set()
		for sprite in self.List.ToArray():
			sprite.Dispose()

	private def Move():
		tr as uint = FTimer.TimeRemaining
		return if tr > 0
		++FLastFrame
		frame as ushort = FLastFrame
		ClearSpriteList()
		for currFrame in FBase.Frames.Where({ input | return input.Frame == frame }):
			SetupFrame(currFrame)
		PlayEffect(frame) if FLastEffect < FBase.Effects.Count
		FTimer = TRpgTimestamp(32)

	private def SetupFrame(currFrame as TAnimCell):
		var newSprite = TAnimSpriteCell(self)
		newSprite.Pinned = true
		newSprite.ImageName = 'Anim ' + FBase.Filename
		newSprite.ImageIndex = currFrame.ImageIndex
		if FFullScreen:
			newSprite.X = currFrame.Position.x + (Engine.Canvas.Width / 2)
			newSprite.Y = currFrame.Position.y + (Engine.Canvas.Height / 2)
		else:
			sign as int
			caseOf FBase.YTarget:
				case TAnimYTarget.Top:
					sign = -1
				case TAnimYTarget.Center:
					sign = 0
				case TAnimYTarget.Bottom:
					sign = 1
				default :
					raise ESpriteError('Bad yTarget value')
			position as TSgPoint = FTarget.Position(sign)
			newSprite.X = currFrame.Position.x + position.x
			newSprite.Y = currFrame.Position.y + position.y
		newSprite.Z = 1
		newSprite.ScaleX = currFrame.Zoom / 100.0
		newSprite.ScaleY = newSprite.ScaleX
		newSprite.Red = commons.round(currFrame.Color.Rgba[1] * 1.275) //half of 2.55
		newSprite.Green = commons.round(currFrame.Color.Rgba[2] * 1.275)
		newSprite.Blue = commons.round(currFrame.Color.Rgba[3] * 1.275)
		newSprite.Alpha = 255
		newSprite.Sat = commons.round(currFrame.Color.Rgba[4] * 1.275)

	private def PlayEffect(frame as ushort):
		r as byte
		g as byte
		b as byte
		a as byte
		while (FLastEffect < FBase.Effects.Count) and (FBase.Effects[FLastEffect].Frame == frame):
			currEffect as TAnimEffects = FBase.Effects[FLastEffect]
			if assigned(currEffect.Sound) and not string.IsNullOrEmpty(currEffect.Sound.Filename):
				PlaySoundData(currEffect.Sound)
			caseOf currEffect.Flash:
				case TFlashTarget.None:
					pass
				case TFlashTarget.Target:
					ExtractColors(currEffect, r, g, b, a)
					if assigned(FTarget):
						FTarget.Flash(r, g, b, a, 2)
					else: FlashScreen(r, g, b, a, 2, false)
				case TFlashTarget.Screen:
					ExtractColors(currEffect, r, g, b, a)
					FlashScreen(r, g, b, a, 2, false)
				default : assert false
			++FLastEffect

	protected override def InVisibleRect() as bool:
		return false

	public override def Draw():
		self.Move()
		super.Draw()
		if FLastFrame == FFrameCount:
			self.Dead()

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private static def ExtractColors(effect as TAnimEffects, ref r as byte, ref g as byte, ref b as byte, ref a as byte):
		r = commons.round(effect.r * MULTIPLIER_31)
		g = commons.round(effect.g * MULTIPLIER_31)
		b = commons.round(effect.b * MULTIPLIER_31)
		a = commons.round(effect.a * MULTIPLIER_31)
