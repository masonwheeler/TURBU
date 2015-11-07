namespace Jv.StringHolder

import System.Collections.Generic
import System.ComponentModel

class TJvMultiStringHolder(Component):
	
	[Property(MultipleStrings)]
	_strings = SortedDictionary[of string, string]()
	
	StringsByName[name as string] as string:
		get: return _strings[name]
	
	def Add(key as string, value as string):
		_strings.Add(key, value)