namespace sdl.canvas

import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import SDL.ImageManager
import SG.defs
import SDL2.SDL
import OpenGL4NET
import System.Drawing

abstract class TSdlRenderSurface(TObject):

	[Getter(parent)]
	private FParent as TSdlCanvas

	[Getter(size)]
	private FSize as TSgPoint

	private def SetBgColor(Value as TSgColor):
		assert lCurrentRenderTarget == self
		SDL_SetRenderDrawColor(FParent.FRenderer, Value.rgba[1], Value.rgba[2], Value.rgba[3], Value.rgba[4])

	public def Clear():
		assert lCurrentRenderTarget == self
		SDL_RenderFillRect(FParent.FRenderer, null)

	public abstract def SetRenderer():
		pass

	public Width as int:
		get:
			return FSize.x

	public Height as int:
		get:
			return FSize.y

class TSdlRenderTarget(TSdlRenderSurface):

	[Getter(handle)]
	private FHandle as IntPtr

	public def constructor(size as TSgPoint):
		info as SDL_RendererInfo
		super()
		assert assigned(lCurrentRenderTarget)
		FParent = lCurrentRenderTarget.FParent
		SDL_GetRendererInfo(FParent.FRenderer, info)
		FHandle = TSdlTexture.Create(FParent.FRenderer, info.texture_formats[0], sdltaRenderTarget, size.x, size.y)
		SDL_SetTextureBlendMode(FHandle, [sdlbBlend])
		FSize = FHandle.size

	def destructor():
		FHandle.Free()

	public override def SetRenderer():
		if SDL_SetRenderTarget(FParent.FRenderer, FHandle) != 0:
			System.Diagnostics.Debugger.Break()
		FParent.SetRenderTarget(self)

	public def DrawFull():
		xScale as single
		yScale as single
		lHeight as int
		lWidth as int
		glEnable(GL_TEXTURE_RECTANGLE_ARB)
		self.handle.bind
		SDL_RenderGetScale(FParent.FRenderer, xScale, yScale)
		lWidth = round((Width * xScale))
		lHeight = round((Height * yScale))
		glBegin(GL_QUADS)
		glTexCoord2i(0, 0)
		glVertex2i(0, 0)
		glTexCoord2i(0, Height)
		glVertex2i(0, lHeight)
		glTexCoord2i(Width, Height)
		glVertex2i(lWidth, lHeight)
		glTexCoord2i(Width, 0)
		glVertex2i(lWidth, 0)
		glEnd

	public def DrawFull(TopLeft as Point):
		xScale as single
		yScale as single
		glEnable(GL_TEXTURE_RECTANGLE_ARB)
		self.handle.bind
		SDL_RenderGetScale(FParent.FRenderer, xScale, yScale)
		glBegin(GL_QUADS)
		glTexCoord2i(0, 0)
		glVertex2i(round((TopLeft.X * xScale)), round((TopLeft.y * yScale)))
		glTexCoord2i(Width, 0)
		glVertex2i(round(((TopLeft.X + Width) * xScale)), round((TopLeft.y * yScale)))
		glTexCoord2i(Width, Height)
		glVertex2i(round(((TopLeft.X + Width) * xScale)), round(((TopLeft.y + Height) * yScale)))
		glTexCoord2i(0, Height)
		glVertex2i(round((TopLeft.X * xScale)), round(((TopLeft.y + Height) * yScale)))
		glEnd

class TSdlRenderTargets(List[of TSdlRenderTarget]):

	public def RenderOn(Index as int, Event as EventHandler, Bkgrnd as uint, FillBk as bool, composite as bool) as bool:
		Target as TSdlRenderTarget
		color as TSgColor
		result = false
		if not ((Index >= 0) and (Index < count)):
			return result
		Target = self[Index]
		currentRenderTarget.FParent.pushRenderTarget
		try:
			target.SetRenderer
			if FillBk:
				color = TSgColor(bkgrnd)
				if composite:
					color.rgba[4] = 0
				else:
					color.rgba[4] = 255
				glDisable(GL_BLEND)
				target.parent.Clear(color)
				glEnable(GL_BLEND)
			if assigned(Event):
				Event(Self)
			result = true
		ensure:
			currentRenderTarget.FParent.popRenderTarget
		return result

class TRenderStack(Stack[of TSdlRenderSurface]):
	pass

callable TSdlCanvasNotifyEvent(sender as TSdlCanvas)
class TSdlCanvas(TSdlRenderSurface):

	[Getter(Renderer)]
	private FRenderer as IntPtr

	private FRenderStack as TRenderStack

	private FRenderTarget as TSdlRenderSurface

	[Getter(Window)]
	private FWindow as IntPtr

	[Property(OnResize)]
	private FOnResize as TSdlCanvasNotifyEvent

	private def SetRenderTarget(Value as TSdlRenderSurface):
		if value == null:
			SetRenderTarget(self)
		else:
			FRenderTarget = Value
		lCurrentRenderTarget = FRenderTarget

	public def constructor(title as string, size as Rectangle, flags as SDL_WindowFlags):
		super()
		FRenderStack = TRenderStack.Create
		if SDL_WasInit(SDL_INIT_VIDEO) != SDL_INIT_VIDEO:
			SDL_InitSubSystem(SDL_INIT_VIDEO)
		FWindow = SDL_CreateWindow(PAnsiChar(title), size.Left, size.Top, size.Right, size.Bottom, flags)
		SDL_RenderGetLogicalSize(FRenderer, FSize.x, FSize.y)
		FRenderer = TSDLRenderer.Create(FWindow, SDL_RendererIndex('opengl'), [sdlrAccelerated])
		SDL_RenderPresent(FRenderer)
		self.RenderTarget = self
		FParent = self

	public def constructor(value as IntPtr):
		super()
		FRenderStack = TRenderStack.Create
		if SDL_WasInit(SDL_INIT_VIDEO) != SDL_INIT_VIDEO:
			SDL_InitSubSystem(SDL_INIT_VIDEO)
		FWindow = value
		self.RenderTarget = self
		FRenderer = SDL_GetRenderer(value)
		SDL_RenderGetLogicalSize(FRenderer, FSize.x, FSize.y)
		FParent = self

	def destructor():
		FRenderStack.Free()

	public def Draw(image as TSdlImage, dest as TSgPoint, flip as SDL_RendererFlip):
		dummy as SDL_Rect
		dummy.TopLeft = dest
		dummy.BottomRight = image.surface.size
		if flip == []:
			assert SDL_RenderCopy(FRenderer, image.surface, null, __addressof__(dummy)) == 0
		else:
			assert SDL_RenderCopyFlipped(FRenderer, image.surface, null, __addressof__(dummy), flip) == 0

	public def Draw(target as TSdlRenderTarget, dest as TSgPoint):
		dummy as SDL_Rect
		dummy.TopLeft = dest
		dummy.BottomRight = target.handle.size
		assert SDL_RenderCopy(FRenderer, target.handle, null, __addressof__(dummy)) == 0

	public def DrawTo(image as TSdlImage, dest as Rectangle):
		assert SDL_RenderCopy(FRenderer, image.surface, null, __addressof__(dest)) == 0

	public def DrawRect(image as TSdlImage, dest as TSgPoint, source as Rectangle, flip as SDL_RendererFlip):
		dummy as SDL_Rect
		dummy.TopLeft = dest
		dummy.BottomRight = source.BottomRight
		if flip == []:
			assert SDL_RenderCopy(FRenderer, image.surface, __addressof__(source), __addressof__(dummy)) == 0
		else:
			assert SDL_RenderCopyFlipped(FRenderer, image.surface, __addressof__(source), __addressof__(dummy), flip) == 0

	public def DrawRect(target as TSdlRenderTarget, dest as TSgPoint, source as Rectangle):
		dummy as SDL_Rect
		dummy.TopLeft = dest
		dummy.BottomRight = source.BottomRight
		assert SDL_RenderCopy(FRenderer, target.handle, __addressof__(source), __addressof__(dummy)) == 0

	public def DrawRectTo(image as TSdlImage, dest as Rectangle, source as Rectangle):
		if SDL_RenderCopy(FRenderer, image.surface, __addressof__(source), __addressof__(dest)) != 0:
			raise ECanvas.CreateFmt('SDL_RenderCopy failed: %s', [AnsiString(SDL_GetError)])

	public def DrawRectTo(target as TSdlRenderTarget, dest as Rectangle, source as Rectangle):
		if SDL_RenderCopy(FRenderer, target.handle, __addressof__(source), __addressof__(dest)) != 0:
			raise ECanvas.CreateFmt('SDL_RenderCopy failed: %s', [AnsiString(SDL_GetError)])

	public def DrawBox(region as Rectangle, color as SDL_Color, alpha as byte):
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		SDL_RenderDrawRect(FRenderer, __addressof__(region))

	public def DrawDashedBox(region as Rectangle, color as SDL_Color, alpha as byte):
		def DrawHorizLine(x1 as int, x2 as int, y as int):
			x as int
			x = x1
			while x < (x2 - 2):
				SDL_RenderDrawLine(FRenderer, x, y, (x + 2), y)
				inc(x, 4)
		def DrawVertLine(y1 as int, y2 as int, x as int):
			y as int
			y = y1
			while y < (y2 - 2):
				SDL_RenderDrawLine(FRenderer, x, y1, x, (y + 2))
				inc(y, 4)
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		DrawHorizLine(region.Left, region.Right, region.Top)
		DrawHorizLine(region.Left, region.Right, region.Bottom)
		DrawVertLine(region.Top, region.Bottom, region.Left)
		DrawVertLine(region.Top, region.Bottom, region.Right)

	public def FillRect(region as Rectangle, color as SDL_Color, alpha as byte):
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		SDL_RenderFillRect(FRenderer, __addressof__(region))

	public def Clear(color as SDL_Color, alpha as byte):
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		glColor4f(((color.r cast double) / 255.0), ((color.g cast double) / 255.0), ((color.b cast double) / 255.0), ((alpha cast double) / 255.0))
		SDL_RenderFillRect(FRenderer, null)

	public virtual def Flip():
		SDL_RenderPresent(FRenderer)

	public def pushRenderTarget():
		FRenderStack.Push(FRenderTarget)

	public def popRenderTarget():
		FRenderStack.Pop.SetRenderer

	public def Resize():
		x as int
		y as int
		SDL_RenderGetLogicalSize(FRenderer, x, y)
		if (x != FSize.x) or (y != FSize.y):
			FSize = sgPoint(x, y)
			if assigned(FOnResize):
				FOnResize(self)

	public RenderTarget as TSdlRenderSurface:
		get:
			return FRenderTarget
		set:
			SetRenderTarget(value)

	public override def SetRenderer():
		SetRenderTarget(null)
		SDL_ResetTargetTexture(FRenderer)

class ECanvas(Exception):
	pass

def currentRenderTarget() as TSdlRenderSurface:
	return lCurrentRenderTarget

