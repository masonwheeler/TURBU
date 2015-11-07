namespace TURBU.LINQ

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Boo.Lang.Compiler

/*
[Extension]
def WhereIndexed[of T]([Required] coll as IEnumerable[of T], [Required] filter as Func[of T, int, bool]) as IEnumerable[of Indexed[of T]]:
	index = 0
	for value in coll:
		if filter(value, index):
			yield Indexed[of T](index, value)
		++index

class Indexed [of T]:
	[Getter(Index)]
	private _index as int
	
	[Getter(Value)]
	private _value as T
	
	def constructor(index as int, value as T):
		_index = index
		_value = value
*/

[Extension]
def IndexWhere[of T]([Required] coll as IEnumerable[of T], [Required] filter as Func[of T, bool]) as IEnumerable[of int]:
	return IndexWhereImpl(coll, filter)

private def IndexWhereImpl[of T](coll as IEnumerable[of T], filter as Func[of T, bool]) as IEnumerable[of int]:
	index = 0
	for value in coll:
		if filter(value):
			yield index
		++index
