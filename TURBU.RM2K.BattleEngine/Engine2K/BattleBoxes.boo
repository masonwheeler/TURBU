namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import Boo.Adt
import TURBU.Meta
import commons
import System.Collections.Generic
import SG.defs
import SDL2
import SDL2.SDL2_GPU
import SDL.ImageManager
import sdl.sprite
import turbu.defs
import turbu.constants
import TURBU.TextUtils
import TURBU.RM2K
import TURBU.RM2K.Menus
import TURBU.RM2K.RPGScript
import timing

let ROW_HEIGHT_STATUS = 16
let MESSAGE_ROWS = 4

let COMMAND_WIDTH = 82
let SLIDE_LENGTH = 9

class TBattleListBox(TCustomScrollBox):

	private _values = List[of string]()

	[Getter(Done)]
	private _done as bool

	[Getter(Result)]
	private _result = -2

	[Property(InputFocus)]
	private _inputFocus as bool

	[Property(CanCancel)]
	private _canCancel = true

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage, columns as int):
		super(parent, coords, main, owner)
		self.Columns = columns cast byte
		FBlank = true

	public override def Reflow():
		FDisplayCapacity = (((FCoords.h - (BORDER_SIZE.y * 2)) / 15) * self.Columns) cast byte

	public def SetItems(texts as List[of string], enabled as List[of bool], values as List[of string]):
		ClearText()
		_values.Clear()
		for i in range(texts.Count):
			FParsedText.Add(texts[i])
			_values.Add((values[i] if values is not null else ''))
		Array.Resize[of bool](FOptionEnabled, texts.Count)
		for i in range(texts.Count):
			FOptionEnabled[i] = (enabled[i] if enabled is not null else true)
		FTopPosition = 0
		FCursorPosition = 0
		InvalidateText()

	public ItemCount as int:
		get: return FParsedText.Count

	public def Begin():
		_done = false
		_result = -2
		_inputFocus = true
		FBlank = false
		Visible = true

	[Property(StayVisible)]
	private _stayVisible as bool

	public def Close():
		_inputFocus = false
		FBlank = true
		Visible = _stayVisible

	private def Finish(value as int):
		_result = value
		_done = true
		_inputFocus = false

	protected override def DrawItem(id as int, x as int, y as int, color as int):
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, FParsedText[id], x, y, color)
		if id < _values.Count and _values[id] != '':
			GFontEngine.DrawTextRightAligned(target, _values[id], x + ColumnWidth - 12, y, color)

	public override def Button(input as TButtonCode):
		return unless _inputFocus
		if assigned(FButtonLock):
			if FButtonLock.TimeRemaining == 0:
				FButtonLock = null
			else:
				return
		var count = FParsedText.Count
		var position = FCursorPosition cast int
		var target = position
		var columns = self.Columns cast int
		caseOf input:
			case TButtonCode.Enter:
				if count > 0 and FOptionEnabled[position]:
					PlaySound(TSfxTypes.Accept)
					Finish(position)
				else:
					PlaySound(TSfxTypes.Buzzer)
			case TButtonCode.Cancel:
				if _canCancel:
					PlaySound(TSfxTypes.Cancel)
					Finish(-1)
			case TButtonCode.Down:
				if position + columns < count:
					target = position + columns
				elif columns == 1:
					target = 0
			case TButtonCode.Up:
				if position >= columns:
					target = position - columns
				elif columns == 1:
					target = count - 1
			case TButtonCode.Right:
				target = position + 1 if columns > 1 and position < count - 1
			case TButtonCode.Left:
				target = position - 1 if columns > 1 and position > 0
			default: pass
		if (input in ARROW_KEYS) and target != position and count > 0:
			FButtonLock = Timestamp(180)
			PlaceCursor(target cast short)
			PlaySound(TSfxTypes.Cursor)

class TBattleStatusBox(TGameMenuBox):

	[Property(Heroes)]
	private _heroes = List[of THeroUnit]()

	[Property(ActiveRow)]
	private _activeRow = -1

	private _actorCursor as TMenuCursor

	private _selecting as bool

	private _all as bool

	[Getter(Done)]
	private _done as bool

	[Getter(Result)]
	private _result = -2

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		_actorCursor = TMenuCursor(parent, FRAME_DISPLACEMENT, 2, NULLRECT)
		_actorCursor.Blink = false
		FBlank = true

	public def BeginSelect(all as bool):
		_all = all
		_selecting = true
		_done = false
		_result = -2
		FBlank = false
		Array.Resize[of bool](FOptionEnabled, Math.Max(_heroes.Count, 1))
		for i in range(FOptionEnabled.Length):
			FOptionEnabled[i] = true
		Visible = true

	public def EndSelect():
		_selecting = false
		FBlank = true

	public override def DrawText():
		target = FTextTarget.RenderTarget
		for i in range(_heroes.Count):
			hero = _heroes[i]
			y = (i * ROW_HEIGHT_STATUS) + 2
			GFontEngine.DrawText(target, hero.Name, 0, y, 0)
			GFontEngine.DrawText(target, hero.TopConditionName, 58, y, hero.TopConditionColor)
			GFontEngine.DrawText(target, TBattleText.Vocab(V_STAT_SHORT_HP), 112, y, 1)
			GFontEngine.DrawTextRightAligned(target, hero.Hp.ToString(), 160, y, hero.HpColor)
			GFontEngine.DrawText(target, TBattleText.Vocab(V_STAT_SHORT_MP), 166, y, 1)
			GFontEngine.DrawTextRightAligned(target, hero.Sp.ToString(), 216, y, hero.SpColor)

	protected override def DoDraw():
		InvalidateText()
		super.DoDraw()

	protected override def PreDrawText():
		return if _selecting or _activeRow < 0 or _activeRow >= _heroes.Count
		coords = GPU_MakeRect(FBounds.x + 4, FBounds.y + 8 + (_activeRow * ROW_HEIGHT_STATUS) - 1, \
				(FBounds.w - FBounds.x) - 8, 18)
		_actorCursor.Layout(coords)
		_actorCursor.Visible = true
		_actorCursor.Draw()
		_actorCursor.Visible = false

	protected override def DoCursor(position as short):
		return unless _selecting and self.Focused
		position = Math.Max(Math.Min(position, _heroes.Count - 1), 0)
		FCursorPosition = position
		height = (_heroes.Count * ROW_HEIGHT_STATUS if _all else ROW_HEIGHT_STATUS)
		top = (0 if _all else position * ROW_HEIGHT_STATUS)
		cursor = FMenuEngine.Cursor
		cursor.Visible = true
		cursor.Layout(GPU_MakeRect(FBounds.x + 4, FBounds.y + 8 + top - 1, (FBounds.w - FBounds.x) - 8, height + 2))

	public override def Button(input as TButtonCode):
		return unless _selecting
		if assigned(FButtonLock):
			if FButtonLock.TimeRemaining == 0:
				FButtonLock = null
			else:
				return
		position = FCursorPosition cast int
		target = position
		caseOf input:
			case TButtonCode.Enter:
				PlaySound(TSfxTypes.Accept)
				_result = position
				_done = true
				_selecting = false
			case TButtonCode.Cancel:
				PlaySound(TSfxTypes.Cancel)
				_result = -1
				_done = true
				_selecting = false
			case TButtonCode.Down:
				target = (position + 1 if position + 1 < _heroes.Count else 0)
			case TButtonCode.Up:
				target = (position - 1 if position > 0 else _heroes.Count - 1)
			default: pass
		if (input in (TButtonCode.Up, TButtonCode.Down)) and not _all and target != position:
			FButtonLock = Timestamp(180)
			PlaceCursor(target cast short)
			PlaySound(TSfxTypes.Cursor)

class TBattleMessageBox(TGameMenuBox):

	private _lines = List[of string]()

	[Property(InputFocus)]
	private _inputFocus as bool

	[Getter(Done)]
	private _done as bool

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		FBlank = true

	public def ClearLines():
		_lines.Clear()
		InvalidateText()

	public def Add(line as string):
		_lines.Add(line)
		_lines.RemoveAt(0) while _lines.Count > MESSAGE_ROWS
		InvalidateText()

	public def SetLines(lines as IList[of string]):
		_lines.Clear()
		_lines.AddRange(lines)
		InvalidateText()

	public def BeginWait():
		_done = false
		_inputFocus = true

	public override def DrawText():
		target = FTextTarget.RenderTarget
		for i in range(_lines.Count):
			GFontEngine.DrawText(target, _lines[i], 3, (i * 16) + 3, 0)

	public override def Button(input as TButtonCode):
		return unless _inputFocus
		if input in (TButtonCode.Enter, TButtonCode.Cancel):
			_done = true
			_inputFocus = false

class TBattlePage(TMenuPage):

	[Getter(Status)]
	private _status as TBattleStatusBox

	[Getter(Commands)]
	private _commands as TBattleListBox

	[Getter(ActorCommands)]
	private _actorCommands as TBattleListBox

	[Getter(Enemies)]
	private _enemies as TBattleListBox

	[Getter(Skills)]
	private _skills as TBattleListBox

	[Getter(Items)]
	private _items as TBattleListBox

	[Getter(Help)]
	private _help as TOnelineLabelBox

	[Getter(Messages)]
	private _messages as TBattleMessageBox

	[Getter(Monsters)]
	private _monsterList = List[of TBattleMonster]()

	[Getter(Effects)]
	private _effects as SpriteEngine

	private _flash as SDL.SDL_Color

	private _flashAlpha as int

	private _flashTicks as int

	private _flashLength as int

	private _hidden = List[of TGameMenuBox]()

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string):
		super(parent, coords, main, layout)
		_status = TBattleStatusBox(parent, GPU_MakeRect(COMMAND_WIDTH, 160, 320, 240), main, self)
		RegisterComponent('Status', _status)
		_commands = TBattleListBox(parent, GPU_MakeRect(0, 160, COMMAND_WIDTH, 240), main, self, 1)
		RegisterComponent('Commands', _commands)
		_actorCommands = TBattleListBox(parent, GPU_MakeRect(320, 160, 320 + COMMAND_WIDTH, 240), main, self, 1)
		_actorCommands.StayVisible = true
		RegisterComponent('ActorCommands', _actorCommands)
		_enemies = TBattleListBox(parent, GPU_MakeRect(0, 160, 136, 240), main, self, 1)
		RegisterComponent('Enemies', _enemies)
		_skills = TBattleListBox(parent, GPU_MakeRect(0, 160, 320, 240), main, self, 2)
		RegisterComponent('Skills', _skills)
		_items = TBattleListBox(parent, GPU_MakeRect(0, 160, 320, 240), main, self, 2)
		RegisterComponent('Items', _items)
		_help = TOnelineLabelBox(parent, GPU_MakeRect(0, 0, 320, 32), main, self)
		RegisterComponent('Help', _help)
		_messages = TBattleMessageBox(parent, GPU_MakeRect(0, 160, 320, 240), main, self)
		RegisterComponent('Messages', _messages)
		self.Visible = false

	protected override def SetVisible(value as bool):
		unless value:
			super.SetVisible(false)
		FVisible = value

	public def SlideTo(step as int):
		var offset = (COMMAND_WIDTH * step) / SLIDE_LENGTH
		_commands.MoveTo(GPU_MakeRect(-offset, 160, COMMAND_WIDTH - offset, 240))
		_status.MoveTo(GPU_MakeRect(COMMAND_WIDTH - offset, 160, 320 - offset, 240))
		_actorCommands.MoveTo(GPU_MakeRect(320 - offset, 160, 320 - offset + COMMAND_WIDTH, 240))

	public def HideBoxes():
		for box in FComponentList:
			box.Visible = false

	public def Suspend():
		_hidden.Clear()
		for box in FComponentList:
			if box.Visible:
				_hidden.Add(box)
				box.Visible = false

	public def Resume():
		for box in _hidden:
			box.Visible = true
		_hidden.Clear()

	public def Open(box as TGameMenuBox, position as int):
		FCurrentMenu = box
		box.Visible = true
		box.PlaceCursor(position cast short)

	public def Focus(box as TGameMenuBox):
		FCurrentMenu = box

	public def Release():
		FCurrentMenu = _status
		GMenuEngine.Value.Cursor.Visible = false

	public def BeginBattle():
		_monsterList.Clear()
		_effects.Dispose() if _effects is not null
		_effects = SpriteEngine(null, GMenuEngine.Value.Canvas)
		_effects.Images = GMenuEngine.Value.Images
		_flashAlpha = 0
		_flashTicks = 0
		HideBoxes()
		SlideTo(0)
		_status.Heroes.Clear()
		_status.ActiveRow = -1
		_messages.ClearLines()

	public def EndBattle():
		_monsterList.Clear()
		if _effects is not null:
			_effects.Dispose()
			_effects = null
		HideBoxes()
		FBackground = ''

	public def SetBackdrop(filename as string):
		if string.IsNullOrEmpty(filename):
			FBackground = ''
			return
		try:
			SetBG("BattleBGs\\$filename.png", 'Battle BG ' + filename)
		except ex as Exception:
			System.Diagnostics.Debug.WriteLine("Battle background '$filename' could not be loaded: $(ex.Message)")
			FBackground = ''

	public def FlashScreen(r as int, g as int, b as int, power as int, ticks as int):
		_flash = SDL.SDL_Color(r: r cast byte, g: g cast byte, b: b cast byte, a: 255)
		_flashAlpha = Math.Min(power * 255 / 31, 255)
		_flashLength = Math.Max(ticks, 1)
		_flashTicks = _flashLength

	public def DrawScene():
		unless string.IsNullOrEmpty(FBackground):
			GMenuEngine.Value.Images.Image[FBackground].Draw()
		for monster in _monsterList:
			monster.Draw()
		if _effects is not null:
			_effects.Dead()
			_effects.Draw()
		if _flashTicks > 0:
			--_flashTicks
			alpha = (_flashAlpha * _flashTicks) / _flashLength
			GMenuEngine.Value.Canvas.FillRect(GPU_MakeRect(0, 0, 320, 240), _flash, alpha cast byte)

	protected override def DoDraw():
		DrawScene()

	public def Finish():
		Return()
