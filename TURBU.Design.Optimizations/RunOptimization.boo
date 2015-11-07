namespace TURBU.Design.Optimizations

import System
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

[Extension]
public def RunOptimization(value as Node):
	value.Accept(RemoveEmptyElseBlocks())
	value.Accept(IfFalseFlipper())
	value.Accept(NestedIfOptimization())

[Extension]
def ToScriptString(value as Node):
	value.RunOptimization()
	return value.ToCodeString()