namespace TURBU.RM2K.RPGScript

import turbu.defs
import turbu.script.engine
import commons
import sdl.sprite
import turbu.constants
import TURBU.Meta
import TURBU.RM2K
import turbu.animations
import turbu.maps
import turbu.pathing
import timing
import SG.defs
import Boo.Adt
import Pythia.Runtime
import turbu.mapchars
import turbu.RM2K.images
import turbu.RM2K.animations
import System
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import TURBU.RM2K.MapEngine
import turbu.RM2K.CharSprites
import turbu.map.sprites
import turbu.RM2K.transitions
import System.Drawing
import System.Threading

def Teleport(MapID as int, x as int, y as int, facing as int):
	newpoint as TSgPoint
	unless Monitor.TryEnter(LTeleportLock):
		GScriptEngine.value.AbortThread()
	try:
		EraseScreen(TTransitions.Default)
		while GSpriteEngine.value.State == TGameState.Fading:
			Thread.Sleep(TRpgTimestamp.FrameLength)
		if MapID == GSpriteEngine.value.MapID:
			newpoint = sgPoint(x, y)
			if GSpriteEngine.value.OnMap(newpoint):
				runThreadsafe(true) def ():
					unless GEnvironment.value.PreserveSpriteOnTeleport:
						GEnvironment.value.Party.ResetSprite()
					GEnvironment.value.Party.Sprite.LeaveTile()
					GEnvironment.value.Party.Sprite.Location = newpoint
					GSpriteEngine.value.CenterOn(x, y)
		else: GGameEngine.value.ChangeMaps(MapID, sgPoint(x, y))
		ShowScreen(TTransitions.Default)
	ensure:
		System.Threading.Monitor.Exit(LTeleportLock)

def TeleportVehicle(which as TRpgVehicle, map as int, x as int, y as int):
	newpoint as Point
	if (which.Gamesprite == GEnvironment.value.Party.Sprite) and (map != GSpriteEngine.value.MapID):
		return
	newpoint = sgPoint(x, y)
	if GSpriteEngine.value.OnMap(newpoint):
		which.Gamesprite.LeaveTile()
		which.Map = map
		which.Location = newpoint

def TeleportMapObject(which as TRpgEvent, x as int, y as int):
	newpoint as TSgPoint
	newpoint = sgPoint(x, y)
	if GSpriteEngine.value.OnMap(newpoint):
		which.Location = newpoint

def MemorizeLocation(map as int, x as int, y as int):
	if not assigned(GEnvironment.value.Party):
		GEnvironment.value.Ints[map] = 0
		GEnvironment.value.Ints[x] = 0
		GEnvironment.value.Ints[y] = 0
	else:
		GEnvironment.value.Ints[map] = GGameEngine.value.CurrentMap.MapID
		GEnvironment.value.Ints[x] = GEnvironment.value.Party.Sprite.Location.x
		GEnvironment.value.Ints[y] = GEnvironment.value.Party.Sprite.Location.y

def SwapMapObjects(first as TRpgEvent, second as TRpgEvent):
	swapper as TSgPoint
	first.Base.LeaveTile()
	second.Base.LeaveTile()
	swapper = first.Location
	first.Location = second.Location
	second.Location = swapper

def RideVehicle():
	if GEnvironment.value.Party.Sprite isa THeroSprite:
		(GEnvironment.value.Party.Sprite cast THeroSprite).BoardVehicle()
	else:
		(GEnvironment.value.Party.Sprite cast TVehicleSprite).State = TVehicleState.Landing

def GetTerrainID(x as int, y as int) as int:
	if (x > GGameEngine.value.CurrentMap.Width) or (y > GGameEngine.value.CurrentMap.Height):
		result = 0
	else:
		result = GGameEngine.value.CurrentMap.GetTile(x, y, 0).Terrain
	return result

def GetObjectID(x as int, y as int) as int:
	events as (TMapSprite)
	result = 0
	if (x > GGameEngine.value.CurrentMap.Width) or (y > GGameEngine.value.CurrentMap.Height):
		return result
	events = GGameEngine.value.CurrentMap.GetTile(x, y, 0).Event
	for Event in events:
		if (Event isa TEventSprite) or \
			((Event isa TCharSprite and (not (Event isa TVehicleSprite))) and (not (Event isa THeroSprite))):
			result = Event.Event.ID
	return result

def SetTransition(which as TTransitionTypes, newTransition as TTransitions):
	if newTransition == TTransitions.Default:
		return
	LDefaultTransitions[which] = newTransition

def EraseScreen(whichTransition as TTransitions):
	if whichTransition == TTransitions.Default:
		turbu.RM2K.transitions.erase(LDefaultTransitions[TTransitionTypes.MapExit])
	else:
		turbu.RM2K.transitions.erase(whichTransition)
	GScriptEngine.value.SetWaiting(waitForBlank)

def ShowScreen(whichTransition as TTransitions):
	if whichTransition == TTransitions.Default:
		turbu.RM2K.transitions.show(LDefaultTransitions[TTransitionTypes.MapEnter])
	else:
		turbu.RM2K.transitions.show(whichTransition)
	GScriptEngine.value.SetWaiting(waitForFadeEnd)

def EraseScreenDefault(whichTransition as TTransitionTypes):
	EraseScreen(LDefaultTransitions[whichTransition])
	unless TThread.CurrentThread.IsMainThread:
		GScriptEngine.value.ThreadWait()

def ShowScreenDefault(whichTransition as TTransitionTypes):
	ShowScreen(LDefaultTransitions[whichTransition])
	unless TThread.CurrentThread.IsMainThread:
		GScriptEngine.value.ThreadWait()

def TintScreen(r as int, g as int, b as int, sat as int, duration as int, wait as bool):
	def convert(number as int) as int:
		return round(clamp(number, 0, 200) * 2.55)
	
	r2 as int = convert(r)
	g2 as int = convert(g)
	b2 as int = convert(b)
	s2 as int = convert(sat)
	GSpriteEngine.value.FadeTo(r2, g2, b2, s2, duration)
	if wait:
		GScriptEngine.value.ThreadSleep(Math.Max(duration * 100, TRpgTimestamp.FrameLength), true)

def FlashScreen(r as int, g as int, b as int, power as int, duration as int, wait as bool, continuous as bool):
	GSpriteEngine.value.FlashScreen(r, g, b, power, duration)
	if wait:
		GScriptEngine.value.ThreadSleep(Math.Max(duration * 100, TRpgTimestamp.FrameLength), true)
	if continuous:
		pass //TODO: Implement this

def EndFlashScreen():
	GSpriteEngine.value.FlashScreen(0, 0, 0, 0, 0)

def ShakeScreen(power as int, Speed as int, duration as int, wait as bool, continuous as bool):
	GSpriteEngine.value.ShakeScreen(power, Speed, duration * 100)
	if wait:
		GScriptEngine.value.ThreadSleep(Math.Max(duration * 100, TRpgTimestamp.FrameLength), true)

def EndShakeScreen():
	GSpriteEngine.value.ShakeScreen(0, 0, 0)

def LockScreen():
	GSpriteEngine.value.ScreenLocked = true

def UnlockScreen():
	GSpriteEngine.value.ScreenLocked = false

def PanScreen(direction as TFacing, distance as int, speed as int, wait as bool):
	halfwidth as int = GSpriteEngine.value.Canvas.Width / 2
	halfheight as int = GSpriteEngine.value.Canvas.Height / 2
	x as int = Math.Truncate((GSpriteEngine.value.WorldX + halfwidth) / TILE_SIZE.x)
	y as int = commons.round((GSpriteEngine.value.WorldY + halfheight) / TILE_SIZE.y)
	caseOf direction:
		case TFacing.Up:
			y -= distance
		case TFacing.Right:
			x += distance
		case TFacing.Down:
			y += distance
		case TFacing.Left:
			x -= distance
	PanScreenTo(x, y, speed, wait)

def PanScreenTo(x as int, y as int, speed as int, wait as bool):
	GSpriteEngine.value.DisplaceTo(x * TILE_SIZE.x, y * TILE_SIZE.y)
	GSpriteEngine.value.SetDispSpeed(speed)
	if wait:
		GScriptEngine.value.SetWaiting(waitForPanEnd)

def ReturnScreen(speed as int, wait as bool):
	GSpriteEngine.value.Returning = true
	PanScreenTo(GEnvironment.value.Party.XPos, GEnvironment.value.Party.YPos, speed, wait)

def SetWeather(effect as TWeatherEffects, severity as int):
	GGameEngine.value.WeatherEngine.WeatherType = effect
	GGameEngine.value.WeatherEngine.Intensity = clamp(severity, 0, MAX_WEATHER)

def IncreaseWeather():
	if GGameEngine.value.WeatherEngine.Intensity < MAX_WEATHER:
		SetWeather(GGameEngine.value.WeatherEngine.WeatherType, (GGameEngine.value.WeatherEngine.Intensity + 1))

def DecreaseWeather():
	if GGameEngine.value.WeatherEngine.Intensity > 0:
		SetWeather(GGameEngine.value.WeatherEngine.WeatherType, (GGameEngine.value.WeatherEngine.Intensity - 1))

def NewImage(Name as string, x as int, y as int, zoom as int, transparency as int, pinned as bool, mask as bool) as TRpgImage:
	image as TRpgImage
	runThreadsafe(true) def():
		try:
			GGameEngine.value.LoadRpgImage(Name, mask)
			image = TRpgImage(GGameEngine.value.ImageEngine, Name, x, y, GSpriteEngine.value.WorldX, GSpriteEngine.value.WorldY, zoom, pinned, mask)
			image.Opacity = (100 - Math.Min(transparency, 100))
		except:
			image = TRpgImage(GSpriteEngine.value, '', 0, 0, 0, 0, 0, false, false)
	return image

def SetBGImage(Name as string, scrollX as int, scrollY as int, autoX as TMapScrollType, autoY as TMapScrollType):
	commons.runThreadsafe(false, { GSpriteEngine.value.SetBG(Name, scrollX, scrollY, autoX, autoY) })

def ShowBattleAnim(which as int, target as TRpgCharacter, wait as bool, fullscreen as bool):
	signal as EventWaitHandle
	if wait:
		signal = EventWaitHandle(false, EventResetMode.ManualReset)
	else:
		signal = null
	commons.runThreadsafe(true, { ShowBattleAnimT(GGameEngine.value.ImageEngine, which, CreateTarget(target), fullscreen, signal) })
	if wait:
		GScriptEngine.value.SetWaiting({ signal.WaitOne(0) })

def ShowBattleAnimT(engine as TSpriteEngine, which as int, target as IAnimTarget, fullscreen as bool, signal as EventWaitHandle):
	template as TAnimTemplate = GDatabase.value.Anim[which]
	return if template == null
	try:
		LoadAnim(template.Filename)
	except:
		return
	TAnimSprite(engine, template, target, fullscreen, signal)

def WaitUntilMoved():
	GEnvironment.value.Party.Sprite.CheckMoveChange()
	for i in range(1, (GEnvironment.value.MapObjectCount + 1)):
		if assigned(GEnvironment.value.MapObject[i]):
			GEnvironment.value.MapObject[i].Base.CheckMoveChange()
	GScriptEngine.value.SetWaiting(AllMoved)

def StopMoveScripts():
	for i in range(1, (GEnvironment.value.MapObjectCount + 1)):
		GEnvironment.value.MapObject[i].Base.Stop()
	for i in range(1, (GEnvironment.value.VehicleCount + 1)):
		if assigned(GEnvironment.value.Vehicle[i]):
			GEnvironment.value.Vehicle[i].Base.Stop()
	GEnvironment.value.Party.Base.Stop()

def ChangeTileset(which as int):
	runThreadsafe(true) def ():
		if GGameEngine.value.EnsureTileset(which):
			GSpriteEngine.value.ChangeTileset(GDatabase.value.Tileset[which])

def RenderPause():
	GGameEngine.value.RenderPause()

private def waitForBlank() as bool:
	return GGameEngine.value.CurrentMap.Blank

private def waitForFadeEnd() as bool:
	return GSpriteEngine.value.State != TGameState.Fading

private def waitForPanEnd() as bool:
	return not GSpriteEngine.value.Displacing

private def LoadAnim(filename as string):
	GSpriteEngine.value.Images.EnsureImage("Animations\\$filename.png", 'Anim ' + filename)

private class TCharacterTarget(TObject, IAnimTarget):

	private FTarget as TRpgCharacter

	def position(sign as int) as TSgPoint:
		result as TSgPoint
		assert sign >= -1 and sign <= 1
		result.x = FTarget.ScreenXP + (FTarget.Base.Tiles[1].Width / 2)
		result.y = FTarget.ScreenYP + (FTarget.Base.Tiles[1].Height * sign)
		return result

	def Flash(r as int, g as int, b as int, power as int, time as int):
		FTarget.Flash(r, g, b, power, time, false)

	public def constructor(target as TRpgCharacter):
		FTarget = target

private def CreateTarget(target as TRpgCharacter) as IAnimTarget:
	return (null if target == null else TCharacterTarget(target))

private def AllMoved() as bool:
	partyMove as Path = GEnvironment.value.Party.Sprite.MoveOrder
	result = not (partyMove is null or partyMove.Looped)
	i = 0
	while result and (i <= GEnvironment.value.MapObjectCount):
		++i
		obj as TRpgEvent = GEnvironment.value.MapObject[i]
		if assigned(obj) and assigned(obj.Base.MoveOrder):
			result = obj.Base.MoveOrder.Looped

let MAX_WEATHER = 10
let LTeleportLock = object()
let LDefaultTransitions = array(TTransitions, Enum.GetValues(TTransitionTypes).Length);