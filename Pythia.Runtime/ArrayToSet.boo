namespace Pythia.Runtime

import System
import System.Collections.Generic

[Boo.Lang.Compiler.Extension]
static def op_Implicit[of T](arr as (T)) as HashSet[of T]:
	return HashSet[of T](arr)