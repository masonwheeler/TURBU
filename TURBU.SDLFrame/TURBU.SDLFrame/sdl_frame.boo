namespace sdl.frame

import System
import System.Drawing
import System.Math
import System.Runtime.InteropServices
import System.Windows.Forms
import SDL2
import SDL2.SDL2_GPU
import SDL.ImageManager
import SG.defs
import Pythia.Runtime

enum TRendererType:
	rtSoftware
	rtGDI
	rtOpenGL
	rtD3D

[Disposable(Destroy, true)]
class TSdlFrame(Control):

	[Getter(SdlWindow)]
	private FWindow as IntPtr

	[Getter(Renderer)]
	private FRenderer as GPU_Target_PTR

	[Getter(Flags)]
	private FFlags as SDL.SDL_WindowFlags

	private FTimer as Timer

	private FFramerate as ushort

	private FActive as bool

	[Getter(Available)]
	private FRendererAvailable as bool

	[Property(RendererType)]
	private FRendererType as TRendererType

	[Getter(Images)]
	private FImageManager as SdlImages

	[Property(OnTimer)]
	private FOnTimer as EventHandler

	[Property(OnAvailable)]
	private FOnAvailable as EventHandler

	private FLogicalWidth as int

	private FLogicalHeight as int

	[Property(OnPaintEvent)]
	private FOnPaint as EventHandler

	[Getter(GLVersion)]
	private FGLVersion as string

	private def CreateWindow():
		flags as SDL.SDL_WindowFlags
		if FWindow == IntPtr.Zero:
			SDL.SDL_SetHint('SDL_FOREIGN_WINDOW_OPENGL_SUPPORT', 'true')
			FWindow = SDL.SDL_CreateWindowFrom(self.Handle)
			if FWindow == IntPtr.Zero:
				raise SDL.SDL_GetError()
		flags = SDL.SDL_GetWindowFlags(FWindow)
		// assert flags & SDL.SDL_WindowFlags.SDL_WINDOW_RESIZABLE == SDL.SDL_WindowFlags.SDL_WINDOW_RESIZABLE
		GPU_SetInitWindow(SDL.SDL_GetWindowID(FWindow))
		raise SDL.SDL_GetError() if FWindow == IntPtr.Zero

	private def DestroyWindow():
		FTimer.Tick -= self.InternalOnTimer
		// GPU_DestroyRenderer(FRenderer) # This needs to be implemented
		SDL.SDL_DestroyWindow(FWindow)
		FFlags = 0
		self.Framerate = 0

	private def CreateRenderer():
		return if FRendererAvailable
		try:
			FRenderer = GPU_InitRenderer(GPU_RendererEnum.GPU_RENDERER_OPENGL_3, FLogicalWidth, FLogicalHeight, 
				SDL.SDL_WindowFlags.SDL_WINDOW_OPENGL)
			if FRenderer.Pointer != IntPtr.Zero:
				SDL2.SDL.SDL_GL_LoadLibrary(null)
				ptr = SDL2.SDL.SDL_GL_GetProcAddress('glGetError')
				glGetError = Marshal.GetDelegateForFunctionPointer[of GlGetErrorType](ptr)
				glCheckError()
				getString = Marshal.GetDelegateForFunctionPointer[of GlGetStringType](SDL2.SDL.SDL_GL_GetProcAddress('glGetString'))
				GL_VERSION = 0x1F02
				FGLVersion = Marshal.PtrToStringAnsi(getString(GL_VERSION))
				glCheckError()

				SDL.SDL_ShowWindow(FWindow)
				ResetLogicalSize()
				GPU_ClearRGBA(FRenderer, 255, 0, 128, 255)
				FFlags = SDL.SDL_GetWindowFlags(FWindow)
				FRendererAvailable = true
				FOnAvailable(self, EventArgs.Empty) if assigned(FOnAvailable)
			else:
				eo = GPU_PopErrorCode()
				raise "GPU_InitRenderer failed: $(eo.function), $(eo.details)"
		ensure:
			glCheckError()

	private def InternalOnTimer(Sender as object, args as EventArgs):
		if self.Disposing or self.IsDisposed:
			FTimer.Enabled = false
		else:
			FOnTimer(self, EventArgs.Empty) if assigned(FOnTimer)

	private def SetFramerate(value as int):
		return if value < 0
		value = Min(value, 100)
		FFramerate = value
		if value == 0:
			SetActive(false)
		else:
			FTimer.Interval = Round((1000.0 / (value cast double)))

	private def SetActive(Value as bool):
		FActive = Value
		FTimer.Enabled = Value

	private def SetLogicalWidth(Value as int):
		return if FLogicalWidth == Value
		
		FLogicalWidth = Value
		if FRendererAvailable:
			GPU_SetVirtualResolution(FRenderer.Pointer, FLogicalWidth, FLogicalHeight)
			self.Flip()

	private def SetLogicalHeight(Value as int):
		return if FLogicalHeight == Value
		
		FLogicalHeight = Value
		if FRendererAvailable:
			GPU_SetVirtualResolution(FRenderer.Pointer, FLogicalWidth, FLogicalHeight)
			self.Flip()

	private def GetAspectRatio() as double:
		return (self.Width cast double) / (self.Height cast double)

	private def GetLogicalSize() as SgPoint:
		return SgPoint(FLogicalWidth, FLogicalHeight)

	private def SetLogicalSize(value as SgPoint):
		if (value.x == FLogicalWidth) and (value.y == FLogicalHeight):
			return
		FLogicalWidth = value.x
		FLogicalHeight = value.y
		if FRendererAvailable:
			GPU_SetVirtualResolution(FRenderer.Pointer, FLogicalWidth, FLogicalHeight)
			self.Flip()

	private def ClearViewport():
		GPU_UnsetViewport(FRenderer)

	protected override def CreateHandle():
		super()
		self.CreateWindow()

	protected override def DestroyHandle():
		DestroyWindow()
		super()

	protected override def OnPaint(e as PaintEventArgs):
		CreateRenderer()
		if assigned(FOnPaint):
			FOnPaint(self, EventArgs.Empty)
		else:
			self.Flip()

	protected override def OnMouseDown(e as MouseEventArgs):
		self.Focus() if self.CanFocus
		super(e)

	protected override def OnResize(e as EventArgs):
		super.OnResize(e)
		if FRenderer.Pointer != IntPtr.Zero:
			BeginInvoke(ClearViewport)

	public def constructor():
		super()
		FTimer = Timer()
		FTimer.Interval = 100
		FTimer.Tick += self.InternalOnTimer
		FRendererType = TRendererType.rtOpenGL
		self.SetStyle(ControlStyles.Opaque | ControlStyles.StandardClick | ControlStyles.StandardDoubleClick, true)
		self.TabStop = true
		FImageManager = SdlImages(true, null)
		FLogicalWidth = 1
		FLogicalHeight = 1
		SDL.SDL_InitSubSystem(SDL.SDL_INIT_VIDEO) unless SDL.SDL_WasInit(SDL.SDL_INIT_VIDEO) == SDL.SDL_INIT_VIDEO

	private def Destroy():
		if FRenderer.Pointer != IntPtr.Zero:
			DestroyWindow()
		FImageManager.Dispose()
		FTimer.Dispose()

	public override def SetBoundsCore(aLeft as int, aTop as int, aWidth as int, aHeight as int, specified as BoundsSpecified):
		if (aWidth != self.Width) or (aHeight != self.Height):
			if FRendererAvailable:
				x as ushort
				y as ushort
				GPU_GetVirtualResolution(FRenderer, x, y)
				var ratioX = (x cast double) / (self.Width cast double)
				var ratioY = (y cast double) / (self.Height cast double)
				self.LogicalWidth = Round(aWidth * ratioX)
				self.LogicalHeight = Round(aHeight * ratioY)
				SDL.SDL_SetWindowSize(FWindow, self.Width, self.Height)
			else:
				FLogicalWidth = aWidth
				FLogicalHeight = aHeight
		super.SetBoundsCore(aLeft, aTop, aWidth, aHeight, specified)

	public def ResetLogicalSize():
		FLogicalWidth = self.Width
		FLogicalHeight = self.Height
		GPU_SetVirtualResolution(FRenderer.Pointer, FLogicalWidth, FLogicalHeight)
		self.Flip()

	public def Clear():
		CreateRenderer()
		for i in range(4):
			GPU_ClearRGBA(FRenderer, 0, 0, 0, 255)
			GPU_Flip(FRenderer)

	public def FillColor(color as SDL.SDL_Color, alpha as byte):
		CreateRenderer()
		GPU_ClearRGBA(FRenderer, color.r, color.g, color.b, alpha)

	public def DrawRect(region as Rectangle, color as SDL.SDL_Color, alpha as byte):
		CreateRenderer()
		lColor = color
		lColor.a = alpha
		GPU_Rectangle(FRenderer, region.Left, region.Top, region.Right, region.Bottom, lColor)

	public def DrawBox(region as GPU_Rect, color as SDL.SDL_Color, alpha as byte):
		CreateRenderer()
		lColor = color
		lColor.a = alpha
		GPU_Rectangle(FRenderer, region.x, region.y, region.x + region.w, region.y + region.h, lColor)

	public def DrawLine(start as Point, finish as Point, color as SDL.SDL_Color, alpha as byte):
		CreateRenderer()
		lColor = color
		lColor.a = alpha
		GPU_Line(FRenderer, start.X, start.Y, finish.X, finish.Y, lColor)

	public def AddTexture(surface as IntPtr) as int:
		return -1 if surface == IntPtr.Zero
		return FImageManager.Add(TSdlImage(surface, FImageManager.Count.ToString(), null))

	public def AddTexture(surface as IntPtr, name as string):
		index as int
		if self.ContainsName(name):
			raise ArgumentException("Texture \"$(name)\" already exists")
		index = FImageManager.Add(TSdlImage(surface, name, null))
		if index == -1:
			raise ArgumentException("Invalid surface")

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def AddImage(image as TSdlImage) as int:
		result = FImageManager.Add(image)
		return result

/*
	public def DrawTexture(texture as IntPtr, src as GPU_Rect, dst as GPU_Rect):
		unless FRendererAvailable:
			raise "No renderer available."
		unless SDL_RenderCopy(FRenderer, texture, src, dst) == 0:
			raise SDL_GetError()

	public def DrawTexture(name as string, src as GPU_Rect, dst as GPU_Rect):
		DrawTexture(FImageManager.Image[name].Surface, src, dst)

	public def DrawTexture(index as int, src as GPU_Rect, dst as GPU_Rect):
		DrawTexture(FImageManager[index].Surface, src, dst)

	public def DrawTextureFlipped(texture as IntPtr, axes as SDL.SDL_RendererFlip, src as GPU_Rect, dst as GPU_Rect):
		unless FRendererAvailable:
			raise "No renderer available."
		unless SDL_RenderCopyEx(FRenderer, texture, src, dst, 0, IntPtr.Zero, axes) == 0:
			raise SDL_GetError()
*/

	public def Flip():
		GPU_Flip(FRenderer)

	public def ContainsName(name as string) as bool:
		return FImageManager.Contains(name)

	public def IndexOfName(name as string) as int:
		return FImageManager.IndexOf(name)

	public def LogicalCoordinates(x as int, y as int) as SgPoint:
		result as SgPoint
		result.x = Truncate(((x * self.LogicalWidth cast double) / self.Width))
		result.y = Truncate(((y * self.LogicalHeight cast double) / self.Height))
		return result

	public def ClearTextures():
		FImageManager.Clear()

	public TextureByName[name as string] as GPU_Image_PTR:
		get:
			image as TSdlImage
			image = FImageManager.Image[name]
			return (image.Surface if assigned(image) else GPU_Image_PTR.Null)

	public AspectRatio as double:
		get: return GetAspectRatio()

	public LogicalSize as Point:
		get: return GetLogicalSize()
		set: SetLogicalSize(value)

	public Framerate as int:
		get: return FFramerate
		set: SetFramerate(value)

	public Active as bool:
		get: return FActive
		set: SetActive(value)

	[ComponentModel.Browsable(false)]
	public LogicalWidth as int:
		get: return FLogicalWidth
		set: SetLogicalWidth(value)
	
	[ComponentModel.Browsable(false)]
	public LogicalHeight as int:
		get: return FLogicalHeight
		set: SetLogicalHeight(value)

	private callable GlGetStringType(name as int) as IntPtr
	private callable GlGetErrorType() as int
	private glGetError as GlGetErrorType

	def glCheckError():
		err = glGetError()
		System.Diagnostics.Debugger.Break() unless err == 0

finalization :
	GPU_Quit()
