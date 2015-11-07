namespace TURBU.RM2K.Menus

import turbu.defs
import TURBU.RM2K
import TURBU.TextUtils
import turbu.constants
import turbu.skills
import turbu.resists
import TURBU.RM2K.RPGScript
import Boo.Adt
import Pythia.Runtime
import turbu.RM2K.items
import turbu.RM2K.skills
import System
import turbu.Heroes
import turbu.RM2K.environment
import turbu.RM2K.Item.types
import SDL2.SDL2_GPU
import TURBU.Meta
import SG.defs

class TQuantityBox(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FItem as TRpgItem

	private FSkill as TRpgSkill

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private new def Clear():
		FItem = null
		FSkill = null

	public override def DrawText():
		if (not assigned(FItem)) and (not assigned(FSkill)):
			return
		target = FTextTarget.RenderTarget
		if assigned(FItem):
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_ITEMS_OWNED], 10, 2, 2)
			GFontEngine.DrawTextRightAligned(target, FItem.Quantity.ToString(), 116, 2, 1)
		else:
			assert assigned(FSkill)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_MP_COST], 10, 2, 2)
			GFontEngine.DrawTextRightAligned(target, FSkill.Template.Cost.ToString(), 116, 2, 1)

	public RpgItem as TRpgItem:
		set:
			self.Clear()
			FItem = value

	public Skill as TRpgSkill:
		set:
			self.Clear()
			FSkill = value

class TGameMiniPartyPanel(TCustomPartyPanel):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FItem as TRpgItem

	private FSkill as TRpgSkill

	private def UseItem():
		target as TRpgHero
		sound as TSfxTypes
		assert FItem isa TAppliedItem
		sound = -1 cast TSfxTypes
		if FItem.Quantity > 0:
			target = GEnvironment.value.Party[FCursorPosition + 1]
			if (FItem cast TAppliedItem).AreaItem():
				if (FItem cast TAppliedItem).UsableArea:
					if not (FItem isa TSkillItem):
						sound = TSfxTypes.Accept
					(FItem cast TAppliedItem).UseArea()
				else:
					sound = TSfxTypes.Buzzer
			elif FItem.UsableBy(target.Template.ID):
				if not (FItem isa TSkillItem):
					sound = TSfxTypes.Accept
				(FItem cast TAppliedItem).Use(target)
			else:
				sound = TSfxTypes.Buzzer
		else:
			sound = TSfxTypes.Buzzer
		if sound != -1 cast TSfxTypes:
			PlaySound(sound)
		else:
			assert FItem isa TSkillItem
			PlaySoundData((FItem cast TSkillItem).Skill.FirstSound)

	private def UseSkill():
		caster as TRpgHero
		target as TRpgHero
		sound as TSfxTypes
		sound = -1 cast TSfxTypes
		assert assigned(FSkill)
		caster = FMenuEngine.CurrentHero
		if caster.MP < FSkill.Template.Cost:
			sound = TSfxTypes.Buzzer
		else:
			target = GEnvironment.value.Party[(FCursorPosition + 1)]
			if FSkill.Template.Range == TSkillRange.Area:
				if FSkill.UsableParty():
					FSkill.UseParty(caster)
				else:
					sound = TSfxTypes.Buzzer
			elif FSkill.UsableOn(target.Template.ID):
				FSkill.UseHero(caster, target)
			else:
				sound = TSfxTypes.Buzzer
		if sound != -1 cast TSfxTypes:
			PlaySound(sound)
		else:
			PlaySoundData(FSkill.FirstSound)
			caster.MP -= FSkill.Template.Cost

	private def SetSkill(value as TRpgSkill):
		FSkill = value

	public override def DrawText():
		origin as TSgPoint
		hero as TRpgHero
		cond as TConditionTemplate
		i = 1
		while GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
			FPortrait[i].Draw()
			origin = sgPoint(Math.Round(FPortrait[i].X) + 54, Math.Round(FPortrait[i].Y) + 3)
			hero = GEnvironment.value.Party[i]
			target = FTextTarget.RenderTarget
			GFontEngine.DrawText(target, hero.Name, origin.x + 1, origin.y, 1)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_LV], origin.x + 1, origin.y + 16, 1)
			GFontEngine.DrawText(target, hero.Level.ToString(), origin.x + 17, origin.y + 16, 1)
			if hero.HighCondition == 0:
				GFontEngine.DrawText(target, GDatabase.value.Vocab[V_NORMAL_STATUS], origin.x + 1, origin.y + 32, 1)
			else:
				cond = GDatabase.value.Conditions[hero.HighCondition]
				GFontEngine.DrawText(target, cond.Name, origin.x + 1, origin.y + 32, cond.Color)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_HP], origin.x + 52, origin.y + 16, 2)
			GFontEngine.DrawTextRightAligned(target, hero.HP.ToString(), origin.x + 86, origin.y + 16, 1)
			GFontEngine.DrawText(target, '/', origin.x + 86, origin.y + 16, 1)
			GFontEngine.DrawTextRightAligned(target, hero.MaxHp.ToString(), origin.x + 110, origin.y + 16, 1)
			GFontEngine.DrawText(target, GDatabase.value.Vocab[V_STAT_SHORT_MP], origin.x + 52, origin.y + 32, 2)
			GFontEngine.DrawTextRightAligned(target, hero.MP.ToString(), origin.x + 86, origin.y + 32, 1)
			GFontEngine.DrawText(target, '/', origin.x + 86, origin.y + 32, 1)
			GFontEngine.DrawTextRightAligned(target, hero.MaxMp.ToString(), origin.x + 110, origin.y + 32, 1)
			++i

	public override def DoSetup(value as int):
		Quantity as TQuantityBox
		itemBox as TOnelineLabelBox
		super.DoSetup(value)
		FItem = null
		SetSkill(null)
		Quantity = FOwner.Menu('Quantity') cast TQuantityBox
		itemBox = FOwner.Menu('Item') cast TOnelineLabelBox
		if FSetupValue > 0:
			SetSkill(TRpgSkill(FSetupValue))
			Quantity.Skill = FSkill
			itemBox.Text = FSkill.Template.Name
		else:
			FItem = (GEnvironment.value.Party.Inventory[Math.Abs(FSetupValue)] cast TRpgItem)
			Quantity.RpgItem = FItem
			itemBox.Text = FItem.Template.Name

	public override def MoveTo(coords as GPU_Rect):
		i as byte
		super.MoveTo(coords)
		for i in range(FPortrait.Length):
			if assigned(FPortrait[i]):
				FPortrait[i].X = self.X + 8
				FPortrait[i].Y = self.Y + 8 + (i * 56)

	public override def DoButton(input as TButtonCode):
		if input != TButtonCode.Enter:
			super.DoButton(input)
		caseOf input:
			case TButtonCode.Enter:
				if assigned(FItem):
					UseItem()
				else: UseSkill()
			case TButtonCode.Cancel:
				if assigned(FItem) and (FItem.Quantity == 0):
					GEnvironment.value.Party.Inventory.Remove(FItem.Template.ID, 0)
			default:
				pass

let PARTY_TARGET_LAYOUT = """[
	{"Name": "Party",    "Class": "TGameMiniPartyPanel", "Coords": [136, 0,  320, 240]},
	{"Name": "Item",     "Class": "TOnelineLabelBox",    "Coords": [0,   0,  136, 32 ]},
	{"Name": "Quantity", "Class": "TQuantityBox",        "Coords": [0,   32, 136, 64 ]}]"""

initialization :
	TMenuEngine.RegisterMenuPage('PartyTarget', PARTY_TARGET_LAYOUT)
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameMiniPartyPanel))
	TMenuEngine.RegisterMenuBoxClass(classOf(TQuantityBox))
