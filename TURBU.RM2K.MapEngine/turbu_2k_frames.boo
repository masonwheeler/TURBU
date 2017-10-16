namespace TURBU.RM2K.Menus

import System
import System.Collections.Generic
import System.Threading
import System.Threading.Tasks

import Boo.Adt
import turbu.defs
import timing
import SG.defs
import sdl.sprite
import SDL.ImageManager
import sdl.canvas
import commons
import TURBU.Meta
import TURBU.TextUtils
import TURBU.RM2K
import turbu.classes
import turbu.script.engine
import TURBU.RM2K.RPGScript
import Pythia.Runtime
import SDL2.SDL2_GPU
import turbu.RM2K.environment
import TURBU.RM2K.Menus
import turbu.RM2K.sprite.engine
import Newtonsoft.Json
import Newtonsoft.Json.Linq

enum TSystemRects:
	Wallpaper
	FrameTL
	FrameTR
	FrameBL
	FrameBR
	FrameT
	FrameB
	FrameL
	FrameR
	ArrowU
	ArrowD
	MerchU
	MerchDot
	MerchD
	MerchEq
	CursorTL
	CursorTR
	CursorBL
	CursorBR
	CursorT
	CursorB
	CursorL
	CursorR
	CursorBG
	Timer
	Shadows
	Colors
	Background
	
enum TMenuState:
	None
	Shared
	ExclusiveShared
	Full

class TSystemTile(TTiledAreaSprite):

	[Property(location)]
	private FLocation as TSgPoint

	public def constructor(parent as TParentSprite, region as GPU_Rect, displacement as TSgPoint, length as int):
		super(parent, region, displacement, length)
		FRenderSpecial = true

	public def constructor(value as TTiledAreaSprite):
		super(value.Parent, value.DrawRect, value.Displacement, value.SeriesLength)
		super.Assign(value)

[Disposable]
class TSystemImages(TObject):

	[Getter(Rects)]
	private FRects = array(GPU_Rect, Enum.GetValues(TSystemRects).Length)

	[Getter(Filename)]
	private FFilename as string

	private FBetterArrow as TSystemTile

	private FDotArrow as TSystemTile

	private FWorseArrow as TSystemTile

	private FEqualValue as TSystemTile

	[Getter(Stretch)]
	private FStretch as bool

	[Getter(Translucent)]
	private FTranslucent as bool

	internal def Setup(parent as TMenuSpriteEngine):
		FBetterArrow = TSystemTile(parent, FRects[TSystemRects.MerchU], ARROW_DISPLACEMENT, 4)
		FBetterArrow.DrawRect = FRects[TSystemRects.MerchU]
		FDotArrow = TSystemTile(parent, FRects[TSystemRects.MerchDot], ARROW_DISPLACEMENT, 4)
		FDotArrow.DrawRect = FRects[TSystemRects.MerchDot]
		FWorseArrow = TSystemTile(parent, FRects[TSystemRects.MerchD], ARROW_DISPLACEMENT, 4)
		FWorseArrow.DrawRect = FRects[TSystemRects.MerchD]
		FEqualValue = TSystemTile(parent, FRects[TSystemRects.MerchEq], ARROW_DISPLACEMENT, 4)
		FEqualValue.DrawRect = FRects[TSystemRects.MerchEq]
		UpdateImage(FFilename)
		if not assigned(GFontEngine):
			System.Diagnostics.Debugger.Break()
		GFontEngine.OnGetColor = self.GetHandle
		GFontEngine.OnGetDrawRect = self.GetDrawRect
		parent.AddSkinNotification(self, self.UpdateImage)

	private def UpdateImage(filename as string):
		FBetterArrow.ImageName = filename
		FDotArrow.ImageName = filename
		FWorseArrow.ImageName = filename
		FEqualValue.ImageName = filename

	private def GetDrawRect(value as int) as GPU_Rect:
		assert value >= 0 and value < 20
		result = FRects[TSystemRects.Colors]
		result.y += result.h if value >= 10
		result.x += result.w * (value % 10)
		return result

	private def GetHandle() as GPU_Image_PTR:
		return FBetterArrow.Image.Surface

	public def constructor(images as TSdlImages, filename as string, stretch as bool, translucent as bool):
		super()
		FFilename = filename
		FStretch = stretch
		FTranslucent = translucent
		cls as TSdlImageClass = images.SpriteClass
		images.SpriteClass = classOf(TSdlImage)
		try:
			images.EnsureImage("SysTiles\\$filename.png", filename)
		ensure:
			images.SpriteClass = cls
		FRects[TSystemRects.Wallpaper]  = GPU_MakeRect(0,   0,  32, 32)
		FRects[TSystemRects.FrameTL]    = GPU_MakeRect(32,  0,  8,  8)
		FRects[TSystemRects.FrameTR]    = GPU_MakeRect(56,  0,  8,  8)
		FRects[TSystemRects.FrameBL]    = GPU_MakeRect(32,  24, 8,  8)
		FRects[TSystemRects.FrameBR]    = GPU_MakeRect(56,  24, 8,  8)
		FRects[TSystemRects.FrameT]     = GPU_MakeRect(40,  0,  16, 8)
		FRects[TSystemRects.FrameB]     = GPU_MakeRect(40,  24, 16, 8)
		FRects[TSystemRects.FrameL]     = GPU_MakeRect(32,  8,  8,  16)
		FRects[TSystemRects.FrameR]     = GPU_MakeRect(56,  8,  8,  16)
		FRects[TSystemRects.ArrowU]     = GPU_MakeRect(40,  8,  16, 8)
		FRects[TSystemRects.ArrowD]     = GPU_MakeRect(40,  16, 16, 8)
		FRects[TSystemRects.MerchU]     = GPU_MakeRect(128, 0,  8,  8)
		FRects[TSystemRects.MerchDot]   = GPU_MakeRect(128, 8,  8,  8)
		FRects[TSystemRects.MerchD]     = GPU_MakeRect(128, 16, 8,  8)
		FRects[TSystemRects.MerchEq]    = GPU_MakeRect(128, 24, 8,  8)
		FRects[TSystemRects.CursorTL]   = GPU_MakeRect(64,  0,  8,  8)
		FRects[TSystemRects.CursorBL]   = GPU_MakeRect(64,  24, 8,  8)
		FRects[TSystemRects.CursorTR]   = GPU_MakeRect(88,  0,  8,  8)
		FRects[TSystemRects.CursorBR]   = GPU_MakeRect(88,  24, 8,  8)
		FRects[TSystemRects.CursorT]    = GPU_MakeRect(72,  0,  16, 8)
		FRects[TSystemRects.CursorB]    = GPU_MakeRect(72,  24, 16, 8)
		FRects[TSystemRects.CursorL]    = GPU_MakeRect(64,  8,  8,  16)
		FRects[TSystemRects.CursorR]    = GPU_MakeRect(88,  8,  8,  16)
		FRects[TSystemRects.CursorBG]   = GPU_MakeRect(72,  8,  16, 16)
		FRects[TSystemRects.Timer]      = GPU_MakeRect(32,  32, 8,  16)
		FRects[TSystemRects.Shadows]    = GPU_MakeRect(128, 32, 32, 16)
		FRects[TSystemRects.Colors]     = GPU_MakeRect(0,   48, 16, 16)
		FRects[TSystemRects.Background] = GPU_MakeRect(0,   32, 16, 16)
	
	private def DrawPart(image as GPU_Image_PTR, target as GPU_Target_PTR, part as TSystemRects, \
			x as int, y as int, w as int, h as int, tiled as bool):
		srcRect = FRects[part]
		if FStretch:
			GPU_BlitScale(image, srcRect, target, x + w / 2, y + h / 2, w / srcRect.w, h / srcRect.h)
		else: DrawTiled(image, target, srcRect, x, y, w, h)
	
	private def DrawPart(image as GPU_Image_PTR, target as GPU_Target_PTR, part as TSystemRects, \
			x as int, y as int, w as int, h as int, tiled as bool, xOffset as int):
		srcRect = FRects[part]
		srcRect.x += xOffset
		if FStretch:
			GPU_BlitScale(image, srcRect, target, x + w / 2, y + h / 2, w / srcRect.w, h / srcRect.h)
		else: DrawTiled(image, target, srcRect, x, y, w, h)
	
	private def DrawTiled(image as GPU_Image_PTR, target as GPU_Target_PTR, srcRect as GPU_Rect, \
			x as int, y as int, w as int, h as int):
		while y < h:
			while x < w:
				GPU_Blit(image, srcRect, target, x, y)
				x += srcRect.w
			y += srcRect.h
			x = 0
	
	private def InternalDrawFrame(image as GPU_Image_PTR, target as GPU_Target_PTR, w as int, h as int) as void:
		tiled = not FStretch
		borderWidth = FRects[TSystemRects.FrameL].w
		borderHeight = FRects[TSystemRects.FrameT].h 
		innerWidth = w - (borderWidth * 2)
		innerHeight = h - (borderHeight * 2)
		DrawPart(image, target, TSystemRects.Wallpaper, 0, 0, w, h, tiled)
		DrawPart(image, target, TSystemRects.FrameT, borderWidth, 0, innerWidth, borderHeight, tiled)
		DrawPart(image, target, TSystemRects.FrameB, borderWidth, h - borderHeight, innerWidth, borderHeight, tiled)
		DrawPart(image, target, TSystemRects.FrameL, 0, borderHeight, borderWidth, innerHeight, tiled)
		DrawPart(image, target, TSystemRects.FrameR, w - borderWidth, borderHeight, borderWidth, innerHeight, tiled)
		DrawPart(image, target, TSystemRects.FrameTL, 0, 0, borderWidth, borderHeight, false)
		DrawPart(image, target, TSystemRects.FrameTR, w - borderWidth, 0, borderWidth, borderHeight, false)
		DrawPart(image, target, TSystemRects.FrameBL, 0, h - borderHeight, borderWidth, borderHeight, false)
		DrawPart(image, target, TSystemRects.FrameBR, w - borderWidth, h - borderHeight, borderWidth, borderHeight, false)
	
	def DrawFrame(target as GPU_Target_PTR, w as int, h as int) as void:
		image = self.GetHandle()
		GPU_SetRGBA(image, 255, 255, 255, 155) if FTranslucent
		InternalDrawFrame(image, target, w, h)
		GPU_SetRGBA(image, 255, 255, 255, 255) if FTranslucent
	
	private def InternalDrawCursor(image as GPU_Image_PTR, target as GPU_Target_PTR, w as int, h as int, xOffset as int, yOffset as int) as void:
		tiled = not FStretch
		borderWidth = FRects[TSystemRects.CursorL].w
		borderHeight = FRects[TSystemRects.CursorT].h 
		innerWidth = w - (borderWidth * 2)
		innerHeight = h - (borderHeight * 2)
		GPU_SetRGBA(image, 255, 255, 255, 80) if FTranslucent
		DrawPart(image, target, TSystemRects.CursorBG, 0,               yOffset,                    w,           h,            tiled, xOffset)
		GPU_SetRGBA(image, 255, 255, 255, 255) if FTranslucent
		DrawPart(image, target, TSystemRects.CursorT,  borderWidth,     yOffset,                    innerWidth,  borderHeight, tiled, xOffset)
		DrawPart(image, target, TSystemRects.CursorB,  borderWidth,     yOffset + h - borderHeight, innerWidth,  borderHeight, tiled, xOffset)
		DrawPart(image, target, TSystemRects.CursorL,  0,               yOffset + borderHeight,     borderWidth, innerHeight,  tiled, xOffset)
		DrawPart(image, target, TSystemRects.CursorR,  w - borderWidth, yOffset + borderHeight,     borderWidth, innerHeight,  tiled, xOffset)
		DrawPart(image, target, TSystemRects.CursorTL, 0,               yOffset,                    borderWidth, borderHeight, false, xOffset)
		DrawPart(image, target, TSystemRects.CursorTR, w - borderWidth, yOffset,                    borderWidth, borderHeight, false, xOffset)
		DrawPart(image, target, TSystemRects.CursorBL, 0,               yOffset + h - borderHeight, borderWidth, borderHeight, false, xOffset)
		DrawPart(image, target, TSystemRects.CursorBR, w - borderWidth, yOffset + h - borderHeight, borderWidth, borderHeight, false, xOffset)
	
	private final static CURSOR_FRAME_WIDTH = 32
	
	def DrawCursor(target as GPU_Target_PTR, w as int, h as int) as void:
		image = self.GetHandle()
		InternalDrawCursor(image, target, w, h, 0,                  0)
		InternalDrawCursor(image, target, w, h, CURSOR_FRAME_WIDTH, h)

enum TMessageBoxTypes:
	Message
	Choice
	Prompt
	Input

interface IMenuEngine(IDisposable):

	def OpenMenu(name as string, cursorValue as int)

	def OpenMenuEx(name as string, data as TObject)

	def CloseMenu()

	def Button(input as TButtonCode)

	def Draw()

[Disposable(Destroy, true)]
class TMenuSpriteEngine(TSpriteEngine):

	[Getter(SystemGraphic)]
	private FSystemGraphic as TSystemImages

	private FWallpapers as Dictionary[of string, TSystemImages]

	private FBoxNotifications as Dictionary[of TObject, Action of string]

	[Property(MenuInt)]
	private FMenuInt as int

	[Getter(Cursor)]
	private FCursor as TMenuCursor

	[Getter(State)]
	private FMenuState as TMenuState

	private FBoxes = array(TCustomMessageBox, Enum.GetValues(TMessageBoxTypes).Length)

	private FCurrentBox as TCustomMessageBox

	private FMenuEngine as IMenuEngine

	private FPosition as TMboxLocation

	private FBoxVisible as bool

	private FEnding as bool

	[async]
	private def WaitForCurrentBox() as Task:
		waitFor { return FCurrentBox == null or FCurrentBox.Signal.WaitOne(0) }

	private def NotifySystemGraphicChanged(Name as string):
		notify as Action of string
		for notify in FBoxNotifications.Values:
			notify(Name)

	internal def EngineEndMessage():
		EndMessage()
	
	protected def EndMessage():
		FMenuState = TMenuState.None
		if assigned(FCurrentBox) and (not FEnding):
			FEnding = true
			try:
				FCurrentBox.EngineEndMessage()
			ensure:
				FEnding = false
			FCursor.Visible = false
		FCurrentBox = null

	protected def InnVocab(style as int, name as string, value as int) as string:
		var key = "Inn$style-$name"
		var result = GDatabase.value.Vocab[key]
		if result == '':
			key = "Inn1-$name"
			result = GDatabase.value.InterpolateVocab(key, name)
		return result.Replace('?$', value.ToString())

	public def constructor(graphic as TSystemImages, Canvas as TSdlCanvas, images as TSdlImages):
		assert GMenuEngine.Value == null
		GMenuEngine.Value = self
		super(null, Canvas)
		self.Images = images
		GFontEngine.Glyphs = images.EnsureImage('SysTiles\\glyphs\\glyphs.png', 'System Glyphs', sgPoint(12, 12))
		FWallpapers = Dictionary[of string, TSystemImages]()
		FBoxNotifications = Dictionary[of TObject, Action of string]()
		FSystemGraphic = graphic
		graphic.Setup(self)
		FWallpapers.Add(graphic.Filename, graphic)
		FCursor = TMenuCursor(self, FRAME_DISPLACEMENT, 2, NULLRECT)
		var size = GPU_MakeRect(0, 0, 320, 80)
		FPosition = TMboxLocation.Bottom
		var menuEngine = TMenuEngine(self, self.EndMessage)
		FBoxes[TMessageBoxTypes.Message] = TMessageBox(self, size, menuEngine, null)
		FBoxes[TMessageBoxTypes.Choice] = TChoiceBox(self, size)
		FBoxes[TMessageBoxTypes.Prompt] = TPromptBox(self, size)
		FBoxes[TMessageBoxTypes.Input] = TValueInputBox(self, size)
		TCustomMessageBox.OnPlaySound = PlaySystemSound
		FMenuEngine = menuEngine

	private new def Destroy():
		GMenuEngine.Value = null
		GFontEngine.OnGetColor = null
		GFontEngine.OnGetDrawRect = null
		EndMessage()
		for box in FBoxes:
			box.Dispose()
		FMenuEngine.Dispose()
		TSysFrame.ClearFrames()

	public def SerializePortrait(writer as JsonWriter):
		portrait as TSprite = self.Portrait
		return if (not portrait.Visible) or (portrait.ImageName == '')
		writer.CheckWrite('Name', portrait.ImageName, '')
		writer.CheckWrite('Index', portrait.ImageIndex, -1)
		writer.WritePropertyName('Flipped')
		writer.WriteValue(portrait.MirrorX)
		writer.WritePropertyName('Rightside')
		writer.WriteValue((FBoxes[TMessageBoxTypes.Message] cast TMessageBox).Rightside)

	public def DeserializePortrait(obj as JObject):
		portrait as TSprite = self.Portrait
		if obj.Count > 0:
			assert obj.Count == 4
			portrait.Visible = true
			SetPortrait(obj['Name']cast string, obj['Index'] cast int)
			portrait.MirrorX = obj['Flipped'] cast bool
			SetRightside(obj['Rightside'] cast bool)
			obj.Remove('Name')
			obj.Remove('Index')
			obj.Remove('Flipped')
			obj.Remove('Rightside')
			obj.CheckEmpty()
		else:
			portrait.Visible = false

	public override def Draw():
		caseOf FMenuState:
			case TMenuState.None:
				pass
			case TMenuState.Shared, TMenuState.ExclusiveShared:
				super.Draw()
			case TMenuState.Full:
				FMenuEngine.Draw()
			default: raise "Unknown menu state: $FMenuState"

	[async]
	public def ShowMessage(msg as string, modal as bool) as Task:
		waitFor {GSpriteEngine.value.State != TGameState.Fading}
		box as TCustomMessageBox = FBoxes[TMessageBoxTypes.Message]
		box.Text = msg
		box.Visible = true
		FCurrentBox = box
		try:
			FMenuState = (TMenuState.ExclusiveShared if modal else TMenuState.Shared)
			await WaitForCurrentBox()
		ensure:
			EndMessage()

	[async]
	public def Inn(style as int, cost as int) as Task:
		greet1 as string = InnVocab(style, 'Greet', cost)
		choices as (string) = (InnVocab(style, 'Stay', 0), InnVocab(style, 'Cancel', 0))
		cbTask as Task = ChoiceBox(greet1, choices, true) def (line as string) as bool:
			return ((GEnvironment.value.Money >= cost) if line == choices[0] else true)
		await cbTask

	[async]
	public def ChoiceBox(msg as string, responses as (string), allowCancel as bool, OnValidate as Func[of string, bool]) as Task:
		waitFor {GSpriteEngine.value.State != TGameState.Fading}
		var box = FBoxes[TMessageBoxTypes.Choice] cast TChoiceBox
		box.Text = msg
		box.SetChoices(responses)
		box.CanCancel = allowCancel
		box.PlaceCursor(0)
		box.OnValidate = OnValidate
		box.Visible = true
		FCurrentBox = box
		try:
			FMenuState = TMenuState.ExclusiveShared
			await WaitForCurrentBox()
		ensure:
			EndMessage()

	[async]
	public def InputNumber(msg as string, digits as int) as Task:
		FCurrentBox = FBoxes[TMessageBoxTypes.Input]
		FCurrentBox.Text = msg
		var box = FCurrentBox cast TValueInputBox
		box.SetupInput(digits)
		box.CanCancel = false
		box.SetupInput(digits)
		FBoxes[TMessageBoxTypes.Input].Visible = true
		try:
			FMenuState = TMenuState.ExclusiveShared
			await WaitForCurrentBox()
		ensure:
			EndMessage()

	public def Button(input as TButtonCode):
		if self.State == TMenuState.Full:
			FMenuEngine.Button(input)
		else:
			assert assigned(FCurrentBox)
			FCurrentBox.Button(input)

	public def SetPortrait(filename as string, index as int):
		(FBoxes[TMessageBoxTypes.Message] cast TMessageBox).SetPortrait(filename, index)

	public def SetRightside(value as bool):
		(FBoxes[TMessageBoxTypes.Message] cast TMessageBox).Rightside = value

	public def SetSkin(Name as string, stretch as bool):
		return if Name == FSystemGraphic.Filename
		
		newPaper as TSystemImages
		unless FWallpapers.TryGetValue(Name, newPaper):
			newPaper = TSystemImages(self.Images, Name, stretch, FSystemGraphic.Translucent)
			FWallpapers.Add(Name, newPaper)
		FSystemGraphic = newPaper
		NotifySystemGraphicChanged(Name)

	public def Reset():
		FMenuEngine.CloseMenu()

	public def OpenMenu(name as string):
		FMenuEngine.OpenMenu(name, FMenuInt)
		FMenuState = TMenuState.Full

	public def OpenMenuEx(name as string, data as TObject):
		FMenuEngine.OpenMenuEx(name, data)
		FMenuState = TMenuState.Full

	public def AddSkinNotification(obj as TObject, notify as Action of string):
		FBoxNotifications[obj] = notify

	public def RemoveSkinNotification(obj as TObject):
		FBoxNotifications.Remove(obj)

	public Position as TMboxLocation:
		get: return FPosition
		set:
			FPosition = value
			for box in FBoxes:
				box.Position = value

	public BoxVisible as bool:
		get: return FBoxVisible
		set:
			FBoxVisible = value
			for box in FBoxes:
				box.BoxVisible = value

	public Portrait as TSprite:
		get: return (FBoxes[TMessageBoxTypes.Message] cast TMessageBox).Portrait

[Disposable(Destroy)]
class TSysFrame(TSystemTile):

	protected struct FrameDesc:
		public Width as int
		public Height as int
		
		def constructor(w as int, h as int):
			Width = w
			Height = h

	private FFrameSize as TSgPoint

	private static final Frames = Dictionary[of FrameDesc, GPU_Image_PTR]()
	
	private static final Cursors = Dictionary[of FrameDesc, TSdlImage]()

	protected static def GetFrame(w as int, h as int) as GPU_Image_PTR:
		result as GPU_Image_PTR
		key = FrameDesc(w, h)
		unless Frames.TryGetValue(key, result):
			result = GPU_CreateImage(w, h, GPU_FormatEnum.GPU_FORMAT_RGBA)
			target = GPU_LoadTarget(result)
			FGraphic.DrawFrame(target, w, h)
			GPU_FreeTarget(target)
			Frames.Add(key, result)
		return result

	protected static def GetCursor(w as int, h as int, engine as TSpriteEngine) as TSdlImage:
		return null if w <= 0 or h <= 0
		result as TSdlImage
		var key = FrameDesc(w, h)
		unless Cursors.TryGetValue(key, result):
			var img = GPU_CreateImage(w, h * 2, GPU_FormatEnum.GPU_FORMAT_RGBA)
			var target = GPU_LoadTarget(img)
			FGraphic.DrawCursor(target, w, h)
			GPU_FreeTarget(target)
			result = TSdlImage(img, "Cursor($w,$h)", engine.Images, TextureSize: TSgPoint(w, h))
			Cursors.Add(key, result)
		return result

	internal static def ClearFrames():
		for value in Frames.Values:
			GPU_FreeImage(value)
		Frames.Clear()
		for cursor in Cursors.Values:
			cursor.Dispose()
		Cursors.Clear()

	[Getter(Bounds)]
	protected FBounds as GPU_Rect

	private static FGraphic as TSystemImages

	protected virtual def SkinChanged(Name as string):
		if assigned(FList):
			for sprite in self.FList:
				sprite.ImageName = Name
		self.ImageName = Name
		ClearFrames()

	public def constructor(parent as TMenuSpriteEngine, displacement as TSgPoint, length as int, coords as GPU_Rect):
		super(parent, NULLRECT, commons.ORIGIN, 0)
		self.Z = 1
		if FGraphic is null:
			FGraphic = parent.SystemGraphic
		else: assert FGraphic == parent.SystemGraphic
		parent.AddSkinNotification(self, self.SkinChanged)
		Visible = false
		Layout(coords)

	private new def Destroy():
		(self.Engine cast TMenuSpriteEngine).RemoveSkinNotification(self)

	public def Layout(coords as GPU_Rect):
		MoveTo(coords)

	public virtual def MoveTo(coords as GPU_Rect):
		self.X = coords.x
		self.Y = coords.y
		self.Width = coords.w cast int
		self.Height = coords.h cast int
		FBounds = coords
		Reflow()

	protected virtual def Reflow():
		pass

class TMenuCursor(TSysFrame):
	public def constructor(parent as TMenuSpriteEngine, displacement as TSgPoint, length as int, coords as GPU_Rect):
		super(parent, displacement, length, coords)

	protected override def DoDraw():
		super.DoDraw()
	
	public override def MoveTo(coords as GPU_Rect):
		super(coords)
		self.Image = GetCursor(coords.w cast int, coords.h cast int, self.Engine)

enum TMessageState:
	Display
	Choice
	Input
	Prompt

[Disposable]
abstract class TCustomMessageBox(TSysFrame):

	[Property(OnPlaySound)]
	private static FPlaySound as Action of TSfxTypes

	private FMessageText as string

	[Property(BoxVisible)]
	private FBoxVisible as bool

	[Property(OnEndMessage)]
	private FOnEndMessage as EventHandler

	private def DrawFrame():
		image = GetFrame(self.Width, self.Height)
		GPU_Blit(image, IntPtr.Zero, currentRenderTarget().RenderTarget, self.X + self.Width / 2.0, self.Y + self.Height / 2.0)

	private enum TTextDrawState:
		None
		InProgress
		Done

	protected FTextDrawn as TTextDrawState

	[Getter(Signal)]
	protected FSignal = EventWaitHandle(false, EventResetMode.ManualReset)

	protected FParsedText = List[of string]()

	private _associatedObjects = Dictionary[of int, object]()

	protected FOptionEnabled = array(bool, 5)

	private FColumns as byte

	protected FDontChangeCursor as bool

	protected FButtonLock as TRpgTimestamp

	protected FLastLineColumns as byte

	protected FPosition as TMboxLocation

	protected FTextTarget as TSdlRenderTarget

	protected FTextPosX as single

	protected FTextPosY as single

	protected FTextCounter as int

	protected FTextColor as int

	protected FTextLine as int

	protected FCoords as GPU_Rect

	protected FPromptLines as int

	protected FCursorPosition as short

	protected def DrawingDone():
		FTextDrawn = TTextDrawState.Done

	protected def DrawingInProgress():
		FTextDrawn = TTextDrawState.InProgress

	protected def InvalidateText():
		FTextDrawn = TTextDrawState.None

	internal def EngineInvalidateText():
		InvalidateText()

	protected ColumnWidth as ushort:
		get: return ((self.FBounds.w - 8) / FColumns) - SEPARATOR

	protected LastColumnWidth as ushort:
		get: return ((self.FBounds.w - 8) / FLastLineColumns) - SEPARATOR

	protected Columns as byte:
		get: return FColumns
		set:
			FColumns = value
			Reflow()

	protected def PlaySound(which as TSfxTypes):
		if assigned(FPlaySound):
			FPlaySound(which)

	protected virtual def ParseText(input as string):
		lock self:
			ClearText()
			ResetText()
			DoParseText(input, FParsedText)
			InvalidateText()

	protected def ClearTarget(target as TSdlRenderTarget):
		target.Parent.PushRenderTarget()
		GPU_Clear(target.RenderTarget)
		target.Parent.PopRenderTarget()

	protected virtual def DoSetPosition(Value as TMboxLocation):
		pass

	internal def EngineEndMessage():
		EndMessage()
	
	protected def EndMessage():
		if assigned(FOnEndMessage):
			FOnEndMessage(self, EventArgs.Empty)
		else:
			(Engine cast TMenuSpriteEngine).EngineEndMessage()
		Visible = false
		FSignal.Set()

	protected override def SkinChanged(Name as string):
		super.SkinChanged(Name)

	protected override def DoDraw():
		if BoxVisible:
			DrawFrame()

	protected def DrawChar(value as char):
		newPos as TSgFloatPoint = GFontEngine.DrawChar(FTextTarget.RenderTarget, value, FTextPosX, FTextPosY, FTextColor)
		FTextPosX = newPos.x
		FTextPosY = newPos.y

	protected def DrawChar(value as string):
		if value.Length == 1:
			DrawChar(value[0])
		elif value == '\r\n':
			NewLine()
		else: DrawSpecialChar(value)

	protected def DrawLine(value as string):
		for ch as char in value:
			DrawChar(ch)

	protected def DrawGlyph(value as char):
		index as int
		if char.IsUpper(value):
			index = ord(value) - ord(char('A'))
		elif char.IsLower(value):
			index = (26 + ord(value)) - ord(char('a'))
		else:
			raise Exception('Invalid glyph Character.')
		newPos as TSgFloatPoint = GFontEngine.DrawGlyph(FTextTarget.RenderTarget, index, FTextPosX, FTextPosY, FTextColor)
		FTextPosX = newPos.x
		FTextPosY = newPos.y

	let TOP_MARGIN = 3
	let LINE_HEIGHT = 16
	let HALF_CHAR = 3
	
	protected virtual def NewLine():
		FTextPosX = 3
		++FTextLine
		FTextPosY = (LINE_HEIGHT * FTextLine) + TOP_MARGIN

	protected virtual def DrawSpecialChar(line as string):
		assert line[0] == char('\\') or line[0] == char('$')
		if line[0] == char('\\'):
			caseOf line[1]:
				case char('$'): DrawLine(GEnvironment.value.Money.ToString())
				case char('_'): FTextPosX = (FTextPosX + HALF_CHAR)
				case char('C'): FTextColor = clamp(GetIntegerValue(line), 0, 19)
				case char('V'): DrawLine(GEnvironment.value.Ints[GetIntegerValue(line)].ToString())
				case char('N'): DrawLine(GetHeroName(GetIntegerValue(line)))
		else: DrawGlyph(line[1])

	protected def GetIntegerValue(value as string) as int:
		tail as string = value[2:]
		if tail.StartsWith('\\V'):
			result = GEnvironment.value.Ints[GetIntegerValue(tail)]
		elif not int.TryParse(tail, result):
			Abort
		return result

	protected def GetHeroName(value as int) as string:
		if value == 0:
			result = ('' if GEnvironment.value.PartySize == 0 else GEnvironment.value.Party[1].Name)
		elif clamp(value, 1, GEnvironment.value.HeroCount) != value:
			Abort
		else: result = GEnvironment.value.Heroes[value].Name
		return result

	protected def GetDrawCoords() as GPU_Rect:
		result as GPU_Rect
		result.x = 0
		result.w = FTextTarget.Parent.Width
		result.h = FTextTarget.Parent.Height / 3
		result.y = result.h * ord(FPosition)
		return result

	protected virtual def ResetText():
		FSignal.Reset()
		ClearTarget(FTextTarget)
		FTextCounter = 0
		FTextLine = -1
		NewLine()
		FTextColor = 0

	protected def ParseToken(input as string, ref counter as int) as string:
		assert input[counter] == char('\\')
		++counter
		var token = char.ToUpper(input[counter])
		caseOf token:
			case char('\\'): result = '\\'
			case char('$'), char('!'), char('.'), char('|'), char('>'), char('<'), char('^'), char('_'):
				result = '\\' + token
			case char('C'), char('S'), char('N'), char('V'), char('T'), char('F'), char('O'):
				result = ParseParamToken(input, counter)
			default : result = '\\E' + input[counter]
		return result

	protected def ParseParamToken(input as string, ref counter as int) as string:
		var token = char.ToUpper(input[counter])
		result = '\\' + token
		caseOf token:
			case char('C'), char('S'), char('N'), char('V'), char('T'), char('F'):
				++counter
				if input[counter] == char('['):
					result = result + ParseInt(input, counter)
				else: result = '\\E' + input[counter]
			case char('O'): result = '\\E' + input[counter]
			default : assert false
		return result

	protected def ParseInt(input as string, ref counter as int) as string:
		++counter
		start as int = counter
		if input[start:start + 3].ToUpper() == '\\V[':
			++counter
			result = '\\V' + ParseInt(input, counter)
		else:
			++counter while (counter <= input.Length) and char.IsDigit(input[counter])
			if (counter > input.Length) or (input[counter] != char(']')):
				result = '\\e'
				counter = start
			else: result = input[start:counter]
		return result

	protected def ParseGlyph(input as string, ref counter as int) as string:
		assert input[counter] == char('$')
		++counter
		token as char = input[counter]
		if char.IsLetter(token):
			result = '$' + token
		elif token == char('$'):
			result = '$'
		else:
			result = '$'
			--counter
		return result

	protected def DoParseText(input as string, list as List[of string]):
		counter as int = 0
		while counter < input.Length:
			if input[counter] == char('\r'):
				list.Add('\r\n')
				if (counter < input.Length) and (input[counter + 1] == char('\n')):
					++counter
			elif input[counter] == char('\\'):
				list.Add(ParseToken(input, counter))
			elif input[counter] == '$':
				list.Add(ParseGlyph(input, counter))
			else: list.Add(input[counter].ToString())
			++counter

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect):
		let BORDER_THICKNESS = 16
		super(parent, commons.ORIGIN, 1, coords)
		FColumns = 1
		FBoxVisible = true
		FTextTarget = TSdlRenderTarget(sgPoint(self.Width - BORDER_THICKNESS, self.Height - BORDER_THICKNESS))
		ClearTarget(FTextTarget)
		FTextColor = 1

	let ARROW_KEYS = TButtonCode.Up | TButtonCode.Down | TButtonCode.Left | TButtonCode.Right

	public virtual def Button(input as TButtonCode):
		if (FCursorPosition == -1) and (input in (TButtonCode.Up, TButtonCode.Down, TButtonCode.Left, TButtonCode.Right)):
			return
		if FOptionEnabled.Length == 0:
			return
		if assigned(FButtonLock):
			if FButtonLock.TimeRemaining == 0:
				FButtonLock = null
			else:
				return
		var lPosition = FCursorPosition
		var max = pred(FOptionEnabled.Length) - FLastLineColumns
		var absMax = max + FLastLineColumns
		ratio as byte
		caseOf input:
			case TButtonCode.Enter:
				if FOptionEnabled[FCursorPosition]:
					(FEngine cast TMenuSpriteEngine).MenuInt = FCursorPosition
					PlaySound(TSfxTypes.Accept)
				else:
					PlaySound(TSfxTypes.Buzzer)
			case TButtonCode.Down:
				if FCursorPosition <= max - FColumns:
					lPosition = FCursorPosition + FColumns
				elif FColumns == 1:
					lPosition = 0
				elif (FLastLineColumns > 0) and (FCursorPosition <= max):
					lPosition = FCursorPosition % FColumns
					ratio = FColumns / FLastLineColumns
					lPosition = ((lPosition / ratio) + max) + 1
			case TButtonCode.Up:
				if FCursorPosition > max:
					ratio = FColumns / FLastLineColumns
					lPosition = FCursorPosition - (max + 1)
					lPosition = (((max + 1) - FColumns) + (lPosition * ratio)) + (ratio / 2)
				elif FCursorPosition >= FColumns:
					lPosition = FCursorPosition - FColumns
				elif FColumns == 1:
					lPosition = FOptionEnabled.Length - 1
			case TButtonCode.Right:
				if (FColumns > 1) and (FCursorPosition < absMax):
					lPosition = FCursorPosition + 1
			case TButtonCode.Left:
				if (FColumns > 1) and (FCursorPosition > 0):
					lPosition = FCursorPosition - 1
			default:
				pass
		if input in ARROW_KEYS and lPosition != FCursorPosition:
			FButtonLock = TRpgTimestamp(180)
			PlaceCursor(lPosition)
			PlaySound(TSfxTypes.Cursor)

	public override def Draw():
		if self.Visible:
			DoDraw()

	public override def MoveTo(coords as GPU_Rect):
		super.MoveTo(coords)
		self.Width = coords.w
		self.Height = coords.h

	public virtual def PlaceCursor(position as short):
		if self.FDontChangeCursor:
			position = self.FCursorPosition
		FCursorPosition = position
		var max = FOptionEnabled.Length - (FPromptLines + FLastLineColumns)
		columns as byte
		width as ushort
		if (position > max) and (FLastLineColumns > 0):
			columns = FLastLineColumns
			width = LastColumnWidth
		else:
			columns = FColumns
			width = ColumnWidth
		position = (0 if FOptionEnabled.Length == 0 else Math.Min(position, FOptionEnabled.Length - 1))
		position -= max + 1 if position > max
		var column = position % columns
		position += FPromptLines * columns
		coords = GPU_MakeRect(
			4 + (column * (width + SEPARATOR)) + FBounds.x,
			((position / columns) * 15) + FBounds.y + 8,
			(width + 8) - FBounds.x,
			18)
		if FCursorPosition > max:
			coords.y += (FCursorPosition / FColumns) * 15
		cursor as TMenuCursor = (FEngine cast TMenuSpriteEngine).Cursor
		cursor.Visible = true
		cursor.Layout(coords)
		FDontChangeCursor = false

	public Text as string:
		get: return FMessageText
		virtual set: ParseText(value)

	public Position as TMboxLocation:
		get: return FPosition
		set:
			FPosition = value
			var h = self.Height
			var y = h * ord(FPosition)
			var coords = GPU_MakeRect(0, y, self.Width, h + y)
			self.MoveTo(coords)
			self.Height = h
			DoSetPosition(value)

	protected def ClearText():
		FParsedText.Clear()
		_associatedObjects.Clear()

	protected def SetText(value as string):
		ClearText()
		FParsedText.AddRange(value.Split((Environment.NewLine,), StringSplitOptions.None))

	protected def AddObject(value as string, obj as object):
		FParsedText.Add(value)
		_associatedObjects.Add(FParsedText.Count - 1, obj)

	protected Objects[i as int] as object:
		get: return _associatedObjects[i]


[Disposable(Destroy, true)]
class TSystemTimer(TParentSprite):

	private FTime as ushort

	private FPrevTime as ushort

	private FTiles = array(TSprite, 5)

	private FPrevState as TGameState

	[Property(OnGetTime)]
	private FOnGetTime as Func of int

	private def AssignDrawRect(tile as TSprite, index as int):
		tile.DrawRect = GPU_MakeRect(32 + (8 * index), 32, 8, 16)

	private def UpdateTime():
		min as int = FTime / 60
		sec as int = FTime % 60
		AssignDrawRect(FTiles[1], (min / 10 if min > 10 else 11))
		AssignDrawRect(FTiles[2], min % 10)
		AssignDrawRect(FTiles[4], sec / 10)
		AssignDrawRect(FTiles[5], sec % 10)

	private def UpdatePosition(location as TSgPoint):
		if FPrevState != GSpriteEngine.value.State:
			FPrevState = GSpriteEngine.value.State
			caseOf FPrevState:
				case TGameState.Map, TGameState.Menu, TGameState.Battle:
					pass
				case TGameState.Message:
					location.y += 160 if GMenuEngine.Value.Position == TMboxLocation.Top
				default : raise EFatalError('Unable to set timer for current game State!')
		++location.x
		location.y += 10
		for i in range(1, 6):
			FTiles[i].X = location.x + (i * 9)
			FTiles[i].Y = location.y

	public def constructor(parent as TSpriteEngine):
		super(parent)
		for i in range(FTiles.Length):
			FTiles[i] = TSprite(self)
			FTiles[i].ImageName = GMenuEngine.Value.SystemGraphic.Filename
		AssignDrawRect(FTiles[1], 11)
		AssignDrawRect(FTiles[3], 10)
		FTime = 0
		Visible = false
		FPrevTime = 0
		Z = 12
		FPrevState = TGameState.Map

	private new def Destroy():
		for tile in FTiles:
			tile.Dead()

	public override def Draw():
		FTime = FOnGetTime()
		return if FTime == 0
		UpdateTime() if FTime != FPrevTime
		FPrevTime = FTime
		if (Engine.WorldX != X) or (Engine.WorldY != Y) or ((Engine cast T2kSpriteEngine).State != FPrevState):
			X = Engine.WorldX
			Y = Engine.WorldY
			UpdatePosition(sgPoint(Math.Round(X), Math.Round(Y)))
		for i in range(1, 6):
			FTiles[i].Draw()


def SetX(sprite as TTiledAreaSprite, x as int):
	sprite.FillArea.x = x

def SetY(sprite as TTiledAreaSprite, y as int):
	sprite.FillArea.y = y

static class GMenuEngine: 
	public Value as TMenuSpriteEngine

let SEPARATOR = 8
let ARROW_DISPLACEMENT = TSgPoint(x: 8, y: 0)
let FRAME_DISPLACEMENT = TSgPoint(x: 32, y: 0)
