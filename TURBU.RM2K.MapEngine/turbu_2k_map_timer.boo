namespace turbu.RM2K.map.timer

import turbu.defs
import turbu.classes
import Pythia.Runtime
import TURBU.RM2K.Menus
import System
import Newtonsoft.Json
import Newtonsoft.Json.Linq

class TRpgTimer(TObject):

	private FTimerSprite as TSystemTimer

	private FTicks as int

	public Time as int:
		get: return FTicks / 60
		set: FTicks = (Math.Min(Math.Max(value, 0) * 60 + 59, 359999) if value > 0 else 0)

	[Getter(Active)]
	private FActivated as bool

	private FVisible as bool

	[Property(InBattle)]
	private FInBattle as bool

	public def Tick():
		return unless FActivated
		if FTicks > 0:
			--FTicks
			FActivated = false if FTicks < 60

	[NoImport]
	public def constructor(sprite as TSystemTimer):
		FTimerSprite = sprite
		sprite.OnGetTime = self.GetTime

	[NoImport]
	public def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('TimeRemaining', self.Time, 0)
			writer.CheckWrite('Activated', FActivated, false)
			writer.CheckWrite('Visible', FVisible, false)
			writer.CheckWrite('InBattle', FInBattle, false)

	[NoImport]
	public def Deserialize(obj as JObject):
		seconds as int = 0
		obj.CheckRead('TimeRemaining', seconds)
		self.Time = seconds
		obj.CheckRead('Activated', FActivated)
		obj.CheckRead('Visible', FVisible)
		obj.CheckRead('InBattle', FInBattle)
		obj.CheckEmpty()

	[NoImport]
	public def Start():
		FActivated = true

	public def Start(visible as bool, inBattle as bool):
		self.Visible = visible
		FInBattle = inBattle
		FActivated = true

	public def Pause():
		FActivated = false

	public def Reset():
		FActivated = false
		FVisible = false
		FTicks = 0

	[NoImport]
	public def GetTime() as int:
		return self.Time

	public Visible as bool:
		get: return FVisible
		set:
			if value == FVisible:
				return
			FVisible = value
			FTimerSprite.Visible = value
