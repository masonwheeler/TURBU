﻿namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Animations(body as ExpressionStatement*):
	result = [|
		def Data() as TAnimTemplate:
			pass
	|]
	value = body.Select({e | e.Expression}).Single()
	result.Body.Statements.Add([|return $value|])
	result.Accept(EnumFiller({'YTarget': [|TAnimYTarget|], 'Flash': [|TFlashTarget|], 'Shake': [|TFlashTarget|] }))
	yield result
	yield ExpressionStatement([|Data()|])

macro Animations.Animation(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro CellSize(w as IntegerLiteralExpression, h as IntegerLiteralExpression):
		return ExpressionStatement([|CellSize(sgPoint($w, $h))|])
	
	return ExpressionStatement(PropertyList('TAnimTemplate', index, body))

macro Animations.Animation.Frames(body as ExpressionStatement*):
	macro Cell(frameID as IntegerLiteralExpression, cellID as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Position(x as IntegerLiteralExpression, y as IntegerLiteralExpression):
			return ExpressionStatement([|Position(sgPoint($x, $y))|])
		
		macro Color(r as IntegerLiteralExpression, g as IntegerLiteralExpression, b as IntegerLiteralExpression, sat as IntegerLiteralExpression):
			return ExpressionStatement([|Color(TSgColor($r, $g, $b, $sat))|])
		
		result = PropertyList('TAnimCell', cellID, body)
		result.NamedArguments.Add(ExpressionPair([|Frame|], frameID))
		return ExpressionStatement(result)
	
	return MakeListValue('Frames', 'TAnimCell', body)

macro Animations.Animation.Effects(body as ExpressionStatement*):
	macro Effect(frameID as IntegerLiteralExpression, ID as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Color(r as IntegerLiteralExpression, g as IntegerLiteralExpression, b as IntegerLiteralExpression, sat as IntegerLiteralExpression):
			return ExpressionStatement([|Color(TSgColor($r, $g, $b, $sat))|])
		
		result = PropertyList('TAnimEffects', ID, body)
		result.NamedArguments.Add(ExpressionPair([|Frame|], frameID))
		return ExpressionStatement(result)
	
	return MakeListValue('Effects', 'TAnimEffects', body)