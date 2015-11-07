namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TGameSkillMenu)]
class TGameSkillMenuClass(TCustomScrollBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGameSkillMenu(parent, coords, main, owner)

