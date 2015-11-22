namespace turbu.RM2K.environment

import System
import System.Linq.Enumerable
import System.Threading
import turbu.defs
import TURBU.Meta
import TURBU.RM2K
import TURBU.MapObjects
import turbu.operators
import turbu.script.engine
import commons
import turbu.constants
import turbu.classes
import timing
import turbu.shops
import Pythia.Runtime
import System.Collections.Generic
import turbu.Heroes
import turbu.mapchars
import turbu.RM2K.images
import turbu.RM2K.map.timer
import turbu.map.sprites
import turbu.RM2K.sprite.engine
import TURBU.RM2K.MapEngine
import TURBU.RM2K.Menus
import Newtonsoft.Json
import Newtonsoft.Json.Linq

[Disposable(Destroy)]
class T2kEnvironment(TObject):

	private FRand = System.Random()

	private FDatabase as TRpgDatabase

	private FHeroes as (TRpgHero)

	private FVehicles as (TRpgVehicle)

	private FSwitches as (bool)

	private FInts as (int)

	private FImages = array(TRpgImage, 0)

	private FEvents as (TRpgEvent)

	[Getter(Party)]
	private FParty as TRpgParty

	private FMenuEnabled as bool

	[Property(SaveEnabled)]
	private FSaveEnabled as bool

	private FEventMap as Dictionary[of TRpgMapObject, TRpgEvent]

	[Getter(SaveCount)]
	private FSaveCount as int

	private FKeyLock as bool

	[Property(PreserveSpriteOnTeleport)]
	private FPreserveSpriteOnTeleport as bool

	[Getter(Timer)]
	private FTimer as TRpgTimer

	[Getter(Timer2)]
	private FTimer2 as TRpgTimer

	private def GetSwitch(i as int) as bool:
		if clamp(i, 0, FSwitches.Length - 1) == i:
			result = FSwitches[i]
		else:
			result = false
		return result

	private def SetSwitch(i as int, value as bool):
		if clamp(i, 0, FSwitches.Length - 1) == i:
			FSwitches[i] = value

	private def GetVehicle(i as int) as TRpgVehicle:
		if clamp(i, 0, FVehicles.Length) == i:
			result = FVehicles[i]
		else:
			result = FVehicles[0]
		return result

	private def EvalConditions(value as TRpgEventConditions) as bool:
		cond as TPageConditions
		result = true
		for cond in value.Conditions.Values():
			caseOf cond:
				case TPageConditions.Switch1:
					result = self.Switch[value.Switch1Set]
				case TPageConditions.Switch2:
					result = self.Switch[value.Switch2Set]
				case TPageConditions.Var1:
					result = EvalVar(value.Variable1Set, value.Variable1Value, value.Variable1Op)
				case TPageConditions.Var2:
					result = EvalVar(value.Variable2Set, value.Variable2Value, value.Variable2Op)
				case TPageConditions.Item:
					result = (self.HeldItems(value.ItemNeeded, false) > 0)
				case TPageConditions.Hero:
					result = self.HeroPresent(value.HeroNeeded)
				case TPageConditions.Timer1:
					result = EvalValue(FTimer.time, value.TimeRemaining, value.Timer1Op)
				case TPageConditions.Timer2:
					result = EvalValue(FTimer2.time, value.TimeRemaining2, value.Timer2Op)
			return false unless result
		return result

	private def EvalVar(index as int, value as int, op as TComparisonOp) as bool:
		return EvalValue(self.Ints[index], value, op)

	private def EvalValue(l as int, r as int, op as TComparisonOp) as bool:
		caseOf op:
			case TComparisonOp.Equals:
				result = (l == r)
			case TComparisonOp.GtE:
				result = (l >= r)
			case TComparisonOp.LtE:
				result = (l <= r)
			case TComparisonOp.Gt:
				result = (l > r)
			case TComparisonOp.Lt:
				result = (l < r)
			case TComparisonOp.NotEquals:
				result = (l != r)
			default :
				raise Exception("T2kEnvironment.EvalValue: Invalid op: $(ord(op))")
		return result

	private def GetInt(i as int) as int:
		if clamp(i, 0, FInts.Length - 1) == i:
			result = FInts[i]
		else:
			result = 0
		return result

	private def SetInt(i as int, value as int):
		if clamp(i, 0, FInts.Length - 1) == i:
			FInts[i] = value

	private def SerializeVariables(writer as JsonWriter):
		i as int
		writer.WritePropertyName('switch')
		writeJsonArray writer:
			for i in range(1, FSwitches.Length):
				if FSwitches[i]:
					writer.WriteValue(i)
		writer.WritePropertyName('int')
		writeJsonArray writer:
			for i in range(1, FInts.Length):
				if FInts[i] != 0:
					writer.WriteValue(i)
					writer.WriteValue(FInts[i])

	private def SerializeHeroes(writer as JsonWriter):
		i as int
		writer.WritePropertyName('Heroes')
		writeJsonArray writer:
			for i in range(1, FHeroes.Length):
				FHeroes[i].Serialize(writer)

	private def SerializeImages(writer as JsonWriter):
		i as int
		writer.WritePropertyName('Images')
		writeJsonObject writer:
			for i in range(1, FImages.Length):
				if assigned(FImages[i]) and assigned(FImages[i].Base):
					writer.WritePropertyName(i.ToString())
					FImages[i].Serialize(writer)

	private def SerializeMapObjects(writer as JsonWriter):
		i as int
		writer.WritePropertyName('MapObjects')
		writeJsonArray writer:
			for i in range(1, FEvents.Length):
				if assigned(FEvents[i]):
					FEvents[i].Serialize(writer)
				else:
					writer.WriteNull()

	private def DeserializeVariables(obj as JObject):
		arr as JArray = obj['switch'] cast JArray
		for i in range(0, arr.Count):
			FSwitches[arr[i] cast int] = true
		arr.Remove()
		arr = obj['int'] cast JArray
		i = 0
		while i < arr.Count:
			FInts[arr[i] cast int] = arr[i + 1] cast int
			i += 2
		arr.Remove()

	private def DeserializeHeroes(obj as JObject):
		arr as JArray = obj['Heroes'] cast JArray
		for i in range(0, arr.Count):
			FHeroes[i + 1].Deserialize(arr[i] cast JObject)
		arr.Remove()

	private def DeserializeImages(obj as JObject):
		sub as JObject
		image as JObject
		Name as string
		masked as bool
		sub = obj['Images'] cast JObject
		for prop as JProperty in sub.Properties():
			image = prop.Value cast JObject
			masked = image['Masked'] cast bool
			Name = image['Name'] cast string
			unless string.IsNullOrEmpty(Name):
				GGameEngine.value.LoadRpgImage(Name, masked)
				self.Image[int.Parse(prop.Name)] = TRpgImage(GGameEngine.value.ImageEngine, image)
		sub.Remove()

	private def DeserializeMapObjects(obj as JObject):
		arr as JArray = obj['MapObjects'] cast JArray
		for i in range(0, arr.Count):
			if arr[i].Type == JTokenType.Null:
				FEvents[i + 1] = null
			else: FEvents[(i + 1)].Deserialize((arr[i] cast JObject))
		arr.Remove()

	private def GetVehicleCount() as int:
		return FVehicles.Length - 1

	internal def constructor(database as TRpgDatabase):
//		vehicle as TVehicleTemplate
		assert GEnvironment.value is null
		GEnvironment.value = self
		FDatabase = database
		FParty = TRpgParty()
		database.Hero.Download()
		Array.Resize[of TRpgHero](FHeroes, database.Hero.Count + 1)
		for hero in database.Hero.Values:
			FHeroes[hero.ID] = TRpgHero(hero, FParty)
		Array.Resize[of bool](FSwitches, database.Switch.Count + 1)
		Array.Resize[of int](FInts, database.Variable.Count + 1)
		Array.Resize[of TRpgVehicle](FVehicles, database.Vehicles.Count + 1)
//		database.Vehicles.Download()
//		for vehicle in database.Vehicles.Values:
//			FVehicles.Add(TRpgVehicle(database.MapTree, vehicle.ID))
		FMenuEnabled = true
		TRpgEventConditions.OnEval = self.EvalConditions
		FEventMap = Dictionary[of TRpgMapObject, TRpgEvent]()

	private def Destroy():
		for image in FImages:
			image.Dispose() if assigned(image)
		GEnvironment.value = null

	internal def CreateTimers():
		if FTimer == null:
			FTimer = TRpgTimer(TSystemTimer(GGameEngine.value.ImageEngine))
			FTimer2 = TRpgTimer(TSystemTimer(GGameEngine.value.ImageEngine))

	public def KeyScan(mask as TButtonCode, wait as bool) as int:
		scan as TButtonCode
		thread as TScriptThread
		btn as TButtonCode
		assert not TThread.CurrentThread.IsMainThread
		thread = (TThread.CurrentThread cast TScriptThread)
		while wait and FKeyLock:
			GScriptEngine.value.ThreadWait()
			scan = GGameEngine.value.ReadKeyboardState()
			Thread.Sleep(TRpgTimestamp.FrameLength)
			scan = scan | GGameEngine.value.ReadKeyboardState()
			scan = scan & mask
			if wait and (scan == TButtonCode.None):
				GScriptEngine.value.SetWaiting(WaitForKeyPress)
				repeat :
					GScriptEngine.value.ThreadWait()
					scan = (GGameEngine.value.ReadKeyboardState() & mask)
					until scan != TButtonCode.None or thread.Terminated
				FKeyLock = true
			result = 0
			if scan == TButtonCode.None:
				return result
			else:
				for btn in scan.Values():
					return ord(btn) //return lowest value found in set
		return result

	public def Wait(duration as int):
		GScriptEngine.value.ThreadSleep(duration * 100, false)

	public def HasItem(id as int):
		return HeldItems(id, false) > 0

	public def HeldItems(id as int, equipped as bool) as int:
		result = 0
		return result if clamp(id, 0, GDatabase.value.Items.Count) != id
		if equipped:
			for i in range(1, (MAXPARTYSIZE + 1)):
				++result if (FParty[i] != FHeroes[0]) and FParty[i].Equipped(id)
		else: result = FParty.Inventory.QuantityOf(id)
		return result

	public def Shop(shopType as TShopTypes, messageSet as int, Inventory as (int)):
		using data = TShopData(shopType, messageSet, Inventory):
			GMenuEngine.Value.OpenMenuEx('Shop', data)
			GScriptEngine.value.SetWaiting({ return GMenuEngine.Value.State == TMenuState.None })

	public def Random(low as int, high as int) as int:
		return FRand.Next(Math.Min(high, low), Math.Max(high, low))

	public def EnableSave(value as bool):
		FSaveEnabled = value

	public def GameOver():
		GGameEngine.value.GameOver()

	public def TitleScreen():
		GScriptEngine.value.KillAll(null)
		commons.runThreadsafe(true, { GGameEngine.value.TitleScreen() })

	public def DeleteObject(permanent as bool):
		obj as TRpgCharacter
		obj = ThisObject
		for i in range(1, FEvents.Length, 1):
			if FEvents[i] == obj:
				runThreadsafe(true) do():
					FEvents[i] = null
				break
		if permanent:
			pass //TODO: implement this

	public def HeroPresent(id as int) as bool:
		return FParty.IndexOf(self.Heroes[id]) > 0

	public def CallScript(objectID as int, pageID as int):
		GScriptEngine.value.RunObjectScript(self.MapObject[objectID].MapObj, pageID)

	public def ImageIndex(img as TRpgImage) as int:
		for i in range(FImages.Length):
			if FImages[i] == img:
				return i
		return -1

	internal def RemoveImage(image as TRpgImage):
		for i in range(FImages.Length):
			if FImages[i] == image:
				FImages[i] = null

	internal def AddEvent(base as TMapSprite):
		newItem as TRpgEvent
		newItem = TRpgEvent(base)
		if newItem.ID >= FEvents.Length:
			Array.Resize[of TRpgEvent](FEvents, newItem.ID + 1)
		FEvents[newItem.ID] = newItem
		FEventMap.Add(base.Event, newItem)

	internal def ClearEvents():
		Array.Resize[of TRpgEvent](FEvents, 1)
		FEventMap.Clear()

	internal def UpdateEvents():
		for Event as TRpgEvent in FEvents:
			Event.Update() if assigned(Event)
		if assigned(FParty?.Base):
			FParty.Base.CheckMoveChange()
		if FKeyLock and (GGameEngine.value.ReadKeyboardState() == TButtonCode.None):
			FKeyLock = false

	internal def CheckVehicles():
		for vehicle in FVehicles:
			if assigned(vehicle) and vehicle.Template.ID != 0:
				vehicle.CheckSprite()

	internal def ClearVehicles():
		for i in range(FVehicles.Length):
			FVehicles[i] = null

	internal def Serialize(writer as JsonWriter, explicitSave as bool):
		writeJsonObject writer:
			SerializeVariables(writer)
			SerializeHeroes(writer)
			SerializeImages(writer)
			SerializeMapObjects(writer)
			writer.WritePropertyName('Party')
			FParty.Serialize(writer)
			writer.CheckWrite('MenuEnabled', FMenuEnabled, false)
			++FSaveCount if explicitSave
			writer.CheckWrite('SaveCount', FSaveCount, 0)
			writer.CheckWrite('PreserveSpriteOnTeleport', FPreserveSpriteOnTeleport, false)
			writer.CheckWrite('SaveEnabled', FSaveEnabled, false)
			if Timer.time > 0:
				writer.WritePropertyName('Timer')
				Timer.Serialize(writer)
			if Timer2.time > 0:
				writer.WritePropertyName('Timer2')
				Timer2.Serialize(writer)

	internal def Deserialize(obj as JObject):
		value as JToken
		DeserializeVariables(obj)
		DeserializeHeroes(obj)
		DeserializeImages(obj)
		value = obj['Party']
		assert assigned(value)
		FParty.Deserialize((value cast JObject))
		value.Remove()
		DeserializeMapObjects(obj)
		obj.CheckRead('MenuEnabled', FMenuEnabled)
		obj.CheckRead('SaveCount', FSaveCount)
		obj.CheckRead('PreserveSpriteOnTeleport', FPreserveSpriteOnTeleport)
		obj.CheckRead('SaveEnabled', FSaveEnabled)
		value = obj['Timer']
		if assigned(value):
			FTimer.Deserialize((value cast JObject))
			value.Remove()
		value = obj['Timer2']
		if assigned(value):
			FTimer2.Deserialize((value cast JObject))
			value.Remove()
		obj.CheckEmpty()
		self.UpdateEvents()

	[Lookup('Hero')]
	public Heroes[i as int] as TRpgHero:
		get:
			result = ( FHeroes[i] if clamp(i, 0, FHeroes.Length - 1) == i else FHeroes[0] )
			return result


	public HeroCount as int:
		get: return FHeroes.Length - 1

	public Switch[i as int] as bool:
		get:
			return GetSwitch(i)
		set:
			SetSwitch(i, value)

	public Ints[i as int] as int:
		get:
			return GetInt(i)
		set:
			SetInt(i, value)

	[Lookup('Vehicles')]
	public Vehicle[i as int] as TRpgVehicle:
		get:
			return GetVehicle(i)

	public VehicleCount as int:
		get:
			return GetVehicleCount()

	public Image[i as int] as TRpgImage:
		get:
			i = clamp(i, 0, 250)
			Array.Resize[of TRpgImage](FImages, i + 1) if i >= FImages.Length
			if FImages[i] == null:
				FImages[i] = TRpgImage(GSpriteEngine.value, '', 0, 0, 0, 0, 0, false, false)
			return FImages[i]
		set:
			commons.runThreadsafe(true) def ():
				i = clamp(i, 0, 250)
				if i >= FImages.Length:
					Array.Resize[of TRpgImage](FImages, i + 1)
				else:
					FImages[i].Dispose() if assigned(FImages[i])
				FImages[i] = value

	public ImageCount as int:
		get: return FImages.Length - 1

	public MapObject[i as int] as TRpgEvent:
		get: return (FEvents[i] if (clamp(i, 0, FEvents.Length - 1) == i) and assigned(FEvents[i]) else FEvents[0])

	public MapObjectCount as int:
		get: return FEvents.Length - 1

	public Money as int:
		get: return FParty.Money
		set: FParty.Money = clamp(value, 0, MAXGOLD)

	public PartySize as int:
		get: return FParty.Count({h | h != FHeroes[0]})

	public BattleCount as int:
		get: return 0

	public Victories as int:
		get: return 0

	public Losses as int:
		get: return 0

	public Flees as int:
		get: return 0

	public LevelGainNotify as bool:
		set: FParty.LevelNotify = value

	public DeathPossible as bool:
		set: FParty.DeathPossible = value

	public MenuEnabled as bool:
		get: return FMenuEnabled
		set: FMenuEnabled = value

	public ThisObject as TRpgEvent:
		get:
			obj as TRpgMapObject
			obj = (TThread.CurrentThread cast TScriptThread).CurrentObject
			return FEventMap[obj]
			
	private static def WaitForKeyPress() as bool:
		return GGameEngine.value.ReadKeyboardState() != TButtonCode.None

static class GEnvironment:
	public value as T2kEnvironment
