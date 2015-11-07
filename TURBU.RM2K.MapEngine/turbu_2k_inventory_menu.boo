namespace TURBU.RM2K.Menus

import turbu.defs
import Boo.Adt
import Pythia.Runtime
import System
import TURBU.RM2K.Menus
import turbu.RM2K.Item.types
import turbu.RM2K.environment
import SDL2.SDL2_GPU

class TGameItemMenu(TCustomGameItemMenu):

	private def ItemButton(which as TButtonCode, theMenu as TGameMenuBox, theOwner as TMenuPage):
		if Inventory.Count == 0:
			return
		if (which == TButtonCode.Enter) and OptionEnabled[CursorPosition]:
			if Inventory[CursorPosition] isa TAppliedItem:
				FocusPage('PartyTarget', (CursorPosition * -1))
				if (Inventory[CursorPosition] cast TAppliedItem).AreaItem():
					MenuEngine.PlaceCursor(-1)
				else:
					MenuEngine.PlaceCursor(0)
			elif Inventory[CursorPosition] isa TSwitchItem:
				(Inventory[CursorPosition] cast TSwitchItem).Use()
				MenuEngine.Leave(false)

	private def itemCursor(position as short, theMenu as TGameMenuBox, theOwner as TMenuPage):
		if Inventory.Count > 0:
			(theOwner.Menu('Desc') cast TOnelineLabelBox).Text = Inventory[position].Desc

	private def itemSetup(position as int, theMenu as TGameMenuBox, theOwner as TMenuPage):
		i as int
		for i in range(0, Inventory.Count):
			OptionEnabled[i] = Inventory[i].UsableOnField

	protected override def DoSetup(value as int):
		self.Inventory = GEnvironment.value.Party.Inventory
		super.DoSetup(value)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		self.OnButton = ItemButton
		self.OnCursor = itemCursor
		self.OnSetup = itemSetup

let INVENTORY_LAYOUT = """
	[{"Name": "Inventory", "Class": "TGameItemMenu",    "Coords": [0, 32, 320, 240]},
	 {"Name": "Desc",      "Class": "TOnelineLabelBox", "Coords": [0, 0,  320, 32 ]}]"""
	 
initialization :
	TMenuEngine.RegisterMenuPage('Inventory', INVENTORY_LAYOUT)
	TMenuEngine.RegisterMenuBoxClass(classOf(TGameItemMenu))
