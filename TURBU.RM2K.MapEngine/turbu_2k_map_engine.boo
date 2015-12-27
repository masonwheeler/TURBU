namespace TURBU.RM2K.MapEngine

import System
import System.IO
import System.Threading
import System.Windows.Forms
import archiveInterface
import AsphyreTimer
import commons
import dm.shaders
import project.folder
import Pythia.Runtime
import TURBU.RM2K.RPGScript
import sdl.canvas
import SDL.ImageManager
import SDL2
import SDL2.SDL2_GPU
import SG.defs
import timing
import TURBU.BattleEngine
import TURBU.DataReader
import TURBU.MapEngine
import TURBU.MapInterface
import TURBU.MapObjects
import TURBU.Meta
import TURBU.RM2K
import TURBU.RM2K.GameData
import TURBU.RM2K.Menus
import TURBU.PluginInterface
import TURBU.TextUtils
import TURBU.TransitionInterface
import turbu.constants
import turbu.defs
import turbu.Heroes
import turbu.map.metadata
import turbu.map.sprites
import turbu.maps
import turbu.RM2K.CharSprites
import turbu.RM2K.environment
import turbu.RM2K.image.engine
import turbu.RM2K.map.locks
import turbu.RM2K.sprite.engine
import turbu.RM2K.transitions.graphics
import turbu.RM2K.weather
import turbu.script.engine
import turbu.sdl.image
import turbu.tilesets
import turbu.versioning

enum TSwitchState:
	NoSwitch
	Ready
	Switching

class T2kMapEngine(TMapEngine):

	public enum TGameState:
		Title
		Playing
		GameOver

	private FRenderer as GPU_Target_PTR

	private FStretchRatio as TSgFloatPoint

	private FSignal as EventWaitHandle

	private FButtonState as TButtonCode

	private FSwitchState as TSwitchState

	private FTeleportThread as TThread

	private FGameState as TGameState

	private FTransition as ITransition

	private FTransitionFirstFrameDrawn as bool

	private FRenderPause as TRpgTimestamp

	private FRenderPauseLock as object

	private def UpdatePartySprite(value as TCharSprite):
		if assigned(value):
			FPartySprite = value

	private def StopPlaying():
		FPlaying = false
		runThreadsafe(true) def ():
			FPartySprite = null
			GEnvironment.value.ClearVehicles()
			FCurrentMap = null
			FCanvas.DrawBox(GPU_MakeRect(0, 0, 1, 1), SDL_WHITE, 255)

	protected FDatabase as TRpgDatabase

	protected FCanvas as TSdlCanvas

	[Getter(CurrentMap)]
	protected FCurrentMap as T2kSpriteEngine

	protected FWaitingMap as TRpgMap

	protected FWaitingMapEngine as T2kSpriteEngine

	protected FImages as TSdlImages

	protected FScrollPosition as TSgPoint

	protected FTimer as TAsphyreTimer

	[Getter(PartySprite)]
	protected FPartySprite as TCharSprite

	protected FObjectManager as TMapObjectManager

	protected FShaderEngine as TdmShaders

	[Getter(ImageEngine)]
	protected FImageEngine as TImageEngine

	[Getter(WeatherEngine)]
	protected FWeatherEngine as TWeatherSystem

	protected FPlaying as bool
	
	private _reader as IDataReader

	protected def Repaint():
		GRenderTargets.RenderOn(RENDERER_MAIN, RenderFrame, 0, true, false)
		DrawRenderTarget(GRenderTargets[RENDERER_MAIN], false)
		self.AfterPaint()
		FCanvas.Flip()

	protected def LoadTileset(value as TTileSet):
		for input in value.Records:
			continue if string.IsNullOrEmpty(input.Group.Filename)
			filename as string = "Tilesets\\$(input.Group.Filename).png"
			unless FImages.Contains(filename):
				FImages.AddSpriteFromArchive(filename, input.Group.Filename, input.Group.Dimensions, null)

	protected def LoadSprite(filename as string):
		return if filename.StartsWith('*')
		lName as string = "Sprites\\$filename.png"
		unless FImages.Contains(filename):
			FImages.AddSpriteFromArchive(lName, filename, SPRITE_SIZE, null)

	protected def CreateViewport(map as TRpgMap, center as TSgPoint) as GPU_Rect:
		screensize as TSgPoint = FCanvas.Size / TILE_SIZE
		center = (center / TILE_SIZE) - (screensize / 2.0)
		unless (TWraparound.Horizontal in map.Wraparound):
			if center.x < 0:
				center.x = 0
			elif (center.x + screensize.x) >= map.Size.x:
				center.x = pred(map.Size.x - (screensize.x / 2))
		unless (TWraparound.Vertical in map.Wraparound):
			if center.y < 0:
				center.y = 0
			elif (center.y + screensize.y) >= map.Size.y:
				center.y = pred(map.Size.y - (screensize.y / 2))
		return GPU_MakeRect(center.x, center.y, screensize.x, screensize.y)

	protected def CanvasResize(sender as TSdlCanvas):
		GRenderTargets.Clear()
		for i in range(1, 6):
			GRenderTargets.Add(TSdlRenderTarget(FCanvas.Size))

	protected def LoadMapSprites(map as TRpgMap):
		for mapObj in map.MapObjects:
			continue if mapObj.ID == 0
			for page in mapObj.Pages:
				LoadSprite(page.Name) unless page.IsTile
		GEnvironment.value.CheckVehicles()

	protected def DoneLoadingMap() as bool:
		FCurrentMap = FWaitingMapEngine
		FWaitingMapEngine = null
		FCurrentMap.OnPartySpriteChanged = self.UpdatePartySprite
		FCurrentMap.OnDrawWeather = self.DrawWeather
		if FImageEngine == null:
			FImageEngine = TImageEngine(FCurrentMap, FCanvas, FImages)
			GEnvironment.value.CreateTimers()
		GSpriteEngine.value = FCurrentMap
		LoadMapSprites(FCurrentMap.MapObj)
		FObjectManager.LoadMap(FWaitingMap, FTeleportThread)
		FObjectManager.Tick() if FPlaying
		FCurrentMap.Dead()
		return FSignal.WaitOne(Timeout.Infinite)

	protected def PrepareMap(data as IMapMetadata):
		FTimer.Enabled = false
		raise ERpgPlugin("Can't load a map on an uninitialized map engine.") unless FInitialized
		GEnvironment.value.ClearEvents()
		var map = data as TMapMetadata
		raise ERpgPlugin('Incompatible metadata object.') unless assigned(map)
		FWaitingMap = dmDatabase.value.LoadMap(map.InternalFilename)
		FScrollPosition = map.ScrollPosition

	protected def InitializeParty():
		party as TRpgParty = GEnvironment.value.Party
		for i in range(FDatabase.Layout.StartingHeroes.Length):
			party[i + 1] = GEnvironment.value.Heroes[FDatabase.Layout.StartingHero[i + 1]]
		FPartySprite = THeroSprite(FCurrentMap, party[1], party)

	private FFrame as int

	private FHeartbeat as int

	[Property(EnterLock)]
	private FEnterLock as bool

	private FSaveLock as bool

	private FCutscene as int

	private def OnTimer():
		++FFrame
		TRpgTimestamp.NewFrame()
		lock FRenderPauseLock:
			caseOf FGameState:
				case T2kMapEngine.TGameState.Title: RenderTitle()
				case T2kMapEngine.TGameState.Playing: RenderPlaying()
				case T2kMapEngine.TGameState.GameOver: RenderGameOver()
		if FFrame > FHeartbeat:
			FCurrentMap.AdvanceFrame() if assigned(FCurrentMap)
			FFrame = 0
		FTimer.Process()

	private def StandardRender():
		return if FSwitchState == TSwitchState.Switching
		caseOf GMenuEngine.Value.State:
			case TMenuState.None, TMenuState.Shared, TMenuState.ExclusiveShared: FCurrentMap.Draw()
			case TMenuState.Full:
				pass
		FSwitchState = TSwitchState.Switching if FSwitchState == TSwitchState.Ready
			

	private def RenderImages(sender as TObject):
		FImageEngine.Draw() if assigned(FImageEngine)

	private def OnProcess():
		return if FSwitchState != TSwitchState.NoSwitch
		FButtonState = ReadKeyboardState()
		for button in FButtonState.Values():
			PressButton(button)
		if FSaveLock:
			FSaveLock = KeyIsPressed(Keys.F2) or KeyIsPressed(Keys.F6)
		else:
			if KeyIsPressed(Keys.F2):
				Quicksave()
				FSaveLock = true
			elif KeyIsPressed(Keys.F6):
				Quickload()
				FSaveLock = true
		if FGameState == T2kMapEngine.TGameState.Playing:
			GMapObjectManager.value.Tick()
			FCurrentMap.Process()

	private def PressButton(button as TButtonCode):
		return if FEnterLock and (button in (TButtonCode.Enter, TButtonCode.Cancel))
		if FGameState == T2kMapEngine.TGameState.GameOver:
			TitleScreen() if button == TButtonCode.Enter
			return
		caseOf GMenuEngine.Value.State:
			case TMenuState.None:
				if FCutscene > 0:
					return
				elif (button == TButtonCode.Cancel) and GEnvironment.value.MenuEnabled:
					FEnterLock = true
					PlaySystemSound(TSfxTypes.Accept)
					OpenMenu()
				elif assigned(FPartySprite):
					PartyButton(button)
			case TMenuState.Shared, TMenuState.ExclusiveShared, TMenuState.Full:
				GMenuEngine.Value.Button(button)
				FEnterLock = true

	private def PartyButton(Button as TButtonCode):
		System.Threading.Monitor.Enter(GMoveLock) if Button in (TButtonCode.Up, TButtonCode.Right, TButtonCode.Down, TButtonCode.Left)
		try:
			caseOf Button:
				case TButtonCode.Enter:
					FEnterLock = true
					lock GEventLock:
						FPartySprite.Action(TButtonCode.Enter)
				case TButtonCode.Up: FPartySprite.Move(TDirections.Up)
				case TButtonCode.Down: FPartySprite.Move(TDirections.Down)
				case TButtonCode.Left: FPartySprite.Move(TDirections.Left)
				case TButtonCode.Right: FPartySprite.Move(TDirections.Right)
		ensure:
			System.Threading.Monitor.Exit(GMoveLock) if Button in (TButtonCode.Up, TButtonCode.Right, TButtonCode.Down, TButtonCode.Left)

	private def PlayMapMusic(metadata as TMapMetadata, Clear as bool):
		id as short = metadata.ID
		caseOf metadata.BgmState:
			case TInheritedDecision.Parent:
				repeat:
					id = FDatabase.MapTree[id].Parent
					until id == 0 or (FDatabase.MapTree[id] cast TMapMetadata).BgmState != TInheritedDecision.Parent
				if id == 0:
					StopMusic()
				elif (FDatabase.MapTree[id] cast TMapMetadata).BgmState == TInheritedDecision.Yes:
					PlayMusicData((FDatabase.MapTree[id] cast TMapMetadata).BgmData)
			case TInheritedDecision.No:
				FadeOutMusic(1000) if Clear
			case TInheritedDecision.Yes: PlayMusicData((FDatabase.MapTree[id] cast TMapMetadata).BgmData)

	private def DrawRenderTarget(target as TSdlRenderTarget, canTint as bool):
		glCheckError()
		color = GPU_GetColor(target.Image)
		GPU_SetRGBA(target.Image, 255, 255, 255, 255)
		unless (canTint and FCurrentMap.Fade()):
			//FShaderEngine.UseShaderProgram(FShaderEngine.ShaderProgram('default', 'defaultF'))
			GPU_DeactivateShaderProgram()
		target.DrawFull()
		GPU_SetColor(target.Image, color)
		GPU_DeactivateShaderProgram()

	private def RenderFrame():
		GRenderTargets.RenderOn(RENDERER_MAP, StandardRender, 0, true, false)
		DrawRenderTarget(GRenderTargets[RENDERER_MAP], true)
		//FShaderEngine.UseShaderProgram(FShaderEngine.ShaderProgram('default', 'defaultF'))
		GPU_DeactivateShaderProgram()
		RenderImages(self)
		FCurrentMap.DrawFlash()
		if GMenuEngine.Value.State != TMenuState.None:
			GMenuEngine.Value.Draw()
		GPU_DeactivateShaderProgram()

	private def DrawWeather():
		FWeatherEngine.Draw()

	private def RenderGameOver():
		imagename as string
		image as TSdlImage
		preserving FImages.SpriteClass:
			FImages.SpriteClass = classOf(TSdlOpaqueImage)
			imagename = "Special Images\\$(GDatabase.value.Layout.GameOverScreen).png"
			image = FImages.EnsureImage(imagename, '*GameOver', sgPoint(GDatabase.value.Layout.Width, GDatabase.value.Layout.Height))
		GPU_SetBlending(image.Surface, 0)
		image.Draw()
		FCanvas.Flip()
		FTimer.Process()

	private def RenderPlaying():
		if assigned(FRenderPause) and (FRenderPause.TimeRemaining == 0):
			FRenderPause = null
		if FRenderPause == null:
			FCanvas.Clear()
			if assigned(FTransition):
				unless FTransitionFirstFrameDrawn:
					GRenderTargets.RenderOn(RENDERER_ALT, RenderFrame, 0, true, false)
					FTransitionFirstFrameDrawn = true
				unless FTransition.Draw():
					FTransitionFirstFrameDrawn = false
					FTransition = null
			else:
				if FCurrentMap.Blank:
					GRenderTargets.RenderOn(RENDERER_MAIN, null, 0, true, false)
				else: GRenderTargets.RenderOn(RENDERER_MAIN, RenderFrame, 0, true, false)
				DrawRenderTarget(GRenderTargets[RENDERER_MAIN], false)
			FCanvas.Flip()

	private def RenderTitle():
		if GMenuEngine.Value.State == TMenuState.None:
			GMenuEngine.Value.OpenMenu('Title')
		GMenuEngine.Value.Draw()
		FCanvas.Flip()
		FTimer.Process()

	protected FDatabaseOwner as bool

	protected override def Cleanup():
		assert FInitialized
		FInitialized = false
		if FDatabaseOwner:
			FObjectManager.ScriptEngine.KillAll(null) if FObjectManager is not null
			GMenuEngine.Value = null
		FShaderEngine.Dispose() if assigned(FShaderEngine)
		FShaderEngine = null
		GEnvironment.value = null
		FPartySprite = null
		FCanvas = null
		FImages = null
		FSignal = null
		FImageEngine = null
		FWeatherEngine = null
		FCurrentMap = null
		if FDatabaseOwner:
			GGameEngine.value = null
			FDatabase = null
			GDatabase.value = null
			dmDatabase.value = null
			FObjectManager = null
			GMapObjectManager.value = null
			GScriptEngine.value = null
			GFontEngine.Dispose()
		super.Cleanup()
		GC.Collect()

	protected virtual def AfterPaint():
		pass

	protected def Quicksave():
		savefile as string
		savefile = Path.Combine(GProjectFolder.value, 'quicksave.tsg')
		turbu.RM2K.savegames.SaveTo(savefile, GEnvironment.value.Party.MapID, false)

	protected def Quickload():
		Load(Path.Combine(GProjectFolder.value, 'quicksave.tsg'))

	public def constructor():
		super()
		self.Data = TMapEngineData('TURBU basic map engine', TVersion(0, 1, 0))
		FRenderPauseLock = object()

	public override def Initialize(window as IntPtr, database as string) as IntPtr:
		layout as TGameLayout
		trn as TTransitionTypes
		sfx as TSfxTypes
		bgm as TBgmTypes
		if FInitialized:
			return window
		try:
			FInitialized = true
			super.Initialize(window, database)
			if dmDatabase.value == null:
				assert assigned(_reader)
				_reader.Initialize(database)
				FDatabaseOwner = true
				GGameEngine.value = self
				dmDatabase.value = TdmDatabase()
				dmDatabase.value.Load(_reader)
				FDatabase = TRpgDatabase(dmDatabase.value)
				GDatabase.value = FDatabase
				unless assigned(FDatabase):
					raise ERpgPlugin('Incompatible project database')
				FObjectManager = TMapObjectManager()
				GScriptEngine.value.OnEnterCutscene = self.EnterCutscene
				GScriptEngine.value.OnLeaveCutscene = self.LeaveCutscene
				GScriptEngine.value.OnRenderUnpause = self.RenderUnpause
				GEnvironment.value = T2kEnvironment(FDatabase)
				dmDatabase.value.RegisterEnvironment(GEnvironment.value)
				FObjectManager.LoadGlobalScripts(GDatabase.value.GlobalEvents)
				FObjectManager.OnUpdate = GEnvironment.value.UpdateEvents
			else:
				FDatabase = GDatabase.value
				FObjectManager = GMapObjectManager.value
			layout = FDatabase.Layout
			if window == IntPtr.Zero:
				window = SDL.SDL_CreateWindow("TURBU engine - FDatabase.MapTree[0].Name",
					SDL.SDL_WINDOWPOS_CENTERED_MASK, SDL.SDL_WINDOWPOS_CENTERED_MASK, layout.PhysWidth, layout.PhysHeight,
					SDL.SDL_WindowFlags.SDL_WINDOW_OPENGL | SDL.SDL_WindowFlags.SDL_WINDOW_SHOWN)
				if window == IntPtr.Zero:
					raise ERpgPlugin("Unable to initialize SDL window: \r\n$(SDL.SDL_GetError())")
			winID = SDL.SDL_GetWindowID(window)
			FRenderer = GPU_GetWindowTarget(winID)
			if FRenderer.Pointer == IntPtr.Zero:
				GPU_SetInitWindow(winID)
				FRenderer = GPU_Init(0, 0, 0)
				if FRenderer == IntPtr.Zero:
					raise ERpgPlugin("Unable to initialize SDL_GPU renderer")
			FCanvas = TSdlCanvas.CreateFrom(window)
			FCanvas.OnResize = self.CanvasResize
			FStretchRatio.x = (layout.PhysWidth cast double) / (layout.Width cast double)
			FStretchRatio.y = (layout.PhysHeight cast double) / (layout.Height cast double)
			GPU_SetVirtualResolution(FRenderer.Pointer, layout.Width, layout.Height)
			FCanvas.Resize()
			FImages = TSdlImages(true, null)
			FImages.ArchiveLoader = ALoader
			FImages.SpriteClass = classOf(TRpgSdlImage)
			FWeatherEngine = TWeatherSystem(null, FImages, FCanvas)
			FSignal = EventWaitHandle(true, EventResetMode.ManualReset)
			FShaderEngine = TdmShaders()
			if FDatabaseOwner:
				GFontEngine.Initialize(FShaderEngine)
				GFontEngine.Current = TRpgFont('RMG2000.fon', 7)
				GMenuEngine.Value = TMenuSpriteEngine(TSystemImages(FImages, layout.SysGraphic, layout.WallpaperStretch, layout.TranslucentMessages), FCanvas, FImages)
				for trn in range(TTransitionTypes.BattleEndShow + 1):
					TURBU.RM2K.RPGScript.SetTransition(trn, layout.Transition[trn] + 1)
				for sfx in range(TSfxTypes.ItemUsed + 1):
					SetSystemSoundData(sfx, FDatabase.Sfx[sfx])
				for bgm in range(TBgmTypes.BossBattle + 1):
					SetSystemMusicData(bgm, FDatabase.Bgm[bgm])
			FTimer = TAsphyreTimer(60, self.OnTimer) if FTimer is null
		failure:
			Cleanup()
		return window

	public override def LoadMap(map as IMapMetadata):
		FCurrentMap = null
		PrepareMap(map)
		viewport as GPU_Rect = CreateViewport(FWaitingMap, FScrollPosition)
		if assigned(FWaitingMapEngine):
			FWaitingMapEngine.ReloadMapObjects()
		else:
			EnsureTileset(FWaitingMap.Tileset)
			FWaitingMapEngine = T2kSpriteEngine(FWaitingMap, viewport, FShaderEngine, FCanvas, 
				FDatabase.Tileset[FWaitingMap.Tileset], FImages)
		unless DoneLoadingMap():
			raise Exception('Error loading map')

	public def LoadMap(id as int):
		try:
			if id != GEnvironment.value.Party.MapID:
				LoadMap(GDatabase.value.MapTree[id])
		except:
			raise Exception("Invalid map ID: $id")

	public override def Play():
		assert assigned(FCurrentMap)
		InitializeParty() if FPartySprite is null
		FTimer.Enabled = true
		FPlaying = true

	public override def Playing() as bool:
		return FTimer.Enabled

	public override def MapTree() as IMapTree:
		return FDatabase.MapTree

	public override def NewGame():
		assert FPlaying == false
		FGameState = T2kMapEngine.TGameState.Playing
		loc as TLocation = (FDatabase.MapTree cast TMapTree).Location[0]
		metadata as TMapMetadata = FDatabase.MapTree[loc.map]
		self.LoadMap(metadata)
		InitializeParty()
		FPartySprite.LeaveTile()
		FCurrentMap.CurrentParty = FPartySprite
		FPartySprite.Location = sgPoint(loc.x, loc.y)
		PlayMapMusic(metadata, true)
		self.Play()

	public override def Start():
		FTimer.OnProcess += self.OnProcess
		TitleScreen()
		FTimer.Enabled = true

	public def ChangeMaps(newmap as int, newLocation as TSgPoint):
		assert newmap != FCurrentMap.MapID
		currentMap as T2kSpriteEngine = FCurrentMap
		FSwitchState = TSwitchState.Ready
		FObjectManager.ScriptEngine.KillAll({ currentMap = null })
		while not FCurrentMap.Blank:
			Thread.Sleep(10)
		FTeleportThread = TThread.CurrentThread
		metadata as TMapMetadata
		try:
			runThreadsafe(true) def ():
				FImageEngine = null
				oldEngine as T2kSpriteEngine = FCurrentMap
				hero as TCharSprite = FCurrentMap.CurrentParty
				if assigned(hero):
					(hero cast THeroSprite).PackUp()
				metadata = FDatabase.MapTree[newmap]
				GScriptEngine.value.TeleportThread = FTeleportThread cast TScriptThread
				GC.Collect()
				self.LoadMap(metadata)
				unless GEnvironment.value.PreserveSpriteOnTeleport:
					GEnvironment.value.Party.ResetSprite()
				FCurrentMap.CurrentParty = hero
				FCurrentMap.CopyState(oldEngine)
				if assigned(hero):
					hero.Location = newLocation
					(hero cast THeroSprite).settleDown(FCurrentMap)
				FCurrentMap.CenterOn(newLocation.x, newLocation.y)
		ensure:
			FTeleportThread = null
		PlayMapMusic(metadata, false)
		FSwitchState = TSwitchState.NoSwitch
		FTimer.Enabled = true

	public def LoadRpgImage(filename as string, mask as bool):
		oName as string = filename
		Abort unless ArchiveUtils.GraphicExists(filename, 'pictures')
		cls as TSdlImageClass = FImages.SpriteClass
		FImages.SpriteClass = classOf(TSdlImage)
		try:
			image as TSdlImage = FImages.EnsureImage('pictures/' + filename, oName)
			GPU_SetBlending(image.Surface, (1 if mask else 0))
		ensure:
			FImages.SpriteClass = cls

	public virtual def TitleScreen():
		FGameState = T2kMapEngine.TGameState.Title
		StopPlaying()
		PlaySystemMusic(TBgmTypes.Title, false)

	public virtual def GameOver():
		FGameState = T2kMapEngine.TGameState.GameOver
		StopPlaying()
		PlaySystemMusic(TBgmTypes.GameOver, false)

	public def EnterCutscene():
		GMapObjectManager.value.InCutscene = true
		++FCutscene

	public def LeaveCutscene():
		raise Exception('Mismatched call to T2kMapEngine.LeaveCutscene') if FCutscene <= 0
		--FCutscene
		GMapObjectManager.value.InCutscene = FCutscene != 0

	public def ReadKeyboardState() as TButtonCode:
		result = TButtonCode.None
		result |= TButtonCode.Left if KeyIsPressed(Keys.Left)
		result |= TButtonCode.Right if KeyIsPressed(Keys.Right)
		result |= TButtonCode.Up if KeyIsPressed(Keys.Up)
		result |= TButtonCode.Down if KeyIsPressed(Keys.Down)
		result |= TButtonCode.Enter if KeyIsPressed(Keys.Return)
		result |= TButtonCode.Cancel if KeyIsPressed(Keys.Escape) or KeyIsPressed(Keys.Insert)
		FEnterLock = false if result & (TButtonCode.Enter | TButtonCode.Cancel) == TButtonCode.None
		return result

	public def EnsureTileset(id as int) as bool:
		result = FDatabase.Tileset.ContainsKey(id)
		unless result:
			try:
				LoadTileset(FDatabase.Tileset[id])
				result = true
			except:
				pass
		return result

	public def RenderPause():
		lock FRenderPauseLock:
			FRenderPause = TRpgTimestamp(50)

	public def RenderUnpause():
		lock FRenderPauseLock:
			FRenderPause = null

	public def Load(savefile as string) as bool:
		return false unless File.Exists(savefile)
		
		FTimer.Enabled = false
		GScriptEngine.value.KillAll(null)
		GEnvironment.value = null
		FPartySprite = null
		GSpriteEngine.value = null
		GEnvironment.value = T2kEnvironment(FDatabase)
		GScriptEngine.value.Reset()
		//SetupScriptImports()
		FPlaying = false
		FCurrentMap = null
		turbu.RM2K.savegames.Load(savefile, self.InitializeParty)
		FCurrentMap.CurrentParty = (GEnvironment.value.Party.Sprite cast TCharSprite)
		FImageEngine = TImageEngine(GSpriteEngine.value, FCanvas, FImages)
		GEnvironment.value.CreateTimers()
		GC.Collect()
		GMapObjectManager.value.InCutscene = false
		FGameState = T2kMapEngine.TGameState.Playing
		Play()
		return true

	public Transition as ITransition:
		get: return FTransition
		set:
			FTransition = value
			FTransitionFirstFrameDrawn = false
			RenderUnpause()

	private static def ALoader(filename as string) as string:
		return Path.Combine(GArchives[IMAGE_ARCHIVE].Root, filename)
	
	public def RegisterDataReader(value as IDataReader):
		_reader = value

static class GGameEngine:
	public value as T2kMapEngine

[DllImport("USER32.dll")]
static internal def GetAsyncKeyState(vKey as System.Windows.Forms.Keys) as short:
	pass

internal def KeyIsPressed(value as Keys) as bool:
	result = GetAsyncKeyState(value) 
	return result != 0

/*
private def WriteTimestamp():
	hour as ushort
	min as ushort
	sec as ushort
	msec as ushort
	
	decodeTime(sysUtils.GetTime, hour, min, sec, msec)
	commons.OutputFormattedString('Frame timestamp: %d:%d:%d.%d', [hour, min, sec, msec])
*/