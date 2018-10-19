namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Monsters(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgMonster]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller({'Action': [|TMonsterBehaviorAction|] }))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.monsters|]

macro Monsters.Monster(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Attributes(values as IntegerLiteralExpression*):
		var list = System.Collections.Generic.List[of Expression]()
		for i in range(values.Count):
			list.Add([|SgPoint($(i + 1), $(values[i]))|])
		return MakeArrayValue('Resist', list)
	
	macro Condition(values as IntegerLiteralExpression*):
		var list = System.Collections.Generic.List[of Expression]()
		for i in range(values.Count):
			list.Add([|SgPoint($(i + 1), $(values[i]))|])
		return MakeArrayValue('Condition', list)
	
	macro Stats(values as IntegerLiteralExpression*):
		return MakeArrayValue('Stats', values)
	
	macro Behavior(body as ExpressionStatement*):
		macro MonsterBehavior(id as IntegerLiteralExpression, body as ExpressionStatement*):
			macro Requirement(value as Expression):
				return ExpressionStatement([|Requirement({return $value})|])
			
			return ExpressionStatement(PropertyListWithID('TMonsterBehavior', id, body))
	
		return MakeArrayValue('Behavior', body.Select({es | es.Expression}))
	
	return Lambdify('TRpgMonster', index, body)
