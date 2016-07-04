namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro MapTree(body as JsonStatement*):
	var result = PropertyList( body )
	AddResource('MapTree', result)

macro MapTree.MapEngines(body as ExpressionStatement*):
	return JsonStatement(JProperty('MapEngines', JArray(body.Select( {es | ExpressionValue(es.Expression)} ))))

macro MapTree.Maps(body as JsonStatement*):
	macro Root(body as Statement*):
		var element = PropertyList(0, body)
		return JsonStatement(element)
	
	return MakeListValue('Elements', body)

macro MapTree.Maps.Map(index as int, body as Statement*):
	macro ScrollPosition(x as int, y as int):
		return JsonStatement(JProperty('ScrollPosition', JArray(x, y)))
	
	macro Battles(values as int*):
		return JsonStatement(JProperty('Battles', JArray(values)))
	
	macro EncounterScript(script as MethodInvocationExpression):
		var name = (script.Target cast ReferenceExpression).ToString()
		Map.Body.Add([|EncounterScript($name)|])
		arr = ArrayLiteralExpression()
		arr.Items.AddRange(script.Arguments)
		Map.Body.Add([|EncounterParams($arr)|])
	
	macro Regions(body as JsonStatement*):
		macro Region(index as int, body as Statement*):
			macro Bounds(x as int, y as int, w as int, h as int):
				return JsonStatement(JProperty('Bounds', JArray(x, y, w, h)))
			
			return JsonStatement(PropertyList(index, body))
		
		return MakeListValue('Regions', body)
	
	var element = PropertyList(index, body)
	return JsonStatement(element)

macro MapTree.CurrentMap(id as int):
	return JsonStatement(JProperty('CurrentMap', id))

macro MapTree.StartPoints(body as ExpressionStatement*):
	var result = JArray()
	var sps = body.Select({es | es.Expression}).Cast[of ArrayLiteralExpression]()
	for sp in sps:
		result.Add(JArray( sp.Items.Cast[of IntegerLiteralExpression]().Select({il | il.Value}) ))
	return JsonStatement(JProperty('StartPoints', result))