namespace turbu.multimaps

import Pythia.Runtime
import System.Collections.Generic

class TMultimap[of TKey, TValue](Dictionary[of TKey, List[of TValue]]):

	private FLastKey as TKey

	protected FLast as List[of TValue]

	protected def EnsureList(key as TKey):
		if not (assigned(FLast) and self.Comparer.Equals(key, FLastKey)):
			if not self.TryGetValue(key, FLast):
				FLast = List[of TValue]()
				super.Add(key, FLast)
			FLastKey = key

	public def constructor():
		super()

	public virtual def Add(key as TKey, value as TValue):
		EnsureList(key)
		FLast.Add(value)

	public def RemovePair(key as TKey, value as TValue):
		self[key].Remove(value)

	public new def Clear():
		FLastKey = Default(TKey)
		FLast = null
		super.Clear()

	public def KeyHasValue(key as TKey, value as TValue) as bool:
		return (self.ContainsKey(key) and self[key].Contains(value))

class TDistinctMultimap[of TKey, TValue](TMultimap[of TKey, TValue]):

	public override def Add(key as TKey, value as TValue):
		index as int
		EnsureList(key)
		index = FLast.BinarySearch(value)
		if index < 0:
			FLast.Insert(-index, value)
