namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Skills(body as ExpressionStatement*):
	macro Cost(value as int, percentCost as bool):
		var parent = Cost.GetAncestor[of MacroStatement]()
		parent.Body.Add([|Cost($value)|])
		parent.Body.Add([|CostAsPercentage(true)|]) if percentCost
	
	macro SFX(name as string, v1 as int, v2 as int, v3 as int, v4 as int):
		return ExpressionStatement([|Sfx(TRpgSound($name, $v1, $v2, $v3, $v4))|])
	
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TSkillTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller( {'Usable': [|TUsableWhere|], 'Range': [|TSkillRange|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.skills|]
	yield [|import turbu.sounds|]

macro Skills.Skill(index as IntegerLiteralExpression, body as ExpressionStatement*):
	
	macro SkillPower(values as IntegerLiteralExpression*):
		return MakeArrayValue('SkillPower', values)
	
	macro Stats(values as BoolLiteralExpression*):
		return MakeArrayValue('Stats', values)
	
	macro Condition(values as IntegerLiteralExpression*):
		return MakeArrayValue('Condition', values)
	
	macro Attributes(body as ExpressionStatement*):
		macro Attribute(id as IntegerLiteralExpression, value as IntegerLiteralExpression):
			return ExpressionStatement([|SgPoint($id, $value)|])
		return MakeArrayValue('Attributes', body.Select({es | es.Expression}))
	
	return Lambdify('TNormalSkillTemplate', index, body, 'TSkillTemplate')

macro Skills.TeleportSkill(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TTeleportSkillTemplate', index, body, 'TSkillTemplate')

macro Skills.VariableSkill(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Which(value as ReferenceExpression, id as int):
		assert value.Name == 'Switch', 'Non-switch VariableSkill types are not yet supported'
		return ExpressionStatement([| Which($id) |])
	
	return Lambdify('TVariableSkillTemplate', index, body, 'TSkillTemplate')
