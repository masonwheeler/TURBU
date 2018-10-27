namespace TURBU.Meta

import Boo.Lang.Compiler.Ast

macro until(arg as Expression):
	body as Block = until.Body
	return [|
		while true:
			$body
			break if $arg
	|]