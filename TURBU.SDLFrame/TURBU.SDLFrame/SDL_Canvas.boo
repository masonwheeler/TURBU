namespace sdl.canvas

import System
import SDL2
import SDL2.SDL2_GPU
import System.Collections.Generic
import SDL.ImageManager
import SG.defs
import System.Drawing
import Pythia.Runtime

//because https://github.com/bamboo/boo/issues/105 sucks...
interface ISdlRenderSurface:
	Width as int:
		get

	Height as int:
		get

abstract class SdlRenderSurface(ISdlRenderSurface):
	static internal lCurrentRenderTarget as SdlRenderSurface

	[Getter(Parent)]
	protected _parent as ISdlCanvas

	[Getter(Size)]
	protected _size as SgPoint
	
	private _bgColor as TSgColor
	
	[Getter(RenderTarget)]
	protected _renderTarget as GPU_Target_PTR

	public def Clear():
		assert lCurrentRenderTarget == self
		GPU_ClearRGBA(_renderTarget, _bgColor.Rgba[1], _bgColor.Rgba[2], _bgColor.Rgba[3], _bgColor.Rgba[4])

	public abstract def SetRenderer():
		pass

	public Width as int:
		get: return _size.x

	public Height as int:
		get: return _size.y

[Disposable(Destroy, true)]
class SdlRenderTarget(SdlRenderSurface):
	
	//GPU_Image that holds the target
	[Getter(Image)]
	private _image as GPU_Image_PTR

	public def constructor(size as SgPoint):
		super()
		assert assigned(lCurrentRenderTarget)
		_parent = lCurrentRenderTarget._parent
		_image = GPU_CreateImage(size.x, size.y, GPU_FormatEnum.GPU_FORMAT_RGBA)
		_renderTarget = GPU_LoadTarget(_image)
		GPU_SetBlendMode(_image, GPU_BlendPresetEnum.GPU_BLEND_NORMAL)
		_size = size

	private def Destroy():
		GPU_FreeTarget(_renderTarget)
		GPU_FreeImage(_image)

	public override def SetRenderer():
		_parent.SetRenderTarget(self)

	public def DrawFull():
		_parent.Draw(self, sgPoint(0, 0))

	public override def ToString():
		return "SdlRenderTarget: (${_size.x}, ${_size.y})"

class SdlRenderTargets(List[of SdlRenderTarget]):

	public def RenderOn(index as int, Event as Action, bkgrnd as uint, fillBk as bool, composite as bool) as bool:
		return false  unless (index >= 0) and (index < Count)
		target as SdlRenderTarget = self[index]
		currentRenderTarget().Parent.PushRenderTarget()
		try:
			target.SetRenderer()
			if fillBk:
				var color = TSgColor(bkgrnd)
				color.Rgba[4] = (0 if composite else 255)
				target.Parent.Clear(color, 0xFF)
			Event() unless Event is null
			return true
		ensure:
			currentRenderTarget().Parent.PopRenderTarget()

interface ISdlCanvas(ISdlRenderSurface):
	def SetRenderTarget(Value as SdlRenderSurface)
	
	def Draw(image as TSdlImage, dest as SgPoint, flip as SDL.SDL_RendererFlip)

	def Draw(target as SdlRenderTarget, dest as SgPoint)

	def DrawTo(image as TSdlImage, dest as GPU_Rect)

	def DrawRect(image as TSdlImage, dest as SgPoint, source as GPU_Rect, flip as SDL.SDL_RendererFlip)

	def DrawRect(target as SdlRenderTarget, dest as SgPoint, source as GPU_Rect)

	def DrawRectTo(image as TSdlImage, dest as GPU_Rect, source as GPU_Rect)

	def DrawRectTo(target as SdlRenderTarget, dest as GPU_Rect, source as GPU_Rect)

	def DrawBox(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte)

	def DrawDashedBox(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte)

	def FillRect(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte)

	def FillRect(region as GPU_Rect, color as SDL.SDL_Color)

	def Clear(color as SDL.SDL_Color, alpha as byte)

	def Clear(color as SDL.SDL_Color)

	def Flip()

	def PushRenderTarget()

	def PopRenderTarget()

	def Resize()

	RenderSurface as SdlRenderSurface:
		get
		set

	def SetRenderer()

class SdlCanvas(SdlRenderSurface, ISdlCanvas):
	
	private _renderStack = Stack[of SdlRenderSurface]()

	private _renderSurface as SdlRenderSurface

	[Property(OnResize)]
	private _onResize as Action of SdlCanvas

	def SetRenderTarget(Value as SdlRenderSurface):
		if Value == null:
			SetRenderTarget(self)
		else: _renderSurface = Value
		lCurrentRenderTarget = _renderSurface

	public def constructor(title as string, size as Rectangle, flags as SDL.SDL_WindowFlags):
		super()
		_renderTarget = GPU_InitRenderer(GPU_RendererEnum.GPU_RENDERER_OPENGL_3, size.Right, size.Bottom, flags)
		_size = SgPoint(size.Right, size.Bottom)
		GPU_Flip(_renderTarget)
		self.RenderSurface = self
		_parent = self

	public def constructor(window as UInt32):
	""" Create a canvas for an existing SDL window """
		super()
		x as UInt16
		y as UInt16
		_renderTarget = GPU_GetWindowTarget(window)
		if _renderTarget.Pointer == IntPtr.Zero:
			GPU_SetInitWindow(window)
			_renderTarget = GPU_InitRenderer(GPU_RendererEnum.GPU_RENDERER_OPENGL_3, 0, 0, SDL.SDL_WindowFlags.SDL_WINDOW_OPENGL)
		self.RenderSurface = self
		GPU_GetVirtualResolution(GPU_GetWindowTarget(window), x, y)
		_parent = self

	public def Draw(image as TSdlImage, dest as SgPoint, flip as SDL.SDL_RendererFlip):
		if flip == SDL.SDL_RendererFlip.SDL_FLIP_NONE:
			GPU_Blit(image.Surface, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x + image.TextureSize.x / 2.0, dest.y + image.TextureSize.y / 2.0)
		else:
			var xScale = (-1 if flip & SDL.SDL_RendererFlip.SDL_FLIP_HORIZONTAL > 0 else 1)
			var yScale = (-1 if flip & SDL.SDL_RendererFlip.SDL_FLIP_VERTICAL > 0 else 1)
			GPU_BlitScale(image.Surface, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x + image.TextureSize.x / 2.0, dest.y + image.TextureSize.y / 2.0, xScale, yScale)

	public def Draw(target as SdlRenderTarget, dest as SgPoint):
		GPU_Blit(target.Image, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x + target.Width / 2.0, dest.y + target.Height / 2.0)

	public def DrawTo(image as TSdlImage, dest as GPU_Rect):
		GPU_BlitScale(image.Surface, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x, dest.y, dest.w / image.ImageSize.x , dest.h / image.ImageSize.y)

	public def DrawRect(image as TSdlImage, dest as SgPoint, source as GPU_Rect, flip as SDL.SDL_RendererFlip):
		if flip == SDL.SDL_RendererFlip.SDL_FLIP_NONE:
			GPU_Blit(image.Surface, source, lCurrentRenderTarget.RenderTarget, dest.x + (source.w / 2), dest.y + (source.h / 2))
		else:
			var xScale = (-1 if flip & SDL.SDL_RendererFlip.SDL_FLIP_HORIZONTAL > 0 else 1)
			var yScale = (-1 if flip & SDL.SDL_RendererFlip.SDL_FLIP_VERTICAL > 0 else 1)
			GPU_BlitScale(image.Surface, source, lCurrentRenderTarget.RenderTarget, dest.x + (source.w / 2), dest.y + (source.h / 2), xScale, yScale)

	public def DrawRect(target as SdlRenderTarget, dest as SgPoint, source as GPU_Rect):
		GPU_Blit(target.Image, source, lCurrentRenderTarget.RenderTarget, dest.x, dest.y)

	public def DrawRectTo(image as TSdlImage, dest as GPU_Rect, source as GPU_Rect):
		GPU_BlitScale(image.Surface, source, lCurrentRenderTarget.RenderTarget, dest.x, dest.y, dest.w / image.ImageSize.x , dest.h / image.ImageSize.y)

	public def DrawRectTo(target as SdlRenderTarget, dest as GPU_Rect, source as GPU_Rect):
		GPU_BlitScale(target.Image, source, lCurrentRenderTarget.RenderTarget, dest.x, dest.y, dest.w / target.Size.x , dest.h / target.Size.y)

	public def DrawBox(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte):
		GPU_Rectangle(lCurrentRenderTarget.RenderTarget, region.x, region.y, region.x + region.w, region.y + region.h, color)

	public def DrawDashedBox(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte):
		def DrawHorizLine(x1 as int, x2 as int, y as int):
			x as int
			x = x1
			while x < (x2 - 2):
				GPU_Line(lCurrentRenderTarget.RenderTarget, x, y, x + 2, y, color)
				x += 4
		
		def DrawVertLine(y1 as int, y2 as int, x as int):
			y as int
			y = y1
			while y < (y2 - 2):
				GPU_Line(lCurrentRenderTarget.RenderTarget, x, y, x, y + 2, color)
				y += 4
		
		DrawHorizLine(region.x, region.x + region.w, region.y)
		DrawHorizLine(region.x, region.x + region.w, region.y + region.h)
		DrawVertLine(region.y, region.y + region.h, region.x)
		DrawVertLine(region.y, region.y + region.h, region.x + region.w)

	public def FillRect(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte):
		lColor as SDL.SDL_Color = color
		lColor.a = alpha
		GPU_RectangleFilled(lCurrentRenderTarget.RenderTarget, region.x, region.y, region.x + region.w, region.y + region.h, lColor)

	public def FillRect(region as GPU_Rect, color as SDL.SDL_Color):
		FillRect(region, color, 255)

	public def Clear(color as SDL.SDL_Color, alpha as byte):
		lColor as SDL.SDL_Color = color
		lColor.a = alpha
		GPU_ClearColor(lCurrentRenderTarget.RenderTarget, lColor)

	public def Clear(color as SDL.SDL_Color):
		Clear(color, 255)

	public virtual def Flip():
		GPU_Flip(_renderTarget)

	public def PushRenderTarget():
		_renderStack.Push(_renderSurface)

	public def PopRenderTarget():
		_renderStack.Pop().SetRenderer()

	public def Resize():
		w as ushort
		h as ushort
		GPU_GetVirtualResolution(_renderTarget, w, h)
		if (w != _size.x) or (h != _size.y):
			_size = sgPoint(w, h)
			if assigned(_onResize):
				_onResize(self)

	public RenderSurface as SdlRenderSurface:
		get: return _renderSurface
		set: SetRenderTarget(value)

	public override def SetRenderer():
		SetRenderTarget(null)

	public static def CreateFrom(value as IntPtr) as SdlCanvas:
		return SdlCanvas(SDL.SDL_GetWindowID(value))

static def currentRenderTarget() as SdlRenderSurface:
	return SdlRenderSurface.lCurrentRenderTarget
