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
				value = [|
					for i in range($quantity):
						yield {m | return (m cast turbu.map.sprites.TMapSprite).$expr()}
				|]
				steps.Body.Add(value)
			case MethodInvocationExpression():
				mieStep = step cast MethodInvocationExpression
				var mie = MethodInvocationExpression([|(m cast turbu.map.sprites.TMapSprite).$(mieStep.Target)|])
				mie.Arguments.AddRange(mieStep.Arguments.Select({a | a.CleanClone()}))
				steps.Body.Add([| yield {m | return $mie} |])
			case ReferenceExpression():
				steps.Body.Add([| yield {m | return (m cast turbu.map.sprites.TMapSprite).$step()} |])
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
