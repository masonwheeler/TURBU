namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TMessageBox)]
class TMessageBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TMessageBox(parent, coords, main, owner)

[Metaclass(TInputBox)]
abstract class TInputBoxClass(TCustomMessageBoxClass):
	pass

[Metaclass(TChoiceBox)]
class TChoiceBoxClass(TInputBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		return TChoiceBox(parent, coords)

[Metaclass(TValueInputBox)]
class TValueInputBoxClass(TInputBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		return TValueInputBox(parent, coords)

[Metaclass(TPromptBox)]
class TPromptBoxClass(TInputBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect) as TCustomMessageBox:
		return TPromptBox(parent, coords)
