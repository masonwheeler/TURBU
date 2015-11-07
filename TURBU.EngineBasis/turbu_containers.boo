namespace turbu.containers

import System.Collections.Generic

class TRpgObjectList[of T](List[of T]):
	
	def constructor():
		super()
	
	def constructor(collection as T*):
		super(collection)
	
	public High as int:
		get: return (Count - 1)
	
	public Last as T:
		get: return self[Count - 1]