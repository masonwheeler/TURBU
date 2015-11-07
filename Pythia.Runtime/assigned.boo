namespace Pythia.Runtime

import Boo.Lang.Compiler.Ast

[Meta]
def assigned(expr as Expression) as Expression:
	return [|$expr is not null|]