namespace turbu.RM2K.map.timer

import Pythia.Runtime
import TURBU.RM2K.Menus

[Metaclass(TRpgTimer)]
class TRpgTimerClass(TClass):

	virtual def create(sprite as TSystemTimer) as turbu.RM2K.map.timer.TRpgTimer:
		return turbu.RM2K.map.timer.TRpgTimer(sprite)

