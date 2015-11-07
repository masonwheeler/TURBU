namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TQuantityBox)]
class TQuantityBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TQuantityBox(parent, coords, main, owner)

[Metaclass(TGameMiniPartyPanel)]
class TGameMiniPartyPanelClass(TCustomPartyPanelClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGameMiniPartyPanel(parent, coords, main, owner)
