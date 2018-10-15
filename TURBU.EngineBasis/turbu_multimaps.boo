namespace turbu.multimaps

import Pythia.Runtime
import System.Collections.Generic

class Multimap[of TKey, TValue](Dictionary[of TKey, List[of TValue]]):

	private _lastKey as TKey

	protected _last as List[of TValue]

	protected def EnsureList(key as TKey):
		if not (assigned(_last) and self.Comparer.Equals(key, _lastKey)):
			if not self.TryGetValue(key, _last):
				_last = List[of TValue]()
				super.Add(key, _last)
			_lastKey = key

	public def constructor():
		super()

	public virtual def Add(key as TKey, value as TValue):
		EnsureList(key)
		_last.Add(value)

	public def RemovePair(key as TKey, value as TValue):
		self[key].Remove(value)

	public new def Clear():
		_lastKey = Default(TKey)
		_last = null
		super.Clear()

	public def KeyHasValue(key as TKey, value as TValue) as bool:
		return (self.ContainsKey(key) and self[key].Contains(value))
