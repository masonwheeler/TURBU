namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Animations(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TAnimTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller({'YTarget': [|TAnimYTarget|], 'Flash': [|TFlashTarget|], 'Shake': [|TFlashTarget|] }))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.animations|]

macro Animations.Animation(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro CellSize(w as IntegerLiteralExpression, h as IntegerLiteralExpression):
		return ExpressionStatement([|CellSize(SgPoint($w, $h))|])
	
	return Lambdify('TAnimTemplate', index, body)

macro Animations.Animation.Frames(body as ExpressionStatement*):
	macro Cell(frameID as IntegerLiteralExpression, cellID as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Position(x as IntegerLiteralExpression, y as IntegerLiteralExpression):
			return ExpressionStatement([|Position(SgPoint($x, $y))|])
		
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