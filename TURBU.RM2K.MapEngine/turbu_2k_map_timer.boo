namespace turbu.RM2K.map.timer

import turbu.defs
import turbu.classes
import Pythia.Runtime
import TURBU.RM2K.Menus
import System
import Newtonsoft.Json
import Newtonsoft.Json.Linq

[Disposable]
class TRpgTimer(TObject):

	private FTimerSprite as TSystemTimer

	private FSecs as ushort

	[Property(Time)]
	private FTimeRemaining as int

	[Getter(Active)]
	private FActivated as bool

	private FVisible as bool

	[Property(InBattle)]
	private FInBattle as bool

	private def Tick():
		return unless FActivated
		secs = DateTime.Now.Second
		secs = 60 if (secs == 0) and (FSecs == 59)
		if (secs - FSecs > 0) and (FTimeRemaining > 0):
			--FTimeRemaining
			FSecs = secs % 60

	[NoImport]
	public def constructor(sprite as TSystemTimer):
		FTimerSprite = sprite
		msec = DateTime.Now.Millisecond
		++FSecs if msec >= 500
		sprite.OnGetTime = self.GetTime

	[NoImport]
	public def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('TimeRemaining', FTimeRemaining, 0)
			writer.CheckWrite('Activated', FActivated, false)
			writer.CheckWrite('Visible', FVisible, false)
			writer.CheckWrite('InBattle', FInBattle, false)

	[NoImport]
	public def Deserialize(obj as JObject):
		obj.CheckRead('TimeRemaining', FTimeRemaining)
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
		FTimeRemaining = 0

	[NoImport]
	public def GetTime() as int:
		Tick()
		return FTimeRemaining

	public Visible as bool:
		get: return FVisible
		set:
			if value == FVisible:
				return
			FVisible = value
			FTimerSprite.Visible = value
