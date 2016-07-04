namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Conditions(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TConditionTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller({'StatEffect': [|TStatEffect|], 'AttackLimit': [|TAttackLimitation|], 'HPDot': [|TDotEffect|], 'MPDot': [|TDotEffect|] }))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.resists|]

macro Conditions.Condition(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Damage(values as IntegerLiteralExpression*):
		return MakeArrayValue('Standard', values)
	
	return Lambdify('TConditionTemplate', index, body)
