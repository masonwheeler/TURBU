namespace TURBU.Meta

import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

[Meta]
def MoveMapObject(obj as Expression, frequency as Expression, loop as BoolLiteralExpression,
		skip as BoolLiteralExpression, path as ArrayLiteralExpression) as MethodInvocationExpression:
	var result = [|$obj.Move($frequency, $skip)|]
	var steps = DoBuildSteps(loop, path)
	result.Arguments.Add(steps)
	return result

[Meta]
def CreatePath(loop as BoolLiteralExpression, skip as BoolLiteralExpression, path as ArrayLiteralExpression) as MethodInvocationExpression:
	var steps = DoBuildSteps(loop, path)
	var result = [|turbu.pathing.Path($skip, $steps)|]
	return result

private def SpriteCall(name as Expression, arguments as ExpressionCollection) as MethodInvocationExpression:
	var target = MemberReferenceExpression([|m cast turbu.map.sprites.TMapSprite|], (name cast ReferenceExpression).Name)
	var result = MethodInvocationExpression(target)
	result.Arguments.AddRange(arguments.Select({a | a.CleanClone()})) if arguments is not null
	return result

private def DoBuildSteps(loop as BoolLiteralExpression, path as ArrayLiteralExpression) as BlockExpression:
	var steps = BlockExpression()
	steps.Parameters.Add(ParameterDeclaration.Lift([|p as turbu.pathing.Path|]))
	steps.ReturnType = GenericTypeReference(
		'System.Collections.Generic.IEnumerable',
		GenericTypeReference(
			'System.Func',
			SimpleTypeReference('Pythia.Runtime.TObject'),
			SimpleTypeReference('bool')))
	for step in path.Items:
		match step:
			case [|$expr * $quantity|]:
				call = SpriteCall(expr, null)
				value = [|
					for i in range($quantity):
						yield {m as Pythia.Runtime.TObject | return $call}
				|]
				steps.Body.Add(value)
			case MethodInvocationExpression():
				mieStep = step cast MethodInvocationExpression
				mie = SpriteCall(mieStep.Target, mieStep.Arguments)
				steps.Body.Add([| yield {m as Pythia.Runtime.TObject | return $mie} |])
			case ReferenceExpression():
				call = SpriteCall(step, null)
				steps.Body.Add([| yield {m as Pythia.Runtime.TObject | return $call} |])
	if steps.Body.IsEmpty:
		steps.Body.Add([|return System.Linq.Enumerable.Empty[of System.Func[of Pythia.Runtime.TObject, bool]]()|])
	elif loop.Value:
		var body = steps.Body
		steps.Body = Block()
		var infLoop = [|
			while true:
				$body
				p.Looped = true
		|]
		steps.Body.Add(infLoop)
	return steps
