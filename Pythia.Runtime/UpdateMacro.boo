namespace Pythia.Runtime

import System

macro Update (arg as Boo.Lang.Compiler.Ast.Expression):
	return [|
		$arg.BeginUpdate()
		try:
			$(Update.Body)
		ensure:
			$arg.EndUpdate()
	|]