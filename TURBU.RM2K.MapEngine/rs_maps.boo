namespace TURBU.RM2K.RPGScript

import System
import System.Threading
import System.Threading.Tasks

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
import SG.defs
import Boo.Adt
import Pythia.Runtime
import turbu.mapchars
import turbu.RM2K.images
import turbu.RM2K.animations
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import TURBU.RM2K.MapEngine
import turbu.RM2K.CharSprites
import turbu.map.sprites
import turbu.RM2K.transitions
import Newtonsoft.Json
import Newtonsoft.Json.Linq

[async]
def Teleport(mapID as int, x as int, y as int) as Task:
	await Teleport(mapID, x, y, 0)

[async]
def Teleport(mapID as int, x as int, y as int, facing as int) as Task:
	unless Monitor.TryEnter(LTeleportLock):
		Abort
	try:
		GScriptEngine.value.BeginTeleport()
		await EraseScreen(TTransitions.Default)
		while GSpriteEngine.value.State == TGameState.Fading:
			await GScriptEngine.value.FramePause()
		if mapID == GSpriteEngine.value.MapID:
			var newpoint = SgPoint(x, y)
			if GSpriteEngine.value.OnMap(newpoint):
				unless GEnvironment.value.PreserveSpriteOnTeleport:
					GEnvironment.value.Party.ResetSprite()
				GEnvironment.value.Party.Sprite.LeaveTile()
				GEnvironment.value.Party.Sprite.Location = newpoint
				GSpriteEngine.value.CenterOn(x, y)
		else:
			GGameEngine.value.ChangeMaps(mapID, SgPoint(x, y))
		await ShowScreen(TTransitions.Default)
	ensure:
		System.Threading.Monitor.Exit(LTeleportLock)
		GScriptEngine.value.EndTeleport()

def TeleportVehicle(which as TRpgVehicle, map as int, x as int, y as int):
	if (which.Gamesprite == GEnvironment.value.Party.Sprite) and (map != GSpriteEngine.value.MapID):
		return
	var newpoint = SgPoint(x, y)
	if GSpriteEngine.value.OnMap(newpoint):
		which.Gamesprite.LeaveTile()
		which.Map = map
		which.Location = newpoint

def TeleportMapObject(which as TRpgEvent, x as int, y as int):
	var newpoint = SgPoint(x, y)
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
	swapper as SgPoint
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

[async]
def EraseScreen(whichTransition as TTransitions) as Task:
	if whichTransition == TTransitions.Default:
		turbu.RM2K.transitions.Erase(LDefaultTransitions[TTransitionTypes.MapExit])
	else:
		turbu.RM2K.transitions.Erase(whichTransition)
	waitFor WaitForBlank

[async]
def ShowScreen(whichTransition as TTransitions) as Task:
	if whichTransition == TTransitions.Default:
		turbu.RM2K.transitions.Show(LDefaultTransitions[TTransitionTypes.MapEnter])
	else:
		turbu.RM2K.transitions.Show(whichTransition)
	waitFor WaitForFadeEnd

[async]
def EraseScreenDefault(whichTransition as TTransitionTypes) as Task:
	await EraseScreen(LDefaultTransitions[whichTransition])

[async]
def ShowScreenDefault(whichTransition as TTransitionTypes) as Task:
	await ShowScreen(LDefaultTransitions[whichTransition])

def TintScreen(r as int, g as int, b as int, sat as int, duration as int):
	def convert(number as int) as int:
		return round(clamp(number, 0, 200) * 2.55)
	
	r2 as int = convert(r)
	g2 as int = convert(g)
	b2 as int = convert(b)
	s2 as int = convert(sat)
	GSpriteEngine.value.FadeTo(r2, g2, b2, s2, duration)

[async]
def TintScreenAndWait(r as int, g as int, b as int, sat as int, duration as int) as Task:
	TintScreen(r, g, b, sat, duration)
	await GScriptEngine.value.Sleep(duration * 100, true)

def FlashScreen(r as int, g as int, b as int, power as int, duration as int, continuous as bool):
	GSpriteEngine.value.FlashScreen(r, g, b, power, duration)
	if continuous:
		pass //TODO: Implement this

[async]
def FlashScreenAndWait(r as int, g as int, b as int, power as int, duration as int) as Task:
	FlashScreen(r, g, b, power, duration, false)
	await GScriptEngine.value.Sleep(duration * 100, true)

def EndFlashScreen():
	GSpriteEngine.value.FlashScreen(0, 0, 0, 0, 0)

def ShakeScreen(power as int, speed as int, duration as int, continuous as bool):
	GSpriteEngine.value.ShakeScreen(power, speed, duration * 100)
	if continuous:
		pass //TODO: Implement this

[async]
def ShakeScreenAndWait(power as int, speed as int, duration as int) as Task:
	ShakeScreen(power, speed, duration, false)
	await GScriptEngine.value.Sleep(duration * 100, true)

def EndShakeScreen():
	GSpriteEngine.value.ShakeScreen(0, 0, 0)

def LockScreen():
	GSpriteEngine.value.ScreenLocked = true

def UnlockScreen():
	GSpriteEngine.value.ScreenLocked = false

def PanScreen(direction as TFacing, distance as int, speed as int):
	halfwidth as int = GSpriteEngine.value.Canvas.Width / 2
	halfheight as int = GSpriteEngine.value.Canvas.Height / 2
	var vp = GSpriteEngine.value.Viewport
	x as int = Math.Truncate((vp.WorldX + halfwidth) / TILE_SIZE.x)
	y as int = commons.round((vp.WorldY + halfheight) / TILE_SIZE.y)
	caseOf direction:
		case TFacing.Up:
			y -= distance
		case TFacing.Right:
			x += distance
		case TFacing.Down:
			y += distance
		case TFacing.Left:
			x -= distance

[async]
def PanScreenAndWait(direction as TFacing, distance as int, speed as int) as Task:
	PanScreen(direction, distance, speed)
	waitFor WaitForPanEnd

def PanScreenTo(x as int, y as int, speed as int):
	GSpriteEngine.value.DisplaceTo(x * TILE_SIZE.x, y * TILE_SIZE.y)
	GSpriteEngine.value.SetDispSpeed(speed)

[async]
def PanScreenToAndWait(x as int, y as int, speed as int) as Task:
	PanScreenTo(x, y, speed)
	waitFor WaitForPanEnd

def ReturnScreen(speed as int):
	GSpriteEngine.value.Returning = true
	PanScreenTo(GEnvironment.value.Party.XPos, GEnvironment.value.Party.YPos, speed)

[async]
def ReturnScreenAndWait(speed as int) as Task:
	ReturnScreen(speed)
	waitFor WaitForPanEnd

def SetWeather(effect as TWeatherEffects, severity as int):
	GGameEngine.value.WeatherEngine.WeatherType = effect
	GGameEngine.value.WeatherEngine.Intensity = clamp(severity, 0, MAX_WEATHER)

def IncreaseWeather():
	if GGameEngine.value.WeatherEngine.Intensity < MAX_WEATHER:
		SetWeather(GGameEngine.value.WeatherEngine.WeatherType, (GGameEngine.value.WeatherEngine.Intensity + 1))

def DecreaseWeather():
	if GGameEngine.value.WeatherEngine.Intensity > 0:
		SetWeather(GGameEngine.value.WeatherEngine.WeatherType, (GGameEngine.value.WeatherEngine.Intensity - 1))

def NewImage(name as string, x as int, y as int, zoom as int, transparency as int, pinned as bool, mask as bool) as TRpgImage:
	image as TRpgImage
	try:
		GGameEngine.value.LoadRpgImage(name, mask)
		var se = GSpriteEngine.value
		image = TRpgImage(GGameEngine.value.ImageEngine, name, x, y, se.Viewport.WorldX, se.Viewport.WorldY, zoom, pinned, mask)
		image.Opacity = 100 - Math.Min(transparency, 100)
	except:
		image = TRpgImage(GSpriteEngine.value, '', 0, 0, 0, 0, 0, false, false)
	return image

def SetBGImage(Name as string, scrollX as int, scrollY as int, autoX as TMapScrollType, autoY as TMapScrollType):
	GSpriteEngine.value.SetBG(Name, scrollX, scrollY, autoX, autoY)

def ShowBattleAnim(which as int, target as TRpgCharacter, fullscreen as bool):
	ShowBattleAnimT(GGameEngine.value.ImageEngine, which, CreateTarget(target), fullscreen, null)

[async]
def ShowBattleAnimAndWait(which as int, target as TRpgCharacter, fullscreen as bool) as Task:
	var signal = EventWaitHandle(false, EventResetMode.ManualReset)
	ShowBattleAnimT(GGameEngine.value.ImageEngine, which, CreateTarget(target), fullscreen, signal)
	waitFor { signal.WaitOne(0) }

def ShowBattleAnimB(which as int, target as IAnimTarget, fullscreen as bool):
	ShowBattleAnimT(GGameEngine.value.ImageEngine, which, target, fullscreen, null)

[async]
def ShowBattleAnimBAndWait(which as int, target as IAnimTarget, fullscreen as bool) as Task:
	var signal = EventWaitHandle(false, EventResetMode.ManualReset)
	ShowBattleAnimT(GGameEngine.value.ImageEngine, which, target, fullscreen, signal)
	waitFor { signal.WaitOne(0) }

def ShowBattleAnimT(engine as SpriteEngine, which as int, target as IAnimTarget, fullscreen as bool, signal as EventWaitHandle):
	template as TAnimTemplate = GDatabase.value.Anim[which]
	return if template == null
	try:
		LoadAnim(template.Filename, template.CellSize)
	except:
		return
	TAnimSprite(engine, template, target, fullscreen, signal)

[async]
def WaitUntilMoved() as Task:
	GEnvironment.value.Party.Sprite.CheckMoveChange()
	for i in range(1, GEnvironment.value.MapObjectCount + 1):
		if assigned(GEnvironment.value.MapObject[i]):
			GEnvironment.value.MapObject[i].Base.CheckMoveChange()
	waitFor AllMoved

def StopMoveScripts():
	for i in range(1, (GEnvironment.value.MapObjectCount + 1)):
		GEnvironment.value.MapObject[i].Base.Stop()
	for i in range(1, (GEnvironment.value.VehicleCount + 1)):
		if assigned(GEnvironment.value.Vehicles[i]):
			GEnvironment.value.Vehicles[i].Base.Stop()
	GEnvironment.value.Party.Base.Stop()

def ChangeTileset(which as int):
	if GGameEngine.value.EnsureTileset(which):
		GSpriteEngine.value.ChangeTileset(GDatabase.value.Tileset[which])

macro RenderPause(body as Boo.Lang.Compiler.Ast.Statement*):
	yield [|TURBU.RM2K.RPGScript.RenderPause()|]
	yieldAll body

def RenderPause():
	GGameEngine.value.RenderPause()

def SetEscape(map as int, x as int, y as int, switch as int):
	LData.Escape = (map, x, y, switch)

def EnableEscape(value as bool):
	LData.CanEscape = value

def SubstituteTiles(layer as int, fromTile as int, toTile as int):
"""
This method will have to forward its call on to the current map.  It should also
probably keep a record of what substitutions have been performed, so they can be
preserved ove a save.  Check RM2K behavior to see if they're preserved over
save (maybe) and/or map exit/reentry (probably not).
"""
	raise "Not supported yet"

private def WaitForBlank() as bool:
	return GGameEngine.value.CurrentMap.Blank

private def WaitForFadeEnd() as bool:
	return GSpriteEngine.value.State != TGameState.Fading

private def WaitForPanEnd() as bool:
	return not GSpriteEngine.value.Displacing

private def LoadAnim(filename as string, cellSize as SgPoint):
	var image = GSpriteEngine.value.Images.EnsureImage("Animations\\$filename.png", 'Anim ' + filename)
	image.TextureSize = cellSize

private class TCharacterTarget(TObject, IAnimTarget):

	private FTarget as TRpgCharacter

	def Position(sign as int) as SgPoint:
		result as SgPoint
		assert sign >= -1 and sign <= 1
		result.x = FTarget.ScreenXP + (FTarget.Base.Tiles[0].Width / 2)
		result.y = FTarget.ScreenYP + (FTarget.Base.Tiles[0].Height * sign)
		return result

	def Flash(r as int, g as int, b as int, power as int, time as int):
		FTarget.Flash(r, g, b, power, time)

	public def constructor(target as TRpgCharacter):
		FTarget = target

private def CreateTarget(target as TRpgCharacter) as IAnimTarget:
	return (null if target == null else TCharacterTarget(target))

private def AllMoved() as bool:
	partyMove as Path = GEnvironment.value.Party.Sprite.MoveOrder
	result = partyMove is null or partyMove.Looped
	i = 0
	while result and (i <= GEnvironment.value.MapObjectCount):
		++i
		obj as TRpgEvent = GEnvironment.value.MapObject[i]
		if assigned(obj) and assigned(obj.Base.MoveOrder):
			result = obj.Base.MoveOrder.Looped
	return result

def SerializeLocations(writer as JsonWriter):
	writeJsonObject writer:
		if LData.Escape[0] != 0:
			writer.WritePropertyName('Escape')
			writeJsonArray writer:
				for value in LData.Escape:
					writer.WriteValue(value)
		if LData.Teleport.Count > 0:
			writer.WritePropertyName('Teleport')
			writeJsonArray writer:
				for tel in LData.Teleport:
					writeJsonArray writer:
						for value2 in tel:
							writer.WriteValue(value2)
		writer.WritePropertyName('CanEscape')
		writer.WriteValue(LData.CanEscape)

def DeserializeLocations(obj as JObject):
	value as JToken
	arr as JArray
	if obj.TryGetValue('Escape', value):
		arr = value cast JArray
		for i in range(arr.Count):
			LData.Escape[i] = arr[i] cast int
		obj.Remove('Escape')
	else: LData.Escape = array(int, 4)
	var tp = LData.Teleport
	tp.Clear()
	if obj.TryGetValue('Teleport', value):
		arr = value cast JArray
		for x in range(arr.Count):
			var list = arr[x] cast JArray
			var tpItem = array(int, list.Count)
			for y in range(list.Count):
				tpItem[y] = list[y] cast int
			tp.Add(tpItem)
		obj.Remove('Teleport')
	if obj.TryGetValue('Escape', value):
		LData.CanEscape = value cast bool
	else: LData.CanEscape = true

private static class LData:
	public CanEscape = true
	public Escape = array(int, 4)
	public Teleport = List of (int)()

let MAX_WEATHER = 10
let LTeleportLock = object()
let LDefaultTransitions = array(TTransitions, Enum.GetValues(TTransitionTypes).Length);