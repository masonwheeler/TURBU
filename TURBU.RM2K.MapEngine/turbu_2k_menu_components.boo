namespace TURBU.RM2K.Menus

import sdl.sprite
import TURBU.TextUtils
import TURBU.RM2K
import turbu.constants
import turbu.characters
import SG.defs
import Pythia.Runtime
import System
import turbu.RM2K.items
import turbu.RM2K.environment
import SDL2.SDL2_GPU

class TGameCashMenu(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
	
	public override def DrawText():
		Money as string = GEnvironment.value.Money.ToString()
		yPos as single = 2
		target = FTextTarget.RenderTarget
		xPos as single = GFontEngine.DrawTextRightAligned(target, GDatabase.value.Vocab[V_MONEY_NAME], GetRightSide(), yPos, 1).x
		GFontEngine.DrawTextRightAligned(target, Money, xPos - 4, yPos, 0)

[Disposable]
abstract class TCustomScrollBox(TGameMenuBox):

	private FNextArrow as TSystemTile

	private FPrevArrow as TSystemTile

	private FTimer as byte

	protected FDisplayCapacity as byte

	protected FTopPosition as short

	protected abstract def DrawItem(id as int, x as int, y as int, color as int):
		pass

	protected override def DoCursor(position as short):
		if FParsedText.Count == 0:
			position = 0
		elif position >= FParsedText.Count:
			position = FParsedText.Count - 1
		if position < FTopPosition:
			FTopPosition = position - (position % FColumns)
		elif position >= FTopPosition + FDisplayCapacity:
			FTopPosition = ((position - (position % FColumns)) + FColumns) - FDisplayCapacity
		super.DoCursor(position - FTopPosition)
		FCursorPosition = position
		FPrevArrow.Visible = FTopPosition > 0
		FNextArrow.Visible = (FTopPosition + FDisplayCapacity) < FParsedText.Count

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		FNextArrow = TSystemTile(parent, parent.SystemGraphic.Rects[TSystemRects.ArrowD], commons.ORIGIN, 0)
		FPrevArrow = TSystemTile(parent, parent.SystemGraphic.Rects[TSystemRects.ArrowU], commons.ORIGIN, 0)
		FNextArrow.ImageName = parent.SystemGraphic.Filename
		FPrevArrow.ImageName = parent.SystemGraphic.Filename
		FPrevArrow.Visible = false
		FNextArrow.Visible = false
		super(parent, coords, main, owner)

	public override def DrawText():
		j as int
		color as int
		max as int = FParsedText.Count - (FLastLineColumns + 1)
		for i in range(FTopPosition, Math.Min(max, (FTopPosition + FDisplayCapacity) - 1) + 1):
			j = i - FTopPosition
			color = (0 if FOptionEnabled[i] else 3)
			DrawItem(i, 5 + ((j % FColumns) * (ColumnWidth + SEPARATOR)), ((j / FColumns) * 15) + 4, color)
		if FLastLineColumns > 0:
			for i in range(max + 1, FParsedText.Count):
				j = i - (max + 1)
				color = (0 if FOptionEnabled[i] else 3)
				GFontEngine.DrawTextCentered(
					FTextTarget.RenderTarget,
					FParsedText[i],
					13 + ((j % FLastLineColumns) * (LastColumnWidth + SEPARATOR)),
					(((j / FLastLineColumns) + (i / FColumns)) * 15) + 12,
					color,
					LastColumnWidth)
		++FTimer
		if FTimer > 9:
			FPrevArrow.Draw()
			FNextArrow.Draw()
		FTimer = 0 if FTimer > 18

	public override def MoveTo(coords as GPU_Rect):
		super.MoveTo(coords)
		FPrevArrow.Y = FBounds.x
		FPrevArrow.X = (FBounds.x + Math.Truncate(FBounds.w / 2.0)) - Math.Truncate(FPrevArrow.PatternWidth / 2.0)
		FNextArrow.Y = (FBounds.x + FBounds.h) - 8
		FNextArrow.X = FPrevArrow.X

abstract class TCustomOnelineBox(TGameMenuBox):
	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

class TOnelineLabelBox(TCustomOnelineBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
	
	private FText = ''

	public override def DrawText():
		assert FOrigin.x >= 0
		GFontEngine.DrawText(FTextTarget.RenderTarget, FText, 2, 2,  0)

	public Text as string:
		set:
			FText = value
			InvalidateText()

class TOnelineCharReadout(TCustomOnelineBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	[Property(Character)]
	private FChar as ushort

	public override def DrawText():
		yPos as int
		hero = GEnvironment.value.Heroes[FChar]
		yPos = 2
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, hero.Name, 0, yPos, 0)
		GFontEngine.DrawText(target, GDatabase.value.Vocab['StatShort-Lv'], 78, yPos, 1)
		GFontEngine.DrawTextRightAligned(target, hero.Level.ToString(), 108, yPos, 0)
		if hero.HighCondition == 0:
			GFontEngine.DrawText(target, GDatabase.value.Vocab['Normal Status'], 118, yPos, 0)
		else:
			GFontEngine.DrawText(target, Name, 118, yPos, GDatabase.value.Conditions[hero.HighCondition].Color)
		GFontEngine.DrawText(target, GDatabase.value.Vocab['StatShort-HP'], 178, yPos, 1)
		GFontEngine.DrawTextRightAligned(target, hero.HP.ToString(), 216, yPos, 0)
		GFontEngine.DrawText(target, '/', 216, yPos, 0)
		GFontEngine.DrawTextRightAligned(target, hero.MaxHp.ToString(), 240, yPos, 0)
		GFontEngine.DrawText(target, GDatabase.value.Vocab['StatShort-MP'], 246, yPos, 1)
		GFontEngine.DrawTextRightAligned(target, hero.MP.ToString(), 280, yPos, 0)
		GFontEngine.DrawText(target, '/', 280, yPos, 0)
		GFontEngine.DrawTextRightAligned(target, hero.MaxMp.ToString(), 304, yPos, 0)

[Disposable(Destroy, true)]
abstract class TCustomPartyPanel(TGameMenuBox):

	protected FPortrait as (TSprite)

	protected FCount as byte

	protected override def DoSetup(value as int):
		template as TClassTemplate
		super.DoSetup(value)
		var i = 1
		FParsedText.Clear()
		Array.Resize[of bool](FOptionEnabled, GEnvironment.value.Party.Size)
		while GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
			template = GEnvironment.value.Party[i].Template
			FPortrait[i - 1].Dead() if assigned(FPortrait[i - 1])
			var newPortrait = LoadPortrait(template.Portrait, template.PortraitIndex)
			FPortrait[i - 1] = newPortrait
			newPortrait.X = 4
			newPortrait.Y = (i - 1) * 56
			newPortrait.SetSpecialRender()
			FParsedText.Add(GEnvironment.value.Party[i].Name)
			FOptionEnabled[i - 1] = true
			++i
		InvalidateText()
		FCount = i - 1
		if i < 4:
			for i in range(i, 4):
				if assigned(FPortrait[i]):
					FPortrait[i].Dead()
					FPortrait[i] = null
				FOptionEnabled[i - 1] = false if i < FOptionEnabled.Length

	protected override def DoCursor(position as short):
		coords as GPU_Rect
		origin2 as TSgPoint
		dummy as ushort
		cursor as TSysFrame
		if self.FDontChangeCursor:
			position = self.FCursorPosition
		origin2.x = (FOrigin.x + 4)
		if position != -1:
			origin2.y = ((FOrigin.y + (position * 56)) + 4)
			coords = GPU_MakeRect(origin2.x, origin2.y, self.Width - 8, 56)
		else:
			origin2.y = FOrigin.y + 4
			dummy = GEnvironment.value.Party.OpenSlot - 1
			dummy = 56 * dummy
			coords = GPU_MakeRect(origin2.x, origin2.y, self.Width - 66, dummy)
		cursor = (Engine cast TMenuSpriteEngine).Cursor
		cursor.Visible = true
		cursor.Layout(coords)
		FCursorPosition = position
		FDontChangeCursor = false

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		FPortrait = array(TSprite, 4) //this needs to be initialized before the super call, not in the declaration.
		super(parent, coords, main, owner)
		Array.Resize[of bool](FOptionEnabled, MAXPARTYSIZE)

	public override def MoveTo(coords as GPU_Rect):
		super.MoveTo(coords)
		for i in range(FPortrait.Length):
			if assigned(FPortrait[i]):
				FPortrait[i].X = 4
				FPortrait[i].Y = i * 56

	private new def Destroy():
		for portrait in FPortrait:
			portrait.Dispose() if portrait is not null

class TCustomGameItemMenu(TCustomScrollBox):

	private FInventory as TRpgInventory

	protected override def DrawItem(id as int, x as int, y as int, color as int):
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, FParsedText[id], x, y, color)
		GFontEngine.DrawText(target, ':', x + 120, y, color)
		GFontEngine.DrawTextRightAligned(target, FInventory[id].Quantity.ToString(), x + 136, y, color)

	protected override def DoSetup(value as int):
		super.DoSetup(value)
		FParsedText.Clear()
		if assigned(FInventory):
			Array.Resize[of bool](FOptionEnabled, FInventory.Count)
			FInventory.Sort()
			for i in range(0, FInventory.Count):
				FParsedText.Add(FInventory[i].Template.Name)
		else:
			Array.Resize[of bool](FOptionEnabled, 0)
		self.PlaceCursor(FSetupValue)
		InvalidateText()

	protected override def DoCursor(position as short):
		if self.FDontChangeCursor:
			position = self.FCursorPosition
		super.DoCursor(position)
		FDontChangeCursor = false

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		assert coords.h % 16 == 0
		super(parent, coords, main, owner)
		FDisplayCapacity = Math.Truncate((coords.h - 16) / 8.0)
		FColumns = 2

	public Inventory as TRpgInventory:
		get: return FInventory
		set:
			if FInventory != value:
				FInventory = value
				self.Setup(0)

def LoadPortrait(filename as string, index as byte) as TSprite:
	return null unless ArchiveUtils.GraphicExists(filename, 'portraits')
	
	engine as TSpriteEngine = GMenuEngine.Value
	engine.Images.EnsureImage("portraits\\$filename", filename, GDatabase.value.Layout.PortraitSize)
	result = TSprite(engine)
	result.Visible = true
	result.ImageName = filename
	result.ImageIndex = index
	result.SetSpecialRender()
	return result

initialization :
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameCashMenu))
	TMenuEngine.RegisterMenuBoxClass(classOf(TOnelineLabelBox))
	TMenuEngine.RegisterMenuBoxClass(classOf(TOnelineCharReadout))
