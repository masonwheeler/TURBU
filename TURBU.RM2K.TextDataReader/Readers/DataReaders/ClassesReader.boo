namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Classes(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TClassTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	#result.Accept(EnumFiller( {'DualWield': [|TWeaponStyle|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.characters|]

//TODO: Finish this when working on a test game that actually uses Classes
macro Classes.Class(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TClassTemplate', index, body)

