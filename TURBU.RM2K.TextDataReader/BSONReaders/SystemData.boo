namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro SystemData(body as Statement*):
	var result = PropertyList(body)
	AddResource('SystemData', result)

macro SystemData.LogicalSize(x as int, y as int):
	SystemData.Body.Add(JsonStatement(JProperty('Width', x)))
	SystemData.Body.Add(JsonStatement(JProperty('Height', y)))

macro SystemData.WindowSize(x as int, y as int):
	SystemData.Body.Add(JsonStatement(JProperty('PhysWidth', x)))
	SystemData.Body.Add(JsonStatement(JProperty('PhysHeight', y)))

macro SystemData.SpriteSize(x as int, y as int):
	return JsonStatement(JProperty('SpriteSize', JArray(x, y)))

macro SystemData.SpriteSheetSize(spritesX as int, spritesY as int, framesX as int, framesY as int):
	SystemData.Body.Add(JsonStatement(JProperty('SpriteSheet', JArray(spritesX, spritesY))))
	SystemData.Body.Add(JsonStatement(JProperty('SpriteSheetFrames', JArray(framesX, framesY))))

macro SystemData.TileSize(x as int, y as int):
	return JsonStatement(JProperty('TileSize', JArray(x, y)))

macro SystemData.PortraitSize(x as int, y as int):
	return JsonStatement(JProperty('PortraitSize', JArray(x, y)))

macro SystemData.Transitions(values as ReferenceExpression*):
	var arr = JArray(values.Select({re | re.Name}))
	return JsonStatement(JProperty('Transitions', arr))

macro SystemData.BattleCommands(values as int*):
	var arr = JArray(values)
	return JsonStatement(JProperty('BattleCommands', arr))

macro SystemData.StartingHeroes(values as int*):
	var arr = JArray(values)
	return JsonStatement(JProperty('StartingHeroes', arr))

macro SystemData.MoveMatrix(body as ExpressionStatement*):
	var arr = JArray(body.Select({es | es.Expression}).Cast[of ArrayLiteralExpression]().Select(ExpressionValue))
	return JsonStatement(JProperty('MoveMatrix', arr))

macro SystemData.BattleTestData:
	pass //don't worry about this for now

macro SystemData.BattleLayout:
	pass //don't worry about this for now
