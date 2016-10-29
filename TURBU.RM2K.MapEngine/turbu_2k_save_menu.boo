namespace TURBU.RM2K.Menus

import turbu.constants
import turbu.defs
import timing
import sdl.sprite
import commons
import project.folder
import TURBU.RM2K
import TURBU.TextUtils
import TURBU.RM2K.RPGScript
import Boo.Adt
import Pythia.Runtime
import System
import System.IO
import SDL2.SDL2_GPU
import turbu.RM2K.savegames
import turbu.RM2K.sprite.engine
import TURBU.RM2K.MapEngine
import Newtonsoft.Json.Linq
import TURBU.Meta
import SG.defs

struct TPortraitID:
	Name as string
	Index as int

	def constructor(Name as string, index as int):
		self.Name = Name
		self.Index = index

class TSaveData(TObject):

	[Getter(Name)]
	private FName as string

	[Getter(Level)]
	private FLevel as int

	[Getter(Hp)]
	private FHp as int

	[Getter(Portraits)]
	private FPortraits as (TPortraitID)

	public def constructor(name as string, level as int, HP as int, portraits as (TPortraitID)):
		FName = name
		FLevel = level
		FHp = HP
		FPortraits = portraits

class TSaveBox(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FPortraits = array(TSprite, 0)

	private FIndex as int

	protected override def DrawText():
		for portrait in FPortraits:
			portrait.Dead()
		data as TSaveData = (FOwner cast TSaveMenuPage).SaveData(FIndex)
		var color = (0 if assigned(data) else 3)
		var target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, "File $FIndex", 6, 4, color)
		if assigned(data):
			GFontEngine.DrawText(target, data.Name, 6, 22, 0)
			GFontEngine.DrawText(target, 'L', 6, 40, 1)
			GFontEngine.DrawTextRightAligned(target, data.Level.ToString(), 22, 40, 0)
			GFontEngine.DrawText(target, 'HP', 40, 40, 1)
			GFontEngine.DrawTextRightAligned(target, data.Hp.ToString(), 70, 40, 0)
			Array.Resize[of TSprite](FPortraits, data.Portraits.Length)
			for i in range(data.Portraits.Length):
				FPortraits[i] = LoadPortrait(data.Portraits[i].Name, data.Portraits[i].Index)
				FPortraits[i].X = 90 + (56 * i)
				FPortraits[i].Y = 4
				FPortraits[i].Draw()
		else:
			Array.Resize[of TSprite](FPortraits, 0)

	protected override def DoCursor(position as short):
		if self.Focused:
			coords as GPU_Rect = GPU_MakeRect(FBounds.x + 8, FBounds.y + 8, 52, 20)
			GMenuEngine.Value.Cursor.Visible = true
			GMenuEngine.Value.Cursor.Layout(coords)

	protected override def DoButton(input as TButtonCode):
		filename as string
		super.DoButton(input)
		if input == TButtonCode.Enter and FOptionEnabled[FCursorPosition]:
			filename = Path.Combine(GProjectFolder.value, "save$(FIndex.ToString('D2')).tsg")
			if FSetupValue == 0:
				SaveTo(filename, GSpriteEngine.value.MapObj.ID, true)
			else:
				GGameEngine.value.Load(filename)
				FMenuEngine.Leave(false)
			self.Return()

	protected override def DoSetup(value as int):
		super.DoSetup(value)
		if value == 0:
			FOptionEnabled[0] = true
		else:
			FOptionEnabled[0] = assigned((FOwner cast TSaveMenuPage).SaveData(FIndex))
		InvalidateText()

	internal Index as int:
		set:
			FIndex = value
			DoSetup(FSetupValue)

[Disposable(Destroy)]
class TSaveMenuPage(TMenuPage):

	private FSlots = array(TSaveBox, 3)

	private FTitle as TOnelineLabelBox

	private FSaveData = array(TSaveData, MAX_SAVE_SLOTS)

	private FCursorPosition as int

	private FTop as int

	private FButtonLock as TRpgTimestamp

	private def ReadSaveData(index as int) as TSaveData:
		var filename = Path.Combine(GProjectFolder.value, "save$(index.ToString('D2')).tsg")
		unless File.Exists(filename):
			return null
		using obj = JObject.Parse(File.ReadAllText(filename)):
			if obj == null:
				return null
			var party = (obj['Environment']['Party']['Heroes'] cast JArray)
			var heroes = (obj['Environment']['Heroes'] cast JArray)
			var HP = 0
			var LV = 0
			var leader = ''
			portrait as string
			elem as JToken
			portraitID as int
			portraits = array (TPortraitID, 0)
			for i in range(0, party.Count):
				continue if party[i].Type == JTokenType.Null
				var hero = party[i] cast int
				var heroObj = (heroes[hero - 1] cast JObject)
				if leader == '':
					if heroObj.TryGetValue('Name', elem):
						leader = elem cast string
					else:
						leader = GDatabase.value.Hero[hero].Name
					if heroObj.TryGetValue('HitPoints', elem):
						HP = elem cast int
					else: HP = 0
					if heroObj.TryGetValue('Level', elem):
						LV = elem cast int
					else:
						LV = GDatabase.value.Hero[hero].MinLevel
				if heroObj.TryGetValue('FaceName', elem):
					portrait = elem cast string
				else:
					portrait = GDatabase.value.Hero[hero].Portrait
				if heroObj.TryGetValue('FaceNum', elem):
					portraitID = elem cast int
				else:
					portraitID = GDatabase.value.Hero[hero].PortraitIndex
				Array.Resize[of TPortraitID](portraits, portraits.Length + 1)
				portraits[portraits.Length - 1] = TPortraitID(portrait, portraitID)
			result = TSaveData(leader, LV, HP, portraits)
		return result

	private def ResetSlots():
		for i in range(FSlots.Length):
			FSlots[i].Index = FTop + i

	private def MoveSlot(input as TButtonCode):
		caseOf input:
			case TButtonCode.Down:
				if FCursorPosition == FSlots.Length - 1:
					if (FTop + FSlots.Length - 1) < MAX_SAVE_SLOTS:
						++FTop
						ResetSlots()
				else:
					++FCursorPosition
					FocusMenu(null, FSlots[FCursorPosition], true)
			case TButtonCode.Up:
				if FCursorPosition == 0:
					if FTop > 1:
						--FTop
						ResetSlots()
				else:
					--FCursorPosition
					FocusMenu(null, FSlots[FCursorPosition], true)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string):
		let SIZE = sgPoint(320, 68)
		boxCoords as GPU_Rect
		super(parent, coords, main, layout)
		boxCoords.w = SIZE.x
		boxCoords.x = 0
		for i in range(FSlots.Length):
			boxCoords.y = 32 + (68 * i)
			boxCoords.h = SIZE.y + boxCoords.y
			FSlots[i] = TSaveBox(parent, boxCoords, main, self)
			FSlots[i].Index = i + 1
			RegisterComponent("Slot$i", FSlots[i])
		FTitle = TOnelineLabelBox(parent, GPU_MakeRect(0, 0, 320, 32), main, self)
		RegisterComponent('Title', FTitle)

	private def Destroy():
		for slot in FSlots:
			slot.Dispose()

	public def SaveData(index as int) as TSaveData:
		return null if clamp(index, 0, FSaveData.Length - 1) != index
		FSaveData[index] = ReadSaveData(index) if FSaveData[index] == null
		return FSaveData[index]

	public override def Button(input as TButtonCode):
		return if (input in TButtonCode.Up | TButtonCode.Down) and assigned(FButtonLock) and (FButtonLock.TimeRemaining > 0)
		FButtonLock = null
		oldSlot as int = FTop + FCursorPosition
		caseOf input:
			case TButtonCode.Up, TButtonCode.Down:
				MoveSlot(input)
			case TButtonCode.Enter, TButtonCode.Cancel:
				super.Button(input)
		if oldSlot != FTop + FCursorPosition:
			PlaySystemSound(TSfxTypes.Cursor)
			FButtonLock = TRpgTimestamp(180)

	public override def Setup(value as int):
		super.Setup(value)
		FTitle.Text = (GDatabase.value.Vocab[V_SAVE_WHERE] if value == 0 else GDatabase.value.Vocab[V_LOAD_WHERE])

initialization :
	TMenuEngine.RegisterMenuPageEx(classOf(TSaveMenuPage), 'Save', '[]')
