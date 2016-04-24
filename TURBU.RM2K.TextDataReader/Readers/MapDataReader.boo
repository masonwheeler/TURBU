namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro MapData(id as IntegerLiteralExpression, body as ExpressionStatement*):
	name = "Map$(id.Value.ToString('D4'))"
	result = PropertyList(name, id, body)
	result.Accept(EnumFiller( {'Wraparound': [|TWraparound|], 'Trigger': [|TStartCondition|]} ))
	yield [|
		def Data():
			result = $result
			result.Initialize()
			return result
	|]
	yield ExpressionStatement([|Data()|])

macro MapData.Size(x as int, y as int):
	return ExpressionStatement([|Size(sgPoint($x, $y))|])

macro MapData.Panning(hPan as ReferenceExpression, hPanSpeed as int, vPan as ReferenceExpression, vPanSpeed as int):
	MapData.Body.Add([|HScroll(TMapScrollType.$hPan)|])
	MapData.Body.Add([|VScroll(TMapScrollType.$vPan)|])
	MapData.Body.Add([|ScrollSpeed(sgPoint($hPanSpeed, $vPanSpeed))|])

macro MapData.Background(usesBG as bool, bgName as string):
	MapData.Body.Add([|HasBackground($usesBG)|])
	MapData.Body.Add([|BgName($bgName)|])

macro MapData.Tiles(body as ExpressionStatement*):
	macro Layer(body as ExpressionStatement*):
		layer = ArrayLiteralExpression()
		layer.Items.AddRange(
					body.SelectMany({es | (es.Expression cast ArrayLiteralExpression).Items}) \
						.Cast[of IntegerLiteralExpression]() \
						.Select({i | [|turbu.tilesets.TTileRef($i)|]}))
		return ExpressionStatement(layer)
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({es | es.Expression}))
	return ExpressionStatement([|TileMap($arr)|])

macro MapData.MapObjects(body as ExpressionStatement*):
	macro MapObject(id as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Position(x as int, y as int):
			return ExpressionStatement([|Location(sgPoint($x, $y))|])
		
		result = ExpressionStatement(PropertyList('TRpgMapObject', id, body))
		return result
	return MakeListValue('MapObjects', 'TRpgMapObject', body)

macro MapData.MapObjects.MapObject.Pages(body as ExpressionStatement*):
	macro Page(id as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Sprite(filename as string, index as int, facing as ReferenceExpression, frame as int, transparent as bool):
			Page.Body.Add([|Name($filename)|])
			Page.Body.Add([|SpriteIndex($index)|])
			Page.Body.Add([|Direction(TDirections.$facing)|])
			Page.Body.Add([|Frame($frame)|])
			Page.Body.Add([|Transparent($transparent)|])
		
		macro Move(moveType as ReferenceExpression, frequency as int, animType as ReferenceExpression, speed as int):
			Page.Body.Add([|MoveType(TMoveType.$moveType)|])
			Page.Body.Add([|MoveFrequency($frequency)|])
			Page.Body.Add([|AnimType(TAnimType.$animType)|])
			Page.Body.Add([|MoveSpeed($speed)|])
		
		macro Height(z as int, barrier as bool):
			Page.Body.Add([|ZOrder($z)|])
			Page.Body.Add([|IsBarrier($barrier)|])
		
		result = ExpressionStatement(PropertyListWithID('TRpgEventPage', id, body))
		return result
	
	return MakeListValue('Pages', 'TRpgEventPage', body)

macro MapData.MapObjects.MapObject.Pages.Page.Conditions(body as ExpressionStatement*):
	macro Switch(id as int):
		return ExpressionStatement([|Switch[$id]|])
	
	macro Variable(comp as BinaryExpression):
		be = BinaryExpression(comp.Operator, [|Ints[$(comp.Left)]|], comp.Right)
		return ExpressionStatement(be)
	
	macro Item(id as int):
		return ExpressionStatement([|HasItem($id)|])
	
	macro Hero(id as int):
		return ExpressionStatement([|HeroPresent($id)|])
	
	macro Timer1(value as int):
		return ExpressionStatement([|Timer.Time <= ($value)|])
	
	macro Timer2(value as int):
		return ExpressionStatement([|Timer2.Time <= ($value)|])
	
	result as Expression
	for line in body:
		result = (line.Expression if result is null else [|$result and $(line.Expression)|])
	return ExpressionStatement([| Conditions({return $result}) |])

macro MapData.MapObjects.MapObject.Pages.Page.MoveScript(loop as bool, ignoreObstacles as bool, body as ExpressionStatement*):
	var arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({es | es.Expression}))
	var result = [|CreatePath($loop, $ignoreObstacles, $arr)|]
	return ExpressionStatement([|Path($result)|])