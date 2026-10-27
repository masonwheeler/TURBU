namespace TURBU.Meta

import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

[Meta]
def MoveMapObject(obj as Expression, frequency as Expression, loop as BoolLiteralExpression,
		skip as BoolLiteralExpression, path as ArrayLiteralExpression) as MethodInvocationExpression:
	var result = [|$obj.Move($frequency, $skip, $loop)|]
	DoBuildSteps(path, result.Arguments)
	return result

[Meta]
def CreatePath(loop as BoolLiteralExpression, skip as BoolLiteralExpression, path as ArrayLiteralExpression) as MethodInvocationExpression:
	var result = [|turbu.pathing.Path($skip, $loop)|]
	DoBuildSteps(path, result.Arguments)
	return result

private def SpriteCall(name as Expression, arguments as ExpressionCollection) as MethodInvocationExpression:
	var target = MemberReferenceExpression([|m cast turbu.map.sprites.TMapSprite|], (name cast ReferenceExpression).Name)
	var result = MethodInvocationExpression(target)
	result.Arguments.AddRange(arguments.Select({a | a.CleanClone()})) if arguments is not null
	return result

private def DoBuildSteps(path as ArrayLiteralExpression, arguments as ExpressionCollection):
	for step in path.Items:
		quantity as Expression = [|1|]
		call as MethodInvocationExpression
		match step:
			case [|$expr * $count|]:
				call = SpriteCall(expr, null)
				quantity = count
			case MethodInvocationExpression():
				mieStep = step cast MethodInvocationExpression
				call = SpriteCall(mieStep.Target, mieStep.Arguments)
			case ReferenceExpression():
				call = SpriteCall(step, null)
		arguments.Add([|turbu.pathing.PathStep($quantity, {m as Pythia.Runtime.TObject | return $call})|])
