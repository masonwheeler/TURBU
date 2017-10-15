namespace TURBU.RM2K.Menus

import turbu.defs
import TURBU.RM2K
import turbu.skills
import TURBU.TextUtils
import Boo.Adt
import Pythia.Runtime
import System
import turbu.Heroes
import turbu.RM2K.environment
import SDL2.SDL2_GPU

class TGameSkillMenu(TCustomScrollBox):

	[Property(Hero)]
	private FWhichHero as ushort

	private FSkillIndex as (ushort)

	protected override def DrawItem(id as int, x as int, y as int, color as int):
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, FParsedText[id], x, y, color)
		GFontEngine.DrawText(target, '-', x + 112, y, color)
		GFontEngine.DrawTextRightAligned(target, GDatabase.value.Skill[FSkillIndex[id]].Cost.ToString(), x + 136, y, color)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		self.Columns = 2
		FDisplayCapacity = 20

	public override def DoSetup(value as int):
		index as int
		ourHero as TRpgHero
		super.DoSetup(value)
		assert FSetupValue > 0
		FWhichHero = FSetupValue
		ourHero = GEnvironment.value.Heroes[FWhichHero]
		FMenuEngine.CurrentHero = ourHero
		(FOwner.Menu('CharData') cast TOnelineCharReadout).Character = FWhichHero
		Array.Resize[of bool](FOptionEnabled, ourHero.Skills)
		ClearText()
		Array.Resize[of ushort](FSkillIndex, ourHero.Skills)
		index = 0
		for i in range(1, GDatabase.value.Skill.Count):
			if ourHero.Skill[i]:
				FSkillIndex[index] = i
				FOptionEnabled[index] = GDatabase.value.Skill[i].Usable in (TUsableWhere.Field, TUsableWhere.Both)
				++index
				FParsedText.Add(GDatabase.value.Skill[i].Name)
		self.Visible = true
		self.DoCursor(0)

	public override def DoCursor(position as short):
		super.DoCursor(position)
		if GEnvironment.value.Heroes[FWhichHero].Skills > 0:
			FOwner.Menu('Effect').Text = GDatabase.value.Skill[FSkillIndex[position]].Desc

	public override def DoButton(input as TButtonCode):
		super.DoButton(input)
		if input == TButtonCode.Enter:
			if (FCursorPosition < FOptionEnabled.Length) and FOptionEnabled[FCursorPosition]:
				self.FocusPage('PartyTarget', FSkillIndex[FCursorPosition])
				if GDatabase.value.Skill[FSkillIndex[FCursorPosition]].Range == TSkillRange.Area:
					FMenuEngine.PlaceCursor(-1)
				else:
					FMenuEngine.PlaceCursor(0)
			elif FCursorPosition >= FOptionEnabled.Length:
				PlaySound(TSfxTypes.Buzzer)


let SKILL_LAYOUT = """
	[{"Name": "Skill",    "Class": "TGameSkillMenu",      "Coords": [0, 64, 320, 240]},
	 {"Name": "Effect",   "Class": "TOnelineLabelBox",    "Coords": [0, 0,  320, 32 ]},
	 {"Name": "CharData", "Class": "TOnelineCharReadout", "Coords": [0, 32, 320, 64 ]}]"""

initialization :
	TMenuEngine.RegisterMenuPage('Skills', SKILL_LAYOUT)
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameSkillMenu))
