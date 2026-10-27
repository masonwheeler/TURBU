namespace TURBU.RM2K.BattleEngine

import Pythia.Runtime
import SDL2.SDL2_GPU
import TURBU.RM2K.Menus

[Metaclass(TBattlePage)]
class TBattlePageClass(TMenuPageClass):

	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string) as TURBU.RM2K.Menus.TMenuPage:
		return TBattlePage(parent, coords, main, layout)
