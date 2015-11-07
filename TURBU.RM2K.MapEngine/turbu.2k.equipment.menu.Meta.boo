namespace TURBU.RM2K.Menus

import Pythia.Runtime
import TURBU.RM2K.Menus
import SDL2.SDL2_GPU

[Metaclass(TCharStatBox)]
class TCharStatBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TCharStatBox(parent, coords, main, owner)

[Metaclass(TEqInventoryMenu)]
class TEqInventoryMenuClass(TCustomScrollBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TEqInventoryMenu(parent, coords, main, owner)

[Metaclass(TGameEquipmentMenu)]
class TGameEquipmentMenuClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGameEquipmentMenu(parent, coords, main, owner)

