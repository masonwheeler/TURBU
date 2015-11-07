namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TGameCashMenu)]
class TGameCashMenuClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TGameCashMenu(parent, coords, main, owner)

[Metaclass(TCustomScrollBox)]
abstract class TCustomScrollBoxClass(TGameMenuBoxClass):
	pass

[Metaclass(TCustomOnelineBox)]
abstract class TCustomOnelineBoxClass(TGameMenuBoxClass):
	pass

[Metaclass(TOnelineLabelBox)]
class TOnelineLabelBoxClass(TCustomOnelineBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TOnelineLabelBox(parent, coords, main, owner)
	
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		assert false, "Obsolete constructor"

[Metaclass(TOnelineCharReadout)]
class TOnelineCharReadoutClass(TCustomOnelineBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TOnelineCharReadout(parent, coords, main, owner)
	
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		assert false, "Obsolete constructor"

[Metaclass(TCustomPartyPanel)]
abstract class TCustomPartyPanelClass(TGameMenuBoxClass):
	pass

[Metaclass(TCustomGameItemMenu)]
abstract class TCustomGameItemMenuClass(TCustomScrollBoxClass):
	pass