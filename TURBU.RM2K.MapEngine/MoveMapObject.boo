﻿namespace TURBU.Meta

import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

[Meta]
def MoveMapObject(obj as Expression, frequency as IntegerLiteralExpression, loop as BoolLiteralExpression,
		skip as BoolLiteralExpression, path as ArrayLiteralExpression) as MethodInvocationExpression:
	var result = [|$obj.Move($frequency, $skip)|]
	var steps = BlockExpression()
	
	steps.Parameters.Add(ParameterDeclaration.Lift([|p as turbu.pathing.Path|]))
	steps.ReturnType = GenericTypeReference('System.Collections.Generic.IEnumerable', GenericTypeReference('System.Func', SimpleTypeReference('bool')))
	for step in path.Items:
		match step:
			case [|$expr * $quantity|]:
				value = [|
					for i in range($quantity):
						yield {return $obj.Base.$expr()}
				|]
				steps.Body.Add(value)
			case MethodInvocationExpression():
				mieStep = step cast MethodInvocationExpression
				var mie = MethodInvocationExpression([|$obj.Base.$(mieStep.Target)|])
				mie.Arguments.AddRange(mieStep.Arguments.Select({a | a.CleanClone()}))
				steps.Body.Add([| yield {return $mie} |])
			case ReferenceExpression():			steps.Body.Add([| yield {return $obj.Base.$step()} |])
	if loop.Value:
		var body = steps.Body
		steps.Body = Block()
		var infLoop = [|
			while true:
				$body
				p.Looped = true
		|]
		steps.Body.Add(infLoop)
	result.Arguments.Add(steps)
	return result