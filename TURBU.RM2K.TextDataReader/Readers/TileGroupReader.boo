namespace TURBU.RM2K.TextDataReader.Readers

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro TileGroups(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TTileGroup]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	i = 0
	for elem in body:
		++i
		index = Expression.Lift(i)
		value = Lambdify(elem.Expression, index, 'TTileGroup')
		arr.Items.Add(value.Expression)
	result.Body.Statements.Add([|return $(arr)|])
	yield result
	yield ExpressionStatement([|Data()|])

macro TileGroups.TileGroup(name as StringLiteralExpression, body as ExpressionStatement*):
	macro TileType(values as ReferenceExpression*):
		items = values.ToArray()
		result as Expression = [|TTileType.$(items[0])|]
		i = 1
		while i < items.Length:
			result = [| $result | TTileType.$(items[i]) |]
			++i
		return ExpressionStatement([| TileType($result) |])
	
	result = PropertyList('TTileGroup', [|0|], body)
	result.NamedArguments.Add(ExpressionPair([|Name|], name))
	return ExpressionStatement(result)
