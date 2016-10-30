namespace map.default.plugin

import Pythia.Runtime
import TURBU.PluginInterface
import TURBU.RM2K.MapEngine

class TRpgBasicMapPlugin(ITurbuPlugin):

	public def ListPlugins() as TEngineData*:
		return (TEngineData(TEngineStyle.Map, classOf(T2kMapEngine)),)

initialization:
	Jv.PluginManager.RegisterPlugin(TRpgBasicMapPlugin())