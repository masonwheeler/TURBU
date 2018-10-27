namespace TURBU.RM2K.MapEngine

from System import Exception, GC, IDisposable, IntPtr
from System.Collections.Generic import Dictionary
from System.IO import File, Path
from System.Threading import EventResetMode, EventWaitHandle, Timeout
from System.Threading.Tasks import Task
from System.Windows.Forms import Keys

from archiveInterface import GArchives, IMAGE_ARCHIVE
from AsphyreTimer import AsphyreTimer
from dm.shaders import TdmShaders, glCheckError
from project.folder import GProjectFolder
from Pythia.Runtime import AbortMacro, assigned, classOf, EAbort, TClass

from sdl.canvas import SdlCanvas, SdlRenderTarget
from SDL.ImageManager import SdlImages, TSdlImage, TSdlImageClass, TSdlOpaqueImageClass
import SDL2
import SDL2.SDL2_GPU
from SG.defs import SgFloatPoint, SgPoint, SDL_WHITE
from timing import Timestamp
from TURBU.DataReader import IDataReader
from TURBU.MapEngine import TMapEngine, TMapEngineData
from TURBU.MapInterface import IMapMetadata, IMapTree
import TURBU.Meta
from TURBU.RM2K import dmDatabase, GDatabase, TdmDatabase, TRpgDatabase
from TURBU.RM2K.GameData import TGameLayout
from TURBU.RM2K.Menus import GMenuEngine, TMenuSpriteEngine, TMenuState, TSystemImages
from TURBU.RM2K.RPGScript import FadeOutMusic, OpenMenu, PlayMusicData, PlaySystemSound, PlaySystemMusic, \
								 SetSystemSoundData, SetSystemMusicData, StopMusic
from TURBU.PluginInterface import RpgPluginException
from TURBU.TextUtils import GFontEngine, TRpgFont
from TURBU.TransitionInterface import ITransition
import turbu.constants
import turbu.defs
import turbu.Heroes
import turbu.map.metadata
import turbu.map.sprites
import turbu.maps
from turbu.RM2K.CharSprites import THeroSprite
from turbu.RM2K.environment import GEnvironment, T2kEnvironment
from turbu.RM2K.image.engine import TImageEngine
import turbu.RM2K.map.locks
from turbu.RM2K.sprite.engine import GSpriteEngine, T2kSpriteEngine
import turbu.RM2K.transitions.graphics
from turbu.RM2K.weather import TWeatherSystem
from turbu.script.engine import GMapObjectManager, GScriptEngine, TMapObjectManager
from turbu.sdl.image import TRpgSdlImageClass
from turbu.tilesets import TTileSet
from turbu.versioning import TVersion

class T2kMapEngine(TMapEngine):

	private enum SwitchState:
		NoSwitch
		Ready
		Switching

	protected enum TGameState:
		Title
		Playing
		GameOver
		Cleanup

	private _renderer as GPU_Target_PTR

	private _stretchRatio as SgFloatPoint

	private _signal as EventWaitHandle

	private _buttonState as TButtonCode

	private _switchState as SwitchState

	private _gameState as TGameState

	private _transition as ITransition

	private _transitionFirstFrameDrawn as bool

	private _renderPause as Timestamp

	private _renderPauseLock = object()

	private _heldMaps = Dictionary[of int, TRpgMap]()

	private def UpdatePartySprite(value as TCharSprite):
		if assigned(value):
			_partySprite = value

	private def StopPlaying():
		_playing = false
		if assigned(_partySprite):
			_partySprite.Dispose()
			_partySprite = null
		GEnvironment.value.ClearVehicles()
		GEnvironment.value.Party.Clear()
		if assigned(_currentMap):
			_currentMap.Dispose()
			_currentMap = null
		if assigned(_imageEngine):
			_imageEngine.Dispose()
			_imageEngine = null
		_canvas.DrawBox(GPU_MakeRect(0, 0, 1, 1), SDL_WHITE, 255)

	protected _database as TRpgDatabase

	protected _canvas as SdlCanvas

	[Getter(CurrentMap)]
	protected _currentMap as T2kSpriteEngine

	protected _waitingMap as TRpgMap

	protected _waitingMapEngine as T2kSpriteEngine

	protected _images as SdlImages

	protected _scrollPosition as SgPoint

	protected _timer as AsphyreTimer

	[Getter(PartySprite)]
	protected _partySprite as TCharSprite

	protected _objectManager as TMapObjectManager

	protected _shaderEngine as TdmShaders

	[Getter(ImageEngine)]
	protected _imageEngine as TImageEngine

	[Getter(WeatherEngine)]
	protected _weatherEngine as TWeatherSystem

	protected _playing as bool
	
	private _reader as IDataReader

	protected def Repaint():
		GRenderTargets.RenderOn(RENDERER_MAIN, RenderFrame, 0, true, false)
		DrawRenderTarget(GRenderTargets[RENDERER_MAIN], false)
		self.AfterPaint()
		_canvas.Flip()

	protected def LoadTileset(value as TTileSet):
		for input in value.Records:
			continue if string.IsNullOrEmpty(input.Group.Filename)
			var filename = "Tilesets\\${input.Group.Filename}.png"
			unless _images.Contains(filename):
				_images.AddSpriteFromArchive(filename, input.Group.Filename, input.Group.Dimensions, null)

	protected def LoadSprite(filename as string):
		return if filename.StartsWith('*')
		var lName = "Sprites\\$filename.png"
		unless _images.Contains(filename):
			_images.AddSpriteFromArchive(lName, filename, SPRITE_SIZE, null)

	protected def CreateViewport(map as TRpgMap, center as SgPoint) as GPU_Rect:
		screensize as SgPoint = _canvas.Size / TILE_SIZE
		center = (center / TILE_SIZE) - (screensize / 2.0)
		unless (TWraparound.Horizontal in map.Wraparound):
			if center.x < 0:
				center.x = 0
			elif (center.x + screensize.x) >= map.Size.x:
				center.x = (map.Size.x - (screensize.x / 2)) - 1
		unless (TWraparound.Vertical in map.Wraparound):
			if center.y < 0:
				center.y = 0
			elif (center.y + screensize.y) >= map.Size.y:
				center.y = (map.Size.y - (screensize.y / 2)) - 1
		return GPU_MakeRect(center.x, center.y, screensize.x, screensize.y)

	private def DisposeRenderTargets():
		for target in GRenderTargets:
			target.Dispose()
		GRenderTargets.Clear()

	protected def CanvasResize(sender as SdlCanvas):
		DisposeRenderTargets
		for i in range(6):
			GRenderTargets.Add(SdlRenderTarget(_canvas.Size))

	protected def LoadMapSprites(map as TRpgMap):
		for mapObj in map.MapObjects:
			continue if mapObj.ID == 0
			for page in mapObj.Pages:
				LoadSprite(page.Name) unless page.IsTile
		GEnvironment.value.CheckVehicles()

	protected def DoneLoadingMap() as bool:
		_currentMap = _waitingMapEngine
		_waitingMapEngine = null
		_currentMap.OnPartySpriteChanged = self.UpdatePartySprite
		_currentMap.OnDrawWeather = self.DrawWeather
		if _imageEngine == null:
			_imageEngine = TImageEngine(_currentMap, _canvas, _images)
			GEnvironment.value.CreateTimers()
		GSpriteEngine.value = _currentMap
		LoadMapSprites(_currentMap.MapObj)
		_objectManager.LoadMap(_waitingMap)
		_objectManager.Tick() if _playing
		_currentMap.Dead()
		return _signal.WaitOne(Timeout.Infinite)

	protected def PrepareMap(data as IMapMetadata):
		_timer.Enabled = false
		raise RpgPluginException("Can't load a map on an uninitialized map engine.") unless FInitialized
		GEnvironment.value.ClearEvents()
		var map = data as TMapMetadata
		raise RpgPluginException('Incompatible metadata object.') unless assigned(map)
		unless _heldMaps.TryGetValue(data.ID, _waitingMap):
			_waitingMap = dmDatabase.value.LoadMap(data)
		_scrollPosition = map.ScrollPosition

	protected def InitializeParty():
		party as TRpgParty = GEnvironment.value.Party
		for i in range(_database.Layout.StartingHeroes.Length):
			party[i + 1] = GEnvironment.value.Heroes[_database.Layout.StartingHero[i + 1]]
		_partySprite.Dispose() if _partySprite is not null
		_partySprite = THeroSprite(_currentMap, party[1], party)

	private _frame as int

	private _heartbeat as int

	[Property(EnterLock)]
	private _enterLock as bool

	private _saveLock as bool

	private _cutscene as int

	private def OnTimer():
		return if _gameState == TGameState.Cleanup
		++_frame
		Timestamp.NewFrame()
		lock _renderPauseLock:
			caseOf _gameState:
				case T2kMapEngine.TGameState.Title: RenderTitle()
				case T2kMapEngine.TGameState.Playing: RenderPlaying()
				case T2kMapEngine.TGameState.GameOver: RenderGameOver()
		if _frame > _heartbeat:
			_currentMap.AdvanceFrame() if assigned(_currentMap)
			_frame = 0
		_timer.Process()
		_currentMap.Dead() if assigned(_currentMap)

	private def StandardRender():
		return if _switchState == SwitchState.Switching
		caseOf GMenuEngine.Value.State:
			case TMenuState.None, TMenuState.Shared, TMenuState.ExclusiveShared: _currentMap.Draw()
			case TMenuState.Full:
				pass
		_switchState = SwitchState.Switching if _switchState == SwitchState.Ready
			

	private def RenderImages():
		_imageEngine.Draw() if assigned(_imageEngine)

	private def OnProcess():
		return if _switchState != SwitchState.NoSwitch
		_buttonState = ReadKeyboardState()
		for button in _buttonState.Values():
			PressButton(button)
		if _saveLock:
			_saveLock = KeyIsPressed(Keys.F2) or KeyIsPressed(Keys.F6)
		else:
			if KeyIsPressed(Keys.F2):
				Quicksave()
				_saveLock = true
			elif KeyIsPressed(Keys.F6):
				Quickload()
				_saveLock = true
		if _gameState == T2kMapEngine.TGameState.Playing:
			GMapObjectManager.value.Tick()
			_currentMap.Process() if _playing

	private def PressButton(button as TButtonCode):
		return if _enterLock and (button in (TButtonCode.Enter, TButtonCode.Cancel))
		if _gameState == T2kMapEngine.TGameState.GameOver:
			TitleScreen() if button == TButtonCode.Enter
			return
		caseOf GMenuEngine.Value.State:
			case TMenuState.None:
				if _cutscene > 0:
					return
				elif (button == TButtonCode.Cancel) and GEnvironment.value.MenuEnabled:
					_enterLock = true
					PlaySystemSound(TSfxTypes.Accept)
					OpenMenu() //async method, not awaiting, on purpose
				elif assigned(_partySprite):
					PartyButton(button)
			case TMenuState.Shared, TMenuState.ExclusiveShared, TMenuState.Full:
				GMenuEngine.Value.Button(button)
				_enterLock = true

	private def PartyButton(Button as TButtonCode):
		System.Threading.Monitor.Enter(GMoveLock) if Button in (TButtonCode.Up, TButtonCode.Right, TButtonCode.Down, TButtonCode.Left)
		try:
			caseOf Button:
				case TButtonCode.Enter:
					_enterLock = true
					lock GEventLock:
						_partySprite.Action(TButtonCode.Enter)
				case TButtonCode.Up: _partySprite.Move(TDirections.Up)
				case TButtonCode.Down: _partySprite.Move(TDirections.Down)
				case TButtonCode.Left: _partySprite.Move(TDirections.Left)
				case TButtonCode.Right: _partySprite.Move(TDirections.Right)
		ensure:
			System.Threading.Monitor.Exit(GMoveLock) if Button in (TButtonCode.Up, TButtonCode.Right, TButtonCode.Down, TButtonCode.Left)

	private def PlayMapMusic(metadata as TMapMetadata, Clear as bool):
		var id = metadata.ID
		caseOf metadata.BgmState:
			case TInheritedDecision.Parent:
				until id == 0 or (_database.MapTree[id] cast TMapMetadata).BgmState != TInheritedDecision.Parent:
					id = _database.MapTree[id].Parent
				if id == 0:
					StopMusic()
				elif (_database.MapTree[id] cast TMapMetadata).BgmState == TInheritedDecision.Yes:
					PlayMusicData((_database.MapTree[id] cast TMapMetadata).BgmData)
			case TInheritedDecision.No:
				FadeOutMusic(1000) if Clear
			case TInheritedDecision.Yes: PlayMusicData((_database.MapTree[id] cast TMapMetadata).BgmData)

	private def DrawRenderTarget(target as SdlRenderTarget, canTint as bool):
		glCheckError()
		color = GPU_GetColor(target.Image)
		GPU_SetRGBA(target.Image, 255, 255, 255, 255)
		unless (canTint and _currentMap.Fade()):
			//_shaderEngine.UseShaderProgram(_shaderEngine.ShaderProgram('default', 'defaultF'))
			GPU_DeactivateShaderProgram()
		target.DrawFull()
		GPU_SetColor(target.Image, color)
		GPU_DeactivateShaderProgram()

	private def CopyMain():
		DrawRenderTarget(GRenderTargets[RENDERER_MAIN], true)

	private def RenderFrame():
		GRenderTargets.RenderOn(RENDERER_MAP, StandardRender, 0, true, false)
		DrawRenderTarget(GRenderTargets[RENDERER_MAP], true)
		//_shaderEngine.UseShaderProgram(_shaderEngine.ShaderProgram('default', 'defaultF'))
		GPU_DeactivateShaderProgram()
		RenderImages()
		_currentMap.DrawFlash()
		if GMenuEngine.Value.State != TMenuState.None:
			GMenuEngine.Value.Draw()
		GPU_DeactivateShaderProgram()

	private def DrawWeather():
		_weatherEngine.Draw()

	private def RenderGameOver():
		image as TSdlImage
		preserving _images.SpriteClass:
			_images.SpriteClass = classOf(TSdlOpaqueImage)
			var imagename = "Special Images\\$(GDatabase.value.Layout.GameOverScreen).png"
			image = _images.EnsureImage(imagename, '*GameOver', SgPoint(GDatabase.value.Layout.Width, GDatabase.value.Layout.Height))
		GPU_SetBlending(image.Surface, 0)
		image.Draw()
		_canvas.Flip()
		_timer.Process()

	private def RenderPlaying():
		if _renderPause?.TimeRemaining == 0:
			_renderPause = null
		if _renderPause == null:
			_canvas.Clear()
			var valid = true
			if assigned(_transition):
				valid = false
				unless _transitionFirstFrameDrawn:
					GRenderTargets.RenderOn(RENDERER_ALT, RenderFrame, 0, true, false)
					_transitionFirstFrameDrawn = true
				unless _transition.Draw():
					_transitionFirstFrameDrawn = false
					_transition = null
					valid = true
			if valid:
				if _currentMap.Blank:
					GRenderTargets.RenderOn(RENDERER_MAIN, null, 0, true, false)
				else: GRenderTargets.RenderOn(RENDERER_MAIN, RenderFrame, 0, true, false)
				DrawRenderTarget(GRenderTargets[RENDERER_MAIN], false)
			_canvas.Flip()

	private def RenderTitle():
		if GMenuEngine.Value.State == TMenuState.None:
			GMenuEngine.Value.OpenMenu('Title')
		GMenuEngine.Value.Draw()
		_canvas.Flip()
		_timer.Process()

	protected FDatabaseOwner as bool

	[Async]
	protected override def Cleanup() as Task:
		assert FInitialized
		FInitialized = false
		_gameState = TGameState.Cleanup
		if FDatabaseOwner:
			await(_objectManager.ScriptEngine.KillAll(null)) if _objectManager is not null
			GMenuEngine.Value.Dispose()
		_shaderEngine.Dispose() if assigned(_shaderEngine)
		_partySprite.Dispose() if assigned(_partySprite)
		_canvas = null
		_images.Dispose() if assigned(_images)
		_signal = null
		_imageEngine.Dispose() if assigned(_imageEngine)
		if FDatabaseOwner:
			GEnvironment.value.CleanupImages()
		_weatherEngine.Dispose()
		_currentMap.Dispose() if assigned(_currentMap)
		_timer.Dispose()
		if FDatabaseOwner:
			GEnvironment.value.Dispose()
			GEnvironment.value = null
			GGameEngine.value = null
			_database = null
			GDatabase.value = null
			dmDatabase.value = null
			_objectManager = null
			GMapObjectManager.value = null
			GScriptEngine.value = null
			GFontEngine.Dispose()
			DisposeRenderTargets()
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
				_database = TRpgDatabase(dmDatabase.value)
				GDatabase.value = _database
				unless assigned(_database):
					raise RpgPluginException('Incompatible project database')
				_objectManager = TMapObjectManager(self.ClearHeldMaps)
				GScriptEngine.value.OnEnterCutscene = self.EnterCutscene
				GScriptEngine.value.OnLeaveCutscene = self.LeaveCutscene
				GScriptEngine.value.OnRenderUnpause = self.RenderUnpause
				GEnvironment.value = T2kEnvironment(_database)
				dmDatabase.value.RegisterEnvironment(GEnvironment.value)
				_database.LoadGlobalEvents(dmDatabase.value.MapLoader)
				_objectManager.LoadGlobalScripts(_database.GlobalEvents)
				_objectManager.OnUpdate = GEnvironment.value.UpdateEvents
			else:
				_database = GDatabase.value
				_objectManager = GMapObjectManager.value
			layout = _database.Layout
			if window == IntPtr.Zero:
				window = SDL.SDL_CreateWindow("TURBU engine - _database.MapTree[0].Name",
					SDL.SDL_WINDOWPOS_CENTERED_MASK, SDL.SDL_WINDOWPOS_CENTERED_MASK, layout.PhysWidth, layout.PhysHeight,
					SDL.SDL_WindowFlags.SDL_WINDOW_OPENGL | SDL.SDL_WindowFlags.SDL_WINDOW_SHOWN)
				if window == IntPtr.Zero:
					raise RpgPluginException("Unable to initialize SDL window: \r\n$(SDL.SDL_GetError())")
			winID = SDL.SDL_GetWindowID(window)
			_renderer = GPU_GetWindowTarget(winID)
			if _renderer.Pointer == IntPtr.Zero:
				GPU_SetInitWindow(winID)
				_renderer = GPU_Init(0, 0, 0)
				if _renderer == IntPtr.Zero:
					raise RpgPluginException("Unable to initialize SDL_GPU renderer")
			_canvas = SdlCanvas.CreateFrom(window)
			_canvas.OnResize = self.CanvasResize
			_stretchRatio.x = (layout.PhysWidth cast double) / (layout.Width cast double)
			_stretchRatio.y = (layout.PhysHeight cast double) / (layout.Height cast double)
			GPU_SetVirtualResolution(_renderer.Pointer, layout.Width, layout.Height)
			_canvas.Resize()
			_images = SdlImages(true, null)
			_images.ArchiveLoader = ALoader
			_images.SpriteClass = classOf(TRpgSdlImage)
			_weatherEngine = TWeatherSystem(null, _images, _canvas)
			_signal = EventWaitHandle(true, EventResetMode.ManualReset)
			_shaderEngine = TdmShaders()
			if FDatabaseOwner:
				GFontEngine.Initialize(_shaderEngine)
				GFontEngine.Current = TRpgFont('RMG2000.fon', 7)
				GMenuEngine.Value = TMenuSpriteEngine(TSystemImages(_images, layout.SysGraphic, layout.WallpaperStretch, layout.TranslucentMessages), _canvas, _images)
				for trn in range(TTransitionTypes.BattleEndShow + 1):
					TURBU.RM2K.RPGScript.SetTransition(trn, layout.Transition[trn] + 1)
				for sfx in range(TSfxTypes.ItemUsed + 1):
					SetSystemSoundData(sfx, _database.Sfx[sfx])
				for bgm in range(TBgmTypes.BossBattle + 1):
					SetSystemMusicData(bgm, _database.Bgm[bgm])
			_timer = AsphyreTimer(60, self.OnTimer) if _timer is null
		failure:
			Cleanup()
		return window

	private def ClearHeldMaps():
		for map as IDisposable in _heldMaps.Values:
			map.Dispose()
		_heldMaps.Clear()

	public override def LoadMap(map as IMapMetadata):
		_currentMap = null
		PrepareMap(map)
		viewport as GPU_Rect = CreateViewport(_waitingMap, _scrollPosition)
		if assigned(_waitingMapEngine):
			_waitingMapEngine.ReloadMapObjects()
		else:
			EnsureTileset(_waitingMap.Tileset)
			_waitingMapEngine = T2kSpriteEngine(_waitingMap, viewport, _shaderEngine, _canvas, 
				_database.Tileset[_waitingMap.Tileset], _images)
		unless DoneLoadingMap():
			raise Exception('Error loading map')

	public def LoadMap(id as int):
		try:
			if id != GEnvironment.value.Party.MapID:
				LoadMap(GDatabase.value.MapTree[id])
		except:
			raise Exception("Invalid map ID: $id")

	public override def Play():
		assert assigned(_currentMap)
		InitializeParty() if _partySprite is null
		_timer.Enabled = true
		_playing = true

	public override def Playing() as bool:
		return _timer.Enabled

	public override def MapTree() as IMapTree:
		return _database.MapTree

	public override def NewGame():
		assert _playing == false
		_gameState = T2kMapEngine.TGameState.Playing
		loc as TLocation = (_database.MapTree cast TMapTree).Location[0]
		metadata as TMapMetadata = _database.MapTree[loc.map]
		self.LoadMap(metadata)
		InitializeParty()
		_partySprite.LeaveTile()
		_currentMap.CurrentParty = _partySprite
		_partySprite.Location = SgPoint(loc.x, loc.y)
		PlayMapMusic(metadata, true)
		self.Play()

	public override def Start():
		_timer.OnProcess += self.OnProcess
		TitleScreen()
		_timer.Enabled = true

	public def ChangeMaps(newmap as int, newLocation as SgPoint):
		assert newmap != _currentMap.MapID
		currentMap as T2kSpriteEngine = _currentMap
		_switchState = SwitchState.Ready
		self._heldMaps[currentMap.MapObj.ID] = currentMap.MapObj
		currentMap.ReleaseMap()
		_objectManager.ScriptEngine.KillAll({ currentMap = null; return })
		assert _currentMap.Blank
		metadata as TMapMetadata
		oldEngine as T2kSpriteEngine = _currentMap
		hero as TCharSprite = _currentMap.CurrentParty
		if assigned(hero):
			(hero cast THeroSprite).PackUp()
		metadata = _database.MapTree[newmap]
		GC.Collect()
		self.LoadMap(metadata)
		unless GEnvironment.value.PreserveSpriteOnTeleport:
			GEnvironment.value.Party.ResetSprite()
		_currentMap.CurrentParty = hero
		_currentMap.CopyState(oldEngine)
		if assigned(hero):
			hero.Location = newLocation
			(hero cast THeroSprite).settleDown(_currentMap)
		_imageEngine.ParentEngine = _currentMap
		oldEngine.Dispose()
		_currentMap.CenterOn(newLocation.x, newLocation.y)
		PlayMapMusic(metadata, false)
		_switchState = SwitchState.NoSwitch
		_timer.Enabled = true

	public def LoadRpgImage(filename as string, mask as bool):
		oName as string = filename
		Abort unless ArchiveUtils.GraphicExists(filename, 'pictures')
		cls as TSdlImageClass = _images.SpriteClass
		_images.SpriteClass = classOf(TSdlImage)
		try:
			image as TSdlImage = _images.EnsureImage('pictures/' + filename, oName)
			GPU_SetBlending(image.Surface, (1 if mask else 0))
		ensure:
			_images.SpriteClass = cls

	public virtual def TitleScreen():
		_gameState = T2kMapEngine.TGameState.Title
		StopPlaying()
		PlaySystemMusic(TBgmTypes.Title)

	public virtual def GameOver():
		_gameState = T2kMapEngine.TGameState.GameOver
		StopPlaying()
		PlaySystemMusic(TBgmTypes.GameOver)
		Abort

	public def EnterCutscene():
		GMapObjectManager.value.InCutscene = true
		++_cutscene

	public def LeaveCutscene():
		raise 'Mismatched call to T2kMapEngine.LeaveCutscene' if _cutscene <= 0
		--_cutscene
		GMapObjectManager.value.InCutscene = _cutscene != 0

	public def ReadKeyboardState() as TButtonCode:
		result = TButtonCode.None
		result |= TButtonCode.Left if KeyIsPressed(Keys.Left)
		result |= TButtonCode.Right if KeyIsPressed(Keys.Right)
		result |= TButtonCode.Up if KeyIsPressed(Keys.Up)
		result |= TButtonCode.Down if KeyIsPressed(Keys.Down)
		result |= TButtonCode.Enter if KeyIsPressed(Keys.Return)
		result |= TButtonCode.Cancel if KeyIsPressed(Keys.Escape) or KeyIsPressed(Keys.Insert)
		_enterLock = false if result & (TButtonCode.Enter | TButtonCode.Cancel) == TButtonCode.None
		return result

	public def EnsureTileset(id as int) as bool:
		result = _database.Tileset.ContainsKey(id)
		unless result:
			try:
				LoadTileset(_database.Tileset[id])
				result = true
			except:
				pass
		return result

	public def RenderPause():
		lock _renderPauseLock:
			_renderPause = Timestamp(50)

	public def RenderUnpause():
		lock _renderPauseLock:
			_renderPause = null

	public def Load(savefile as string) as bool:
		return false unless File.Exists(savefile)
		
		_timer.Enabled = false
		GScriptEngine.value.KillAll(null)
#		GEnvironment.value.Dispose()
#		GEnvironment.value = null
		GSpriteEngine.value = null
#		GEnvironment.value = T2kEnvironment(_database)
#		dmDatabase.value.RegisterEnvironment(GEnvironment.value)
#		_objectManager.OnUpdate = GEnvironment.value.UpdateEvents
		_playing = false
		var oldMap = _currentMap
		_currentMap = null
		GMenuEngine.Value.Reset()
		turbu.RM2K.savegames.Load(savefile, self.InitializeParty)
		_currentMap.CurrentParty = (GEnvironment.value.Party.Sprite cast TCharSprite)
		if oldMap is not null:
			oldMap.Dispose()
		if _imageEngine is null:
			_imageEngine = TImageEngine(GSpriteEngine.value, _canvas, _images)
		else: _imageEngine.ParentEngine = _currentMap
		GEnvironment.value.CreateTimers()
		GC.Collect()
		GMapObjectManager.value.InCutscene = false
		_gameState = T2kMapEngine.TGameState.Playing
		Play()
		return true

	public Transition as ITransition:
		get: return _transition
		set:
			_transition = value
			_transitionFirstFrameDrawn = false
			RenderUnpause()

	private static def ALoader(filename as string) as string:
		return Path.Combine(GArchives[IMAGE_ARCHIVE].Root, filename)
	
	public def RegisterDataReader(value as IDataReader):
		_reader = value

static class GGameEngine:
	public value as T2kMapEngine

[DllImport("USER32.dll")]
static internal def GetAsyncKeyState(vKey as Keys) as short:
	pass

internal def KeyIsPressed(value as Keys) as bool:
	result = GetAsyncKeyState(value) 
	return result != 0
