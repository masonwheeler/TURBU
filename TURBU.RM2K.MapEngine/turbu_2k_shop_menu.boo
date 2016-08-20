namespace TURBU.RM2K.Menus

import turbu.constants
import turbu.defs
import sdl.sprite
import dm.shaders
import TURBU.TextUtils
import TURBU.RM2K
import TURBU.Meta
import turbu.items
import turbu.shops
import SG.defs
import Boo.Adt
import Pythia.Runtime
import System
import turbu.RM2K.items
import turbu.Heroes
import TURBU.RM2K.MapEngine
import turbu.RM2K.environment
import SDL2.SDL2_GPU
import System.Threading

class TShopModeBox(TGameMenuBox):

	internal FAccessed as bool

	private new def Return():
		GMenuEngine.Value.MenuInt = (1 if (FOwner cast TShopMenuPage).TransactionComplete else 0)
		(FOwner cast TShopMenuPage).FOngoing = false
		(FOwner cast TShopMenuPage).ItemMenu.Inventory = null
		super.Return()

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		Array.Resize[of bool](FOptionEnabled, 4)
		for i in range(4):
			FOptionEnabled[i] = true
		FColumns = 2
		FPromptLines = 1

	public override def DoSetup(value as int):
		super.DoSetup(value)
		FParsedText.Clear()
		which as int = (FOwner cast TShopMenuPage).Format
		var messageKey = (V_SHOP_NUM_CONTINUE if FAccessed else V_SHOP_NUM_GREET)
		FParsedText.Add(GDatabase.value.VocabNum(messageKey, which))
		FParsedText.Add(GDatabase.value.VocabNum(V_SHOP_NUM_BUY, which))
		FParsedText.Add(GDatabase.value.VocabNum(V_SHOP_NUM_SELL, which))
		FParsedText.Add('Equipment')
		FParsedText.Add(GDatabase.value.VocabNum(V_SHOP_NUM_LEAVE, which))
		self.PlaceCursor(0)
		FAccessed = true
		for i in range(4):
			FOptionEnabled[i] = true
		caseOf cast(TShopMenuPage, FOwner).Style:
			case TShopTypes.BuySell: pass
			case TShopTypes.Buy:
				FOptionEnabled[1] = false
			case TShopTypes.Sell:
				FOptionEnabled[0] = false
			default :
				raise Exception('Bad shop style!')

	public override def DrawText():
		let lOrigin = sgPoint(4, 2)
		GFontEngine.DrawText(FTextTarget.RenderTarget, FParsedText[0], lOrigin.x, lOrigin.y, 0)
		for i in range(1, FParsedText.Count):
			var j = i + 1
			var color = (0 if FOptionEnabled[i - 1] else 3)
			GFontEngine.DrawText(
				FTextTarget.RenderTarget,
				FParsedText[i],
				lOrigin.x + ((j % FColumns) * (ColumnWidth + SEPARATOR)),
				((j / 2) * 15) + lOrigin.y,
				color)

	public override def DoButton(input as TButtonCode):
		super.DoButton(input)
		var owner = FOwner cast TShopMenuPage
		if (input == TButtonCode.Enter) and FOptionEnabled[FCursorPosition]:
			caseOf FCursorPosition:
				case 0:
					owner.State = TShopState.Buying
					self.FocusMenu('Stock', 0)
				case 1:
					owner.ItemMenu.Inventory = GEnvironment.value.Party.Inventory
					self.FocusMenu('Inventory', 0)
					owner.PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_SELL_WHAT, owner.Format)
				case 2:
					self.FocusPage('Equipment', GEnvironment.value.Party[1].Template.ID)
				case 3:
					self.Return()
		elif input == TButtonCode.Cancel:
			self.Return()

	public override def DoCursor(position as short):
		super.DoCursor(position)

class TStockMenu(TCustomScrollBox):

	private def Update(cash as int):
		for i in range(FParsedText.Count):
			var item = FParsedText.Objects[i] cast int
			FOptionEnabled[i] = \
				(GEnvironment.value.Party.Money >= GDatabase.value.Items[item].Cost) and \
				(GEnvironment.value.Party.Inventory.QuantityOf(item) < MAXITEMS)

	protected override def DrawItem(id as int, x as int, y as int, color as int):
		dummy as TItemTemplate = GDatabase.value.Items[FParsedText.Objects[id] cast int]
		GFontEngine.DrawText(FTextTarget.RenderTarget, dummy.Name, x, y, color)
		GFontEngine.DrawTextRightAligned(FTextTarget.RenderTarget, dummy.Cost.ToString(), FBounds.w - 22, y, color)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		FColumns = 1
		FDisplayCapacity = (coords.h / 16) - 1

	public override def DoSetup(value as int):
		super.DoSetup(value)
		inventory as (int) = (FOwner cast TShopMenuPage).Inventory
		FParsedText.Clear()
		for item in inventory:
			FParsedText.AddObject(GDatabase.value.Items[item].Name, item)
		Array.Resize[of bool](FOptionEnabled, FParsedText.Count)
		self.Update(GEnvironment.value.Party.Money)
		if self.Focused:
			self.PlaceCursor(value)
		(FOwner cast TShopMenuPage).PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_BUY_WHAT, (FOwner cast TShopMenuPage).Format)

	public override def DoButton(input as TButtonCode):
		owner as TShopMenuPage
		super.DoButton(input)
		owner = (FOwner cast TShopMenuPage)
		if input == TButtonCode.Cancel:
			owner.State = TShopState.Selling
			owner.DescBox.Text = ''
		elif (input == TButtonCode.Enter) and FOptionEnabled[FCursorPosition]:
			owner.TransactionBox.State = TTransactionState.Buying
			owner.TransactionBox.RpgItem = TRpgItem.NewItem(FParsedText.Objects[FCursorPosition] cast int, 1)
			owner.State = TShopState.Transaction
			self.FocusMenu('Transaction', 0)

	public override def DoCursor(position as short):
		super.DoCursor(position)
		if position < FParsedText.Count:
			item as TRpgItem = TRpgItem.NewItem(FParsedText.Objects[position] cast int, 1)
			(FOwner cast TShopMenuPage).Compat.RpgItem = item
			(FOwner cast TShopMenuPage).DescBox.Text = item.Desc

enum TTransactionState:
	Off
	Buying
	Selling

class TTransactionMenu(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	[Property(State)]
	private FState as TTransactionState

	private FItem as TRpgItem

	private FExistingQuantity as byte

	public override def DrawText():
		align as TSgFloatPoint
		return if FBlank or not assigned(FItem)
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, FItem.Name, 8, 42, 0)
		GFontEngine.DrawText(target, 'x', 136, 42, 0)
		GFontEngine.DrawTextRightAligned(target, FExistingQuantity.ToString(), 168, 42, 0)
		align = GFontEngine.DrawTextRightAligned(target, GDatabase.value.Vocab[V_MONEY_NAME], self.GetRightSide(), 74, 1)
		if FState == TTransactionState.Buying:
			GFontEngine.DrawTextRightAligned(target, (FItem.Cost * FExistingQuantity).ToString(), align.x - 8, 74, 0)
		else:
			GFontEngine.DrawTextRightAligned(
				target,
				Math.Truncate(FItem.Cost * FExistingQuantity * SELLBACK_RATIO).ToString(),
				align.x - 8,
				74,
				0)

	public override def DoCursor(position as short):
		if self.Focused:
			coords = GPU_MakeRect(FBounds.x + 158, FBounds.y + 46, 22, 20)
			GMenuEngine.Value.Cursor.Visible = true
			GMenuEngine.Value.Cursor.Layout(coords)

	public override def DoButton(input as TButtonCode):
		owner as TShopMenuPage
		dummy as int
		maximum as byte
		current as byte
		super.DoButton(input)
		owner = (FOwner cast TShopMenuPage)
		maximum = 0
		caseOf FState:
			case TTransactionState.Off:
				assert false
			case TTransactionState.Buying:
				dummy = GEnvironment.value.Party.Inventory.IndexOf(FItem.ID)
				if dummy != -1:
					maximum = Math.Min(
						MAXITEMS - (GEnvironment.value.Party.Inventory[dummy] cast TRpgItem).Quantity,
						GEnvironment.value.Money / FItem.Cost)
				else:
					maximum = MAXITEMS
			case TTransactionState.Selling:
				maximum = FItem.Quantity
		current = FExistingQuantity
		caseOf input:
			case TButtonCode.Cancel: pass
			case TButtonCode.Enter:
				if FExistingQuantity > 0:
					PlaySound(TSfxTypes.Accept)
					FBlank = true
					caseOf FState:
						case TTransactionState.Off:
							assert false
						case TTransactionState.Buying:
							owner.PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_BOUGHT, owner.Format)
							Thread.Sleep(750)
							GEnvironment.value.Party.Inventory.Add(FItem.ID, FExistingQuantity)
							assert GEnvironment.value.Party.Money >= (FExistingQuantity * FItem.Cost)
							GEnvironment.value.Party.Money = (GEnvironment.value.Party.Money - (FExistingQuantity * FItem.Cost))
						case TTransactionState.Selling:
							owner.PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_SOLD, owner.Format)
							Thread.Sleep(750)
							if FExistingQuantity < FItem.Quantity:
								FItem.Quantity = (FItem.Quantity - FExistingQuantity)
							else:
								GEnvironment.value.Party.Inventory.Remove(FItem.ID, FItem.Quantity)
							GEnvironment.value.Party.Money = (GEnvironment.value.Party.Money + Math.Truncate(((FExistingQuantity * FItem.Cost) * SELLBACK_RATIO)))
							owner.PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_SELL_WHAT, owner.Format)
					owner.FTransactionComplete = true
			case TButtonCode.Up: FExistingQuantity = Math.Min(FExistingQuantity + 10, maximum)
			case TButtonCode.Down: FExistingQuantity = Math.Max(FExistingQuantity - 10, 0)
			case TButtonCode.Right:
				++FExistingQuantity if FExistingQuantity < maximum
			case TButtonCode.Left:
				--FExistingQuantity if FExistingQuantity > 1
		if FExistingQuantity != current:
			PlaySound(TSfxTypes.Cursor)
			InvalidateText()
		if input in TButtonCode.Cancel | TButtonCode.Enter:
			if FState == TTransactionState.Selling:
				owner.State = TShopState.Selling
			elif FState == TTransactionState.Buying:
				owner.State = TShopState.Buying
			else: assert false
			self.State = TTransactionState.Off
			self.Return() if input == TButtonCode.Enter
			owner.CurrentMenu.Setup(CURSOR_UNCHANGED)

	public override def DoSetup(value as int):
		super.DoSetup(value)
		caseOf FState:
			case TTransactionState.Off: pass
			case TTransactionState.Buying:
				(FOwner cast TShopMenuPage).PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_HOW_MANY, (FOwner cast TShopMenuPage).Format)
			case TTransactionState.Selling:
				(FOwner cast TShopMenuPage).PromptBox.Text = GDatabase.value.VocabNum(V_SHOP_NUM_SELL_QUANT, (FOwner cast TShopMenuPage).Format)
		FBlank = false

	public RpgItem as TRpgItem:
		get: return FItem
		set:
			FItem = value
			FExistingQuantity = 1

class TCompatSprite(TSprite):

	private FTemplate as TRpgHero

	private FItem as TRpgItem

	private FTickCount as int

	private FHeartbeat as bool

	private def DrawGrayscale():
		gla = array(single, 4)
		shaders as TdmShaders = GGameEngine.value.CurrentMap.ShaderEngine
		try:
			handle as int = shaders.ShaderProgram('default', 'tint', 'shift')
			shaders.UseShaderProgram(handle)
			shaders.SetUniformValue(handle, 'hShift', 0)
			shaders.SetUniformValue(handle, 'valMult', 1.0 cast single)
			gla[0] = 1
			gla[1] = 1
			gla[2] = 1
			gla[3] = 1
			shaders.SetUniformValue(handle, 'rgbValues', gla)
			shaders.SetUniformValue(handle, 'satMult', 0.0 cast single)
			super.Draw()
		ensure:
			GPU_DeactivateShaderProgram()

	public def constructor(AParent as TSpriteEngine, template as TRpgHero):
		super(AParent)
		FTemplate = template
		var spriteName = template.Template.MapSprite
		commons.runThreadsafe(true, {FEngine.Images.EnsureImage("Sprites\\$spriteName.png", spriteName, GDatabase.value.Layout.SpriteSize)})
		self.ImageName = spriteName
		self.SetSpecialRender()

	public override def Draw():
		FHeartbeat = not FHeartbeat
		++FTickCount if FHeartbeat
		FTickCount = 0 if FTickCount == 28
		frame as int = 26
		tSize as TSgPoint = FImage.TextureSize
		FImage.TextureSize = FImage.TextureSize * sgPoint(1, 2)
		try:
			if FItem.UsableByHypothetical(FTemplate.Template.ID):
				caseOf FTickCount / 7:
					case 0:
						--frame
					case 1, 3: pass
					case 2:
						++frame
				self.ImageIndex = frame
				super.Draw()
			else:
				self.ImageIndex = frame
				DrawGrayscale()
		ensure:
			FImage.TextureSize = tSize

	public Item as TRpgItem:
		set: FItem = value

class TShopCompatBox(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	private FItem as TRpgItem

	private FParty = array(TCompatSprite, MAXPARTYSIZE)

	protected override def DrawText():
		let ONE_PIXEL = GPU_MakeRect(0, 0, 1, 1)
		return unless assigned(FItem)
		var first = false
		for i in range(MAXPARTYSIZE):
			if assigned(FParty[i]):
				if not first:
					first = true
					FParty[i].Image.DrawRectTo(ONE_PIXEL, ONE_PIXEL)
				FParty[i].Draw()
		DrawingInProgress()

	public override def DoSetup(value as int):
		super.DoSetup(value)
		for i in range(MAXPARTYSIZE):
			FParty[i].Dead() if assigned(FParty[i])
			FParty[i] = null
			if GEnvironment.value.Party[i + 1] != GEnvironment.value.Heroes[0]:
				FParty[i] = TCompatSprite(self.Engine, GEnvironment.value.Party[i + 1])
				FParty[i].X = i * 32
				FParty[i].Y = 0
				FParty[i].Item = self.FItem

	public RpgItem as TRpgItem:
		set:
			FItem = value
			for i in range(MAXPARTYSIZE):
				if assigned(FParty[i]):
					FParty[i].Item = value
			(FOwner cast TShopMenuPage).Quantities.RpgItem = value

class TShopQuantityBox(TGameMenuBox):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)

	[Property(RpgItem)]
	private FItem as TRpgItem

	public override def DrawText():
		return unless assigned(FItem)
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_ITEMS_OWNED], 2, 2, 1)
		GFontEngine.DrawTextRightAligned(target, GEnvironment.value.HeldItems(FItem.ID, false).ToString(), self.GetRightSide(), 2, 0)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_ITEMS_EQUIPPED], 2, 18, 1)
		GFontEngine.DrawTextRightAligned(target, GEnvironment.value.HeldItems(FItem.ID, true).ToString(), self.GetRightSide(), 18, 0)

class TShopItemMenu(TCustomGameItemMenu):

	private def ShopButton(which as TButtonCode, theMenu as TGameMenuBox, theOwner as TMenuPage):
		owner = theOwner cast TShopMenuPage
		return if (Inventory.Count == 0) and (which != TButtonCode.Cancel)
		if (which == TButtonCode.Enter) and OptionEnabled[CursorPosition]:
			owner.SetState(TShopState.Transaction)
			owner.TransactionBox.State = TTransactionState.Selling
			owner.TransactionBox.RpgItem = Inventory[CursorPosition]
			FocusMenu('Transaction', CURSOR_UNCHANGED)
		elif which == TButtonCode.Cancel:
			Inventory = null
			owner.DescBox.Text = ''

	private def ShopCursor(position as short, theMenu as TGameMenuBox, theOwner as TMenuPage):
		owner = theOwner cast TShopMenuPage
		if assigned(Inventory) and (Inventory.Count > 0):
			owner.DescBox.Text = Inventory[position].Desc

	private def ShopSetup(position as int, theMenu as TGameMenuBox, theOwner as TMenuPage):
		return if Inventory is null
		
		for i in range(Inventory.Count):
			OptionEnabled[i] = Inventory[i].Cost > 0

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		self.OnButton = ShopButton
		self.OnCursor = ShopCursor
		self.OnSetup = ShopSetup

enum TShopState:
	Selling
	Buying
	Transaction

class TShopMenuPage(TMenuPage):

	[Getter(MainBox)]
	private FMainBox as TShopModeBox

	[Getter(DescBox)]
	private FDescBox as TOnelineLabelBox

	[Getter(PromptBox)]
	private FPromptBox as TOnelineLabelBox

	private FStockBox as TStockMenu

	[Getter(ItemMenu)]
	private FInventoryBox as TShopItemMenu

	[Getter(TransactionBox)]
	private FTransactionBox as TTransactionMenu

	[Getter(Compat)]
	private FCompat as TShopCompatBox

	[Getter(Quantities)]
	private FQuantities as TShopQuantityBox

	private FCash as TGameCashMenu

	[Getter(Style)]
	private FStyle as TShopTypes

	private FState as TShopState

	[Getter(Inventory)]
	private FInventory as (int)

	[Getter(Format)]
	private FFormat as byte

	[Getter(TransactionComplete)]
	internal FTransactionComplete as bool

	internal FOngoing as bool

	internal def SetState(Value as TShopState):
		FState = Value
		SetVisible(true)

	private def TopRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x, input.y, input.x + input.w, input.y + 32)

	private def MidRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x, input.y + 32, input.x + input.w, input.y + 160)

	private def BottomRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x, input.y + 160, input.x + input.w, input.y + 240)

	private def BottomOverlapRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x + 4, input.y + 164, input.x + input.w - 4, input.y + 196)

	private def MidLeftRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x, input.y + 32, input.x + 184, input.y + 160)

	private def MidRightTRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x + 184, input.y + 32, input.x + 320, input.y + 80)

	private def MidRightMRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x + 184, input.y + 80, input.x + 320, input.y + 128)

	private def MidRightBRect(input as GPU_Rect) as GPU_Rect:
		return GPU_MakeRect(input.x + 184, input.y + 128, input.x + 320, input.y + 160)

	protected override def SetVisible(value as bool):
		super.SetVisible(false)
		if value:
			FVisible = true
			FMainBox.Visible = true
			FDescBox.Visible = true
			if FState == TShopState.Selling:
				FInventoryBox.Visible = true
			else:
				FCompat.Visible = true
				FQuantities.Visible = true
				FCash.Visible = true
				if FState == TShopState.Buying:
					FStockBox.Visible = true
				else:
					FTransactionBox.Visible = true
			FPromptBox.Visible = FCurrentMenu != FMainBox

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string):
		super(parent, coords, main, layout)
		FMainBox = TShopModeBox(parent, BottomRect(coords), main, self)
		RegisterComponent('Main', FMainBox)
		FDescBox = TOnelineLabelBox(parent, TopRect(coords), main, self)
		RegisterComponent('Desc', FDescBox)
		FPromptBox = TOnelineLabelBox(parent, BottomOverlapRect(coords), main, self)
		RegisterComponent('Prompt', FPromptBox)
		FInventoryBox = TShopItemMenu(parent, MidRect(coords), main, self)
		RegisterComponent('Inventory', FInventoryBox)
		FStockBox = TStockMenu(parent, MidLeftRect(coords), main, self)
		RegisterComponent('Stock', FStockBox)
		FCompat = TShopCompatBox(parent, MidRightTRect(coords), main, self)
		RegisterComponent('Compat', FCompat)
		FQuantities = TShopQuantityBox(parent, MidRightMRect(coords), main, self)
		RegisterComponent('Quantities', FQuantities)
		FCash = TGameCashMenu(parent, MidRightBRect(coords), main, self)
		RegisterComponent('Cash', FCash)
		FTransactionBox = TTransactionMenu(parent, MidLeftRect(coords), main, self)
		RegisterComponent('Transaction', FTransactionBox)
		self.Visible = false

	public override def Setup(value as int):
		if not FOngoing:
			FTransactionComplete = false
		FOngoing = true
		FMainBox.FAccessed = false
		super.Setup(value)
		SetVisible(true)

	public override def SetupEx(data as TObject):
		var shopData = data cast TShopData
		FInventory = shopData.Inventory
		FStyle = shopData.ShopType
		FFormat = shopData.MessageStyle
		self.State = TShopState.Selling
		super.SetupEx(data)

	public override def FocusMenu(referrer as TGameMenuBox, which as TGameMenuBox, unchanged as bool):
		super.FocusMenu(referrer, which, unchanged)
		SetVisible(true)

	public State as TShopState:
		get:
			return FState
		set:
			SetState(value)

let SELLBACK_RATIO = 0.5
initialization :
	TMenuEngine.RegisterMenuPageEx(classOf(TShopMenuPage), 'Shop', '[]')
