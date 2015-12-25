namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.Meta

class MapResourceExtractor(FastDepthFirstVisitor):
	
	[Getter(Result)]
	_result = Block()
	
	override def OnMacroStatement(node as MacroStatement):
		caseOf node.Name:
			case 'Tiles': pass //don't recurse into this!
			case 'Background': _result.Add([|Background $(node.Arguments[1])|])
			case 'Sprite':
				arg = node.Arguments[0]
				_result.Add([|Sprite $arg|]) if arg isa StringLiteralExpression
			case 'MoveScript':
				for mie in node.Body.Statements.OfType[of ExpressionStatement]().Select({e | e.Expression})\
						.OfType[of MethodInvocationExpression]():
					CheckMoveResources(mie)
			default: super.OnMacroStatement(node)
	
	private def CheckMoveResources(mie as MethodInvocationExpression):
		caseOf cast(ReferenceExpression, mie.Target).Name:
			case 'ChangeSprite':
				_result.Add([|Sprite $(mie.Arguments[0])|])
			case 'PlaySFX':
				_result.Add([|Sound $(mie.Arguments[0])|])