namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Attributes(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TAttributeTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.resists|]

macro Attributes.Attribute(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Damage(values as IntegerLiteralExpression*):
		return MakeArrayValue('Standard', values)
	
	return Lambdify('TAttributeTemplate', index, body)
