namespace turbu.mapchars

import System

import ArchiveUtils
import commons
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import Pythia.Runtime
import SG.defs
import turbu.characters
import turbu.classes
import turbu.constants
import turbu.defs
import turbu.map.metadata
import turbu.map.sprites
import TURBU.MapObjects
import TURBU.Meta
import turbu.pathing
import TURBU.RM2K
import turbu.RM2K.CharSprites
import turbu.RM2K.sprite.engine
import turbu.script.engine

class TRpgCharacter(TObject):

	protected abstract def DoFlash(r as int, g as int, b as int, power as int, time as int):
		pass

	protected abstract def GetX() as int:
		pass

	protected abstract def GetY() as int:
		pass

	protected abstract def GetBase() as TMapSprite:
		pass

	protected virtual def GetTranslucency() as int:
		return Base.Translucency

	protected virtual def SetTranslucency(value as int):
		Base.Translucency = value

	public def Flash(r as int, g as int, b as int, power as int, time as int, wait as bool):
		lock self:
			DoFlash(r, g, b, power, time)
			GScriptEngine.value.ThreadSleep(time * 100, true) if wait

	public def Move(frequency as int, skip as bool, path as Func[of Path, Func[of TObject, bool]*]):
		return unless assigned(self.Base)
		lock self:
			try:
				var lPath = Path(skip, path)
			except as Boo.Lang.Runtime.AssertionFailedException:
				return
			self.Base.MoveChange(lPath, clamp(frequency, 1, 8), skip)

	[NoImport]
	public abstract def ChangeSprite(Name as string, translucent as bool, spriteIndex as int):
		pass

	public ScreenX as int:
		get: return GetX() - round(GSpriteEngine.value.WorldX / TILE_SIZE.x )

	public ScreenY as int:
		get: return GetY() - round(GSpriteEngine.value.WorldY / TILE_SIZE.y )

	public ScreenXP as int:
		get: return self.ScreenX * TILE_SIZE.x

	public ScreenYP as int:
		get: return self.ScreenY * TILE_SIZE.y

	public XPos as int:
		virtual get: return GetX()

	public YPos as int:
		virtual get: return GetY()

	public Base as TMapSprite:
		get: return GetBase()

	public Translucency as int:
		get: return GetTranslucency()
		set: SetTranslucency(value)

class TRpgEvent(TRpgCharacter):

	[Getter(ID)]
	private FID as int

	[Getter(Base)]
	private FBase as TMapSprite

	private FIsChar as bool

	[Getter(MapObj)]
	private FEvent as TRpgMapObject

	private FChangeSpriteName as string

	private FChangeSpriteTranslucent as bool

	private FChangeSprite as bool

	private FChangeSpriteIndex as int

	private def SetLocation(value as TSgPoint):
		lock self:
			FBase.LeaveTile()
			FBase.Location = value

	private def GetFacing() as int:
		TABLE = (8, 6, 2, 4)
		return (TABLE[(FBase cast TCharSprite).Facing] if FIsChar else 2)

	private def InternalChangeSprite():
		FEvent.CurrentPage.OverrideSprite(FChangeSpriteName, FChangeSpriteTranslucent, FChangeSpriteIndex)
		SwitchType()
		FChangeSprite = false

	private def GetTFacing() as TDirections:
		return ((FBase cast TCharSprite).Facing if FIsChar else TDirections.Down)

	private def DeserializeBase(obj as JObject):
		value as JToken = obj['SpriteName']
		if assigned(value):
			FBase.BaseTile.ImageName = value cast string
			obj.Remove('SpriteName')
		value = obj['Transparent']
		if assigned(value):
			FBase.Translucency = value cast int
			obj.Remove('Transparent')
		value = obj['Path']
		if assigned(value):
			FBase.MoveOrder = Path(value cast JObject)
			obj.Remove('Path')
		value = obj['MoveFreq']
		if assigned(value):
			FBase.MoveFreq = value cast int
			obj.Remove('MoveFreq')
		value = obj['MoveRate']
		if assigned(value):
			FBase.MoveRate = value cast int
			obj.Remove('MoveRate')
		obj.CheckEmpty()

	protected override def GetX() as int:
		return ((FBase cast TCharSprite).Location.x if FIsChar else round((FBase.BaseTile.X cast double) / TILE_SIZE.x))

	protected override def GetY() as int:
		return ((FBase cast TCharSprite).Location.y if FIsChar else round((FBase.BaseTile.Y cast double) / TILE_SIZE.y))

	protected override def GetBase() as TMapSprite:
		return self.FBase

	protected override def DoFlash(r as int, g as int, b as int, power as int, time as int):
		FBase.Flash(r, g, b, power, time)

	[NoImport]
	public def constructor(base as TMapSprite):
		return if base is null
		
		FIsChar = (base isa TCharSprite)
		FBase = base
		FBase.OnChangeSprite = self.ChangeSprite
		FEvent = FBase.Event
		FID = FBase.Event.ID unless FEvent is null

	[NoImport]
	public def Serialize(writer as JsonWriter):
		TRANSLUCENCIES as (int) = (0, 3)
		writeJsonObject writer:
			if FBase.Location != FEvent.Location:
				writer.WritePropertyName('Location')
				writeJsonArray writer:
					writer.WriteValue(FBase.Location.x)
					writer.WriteValue(FBase.Location.y)
			if assigned(FEvent.CurrentPage):
				writer.WritePropertyName('Base')
				writeJsonObject writer:
					writeJsonProperty writer, 'PageID', FEvent.CurrentPage.ID
					writer.CheckWrite('SpriteName', FBase.BaseTile.ImageName, FEvent.CurrentPage.BaseFilename)
					writer.CheckWrite('Transparent', FBase.Translucency, TRANSLUCENCIES[(1 if FEvent.CurrentPage.BaseTransparent else 0)])
					if assigned(FBase.MoveOrder):
						writer.WritePropertyName('Path')
						FBase.MoveOrder.Serialize(writer)
					writer.CheckWrite('MoveFreq', FBase.MoveFreq, 1)
					writer.CheckWrite('MoveRate', FBase.MoveRate, 1)

	[NoImport]
	public def Deserialize(obj as JObject):
		value as JToken = obj['Location']
		if assigned(value):
			FBase.Location = sgPoint(value[0] cast int, value[1] cast int)
			obj.Remove('Location')
		FEvent.UpdateCurrentPage()
		if assigned(FEvent.CurrentPage):
			var baseObj = obj['Base'] cast JObject
			var id = baseObj['PageID'] cast int
			if id != FEvent.CurrentPage.ID:
				raise "Expected FEvent.CurrentPage.ID of $id but got $(FEvent.CurrentPage.ID) instead."
			baseObj.Remove('PageID')
			DeserializeBase(baseObj)
			obj.Remove('Base')
		obj.CheckEmpty()

	[NoImport]
	public def Update():
		return if FEvent == null
		FEvent.Locked = false
		unless (FEvent.Updated or FChangeSprite):
			FBase.CheckMoveChange()
			return
		lock self:
			if FChangeSprite:
				InternalChangeSprite()
			elif (FEvent.IsTile and (FBase isa TCharSprite)) or ((not FEvent.IsTile) and (FBase isa TEventSprite)):
				SwitchType()
			else: FBase.UpdatePage(FEvent.CurrentPage)
			FBase.CheckMoveChange()

	[NoImport]
	public override def ChangeSprite(Name as string, translucent as bool, spriteIndex as int):
		lock self:
			FChangeSprite = true
			FChangeSpriteName = Name
			FChangeSpriteTranslucent = translucent
			FChangeSpriteIndex = spriteIndex

	[NoImport]
	public def SwitchType():
		lock self:
			old as TMapSprite = FBase
			FBase = (TEventSprite(FEvent, GSpriteEngine.value) if FEvent.IsTile else TCharSprite(FEvent, GSpriteEngine.value))
			FIsChar = Base isa TCharSprite
			FBase.OnChangeSprite = self.ChangeSprite
			FBase.CopyDrawState(old)
			GSpriteEngine.value.SwapMapSprite(old, FBase)
			FBase.Place()
			old.Dispose()

	public Map as int:
		get: return ((FBase cast TVehicleSprite).Template.Map if FBase isa TVehicleSprite else GSpriteEngine.value.MapID)

	public X as int:
		get: return GetX()

	public Y as int:
		get: return GetY()

	public FacingValue as int:
		get: return GetFacing()

	public Facing as TDirections:
		get: return GetTFacing()

	public Location as TSgPoint:
		get: return sgPoint(self.X, self.Y)
		set: SetLocation(value)

[Disposable(Destroy)]
class TRpgVehicle(TRpgCharacter):

	[Getter(Template)]
	private FTemplate as TVehicleTemplate

	[Getter(Sprite)]
	private FSprite as string

	[Getter(SpriteIndex)]
	private FSpriteIndex as int

	private FTranslucent as bool

	private FMap as int

	private FX as int

	private FY as int

	[Property(Gamesprite)]
	private FGameSprite as TMapSprite

	[Getter(VehicleIndex)]
	private FVehicleIndex as int

	[Property(Carrying)]
	private FCarrying as TRpgCharacter

	private def GetLocation() as TSgPoint:
		return sgPoint(self.X, self.Y)

	private def SetLocation(value as TSgPoint):
		FX = value.x
		FY = value.y
		if assigned(FGameSprite):
			FGameSprite.Location = value

	private def SetX(value as int):
		FX = value
		if assigned(FGameSprite):
			FGameSprite.Location = sgPoint(FX, FGameSprite.Location.y)

	private def SetY(value as int):
		FY = value
		if assigned(FGameSprite):
			FGameSprite.Location = sgPoint(FGameSprite.Location.x, FY)

	private def GetFacing() as int:
		if assigned(FGameSprite):
			caseOf FGameSprite.Facing:
				case TDirections.Up:
					result = 8
				case TDirections.Right:
					result = 6
				case TDirections.Down:
					result = 2
				case TDirections.Left:
					result = 4
				default :
					raise Exception('Invalid facing')
		else:
			result = 4
		return result

	private def SetFacing(value as int):
		if assigned(FGameSprite):
			caseOf value:
				case 8:
					FGameSprite.Facing = TDirections.Up
				case 6:
					FGameSprite.Facing = TDirections.Right
				case 4:
					FGameSprite.Facing = TDirections.Left
				case 2:
					FGameSprite.Facing = TDirections.Down

	private def CreateSprite():
		assert FMap == GSpriteEngine.value.MapID
		FGameSprite = TVehicleSprite(GSpriteEngine.value, self, { FGameSprite = null })
		SetSprite(Template.MapSprite, FTranslucent, FSpriteIndex)
		FGameSprite.Location = sgPoint(FX, FY)
		FGameSprite.Facing = TFacing.Left
		(FGameSprite cast TVehicleSprite).Update(FSprite, false, FSpriteIndex)

	protected override def GetX() as int:
		if assigned(FGameSprite):
			FX = FGameSprite.Location.x
		return FX

	protected override def GetY() as int:
		if assigned(FGameSprite):
			FY = FGameSprite.Location.y
		return FY

	protected override def GetBase() as TMapSprite:
		return FGameSprite

	protected override def DoFlash(r as int, g as int, b as int, power as int, time as int):
		if map == GSpriteEngine.value.MapID:
			self.Gamesprite.Flash(r, g, b, power, time)

	protected override def SetTranslucency(value as int):
		FTranslucent = (value >= 3)
		if assigned(FGameSprite):
			super.SetTranslucency(value)

	[NoImport]
	public def constructor(mapTree as TMapTree, which as int):
		loc as TLocation
		template as TVehicleTemplate
		super()
		FVehicleIndex = which
		if assigned(mapTree):
			loc = mapTree.Location[which]
			FMap = loc.map
			FX = loc.x
			FY = loc.y
		template = GDatabase.value.Vehicles[which]
		FTemplate = template

	private def Destroy():
		FGameSprite.Dispose()

	public def SetSprite(filename as string, translucent as bool, spriteIndex as int):
		return unless GraphicExists(filename, 'Sprites')
		FSprite = System.IO.Path.ChangeExtension(filename, '')
		FTranslucent = translucent
		FSpriteIndex = spriteIndex
		if assigned(FGameSprite):
			FGameSprite.Update(FSprite, translucent, FSpriteIndex)

	[NoImport]
	public override def ChangeSprite(Name as string, translucent as bool, spriteIndex as int):
		lock self:
			self.SetSprite(Name, translucent, spriteIndex)

	public def SetMusic(Name as string, fadeIn as int, volume as int, tempo as int, balance as int):
		pass

	public InUse as bool:
		get: return FCarrying != null

	[NoImport]
	public def CheckSprite():
		FGameSprite = null
		if FMap == GSpriteEngine.value.MapID:
			CreateSprite()

	public Map as int:
		get: return FMap
		set:
			FMap = value
			if assigned(FGameSprite):
				FGameSprite.Visible = (map == GSpriteEngine.value.MapID)

	public X as int:
		get: return GetX()
		set: SetX(value)

	public Y as int:
		get: return GetY()
		set: SetY(value)

	public Location as TSgPoint:
		get: return GetLocation()
		set: SetLocation(value)

	public Facing as int:
		get: return GetFacing()
		set: SetFacing(value)
