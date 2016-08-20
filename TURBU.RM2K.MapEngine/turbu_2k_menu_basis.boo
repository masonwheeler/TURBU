namespace TURBU.RM2K.Menus

import commons
import turbu.defs
import SG.defs
import TURBU.RM2K.RPGScript
import SDL.ImageManager
import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import TURBU.RM2K.Menus
import turbu.Heroes
import TURBU.RM2K.MapEngine
import turbu.RM2K.environment
import Newtonsoft.Json.Linq
import SDL2.SDL2_GPU

enum TMenuShowState:
	Off
	Main
	Fading

//TODO: Way too much menu functionality is hard-coded everywhere.
//Rework the menu engine as a component-based system that can be defined with declarative macros

abstract class TGameMenuBox(TCustomMessageBox):

	[Property(OnButton)]
	private FOnButton as Action[of TButtonCode, TGameMenuBox, TMenuPage]

	[Property(OnCursor)]
	private FOnCursor as Action[of short, TGameMenuBox, TMenuPage]

	[Property(OnSetup)]
	private FOnSetup as Action[of int, TGameMenuBox, TMenuPage]

	[Getter(MenuEngine)]
	protected FMenuEngine as TMenuEngine

	protected FOwner as TMenuPage

	[Getter(Referrer)]
	protected FReferrer as TGameMenuBox

	internal def SetReferrer(value as TGameMenuBox):
		FReferrer = value

	protected FSetupValue as int

	protected FBlank as bool

	protected def Return():
		dummy as TGameMenuBox
		if FReferrer == null:
			FMenuEngine.Return()
		else:
			dummy = FReferrer
			FReferrer = null
			FOwner.BackTo(dummy)

	protected Focused as bool:
		get: return (FMenuEngine.CurrentMenu == FOwner) and (FOwner.CurrentMenu == self)

	protected virtual def DoButton(input as TButtonCode):
		super.Button(input)
		if input == TButtonCode.Cancel:
			PlaySystemSound(TSfxTypes.Cancel)
			self.Return()

	protected virtual def DoCursor(position as short):
		super.PlaceCursor(position) if self.Focused:

	protected virtual def DoSetup(value as int):
		if value != CURSOR_UNCHANGED:
			FSetupValue = value
		else: FDontChangeCursor = true

	protected abstract def DrawText():
		pass

	protected virtual def PostDrawText():
		pass

	protected override def DoDraw():
		let TEXT_TARGET = sgPoint(4, 8)
		super.DoDraw()
		if FTextDrawn != TTextDrawState.Done:
			FTextTarget.Parent.PushRenderTarget()
			FTextTarget.SetRenderer()
			if FTextDrawn == TTextDrawState.None:
				FTextTarget.Parent.Clear(SDL_BLACK, 0)
			DrawText()
			FTextTarget.Parent.PopRenderTarget()
			if FTextDrawn == TTextDrawState.None:
				FTextDrawn = TTextDrawState.Done
		if self.Focused and not FBlank:
			FMenuEngine.Cursor.Draw()
		FTextTarget.Parent.Draw(FTextTarget, FOrigin + TEXT_TARGET)
		PostDrawText()

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		FMenuEngine = main
		FOwner = owner
		super(parent, GPU_MakeRect(0, 0, coords.w, coords.h))
		self.MoveTo(coords)

	public override def Draw():
		if Visible:
			super.Draw()

	public def Setup(value as int):
		DoSetup(value)
		if assigned(FOnSetup):
			FOnSetup(value, self, FOwner)

	public override def Button(input as TButtonCode):
		self.DoButton(input)
		if assigned(OnButton):
			OnButton(input, self, FOwner)

	public override def PlaceCursor(position as short):
		if position == CURSOR_UNCHANGED:
			position = FCursorPosition
		self.DoCursor(position)
		if assigned(OnCursor):
			OnCursor(FCursorPosition, self, FOwner)

	public def FocusPage(which as string, cursorValue as int):
		FOwner.FocusPage(which, cursorValue)

	public def FocusMenu(which as string, setupValue as int):
		FOwner.FocusMenu(self, which, setupValue, false)

	public override def MoveTo(coords as GPU_Rect):
		FOrigin = sgPoint(coords.x, coords.y)
		sCoords = GPU_MakeRect(coords.x, coords.y, coords.w - coords.x, coords.h - coords.y)
		super.MoveTo(sCoords)
		FBounds = coords
		FCoords = sCoords

	protected def GetRightSide() as int:
		return self.Width - BORDER_THICKNESS

	public CursorPosition as short:
		get: return FCursorPosition

	public OptionEnabled[which as ushort] as bool:
		get: return FOptionEnabled[which]
		set: FOptionEnabled[which] = value

[Disposable(Destroy)]
class TMenuPage(TObject):

	private FOwner as TMenuEngine

	protected FVisible as bool

	protected FMainMenu as TGameMenuBox

	[Getter(CurrentMenu)]
	protected FCurrentMenu as TGameMenuBox

	protected FComponents = Dictionary[of string, TGameMenuBox]()

	protected FComponentList = List[of TGameMenuBox]()

	protected FBounds as GPU_Rect

	protected FBackground as string
	
	protected static FSetupDrawLock = object()

	protected static def ShiftX(value as GPU_Rect, distance as int, cutoff as int) as GPU_Rect:
		if distance < 0:
			distance = Math.Max(distance, -(value.x - cutoff))
		else:
			distance = Math.Min(distance, cutoff - value.x)
		value.x += distance
		return value

	protected virtual def SetVisible(value as bool):
		frame as TGameMenuBox
		for frame in FComponents.Values:
			frame.Visible = value
		self.FVisible = value

	protected def RegisterComponent(Name as string, which as TGameMenuBox):
		FComponents.Add(Name, which)
		FComponentList.Add(which)
		which.Name = Name
		if (FMainMenu == null) and (which isa TGameMenuBox):
			FMainMenu = which cast TGameMenuBox

	protected def LoadComponent(obj as JObject):
		Name as string
		cls as string
		boxClass as TGameMenuBoxClass
		coordsArr as JArray
		coords as GPU_Rect
		box as TGameMenuBox
		cls = obj['Class'] cast string
		if not TMenuEngine.FMenuBoxes.TryGetValue(cls, boxClass):
			raise Exception("Menu class \"$cls\" is not reigstered.")
		Name = obj['Name'] cast string
		coordsArr = obj['Coords'] cast JArray
		coords.x = coordsArr[0] cast int
		coords.y = coordsArr[1] cast int
		coords.w = coordsArr[2] cast int
		coords.h = coordsArr[3] cast int
		box = boxClass.Create(FOwner.Parent, coords, FOwner, self)
		self.RegisterComponent(Name, box)

	protected def LoadComponents(layout as string):
		arr as JArray
		i as int
		obj as JObject
		using arr = JArray.Parse(layout):
			for i in range(arr.Count):
				obj = arr[i] cast JObject
				LoadComponent(obj)

	protected def SetBG(filename as string, imagename as string):
		LoadFullImage(filename, imagename, true)
		FBackground = imagename

	protected def LoadFullImage(filename as string, imagename as string, opaque as bool):
		cls as TSdlImageClass
		images as TSdlImages
		images = FOwner.Parent.Images
		if not images.Contains(imagename):
			cls = images.SpriteClass
			images.SpriteClass = (classOf(TSdlOpaqueImage) if opaque else classOf(TSdlImage))
			try:
				images.EnsureImage(filename, imagename)
			ensure:
				images.SpriteClass = cls

	protected def Return():
		FOwner.Return()

	protected virtual def DoDraw():
		unless string.IsNullOrEmpty(FBackground):
			FOwner.Parent.Images.Image[FBackground].Draw()

	protected virtual def Cleanup():
		pass
	
	internal def EngineCleanup():
		self.Cleanup()

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string):
		super()
		FBounds = coords
		FOwner = main
		LoadComponents(layout)

	private def Destroy():
		Cleanup()
		for box in FComponents.Values:
			box.Dispose()

	public def FocusMenu(referrer as TGameMenuBox, which as string, setupValue as int, unchanged as bool):
		frame as TGameMenuBox
		frame = self.Menu(which)
		unless frame isa TGameMenuBox:
			raise Exception("Menu box \"$which\" can't be focused.")
		FocusMenu(referrer, frame cast TGameMenuBox, unchanged)
		(frame cast TGameMenuBox).Setup(setupValue)

	public virtual def FocusMenu(referrer as TGameMenuBox, which as TGameMenuBox, unchanged as bool):
		self.FCurrentMenu = which
		which.Visible = true
		if referrer != null:
			FCurrentMenu.SetReferrer(referrer)
		if unchanged:
			self.PlaceCursor(CURSOR_UNCHANGED)
		else:
			self.PlaceCursor(0)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def FocusPage(which as string, cursorValue as int):
		FOwner.FocusMenu(self, which, cursorValue)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def BackTo(which as TGameMenuBox):
		for frame as TGameMenuBox in FComponents.Values:
			frame.EngineInvalidateText()
		self.FocusMenu(null, which, true)

	public def Draw():
		lock FSetupDrawLock:
			assert FOwner.CurrentMenu == self
			DoDraw()
			for frame in FComponentList:
				if frame.Visible:
					frame.Draw()

	public def PlaceCursor(value as int):
		FCurrentMenu.PlaceCursor(value)

	public virtual def Setup(value as int):
		frame as TGameMenuBox
		lock FSetupDrawLock:
			FCurrentMenu = FMainMenu
			for frame in FComponents.Values:
				if frame isa TGameMenuBox:
					(frame cast TGameMenuBox).Setup(value)
			self.Move()

	public virtual def SetupEx(data as TObject):
		Setup(GMenuEngine.Value.MenuInt)

	public def Move():
		if assigned(FCurrentMenu):
			PlaceCursor(CURSOR_UNCHANGED)

	public virtual def Button(input as TButtonCode):
		FCurrentMenu.Button(input)

	public def Menu(Name as string) as TGameMenuBox:
		result as TGameMenuBox
		if not FComponents.TryGetValue(Name, result):
			raise Exception("No Menu box named \"$Name\" is available.")
		return result

	public Visible as bool:
		get: return FVisible
		set: SetVisible(value)

class TMenuEngine(TObject, IMenuEngine):

	public struct TMenuPageData:
		Cls as TMenuPageClass
		Layout as string

		def constructor(aClass as TMenuPageClass, aLayout as string):
			self.Cls = aClass
			self.Layout = aLayout

	public static FMenuBoxes = Dictionary[of string, TGameMenuBoxClass]()

	public static FMenuLayouts = Dictionary[of string, TMenuPageData]()

	[Getter(Cursor)]
	private FCursor as TSysFrame

	[Getter(Parent)]
	private FParent as TMenuSpriteEngine

	private FVisible as bool

	private FStack = Stack[of TMenuPage]()

	[Getter(CurrentMenu)]
	private FCurrentPage as TMenuPage

	private FState as TMenuShowState

	private FOrigin as TSgPoint

	private FMenus = Dictionary[of string, TMenuPage]()

	private FCloseMenu as Action

	[Property(CurrentHero)]
	private FCurrentHero as TRpgHero

	private def SetVisible(value as bool):
		FVisible = value
		if assigned(FCurrentPage):
			FCurrentPage.Visible = value
		FCursor.Visible = value

	private def Move():
		FCurrentPage.Move()

	private def Initialize():
		GGameEngine.value.EnterLock = true
		self.Move()
		GEnvironment.value.Party.Pack()
		self.Visible = true
		self.FState = TMenuShowState.Fading
		PlaceCursor(0)

	def CloseMenu():
		FCurrentPage.CurrentMenu.EngineEndMessage()

	def OpenMenu(Name as string, cursorValue as int):
		unless FMenus.TryGetValue(Name, FCurrentPage):
			raise Exception("No Menu named \"$Name\" is registered.")
		FCurrentPage.Setup(cursorValue)
		self.Initialize()

	def OpenMenuEx(Name as string, data as TObject):
		unless FMenus.TryGetValue(Name, FCurrentPage):
			raise Exception("No Menu named \"$Name\" is registered.")
		FCurrentPage.SetupEx(data)
		self.Initialize()

	def Button(input as TButtonCode):
		if FState == TMenuShowState.Off:
			raise EFatalError('Tried to send a Menu command when the Menu was not active!')
		else: FCurrentPage.Button(input)

	def Draw():
		FCurrentPage.Draw()

	public def constructor(parent as TMenuSpriteEngine, callback as Action):
		pair as KeyValuePair[of string, TMenuPageData]
		super()
		FParent = parent
		FCursor = parent.Cursor
		self.Visible = false
		for pair in FMenuLayouts:
			FMenus.Add(
				pair.Key,
				pair.Value.Cls.Create(FParent, GPU_MakeRect(0, 0, FParent.Canvas.Width, FParent.Canvas.Height),
				self,
				pair.Value.Layout))
		FCloseMenu = callback

	public def FocusMenu(sender as TMenuPage, which as TMenuPage):
		assert sender != which
		FStack.Push(sender)
		self.FCurrentPage = which
		sender.Visible = false
		which.Visible = true

	public def FocusMenu(sender as TMenuPage, which as string, cursorValue as int):
		Menu as TMenuPage
		unless FMenus.TryGetValue(which, Menu):
			raise Exception("No Menu named \"$which\" is registered.")
		FocusMenu(sender, Menu)
		Menu.Setup(cursorValue)

	public def Return():
		page as TMenuPage
		if FStack.Count == 0:
			self.Leave(false)
		else:
			page = FStack.Pop()
			FCurrentPage.Visible = false
			FCurrentPage.EngineCleanup()
			page.Visible = true
			FCurrentPage = page
			page.Setup(CURSOR_UNCHANGED)

	public def PlaceCursor(value as short):
		if FCurrentPage == null:
			raise EFatalError('Tried to Place a system Menu cursor when the Menu was not active!')
		else: FCurrentPage.PlaceCursor(value)

	public def Leave(PlaySound as bool):
		Return() while FStack.Count > 0
		GGameEngine.value.EnterLock = true
		PlaySystemSound(TSfxTypes.Cancel) if PlaySound
		FState = TMenuShowState.Fading
		self.Visible = false
		var cMap = GGameEngine.value.CurrentMap
		cMap.Wake() if assigned(cMap)
		FCloseMenu()

	public def Activate():
		assert FState == TMenuShowState.Fading
		FState = TMenuShowState.Main
		FOrigin = sgPoint(Math.Round(FParent.WorldX), Math.Round(FParent.WorldY))

	public def Shutdown():
		assert FState == TMenuShowState.Fading
		FState = TMenuShowState.Off

	public static def RegisterMenuBoxClass(cls as TGameMenuBoxClass):
		FMenuBoxes.Add(cls.ClassName, cls)

	public static def RegisterMenuPage(Name as string, layout as string):
		FMenuLayouts.Add(Name, TMenuPageData(classOf(TMenuPage), layout))

	public static def RegisterMenuPageEx(cls as TMenuPageClass, Name as string, layout as string):
		FMenuLayouts.Add(Name, TMenuPageData(cls, layout))

	public Visible as bool:
		get: return FVisible
		set: SetVisible(value)

let CURSOR_UNCHANGED = 9999