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

abstract class TSdlRenderSurface(ISdlRenderSurface):
	static internal lCurrentRenderTarget as TSdlRenderSurface

	[Getter(Parent)]
	protected FParent as ISdlCanvas

	[Getter(Size)]
	protected FSize as TSgPoint
	
	private FBgColor as TSgColor
	
	[Getter(RenderTarget)]
	protected FRenderTarget as GPU_Target_PTR

	public def Clear():
		assert lCurrentRenderTarget == self
		GPU_ClearRGBA(FRenderTarget, FBgColor.Rgba[1], FBgColor.Rgba[2], FBgColor.Rgba[3], FBgColor.Rgba[4])

	public abstract def SetRenderer():
		pass

	public Width as int:
		get: return FSize.x

	public Height as int:
		get: return FSize.y

[Disposable(Destroy, true)]
class TSdlRenderTarget(TSdlRenderSurface):
	
	//GPU_Image that holds the target
	[Getter(Image)]
	private FImage as GPU_Image_PTR

	public def constructor(size as TSgPoint):
		super()
		assert assigned(lCurrentRenderTarget)
		FParent = lCurrentRenderTarget.FParent
		FImage = GPU_CreateImage(size.x, size.y, GPU_FormatEnum.GPU_FORMAT_RGBA)
		FRenderTarget = GPU_LoadTarget(FImage)
		GPU_SetBlendMode(FImage, GPU_BlendPresetEnum.GPU_BLEND_NORMAL)
		FSize = size

	private def Destroy():
		GPU_FreeTarget(FRenderTarget)
		GPU_FreeImage(FImage)

	public override def SetRenderer():
		FParent.SetRenderTarget(self)

	public def DrawFull():
		GPU_Blit(self.FImage, IntPtr.Zero, currentRenderTarget().RenderTarget, 0, 0)

	public def DrawFull(TopLeft as Point):
		GPU_Blit(self.FImage, IntPtr.Zero, currentRenderTarget().RenderTarget, TopLeft.X, TopLeft.Y)
		

class TSdlRenderTargets(List[of TSdlRenderTarget]):

	public def RenderOn(index as int, Event as Action, Bkgrnd as uint, FillBk as bool, composite as bool) as bool:
		return false  unless (index >= 0) and (index < Count)
		target as TSdlRenderTarget = self[index]
		currentRenderTarget().Parent.PushRenderTarget()
		try:
			target.SetRenderer()
			if FillBk:
				color as TSgColor = Bkgrnd cast TSgColor
				color.Rgba[4] = (0 if composite else 255)
				target.Parent.Clear(color, 0xFF)
			Event() unless Event is null
			return true
		ensure:
			currentRenderTarget().Parent.PopRenderTarget()

interface ISdlCanvas(ISdlRenderSurface):
	def SetRenderTarget(Value as TSdlRenderSurface)
	
	def Draw(image as TSdlImage, dest as TSgPoint, flip as SDL.SDL_RendererFlip)

	def Draw(target as TSdlRenderTarget, dest as TSgPoint)

	def DrawTo(image as TSdlImage, dest as GPU_Rect)

	def DrawRect(image as TSdlImage, dest as TSgPoint, source as GPU_Rect, flip as SDL.SDL_RendererFlip)

	def DrawRect(target as TSdlRenderTarget, dest as TSgPoint, source as GPU_Rect)

	def DrawRectTo(image as TSdlImage, dest as GPU_Rect, source as GPU_Rect)

	def DrawRectTo(target as TSdlRenderTarget, dest as GPU_Rect, source as GPU_Rect)

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

	RenderSurface as TSdlRenderSurface:
		get
		set

	def SetRenderer()

class TSdlCanvas(TSdlRenderSurface, ISdlCanvas):
	
	private FRenderStack = Stack[of TSdlRenderSurface]()

	private FRenderSurface as TSdlRenderSurface

	[Property(OnResize)]
	private FOnResize as Action of TSdlCanvas

	def SetRenderTarget(Value as TSdlRenderSurface):
		if Value == null:
			SetRenderTarget(self)
		else: FRenderSurface = Value
		lCurrentRenderTarget = FRenderSurface

	public def constructor(title as string, size as Rectangle, flags as SDL.SDL_WindowFlags):
		super()
		FRenderTarget = GPU_InitRenderer(GPU_RendererEnum.GPU_RENDERER_OPENGL_3, size.Right, size.Bottom, flags)
		FSize = TSgPoint(size.Right, size.Bottom)
		GPU_Flip(FRenderTarget)
		self.RenderSurface = self
		FParent = self

	public def constructor(window as UInt32):
	""" Create a canvas for an existing SDL window """
		super()
		x as UInt16
		y as UInt16
		FRenderTarget = GPU_GetWindowTarget(window)
		if FRenderTarget.Pointer == IntPtr.Zero:
			GPU_SetInitWindow(window)
			FRenderTarget = GPU_InitRenderer(GPU_RendererEnum.GPU_RENDERER_OPENGL_3, 0, 0, SDL.SDL_WindowFlags.SDL_WINDOW_OPENGL)
		self.RenderSurface = self
		GPU_GetVirtualResolution(GPU_GetWindowTarget(window), x, y)
		FParent = self

	public def Draw(image as TSdlImage, dest as TSgPoint, flip as SDL.SDL_RendererFlip):
		if flip == SDL.SDL_RendererFlip.SDL_FLIP_NONE:
			GPU_Blit(image.Surface, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x + image.TextureSize.x / 2.0, dest.y + image.TextureSize.y / 2.0)
		else: raise "Flips are not implemented"
//			assert SDL_RenderCopyEx(FRenderer, image.Surface, IntPtr.Zero, dummy, 0, IntPtr.Zero, flip) == 0

	public def Draw(target as TSdlRenderTarget, dest as TSgPoint):
		GPU_Blit(target.Image, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x + target.Width / 2.0, dest.y + target.Height / 2.0)

	public def DrawTo(image as TSdlImage, dest as GPU_Rect):
		GPU_BlitScale(image.Surface, IntPtr.Zero, lCurrentRenderTarget.RenderTarget, dest.x, dest.y, dest.w / image.ImageSize.x , dest.h / image.ImageSize.y)

	public def DrawRect(image as TSdlImage, dest as TSgPoint, source as GPU_Rect, flip as SDL.SDL_RendererFlip):
		if flip == SDL.SDL_RendererFlip.SDL_FLIP_NONE:
			GPU_Blit(image.Surface, source, lCurrentRenderTarget.RenderTarget, dest.x + (source.w / 2), dest.y + (source.h / 2))
		else: raise "Flips are not implemented"

	public def DrawRect(target as TSdlRenderTarget, dest as TSgPoint, source as GPU_Rect):
		GPU_Blit(target.Image, source, lCurrentRenderTarget.RenderTarget, dest.x, dest.y)

	public def DrawRectTo(image as TSdlImage, dest as GPU_Rect, source as GPU_Rect):
		GPU_BlitScale(image.Surface, source, lCurrentRenderTarget.RenderTarget, dest.x, dest.y, dest.w / image.ImageSize.x , dest.h / image.ImageSize.y)

	public def DrawRectTo(target as TSdlRenderTarget, dest as GPU_Rect, source as GPU_Rect):
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
		GPU_Flip(FRenderTarget)

	public def PushRenderTarget():
		FRenderStack.Push(FRenderSurface)

	public def PopRenderTarget():
		FRenderStack.Pop().SetRenderer()

	public def Resize():
		w as ushort
		h as ushort
		GPU_GetVirtualResolution(FRenderTarget, w, h)
		if (w != FSize.x) or (h != FSize.y):
			FSize = sgPoint(w, h)
			if assigned(FOnResize):
				FOnResize(self)

	public RenderSurface as TSdlRenderSurface:
		get: return FRenderSurface
		set: SetRenderTarget(value)

	public override def SetRenderer():
		SetRenderTarget(null)

	public static def CreateFrom(value as IntPtr) as TSdlCanvas:
		return TSdlCanvas(SDL.SDL_GetWindowID(value))

class ECanvas(System.Exception):
	def constructor(msg as string):
		super(msg)

static def currentRenderTarget() as TSdlRenderSurface:
	return TSdlRenderSurface.lCurrentRenderTarget
