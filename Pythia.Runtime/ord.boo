namespace Pythia.Runtime

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

[Meta]
def ord(expr as Expression) as Expression:
	cb = Boo.Lang.Environments.My[of BooCodeBuilder].Instance
	return cb.CreateCast(cb.TypeSystemServices.IntType, expr)