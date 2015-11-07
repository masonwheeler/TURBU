namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU

[Metaclass(TShopModeBox)]
class TShopModeBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TShopModeBox(parent, coords, main, owner)

[Metaclass(TStockMenu)]
class TStockMenuClass(TCustomScrollBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TStockMenu(parent, coords, main, owner)

[Metaclass(TTransactionMenu)]
class TTransactionMenuClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TShopModeBox(parent, coords, main, owner)

[Metaclass(TShopCompatBox)]
class TShopCompatBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TShopCompatBox(parent, coords, main, owner)

[Metaclass(TShopQuantityBox)]
class TShopQuantityBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TShopQuantityBox(parent, coords, main, owner)

[Metaclass(TShopItemMenu)]
class TShopItemMenuClass(TCustomGameItemMenuClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TShopItemMenu(parent, coords, main, owner)

[Metaclass(TShopMenuPage)]
class TShopMenuPageClass(TMenuPageClass):

	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string) as TURBU.RM2K.Menus.TMenuPage:
		return TURBU.RM2K.Menus.TShopMenuPage(parent, coords, main, layout)

