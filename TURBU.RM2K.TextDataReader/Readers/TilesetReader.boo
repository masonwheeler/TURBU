﻿namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Tilesets(body as ExpressionStatement*):
	result = [|
		def Data() as TTileSet:
			pass
	|]
	value = body.Select({e | e.Expression}).Single()
	result.Body.Statements.Add([|return $value|])
	result.Accept(EnumFiller( {'AnimDir': [|sdl.sprite.TAnimPlayMode|]} ))
	yield result
	yield ExpressionStatement([|Data()|])

macro Tilesets.Tileset(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return ExpressionStatement(PropertyList('TTileSet', index, body))

macro Tilesets.Tileset.TileGroups(body as ExpressionStatement*):
	macro TileGroupRecord(ID as IntegerLiteralExpression, body as ExpressionStatement*):
		macro Terrain(values as IntegerLiteralExpression*):
			arr = ArrayLiteralExpression()
			arr.Items.AddRange(values)
			return ExpressionStatement([| Terrain(System.Collections.Generic.List[of int]($arr)) |])
		
		macro Layers(values as IntegerLiteralExpression*):
			arr = ArrayLiteralExpression()
			arr.Items.AddRange(values)
			return ExpressionStatement([|Layers($arr)|])
		
		macro Attributes(body as ExpressionStatement*):
			arr = ArrayLiteralExpression()
			value as Expression
			for attr in body.Select({es | es.Expression}).Cast[of ListLiteralExpression]():
				if attr.Items.Count == 0:
					value = [|TTileAttribute.None|]
				else:
					value = [|TTileAttribute.$(attr.Items[0])|]
					if attr.Items.Count > 1:
						for i in range(1, attr.Items.Count - 1):
							value = [|$value | TTileAttribute.$(attr.Items[i])|]
				arr.Items.Add(value)
			return ExpressionStatement([| Attributes(System.Collections.Generic.List[of TTileAttribute]($arr)) |])
		
		return ExpressionStatement(PropertyList('TTileGroupRecord', ID, body))
	
	return MakeListValue('Records', 'TTileGroupRecord', body)
