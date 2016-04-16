namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Commands(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TBattleCommand]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller( {'Style': [|TCommandStyle|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.characters|]

macro Commands.Command(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TBattleCommand', index, body)