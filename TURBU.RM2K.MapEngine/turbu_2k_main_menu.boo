namespace TURBU.RM2K.Menus

import turbu.defs
import TURBU.TextUtils
import TURBU.RM2K
import turbu.constants
import turbu.resists
import commons
import Boo.Adt
import Pythia.Runtime
import System
import turbu.RM2K.environment
import turbu.Heroes
import TURBU.RM2K.RPGScript
import SG.defs
import TURBU.Meta
import SDL2.SDL2_GPU

enum TMainPanelState:
	Choosing
	PartySkill
	PartyEq

class TGamePartyPanel(TCustomPartyPanel):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FState as TMainPanelState

	public override def DrawText():
		var i = 1
		var target = FTextTarget.RenderTarget
		while GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
			FPortrait[i - 1].Draw()
			var origin2 = sgPoint(round(FPortrait[i - 1].X - Engine.WorldX) + 54, round(FPortrait[i - 1].Y - Engine.WorldY) + 2)
			hero as TRpgHero = GEnvironment.value.Party[i]
			GFontEngine.DrawText(target, hero.Name, origin2.x, origin2.y, 0)
			GFontEngine.DrawText(target, hero.Title, origin2.x + 92, origin2.y, 0)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_LV], origin2.x, (origin2.y + 16), 1)
			GFontEngine.DrawText(target, hero.Level.ToString(), origin2.x + 16, origin2.y + 16, 0)
			if hero.HighCondition == 0:
				GFontEngine.DrawText(target, GDatabase.value.Vocab[V_NORMAL_STATUS], (origin2.x + 38), (origin2.y + 16), 0)
			else:
				cond as TConditionTemplate = GDatabase.value.Conditions[hero.HighCondition]
				GFontEngine.DrawText(target, cond.Name, origin2.x + 38, origin2.y + 16, cond.Color)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_HP], origin2.x + 102, origin2.y + 16, 1)
			GFontEngine.DrawTextRightAligned(target, hero.HP.ToString(), origin2.x + 138, origin2.y + 16, 0)
			GFontEngine.DrawText(target, '/', origin2.x + 138, origin2.y + 16, 0)
			GFontEngine.DrawTextRightAligned(target, hero.MaxHp.ToString(), origin2.x + 162, origin2.y + 16, 0)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_EXP], origin2.x, origin2.y + 32, 1)
			GFontEngine.DrawTextRightAligned(target, hero.Exp.ToString(), origin2.x + 54, origin2.y + 32, 0)
			GFontEngine.DrawText(target, '/', origin2.x + 54, origin2.y + 32, 0)
			GFontEngine.DrawTextRightAligned(target, (hero.Exp + hero.ExpNeeded).ToString(), origin2.x + 98, origin2.y + 32, 0)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_MP], origin2.x + 102, origin2.y + 32, 1)
			GFontEngine.DrawTextRightAligned(target, hero.MP.ToString(), origin2.x + 138, origin2.y + 32, 0)
			GFontEngine.DrawText(target, '/', origin2.x + 138, origin2.y + 32, 0)
			GFontEngine.DrawTextRightAligned(target, hero.MaxMp.ToString(), origin2.x + 162, origin2.y + 32, 0)
			++i

	public override def DoSetup(value as int):
		super.DoSetup(value)
		if FSetupValue in (0, 1, 2):
			FState = FSetupValue cast TMainPanelState

	public override def DoButton(input as TButtonCode):
		super.DoButton(input)
		caseOf input:
			case TButtonCode.Enter:
				var cursorValue = GEnvironment.value.Party[FCursorPosition + 1].Template.ID
				caseOf FState:
					case TMainPanelState.PartySkill: self.FocusPage('Skills', cursorValue)
					case TMainPanelState.PartyEq: self.FocusPage('Equipment', cursorValue)
					default: assert false
			case TButtonCode.Cancel: FState = TMainPanelState.Choosing
			default:
				pass

class TGameMainMenu(TGameMenuBox):

	protected override def ParseText(input as string):
		SetText(input)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		let MENUTEXT = """Item
Skill
Equipment
Save
End Game"""
		super(parent, coords, main, owner)
		self.Text = MENUTEXT
		Array.Resize[of bool](FOptionEnabled, 5)
		for i in range(5):
			FOptionEnabled[i] = true

	public override def DrawText():
		yVal as int
		if self.Visible:
			for i in range(0, Math.Min(FParsedText.Count - 1, 4) + 1):
				yVal = 3 + (i * 15)
				color as int = (0 if FOptionEnabled[i] else 3)
				GFontEngine.DrawText(FTextTarget.RenderTarget, FParsedText[i], 4, yVal, color)

	public override def DoSetup(value as int):
		super.DoSetup(value)
		FOptionEnabled[1] = GEnvironment.value.Party.Size > 0
		FOptionEnabled[2] = GEnvironment.value.Party.Size > 0
		FOptionEnabled[3] = GEnvironment.value.SaveEnabled
		self.PlaceCursor(FSetupValue)

	public override def DoButton(input as TButtonCode):
		super.DoButton(input)
		if (input == TButtonCode.Enter) and FOptionEnabled[FCursorPosition]:
			caseOf FCursorPosition:
				case 0:
					self.FocusPage('Inventory', 0)
				case 1:
					self.FocusMenu('Party', 1)
				case 2:
					self.FocusMenu('Party', 2)
				case 3:
					if OptionEnabled[3]:
						SaveMenu() //async method, deliberately not awaiting
				case 4:
					self.Return()
					GEnvironment.value.TitleScreen()

let MAIN_LAYOUT = """
	[{"Name": "Main",  "Class": "TGameMainMenu",   "Coords": [0,  0,   88,  96 ]},
	 {"Name": "Party", "Class": "TGamePartyPanel", "Coords": [88, 0,   320, 240]},
	 {"Name": "Cash",  "Class": "TGameCashMenu",   "Coords": [0,  208, 88,  240]}]"""
initialization :
	TMenuEngine.RegisterMenuPage('Main', MAIN_LAYOUT)
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameMainMenu))
	TMenuEngine.RegisterMenuBoxClass(classOf(TGamePartyPanel))
