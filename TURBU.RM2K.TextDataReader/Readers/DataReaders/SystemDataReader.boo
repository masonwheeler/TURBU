﻿namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro SystemData(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TGameLayout]]*:
			pass
	|]
	value = Lambdify('TGameLayout', [|0|], body)
	arr = ArrayLiteralExpression()
	arr.Items.Add(value.Expression)
	result.Body.Statements.Add([|return $(arr)|])
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import TURBU.RM2K.GameData|]

macro SystemData.LogicalSize(x as int, y as int):
	SystemData.Body.Add([|Width($x)|])
	SystemData.Body.Add([|Height($y)|])

macro SystemData.WindowSize(x as int, y as int):
	SystemData.Body.Add([|PhysWidth($x)|])
	SystemData.Body.Add([|PhysHeight($y)|])

macro SystemData.SpriteSize(x as int, y as int):
	return ExpressionStatement([|SpriteSize(SgPoint($x, $y))|])

macro SystemData.SpriteSheetSize(spritesX as int, spritesY as int, framesX as int, framesY as int):
	SystemData.Body.Add([|SpriteSheet(SgPoint($spritesX, $spritesY))|])
	SystemData.Body.Add([|SpriteSheetFrames(SgPoint($framesX, $framesY))|])

macro SystemData.TileSize(x as int, y as int):
	return ExpressionStatement([|TileSize(SgPoint($x, $y))|])

macro SystemData.PortraitSize(x as int, y as int):
	return ExpressionStatement([|PortraitSize(SgPoint($x, $y))|])

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
