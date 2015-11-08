namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro MapTree(body as Statement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TMapTree]]*:
			result = turbu.map.metadata.TMapTree()
	|]
	result.Body.Statements.AddRange(body)
	result.Body.Statements.Add([| return (System.Collections.Generic.KeyValuePair[of int, System.Func[of TMapTree]](0, {return result}),) |])
	result.Accept(EnumFiller( {
		'BgmState': [|TInheritedDecision|],
		'BattleBgState': [|TInheritedDecision|],
		'CanPort': [|TInheritedDecision|],
		'CanEscape': [|TInheritedDecision|],
		'CanSave': [|TInheritedDecision|]} ))
	result.Accept(PropRenamer({'Song': 'BgmData'}))
	yield result
	yield ExpressionStatement([|Data()|])

macro MapTree.MapEngines(body as ExpressionStatement*):
	YieldAll body.Select({es | [|result.MapEngines.Add($(es.Expression))|] })

macro MapTree.root(body as ExpressionStatement*):
	element = PropertyList('TMapMetadata', [|0|], body)
	return ExpressionStatement([|result.Add($element)|])

macro MapTree.map(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro ScrollPosition(x as IntegerLiteralExpression, y as IntegerLiteralExpression):
		return ExpressionStatement([|ScrollPosition(sgPoint($x, $y))|])
	
	macro Battles(values as IntegerLiteralExpression*):
		arr = ArrayLiteralExpression()
		arr.Items.AddRange(values)
		return ExpressionStatement([| Battles($arr) |])
	
	macro EncounterScript(script as MethodInvocationExpression):
		name = (script.Target cast ReferenceExpression).ToString()
		map.Body.Add([|EncounterScript($name)|])
		arr = ArrayLiteralExpression()
		arr.Items.AddRange(script.Arguments)
		map.Body.Add([|EncounterParams($arr)|])
	
	macro Regions(body as ExpressionStatement*):
		macro Region(index as IntegerLiteralExpression, body as ExpressionStatement*):
			macro Bounds(x as int, y as int, w as int, h as int):
				return ExpressionStatement([| Bounds(SDL2.SDL.SDL_Rect($x, $y, $w, $h)) |])
			
			return ExpressionStatement(PropertyList('TMapRegion', index, body))
		
		return MakeDataListValue('Regions', 'TMapRegion', body)
	
	element = PropertyList('TMapMetadata', index, body)
	return ExpressionStatement([|result.Add($element)|])

macro MapTree.CurrentMap(id as IntegerLiteralExpression):
	return ExpressionStatement([|result.CurrentMap = $id|])

macro MapTree.StartPoint(map as IntegerLiteralExpression, x as IntegerLiteralExpression, y as IntegerLiteralExpression):
	return ExpressionStatement([| result.Location.Add(result.Location.Count, TLocation($map, $x, $y)) |])