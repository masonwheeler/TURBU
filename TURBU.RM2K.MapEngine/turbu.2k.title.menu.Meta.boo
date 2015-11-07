namespace TURBU.RM2K.Menus

import Pythia.Runtime
import TURBU.RM2K.Menus
import SDL2.SDL2_GPU

[Metaclass(TTitleMenu)]
class TTitleMenuClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TURBU.RM2K.Menus.TTitleMenu(parent, coords, main, owner)

[Metaclass(TTitleMenuPage)]
class TTitleMenuPageClass(TMenuPageClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string) as TURBU.RM2K.Menus.TMenuPage:
		return TURBU.RM2K.Menus.TTitleMenuPage(parent, coords, main, layout)

