namespace sdl.frame

import Controls
import ExtCtrls
import Messages
import forms
import windows
import System
import SDL2.SDL
import System.Collections.Generic
import SDL.ImageManager
import SG.defs
import OpenGL4NET
import System.Math
import SDL.rwStream
import sdl.canvas
import SDL2.SDL_image
import System.Drawing

enum TRendererType:

	rtSoftware

	rtGDI

	rtOpenGL

	rtD3D

class TSdlFrameClass:
	pass

class TSdlFrame(TCustomControl):

	[Getter(SdlWindow)]
	private FWindow as IntPtr

	[Getter(Renderer)]
	private FRenderer as IntPtr

	[Getter(Flags)]
	private FFlags as SDL_WindowFlags

	private FTimer as TTimer

	private FFramerate as ushort

	private FActive as bool

	[Getter(Available)]
	private FRendererAvailable as bool

	[Property(RendererType)]
	private FRendererType as TRendererType

	[Getter(Images)]
	private FImageManager as TSdlImages

	[Property(OnTimer)]
	private FOnTimer as TNotifyEvent

	[Property(OnAvailable)]
	private FOnAvailable as TNotifyEvent

	private FLogicalWidth as int

	private FLogicalHeight as int

	[Property(OnPaint)]
	private FOnPaint as TNotifyEvent

	private def CreateWindow() as bool:
		flags as SDL_WindowFlags
		if FWindow.ptr == null:
			FWindow = SDL_CreateWindowFrom(self.Handle)
		flags = SDL_GetWindowFlags(FWindow)
		assert sdlwResizable in flags
		result = assigned(FWindow.ptr)
		if not result:
			OutputDebugStringA(SDL_GetError)
		return result

	private def DestroyWindow():
		FTimer.OnTimer = null
		FRenderer.Free()
		FWindow.Free()
		FFlags = []
		self.Framerate = 0

	private def CreateRenderer():
		let (pf as tagPIXELFORMATDESCRIPTOR) = tagPIXELFORMATDESCRIPTOR(nSize: sizeof(pf), nVersion: 1, dwFlags: ((PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL) or PFD_DOUBLEBUFFER), iPixelType: PFD_TYPE_RGBA, cColorBits: 24, cAlphaBits: 8, iLayerType: PFD_MAIN_PLANE)
		let (RENDERERS as (AnsiString)) = ('software', 'gdi', 'opengl', 'd3d')
		pFormat as int
		glContext as uint
		if FRendererAvailable:
			return
		glContext = 0
		try:
			if FRendererType == rtOpenGL:
				pFormat = ChoosePixelFormat(canvas.Handle, __addressof__(pf))
				if not SetPixelFormat(canvas.Handle, pFormat, __addressof__(pf)):
					outputDebugString(PChar(SysErrorMessage(GetLastError)))
				glContext = wglCreateContext(canvas.Handle)
				if glContext == 0:
					outputDebugString(PChar(SysErrorMessage(GetLastError)))
			FRenderer = SDL_CreateRenderer(FWindow, SDL_RendererIndex(RENDERERS[FRendererType]), [sdlrAccelerated])
			if FRenderer.ptr != null:
				SDL_ShowWindow(FWindow)
				ResetLogicalSize
				assert SDL_SetRenderDrawColor(FRenderer, 0, 0, 0, 255) == 0
				SDL_RenderFillRect(FRenderer, null)
				FFlags = SDL_GetWindowFlags(FWindow)
				FRendererAvailable = true
				if assigned(FOnAvailable):
					FOnAvailable(self)
				FImageManager.SetRenderer(FRenderer)
			else:
				outputDebugString(pChar(format('SDL_CreateRenderer failed: %s', [sdl_GetError])))
		ensure:
			if glContext != 0:
				wglDeleteContext(glContext)

	private def InternalOnTimer(Sender as object):
		if csDestroying in self.ComponentState:
			FTimer.Enabled = false
		elif assigned(FOnTimer):
			FOnTimer(self)

	private def SetFramerate(Value as ushort):
		Value = min(Value, 100)
		FFramerate = Value
		if Value == 0:
			SetActive(false)
		else:
			FTimer.Interval = round((1000.0 / (value cast double)))

	private def SetActive(Value as bool):
		FActive = Value
		FTimer.Enabled = Value

	private def GetTextureByName(name as string) as IntPtr:
		image as TSdlImage
		image = FImageManager.Image[name]
		if assigned(image):
			result = image.surface
		else:
			pointer(result) = null
		return result

	private def SetLogicalWidth(Value as int):
		if FLogicalWidth == Value:
			return
		FLogicalWidth = Value
		SDL_RenderSetLogicalSize(FRenderer, FLogicalWidth, FLogicalHeight)
		if FRendererAvailable:
			self.Flip

	private def SetLogicalHeight(Value as int):
		if FLogicalHeight == Value:
			return
		FLogicalHeight = Value
		SDL_RenderSetLogicalSize(FRenderer, FLogicalWidth, FLogicalHeight)
		if FRendererAvailable:
			self.Flip

	private def GetAspectRatio() as double:
		result = ((self.Width cast double) / (self.Height cast double))
		return result

	private def GetLogicalSize() as Point:
		result = point(FLogicalWidth, FLogicalHeight)
		return result

	private def SetLogicalSize(Value as Point):
		if (value.x == FLogicalWidth) and (value.y == FLogicalHeight):
			return
		FLogicalWidth = value.X
		FLogicalHeight = value.Y
		SDL_RenderSetLogicalSize(FRenderer, FLogicalWidth, FLogicalHeight)
		if FRendererAvailable:
			self.Flip

	[Pythia.Attributes.MessageMethod(WM_USER)]
	private def ClearViewport(ref msg):
		SDL_RenderSetViewport(FRenderer, null)

	protected override def CreateWnd():
		super
		self.CreateWindow

	protected override def DestroyWnd():
		DestroyWindow
		super

	protected override def Paint():
		CreateRenderer
		if assigned(FOnPaint):
			FOnPaint(self)
		else:
			self.Flip

	protected override def MouseDown(Button as TMouseButton, Shift as TShiftState, X as int, Y as int):
		if self.CanFocus:
			Windows.SetFocus(Handle)
		super

	[Pythia.Attributes.MessageMethod(WM_GETDLGCODE)]
	protected def WMGetDlgCode(ref msg as TMessage):
		msg.Result = ((((msg.Result or DLGC_WANTCHARS) or DLGC_WANTARROWS) or DLGC_WANTTAB) or DLGC_WANTALLKEYS)

	protected override def Resize():
		super.Resize
		if FRenderer.ptr != null:
			PostMessage(self.Handle, WM_USER, 0, 0)

	[Pythia.Attributes.VirtualConstructorOverride]
	public def constructor(AOwner as TComponent):
		super
		FTimer = TTimer.Create(self)
		FTimer.Interval = 100
		FTimer.OnTimer = Self.InternalOnTimer
		FRendererType = rtOpenGL
		self.ControlStyle = [csCaptureMouse, csClickEvents, csOpaque, csDoubleClicks]
		self.ControlStyle = (self.ControlStyle + [csGestures])
		self.TabStop = true
		FImageManager = TSdlImages.Create(FRenderer)
		FLogicalWidth = 1
		FLogicalHeight = 1
		if SDL_WasInit(SDL_INIT_VIDEO) != SDL_INIT_VIDEO:
			SDL_InitSubSystem(SDL_INIT_VIDEO)

	def destructor():
		if assigned(FRenderer.ptr):
			DestroyWindow
		FImageManager.Free()
		FTimer.Free()
		super

	public override def BeforeDestruction():
		FTimer.Enabled = false
		FTimer.OnTimer = null
		super

	public override def SetBounds(ALeft as int, ATop as int, AWidth as int, AHeight as int):
		size as Point
		ratioX as double
		ratioY as double
		if (AWidth != self.Width) or (AHeight != self.Height):
			if not FRendererAvailable:
				FLogicalWidth = aWidth
				FLogicalHeight = aHeight
			else:
				SDL_RenderGetLogicalSize(FRenderer, size.X, size.Y)
				ratioX = ((size.X cast double) / (self.Width cast double))
				ratioY = ((size.Y cast double) / (self.Height cast double))
				self.LogicalWidth = round((AWidth * ratioX))
				self.LogicalHeight = round((AHeight * ratioY))
				SDL_SetWindowSize(FWindow, self.Width, self.Height)
		super.SetBounds(ALeft, ATop, AWidth, AHeight)

	public def ResetLogicalSize():
		FLogicalWidth = self.Width
		FLogicalHeight = self.Height
		SDL_RenderSetLogicalSize(FRenderer, FLogicalWidth, FLogicalHeight)
		self.Flip

	public def Clear():
		i as int
		CreateRenderer
		for I in Range(1, 4):
			assert SDL_SetRenderDrawColor(FRenderer, 0, 0, 0, 255) == 0
			assert SDL_RenderFillRect(FRenderer, null) == 0
			SDL_RenderPresent(FRenderer)

	public def FillColor(color as SDL_Color, alpha as byte):
		CreateRenderer
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		assert SDL_RenderFillRect(FRenderer, null) == 0

	public def DrawRect(region as Rectangle, color as SDL_Color, alpha as byte):
		CreateRenderer
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		assert SDL_RenderDrawLine(FRenderer, region.Left, region.Top, region.Right, region.Top) == 0
		assert SDL_RenderDrawLine(FRenderer, region.right, region.Top, region.Right, region.bottom) == 0
		assert SDL_RenderDrawLine(FRenderer, region.right, region.bottom, region.left, region.bottom) == 0
		assert SDL_RenderDrawLine(FRenderer, region.Left, region.bottom, region.left, region.Top) == 0

	public def DrawBox(region as Rectangle, color as SDL_Color, alpha as byte):
		CreateRenderer
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		assert SDL_RenderDrawRect(FRenderer, __addressof__(region)) == 0

	public def DrawLine(start as Point, finish as Point, color as SDL_Color, alpha as byte):
		CreateRenderer
		assert SDL_SetRenderDrawColor(FRenderer, color.r, color.g, color.b, alpha) == 0
		assert SDL_RenderDrawLine(FRenderer, start.X, start.Y, finish.X, finish.Y) == 0

	public def AddTexture(surface as IntPtr) as int:
		if not assigned(surface):
			return -1
		result = FImageManager.Add(TSdlImage.Create(FRenderer, surface, IntToStr(FImageManager.Count), null))
		return result

	public def AddTexture(surface as IntPtr, name as string):
		index as int
		if self.ContainsName(name):
			raise EListError.CreateFmt('Texture "%s" already exists', [name])
		index = FIMageManager.Add(TSdlImage.Create(FRenderer, surface, name, null))
		if index == -1:
			raise EInvalidArgument.Create('Invalid surface')

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def AddImage(image as TSdlImage) as int:
		result = FImageManager.Add(image)
		return result

	public def DrawTexture(texture as IntPtr, src as PSdlRect, dst as PSdlRect):
		if not FRendererAvailable:
			raise EBadHandle.Create('No renderer available.')
		if not (SDL_RenderCopy(FRenderer, texture, src, dst) == 0):
			raise EBadHandle.Create(string(SDL_GetError))

	public def DrawTexture(name as string, src as PSdlRect, dst as PSdlRect):
		drawTexture(FImageManager.Image[name].surface, src, dst)

	public def DrawTexture(index as int, src as PSdlRect, dst as PSdlRect):
		drawTexture(FImageManager[index].surface, src, dst)

	public def DrawTextureFlipped(texture as IntPtr, axes as SDL_RendererFlip, src as PSdlRect, dst as PSdlRect):
		if not FRendererAvailable:
			raise EBadHandle.Create('No renderer available.')
		if not (SDL_RenderCopyFlipped(FRenderer, texture, src, dst, axes) == 0):
			raise EBadHandle.Create(string(SDL_GetError))

	public def Flip():
		SDL_RenderPresent(FRenderer)

	public def ContainsName(name as string) as bool:
		result = FImageManager.Contains(name)
		return result

	public def IndexOfName(name as string) as int:
		result = FImageManager.IndexOf(name)
		return result

	public def LogicalCoordinates(x as int, y as int) as Point:
		result.X = trunc((((x * self.LogicalWidth) cast double) / (self.Width cast double)))
		result.Y = trunc((((y * self.LogicalHeight) cast double) / (self.Height cast double)))
		return result

	public def ClearTextures():
		FImageManager.Clear

	public TextureByName[name as string] as IntPtr:
		get:
			return GetTextureByName(name)

	public AspectRatio as double:
		get:
			return GetAspectRatio()

	public LogicalSize as Point:
		get:
			return GetLogicalSize()
		set:
			SetLogicalSize(value)

	public Framerate as ushort:
		get:
			return FFramerate
		set:
			SetFramerate(value)

	public Active as bool:
		get:
			return FActive
		set:
			SetActive(value)

	public LogicalWidth as int:
		get:
			return FLogicalWidth
		set:
			SetLogicalWidth(value)

	public LogicalHeight as int:
		get:
			return FLogicalHeight
		set:
			SetLogicalHeight(value)

def Register():
	RegisterComponents('SDL', [TSdlFrame])

finalization :
	SDL_QuitSubSystem(SDL_INIT_VIDEO)
