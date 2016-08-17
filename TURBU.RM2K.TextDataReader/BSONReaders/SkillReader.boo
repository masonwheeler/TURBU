namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Skills:
	macro Cost(value as int, percentCost as bool):
		var parent = Cost.GetAncestor[of MacroStatement]()
		parent.Body.Add([|Cost($value)|])
		parent.Body.Add([|CostAsPercentage(true)|]) if percentCost
	
	macro SFX(name as string, v1 as int, v2 as int, v3 as int, v4 as int):
		return JsonStatement(JProperty('Sfx', JArray(name, v1, v2, v3, v4)))
	
	macro BattleSkillAnims(body as JsonStatement*):
		macro BattleSkillAnim(id as int, body as Statement*):
			return JsonStatement(PropertyList(id, body))
		
		return MakeListValue('BattleSkillAnims', body)

macro Skills.Skill(index as int, body as Statement*):
	
	macro SkillPower(values as int*):
		return JsonStatement(JProperty('SkillPower', JArray(values)))
	
	macro Stats(values as bool*):
		return JsonStatement(JProperty('Stats', JArray(values)))
	
	macro Condition(values as int*):
		return JsonStatement(JProperty('Condition', JArray(values)))
	
	macro Attributes(body as JsonStatement*):
		macro Attribute(id as int, value as int):
			return JsonStatement(JArray(id, value))
		
		return MakeListValue('Attributes', body)
	
	var result = PropertyList(index, body)
	result['SkillType'] = 'Normal'
	AddResource('Skills', result)

macro Skills.TeleportSkill(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['SkillType'] = 'Teleport'
	AddResource('Skills', result)

macro Skills.VariableSkill(index as int, body as Statement*):
	macro Which(value as ReferenceExpression, id as int):
		assert value.Name == 'Switch', 'Non-switch VariableSkill types are not yet supported'
		return ExpressionStatement([| Which($id) |])
	
	var result = PropertyList(index, body)
	result['SkillType'] = 'Variable'
	AddResource('Skills', result)
