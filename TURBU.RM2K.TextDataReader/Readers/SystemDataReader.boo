namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro SystemData(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TGameLayout]]*:
			pass
	|]
	value = Lambdify(PropertyList('TGameLayout', [|0|], body), [|0|], 'TGameLayout')
	arr = ArrayLiteralExpression()
	arr.Items.Add(value.Expression)
	result.Body.Statements.Add([|return $(arr)|])
	yield result
	yield ExpressionStatement([|Data()|])

macro SystemData.LogicalSize(x as int, y as int):
	SystemData.Body.Add([|Width($x)|])
	SystemData.Body.Add([|Height($y)|])

macro SystemData.WindowSize(x as int, y as int):
	SystemData.Body.Add([|PhysWidth($x)|])
	SystemData.Body.Add([|PhysHeight($y)|])

macro SystemData.SpriteSize(x as int, y as int):
	return ExpressionStatement([|SpriteSize(sgPoint($x, $y))|])

macro SystemData.TileSize(x as int, y as int):
	return ExpressionStatement([|TileSize(sgPoint($x, $y))|])

macro SystemData.PortraitSize(x as int, y as int):
	return ExpressionStatement([|PortraitSize(sgPoint($x, $y))|])

macro SystemData.Transitions(values as ReferenceExpression*):
	a = ArrayLiteralExpression()
	a.Items.AddRange(values.Select({r | return [|TTransitions.$r|]}))
	return ExpressionStatement([|Transitions($a)|])

macro SystemData.BattleCommands(values as IntegerLiteralExpression*):
	a = ArrayLiteralExpression()
	a.Items.AddRange(values)
	return ExpressionStatement([|BattleCommands($a)|])

macro SystemData.StartingHeroes(values as IntegerLiteralExpression*):
	a = ArrayLiteralExpression()
	a.Items.AddRange(values)
	return ExpressionStatement([|StartingHeroes($a)|])

macro SystemData.MoveMatrix(body as ExpressionStatement*):
	a = ArrayLiteralExpression()
	a.Items.AddRange(body.Select({es | es.Expression cast ArrayLiteralExpression}))
	return ExpressionStatement([|MoveMatrix(System.Collections.Generic.List[of ((int))]($a))|])

macro SystemData.BattleTestData:
	pass //don't worry about this for now

macro SystemData.BattleLayout:
	pass //don't worry about this for now
