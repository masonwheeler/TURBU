namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro TileGroups:
	pass

macro TileGroups.TileGroup(name as string, body as Statement*):
	macro TileType(values as ReferenceExpression*):
		var arr = JArray(values.Select({r | r.Name}))
		return JsonStatement(JProperty('TileType', arr))
		
	macro Dimensions(x as int, y as int):
		return JsonStatement(JProperty('Dimensions', JArray(x, y)))
	
	result = PropertyList(body)
	result['Name'] = name
	var id = (TileGroups['Counter'] cast int if TileGroups.ContainsAnnotation('Counter') else 0) + 1
	TileGroups['Counter'] = id
	result['ID'] = id
	AddResource('TileGroups', result)
