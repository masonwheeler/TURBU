namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro MapData(id as int, body as Statement*):
	var result = PropertyList(id, body)
	AddResource('Maps', result)

macro MapData.Size(x as int, y as int):
	return JsonStatement(JProperty('Size', JArray(x, y)))

macro MapData.Panning(hPan as ReferenceExpression, hPanSpeed as int, vPan as ReferenceExpression, vPanSpeed as int):
	yield JsonStatement(JProperty('HScroll', hPan.Name))
	yield JsonStatement(JProperty('VScroll', vPan.Name))
	yield JsonStatement(JProperty('ScrollSpeed', JArray(hPanSpeed, vPanSpeed)))

macro MapData.Background(usesBG as bool, bgName as string):
	yield JsonStatement(JProperty('HasBackground', usesBG))
	yield JsonStatement(JProperty('BgName', bgName))

macro MapData.Tiles(body as JsonStatement*):
	macro Layer(body as ExpressionStatement*):
		var layer = body.SelectMany({es | (es.Expression cast ArrayLiteralExpression).Items}) \
						.Cast[of IntegerLiteralExpression]() \
						.Select({i | i.Value})
		return JsonStatement(JArray(*layer.ToArray()))
		
	return JsonStatement(JProperty('TileMap', JArray(*body.Select({j | j.Value}).ToArray())))

macro MapData.MapObjects(body as JsonStatement*):
	macro MapObject(id as int, body as Statement*):
		macro Position(x as int, y as int):
			return JsonStatement(JProperty('Location', JArray(x, y)))
		
		return JsonStatement(PropertyList(id, body))
	return MakeListValue('MapObjects', body)

macro MapData.MapObjects.MapObject.Pages(body as JsonStatement*):
	macro Page(id as int, body as Statement*):
		macro Sprite(filename as string, index as int, facing as ReferenceExpression, frame as int, transparent as bool):
			yield JsonStatement(JProperty('Name', filename))
			yield JsonStatement(JProperty('SpriteIndex', index))
			yield JsonStatement(JProperty('Direction', facing.Name))
			yield JsonStatement(JProperty('Frame', frame))
			yield JsonStatement(JProperty('Transparent', transparent))
		
		macro Move(moveType as ReferenceExpression, frequency as int, animType as ReferenceExpression, speed as int):
			yield JsonStatement(JProperty('MoveType', moveType.Name))
			yield JsonStatement(JProperty('MoveFrequency', frequency))
			yield JsonStatement(JProperty('AnimType', animType.Name))
			yield JsonStatement(JProperty('MoveSpeed', speed))
		
		macro Height(z as int, barrier as bool):
			yield JsonStatement(JProperty('ZOrder', z))
			yield JsonStatement(JProperty('IsBarrier', barrier))
		
		result = JsonStatement(PropertyList(id, body))
		return result
	
	return MakeListValue('Pages', body)

macro MapData.MapObjects.MapObject.Pages.Page.Conditions(body as JsonStatement*):
	macro Switch(id as int):
		return JsonStatement(JProperty('Switch', id))
	
	macro Switch2(id as int):
		return JsonStatement(JProperty('Switch2', id))
	
	macro Variable(comp as BinaryExpression):
		var result = JObject()
		result.Add('Int', (comp.Left cast IntegerLiteralExpression).Value)
		result.Add('Op', Boo.Lang.Compiler.Ast.Visitors.BooPrinterVisitor.GetBinaryOperatorText(comp.Operator))
		result.Add('Value', (comp.Right cast IntegerLiteralExpression).Value)
		return JsonStatement(JProperty('Int', result))
	
	macro Item(id as int):
		return JsonStatement(JProperty('HasItem', id))
	
	macro Hero(id as int):
		return JsonStatement(JProperty('HeroPresent', id))
	
	macro Timer1(value as int):
		return JsonStatement(JProperty('Timer1', value))
	
	macro Timer2(value as int):
		return JsonStatement(JProperty('Timer2', value))
	
	return JsonStatement(JProperty('Conditions', PropertyList(body)))

macro MapData.MapObjects.MapObject.Pages.Page.MoveScript(loop as bool, ignoreObstacles as bool, body as ExpressionStatement*):
	var arr = JArray()
	for value in body.Select({es | es.Expression}):
		if value.NodeType == NodeType.ReferenceExpression:
			arr.Add(value.ToString())
		elif value.NodeType == NodeType.MethodInvocationExpression:
			var mie = value cast MethodInvocationExpression
			var name = mie.Target.ToString()
			var args = mie.Arguments.Select(ExpressionValue).ToArray()
			subArr = JArray(name)
			subArr.Add(args)
			arr.Add(subArr)
		else:
			var be = value cast BinaryExpression
			var step = be.Left cast ReferenceExpression
			var mult = be.Right cast IntegerLiteralExpression
			arr.Add(JArray(step.Name, mult.Value))
	var result = JObject()
	result['Loop'] = loop
	result['IgnoreObstacles'] = ignoreObstacles
	result['Path'] = arr
	return JsonStatement(JProperty('Path', result))