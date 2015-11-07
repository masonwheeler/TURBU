namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.Meta

class MapTreeResourceExtractor(FastDepthFirstVisitor):
	
	[Getter(Result)]
	_result = Block()
	
	override def OnMacroStatement(node as MacroStatement):
		caseOf node.Name:
			case 'Song': _result.Add([|Music $(node.Arguments[0])|])
			case 'BattleBG':
				arg = node.Arguments[0]
				_result.Add([|Background $arg|]) if arg isa StringLiteralExpression
			case 'MapEngine': _result.Add(node.CleanClone())
			default: super.OnMacroStatement(node)
