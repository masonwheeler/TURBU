namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Tilesets:
	pass

macro Tilesets.Tileset(index as int, body as Statement*):
	var result = PropertyList(index, body)
	AddResource('Tilesets', result)

macro Tilesets.Tileset.TileGroups(body as JsonStatement*):
	macro TileGroupRecord(ID as int, body as Statement*):
		macro Terrain(values as int*):
			return JsonStatement(JProperty('Terrain', JArray(values)))
		
		macro Layers(values as int*):
			return JsonStatement(JProperty('Layers', JArray(values)))
		
		macro Attributes(body as ExpressionStatement*):
			var arr = JArray()
			for attr in body.Select({es | es.Expression}).Cast[of ListLiteralExpression]():
				arr.Add(ExpressionValue(attr))
			return JsonStatement(JProperty('Attributes', arr))
		
		return JsonStatement(PropertyList(ID, body))
	
	return MakeListValue('Records', body)
