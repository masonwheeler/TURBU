namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Tilesets(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TTileSet]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller( {'AnimDir': [|sdl.sprite.TAnimPlayMode|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.tilesets|]

macro Tilesets.Tileset(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TTileSet', index, body)

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
						for i in range(1, attr.Items.Count):
							value = [|$value | TTileAttribute.$(attr.Items[i])|]
				arr.Items.Add(value)
			return ExpressionStatement([| Attributes(System.Collections.Generic.List[of TTileAttribute]($arr)) |])
		
		return ExpressionStatement(PropertyList('TTileGroupRecord', ID, body))
	
	return MakeListValue('Records', 'TTileGroupRecord', body)
