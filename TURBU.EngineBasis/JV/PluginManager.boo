namespace Jv.PluginManager

import Boo.Adt
import TURBU.PluginInterface

let GPluginManager = System.Collections.Generic.List[of TEngineData]()

def RegisterPlugin(value as ITurbuPlugin):
	GPluginManager.AddRange(value.ListPlugins())
