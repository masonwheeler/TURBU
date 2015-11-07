namespace Pythia.Runtime

import Boo.Lang.Compiler.Ast

[Meta]
def pred(x as Expression) as Expression:
	return [|$x - 1|]

[Meta]
def succ(x as Expression) as Expression:
	return [|$x + 1|]
