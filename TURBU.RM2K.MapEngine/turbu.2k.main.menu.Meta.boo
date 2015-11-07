namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TGamePartyPanel)]
class TGamePartyPanelClass(TCustomPartyPanelClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGamePartyPanel(parent, coords, main, owner)

[Metaclass(TGameMainMenu)]
class TGameMainMenuClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGameMainMenu(parent, coords, main, owner)


