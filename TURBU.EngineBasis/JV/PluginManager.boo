namespace Jv.PluginManager

import System
import System.Collections.Generic

class TJvPluginManager[of T(class)]:
	
	[Getter(Plugins)]
	private _plugins = List[of T]()
	
	def constructor():
		assert typeof(T).IsInterface
	
	def LoadPlugin(plugClass as Type):
		unless T in plugClass.GetInterfaces():
			raise "$(plugClass.FullName) does not implement $(typeof(T).FullName)"
		_plugins.Add(Activator.CreateInstance(plugClass) cast T)
