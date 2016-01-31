namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast

macro GlobalVars(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgVarsList]]*:
			result = TRpgVarsList()
	|]
	result.Body.Statements.AddRange(body)
	result.Body.Add([|return (System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgVarsList]](0, {return result}),)|])
	yield result
	yield ExpressionStatement([|Data()|])

macro GlobalVars.Switches(body as ExpressionStatement*):
	return ListReader(body, 'Switches')
	
macro GlobalVars.Variables(body as ExpressionStatement*):
	return ListReader(body, 'Variables')

internal def ListReader(body as ExpressionStatement*, name as string) as ExpressionStatement:
	var max = body.Select({e | e.Expression}).OfType[of BinaryExpression]().Select({b | b.Left}).OfType[of IntegerLiteralExpression]()\
		.Select({i | i.Value}).Max()
	return ExpressionStatement([|result.Values.Add($name, $max)|])