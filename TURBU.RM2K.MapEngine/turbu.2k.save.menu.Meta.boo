namespace TURBU.RM2K.Menus

import Pythia.Runtime
import SDL2.SDL2_GPU

[Metaclass(TSaveData)]
class TSaveDataClass(TClass):

	virtual def Create(Name as string, level as int, HP as int, portraits as (TPortraitID)) as TURBU.RM2K.Menus.TSaveData:
		return TURBU.RM2K.Menus.TSaveData(Name, level, HP, portraits)

[Metaclass(TSaveBox)]
class TSaveBoxClass(TGameMenuBoxClass):
	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage) as TGameMenuBox:
		return TSaveBox(parent, coords, main, owner)

[Metaclass(TSaveMenuPage)]
class TSaveMenuPageClass(TMenuPageClass):

	override def Create(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string) as TURBU.RM2K.Menus.TMenuPage:
		return TURBU.RM2K.Menus.TSaveMenuPage(parent, coords, main, layout)

