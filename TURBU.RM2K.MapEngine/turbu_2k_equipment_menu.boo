namespace TURBU.RM2K.Menus

import System
import System.Linq.Enumerable

import turbu.defs
import turbu.items
import SG.defs
import timing
import turbu.constants
import TURBU.Meta
import TURBU.TextUtils
import TURBU.RM2K
import Pythia.Runtime
import turbu.Heroes
import turbu.RM2K.items
import turbu.RM2K.Item.types
import turbu.RM2K.environment
import SDL2.SDL2_GPU

class TCharStatBox(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FBoxOrigin as TSgPoint

	[Property(Char)]
	private FChar as TRpgHero

	private FPotentialItem as TRpgItem

	private FPotential = array(int, 4)

	internal FCurrentSlot as TSlot

	[Property(Active)]
	private FActive as bool

	protected override def DrawText():
		database as TRpgDatabase
		i as int
		color as int
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, FChar.Name, FBoxOrigin.x, FBoxOrigin.y, 0)
		database = GDatabase.value
		GFontEngine.DrawText(target, database.Vocab[V_STAT_ATTACK], FBoxOrigin.x, FBoxOrigin.y + 16, 1)
		GFontEngine.DrawText(target, database.Vocab[V_STAT_DEFENSE], FBoxOrigin.x, FBoxOrigin.y + 32, 1)
		GFontEngine.DrawText(target, database.Vocab[V_STAT_MIND], FBoxOrigin.x, FBoxOrigin.y + 48, 1)
		GFontEngine.DrawText(target, database.Vocab[V_STAT_SPEED], FBoxOrigin.x, FBoxOrigin.y + 64, 1)
		GFontEngine.DrawTextRightAligned(target, FChar.Attack.ToString(), FBoxOrigin.x + 76, FBoxOrigin.y + 16, 0)
		GFontEngine.DrawTextRightAligned(target, FChar.Defense.ToString(), FBoxOrigin.x + 76, FBoxOrigin.y + 32, 0)
		GFontEngine.DrawTextRightAligned(target, FChar.Mind.ToString(), FBoxOrigin.x + 76, FBoxOrigin.y + 48, 0)
		GFontEngine.DrawTextRightAligned(target, FChar.Agility.ToString(), FBoxOrigin.x + 76, FBoxOrigin.y + 64, 0)
		for i in range(1, 5):
			GFontEngine.DrawText(target, '->', FBoxOrigin.x + 76, FBoxOrigin.y + (i * 16), 1)
		if FActive:
			for i in range(1, 5):
				if FPotential[i - 1] > FChar.Stat[i]:
					color = 2
				elif FPotential[i - 1] < FChar.Stat[i]:
					color = 3
				else: color = 0
				GFontEngine.DrawTextRightAligned(target, FPotential[i - 1].ToString(), FBoxOrigin.x + 108, FBoxOrigin.y + (i * 16), color)

	public PotentialItem as TRpgItem:
		set:
			FPotentialItem = value
			InvalidateText()
			if assigned(value):
				for i in range(1, 5):
					FPotential[i - 1] = FChar.PotentialStat(value.Template.ID, i, FCurrentSlot)
			else:
				for i in range(1, 5):
					FPotential[i - 1] = FChar.PotentialStat(0, i, FCurrentSlot)

	internal CurrentSlot as TSlot:
		set:
			FCurrentSlot = value;
			InvalidateText()

class TEqInventoryMenu(TCustomScrollBox):

	private FCurrentItem as TRpgItem

	[Property(Char)]
	private FChar as TRpgHero

	[Property(Slot)]
	private FCurrentSlot as TSlot

	protected override def DrawItem(id as int, x as int, y as int, color as int):
		if id < (FParsedText.Count - 1):
			target = FTextTarget.RenderTarget
			GFontEngine.DrawText(target, FParsedText[id], x, y, color)
			GFontEngine.DrawTextRightAligned(target, (FParsedText.Objects[id] cast TEquipment).Quantity.ToString(), x + 140, y, color)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		FOwner = owner
		self.Columns = 2
		FDisplayCapacity = 12

	public def Show(slot as TSlot):
		FParsedText.Clear()
		for item in GEnvironment.value.Party.Inventory \
				.OfType[of TEquipment]() \
				.Where({eq | (eq.Template cast TEquipmentTemplate).Slot == slot and eq.UsableBy(FChar.Template.ID)}):
			FParsedText.AddObject(item.Template.Name, item)
		FParsedText.AddObject('', null)
		Array.Resize[of bool](FOptionEnabled, FParsedText.Count)
		for i in range(FOptionEnabled.Length):
			FOptionEnabled[i] = true
		FCurrentSlot = slot
		InvalidateText()

	public override def DoCursor(position as short):
		coords as GPU_Rect
		stat as TCharStatBox
		assert position >= 0
		if (position cast ushort) >= FParsedText.Count:
			position = FParsedText.Count - 1
		if position < FTopPosition:
			FTopPosition = position - (position % self.Columns)
		elif position > FTopPosition + FDisplayCapacity:
			FTopPosition = ((position - (position % self.Columns)) + self.Columns) - FDisplayCapacity
		coords = GPU_MakeRect(6 + ((position % 2) * 156), (((position / 2) * 15) + FOrigin.y) + 8, 150, 18)
		FMenuEngine.Cursor.Layout(coords)
		FCursorPosition = position
		if position < (FParsedText.Count - 1):
			FCurrentItem = (FParsedText.Objects[position] cast TEquipment)
		else:
			FCurrentItem = null
		stat = (FOwner.Menu('Stat') cast TCharStatBox)
		stat.PotentialItem = FCurrentItem
		stat.Active = true
		FOwner.Menu('Desc').Text = (FCurrentItem.Desc if FCurrentItem != null else '')

	public override def DoButton(input as TButtonCode):
		stat as TCharStatBox
		super.DoButton(input)
		if input == TButtonCode.Enter:
			if FParsedText.Objects[FCursorPosition] == null:
				FChar.Unequip(FCurrentSlot)
			else:
				FChar.Equip((FParsedText.Objects[FCursorPosition] cast TEquipment).Template.ID)
			self.Show(FCurrentSlot)
			stat = FOwner.Menu('Stat') cast TCharStatBox
			stat.PotentialItem = null
			stat.Active = false
			self.Return()

[Disposable]
class TGameEquipmentMenu(TGameMenuBox):

	private FPassiveCursor as TSysFrame

	private FChar as TRpgHero

	private FPlacingCursor as bool

	protected override def DrawText():
		lOrigin as TSgPoint = ORIGIN
		FPassiveCursor.Draw() unless self.Focused
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_WEAPON], lOrigin.x + 6, lOrigin.y + 2, 1)
		caseOf FChar.DualWield:
			case TWeaponStyle.Single, TWeaponStyle.Shield:
				GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_SHIELD], lOrigin.x + 6, lOrigin.y + 18, 1)
			default :
				GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_WEAPON], lOrigin.x + 6, lOrigin.y + 18, 1)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_ARMOR], lOrigin.x + 6, lOrigin.y + 34, 1)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_HELMET], lOrigin.x + 6, lOrigin.y + 50, 1)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_EQ_ACCESSORY], lOrigin.x + 6, lOrigin.y + 66, 1)
		for i in range(0, 5):
			GFontEngine.DrawText(target, FParsedText[i], lOrigin.x + 68, lOrigin.y + (i * 16) + 2, 0)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		for i in range(1, 6):
			FParsedText.Add('')
			FOptionEnabled[i - 1] = true
		FPassiveCursor = TSysFrame(GMenuEngine.Value, ORIGIN, 0, GMenuEngine.Value.Cursor.Bounds)

	public override def DoSetup(value as int):
		ourHero as TRpgHero
		super.DoSetup(value)
		InvalidateText()
		ourHero = GEnvironment.value.Heroes[FSetupValue]
		self.Char = ourHero
		for i in range(TSlot.Relic):
			FParsedText[i] = (GDatabase.value.Items[ourHero.Equipment[i]].Name if ourHero.Equipment[i] != 0 else '')
		self.DoCursor(FCursorPosition)

	public override def DoCursor(position as short):
		coords as GPU_Rect
		inv as TEqInventoryMenu
		if FPlacingCursor:
			return
		FPlacingCursor = true
		try:
			if position == FCursorPosition:
				Setup(CURSOR_UNCHANGED)
			coords = GPU_MakeRect(FOrigin.x + 6, (FOrigin.y + 8) + (position * 16), self.Width - 12, 16)
			GMenuEngine.Value.Cursor.Visible = true
			GMenuEngine.Value.Cursor.Layout(coords)
			FCursorPosition = position
			FOwner.Menu('Desc').Text = (GDatabase.value.Items[FChar.Equipment[position]].Desc if FChar.Equipment[position] != 0 else '')
			inv = (FOwner.Menu('Inventory') cast TEqInventoryMenu)
			if (position == 1) and (FChar.DualWield == TWeaponStyle.Dual):
				inv.Show(TSlot.Weapon)
			else:
				inv.Show(position)
			(FOwner.Menu('Stat') cast TCharStatBox).CurrentSlot = position
		ensure:
			FPlacingCursor = false

	public override def DoButton(input as TButtonCode):
		def NextChar() as TRpgHero:
			charIndex as int = GEnvironment.value.Party.IndexOf(FChar)
			index = (1 if charIndex == GEnvironment.value.Party.Size else charIndex + 1)
			return GEnvironment.value.Party[index]
		
		def PrevChar() as TRpgHero:
			charIndex as int = GEnvironment.value.Party.IndexOf(FChar)
			index = (GEnvironment.value.Party.Size if charIndex == 1 else charIndex - 1)
			return GEnvironment.value.Party[index]
		
		dummy as GPU_Rect
		newChar as TRpgHero
		super.DoButton(input)
		if input == TButtonCode.Enter:
			dummy = GMenuEngine.Value.Cursor.Bounds
			dummy = GPU_MakeRect(
				dummy.x - Math.Round(FEngine.WorldX),
				dummy.y - Math.Round(FEngine.WorldY),
				dummy.w,
				dummy.h)
			FPassiveCursor.Layout(dummy)
			self.FocusMenu('Inventory', 0)
		elif (input in (TButtonCode.Left, TButtonCode.Right)) and (GEnvironment.value.Party.Size > 1):
			newChar = (PrevChar() if input == TButtonCode.Left else NextChar())
			self.DoSetup(newChar.Template.ID)
			FButtonLock = TRpgTimestamp(180)

	public Char as TRpgHero:
		get: return FChar
		set: 
			FChar = value
			(FOwner.Menu('Stat') cast TCharStatBox).Char = value
			(FOwner.Menu('Inventory') cast TEqInventoryMenu).Char = value


initialization :
	TMenuEngine.RegisterMenuPage('Equipment', """[
		{"Name": "Equip",     "Class": "TGameEquipmentMenu", "Coords": [128, 32,  320, 128]},
		{"Name": "Desc",      "Class": "TOnelineLabelBox",   "Coords": [0,   0,   320, 32 ]},
		{"Name": "Stat",      "Class": "TCharStatBox",       "Coords": [0,   32,  128, 128]},
		{"Name": "Inventory", "Class": "TEqInventoryMenu",   "Coords": [0,   128, 320, 240]}]""")
	TMenuEngine.RegisterMenuBoxClass(classOf(TCharStatBox))
	TMenuEngine.RegisterMenuBoxClass(classOf(TEqInventoryMenu))
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameEquipmentMenu))
