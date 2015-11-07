namespace TURBU.RM2K.Menus

import Pythia.Runtime
import TURBU.RM2K.Menus
import SDL2.SDL2_GPU

[Metaclass(TGameMenuBox)]
class TGameMenuBoxClass(TCustomMessageBoxClass):
	abstract def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		pass
	
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		assert false, "Obsolete constructor"

[Metaclass(TMenuPage)]
class TMenuPageClass(TClass):

	virtual def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string) as TURBU.RM2K.Menus.TMenuPage:
		return TMenuPage(parent, coords, main, layout)
