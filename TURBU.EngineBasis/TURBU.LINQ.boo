namespace TURBU.LINQ

import System
import Boo.Lang.Compiler

[Extension]
def IndexWhere[of T]([Required] coll as T*, [Required] filter as Func[of T, bool]) as int*:
	result = do() as int*:
		var index = 0
		for value in coll:
			if filter(value):
				yield index
			++index
	return result()
