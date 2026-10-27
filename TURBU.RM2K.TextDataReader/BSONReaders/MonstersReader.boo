namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Monsters:
	pass

macro Monsters.Monster(index as int, body as Statement*):
	//the attribute and condition resistances are listed in order, starting from attribute (or condition) 1
	macro Attributes(values as int*):
		return JsonStatement(JProperty('Resist', JArray(values)))
	
	macro Condition(values as int*):
		return JsonStatement(JProperty('Condition', JArray(values)))
	
	macro Stats(values as int*):
		return JsonStatement(JProperty('Stats', JArray(values)))
	
	var result = PropertyList(index, body)
	AddResource('Monsters', result)

macro Monsters.Monster.Behavior(body as JsonStatement*):
	macro MonsterBehavior(id as int, body as Statement*):
		//a call on BattleState, such as BattleState.MonsterHPBetween(10, 0, 50), kept as its name and arguments
		macro Requirement(call as MethodInvocationExpression):
			var requirement = JObject()
			requirement['Name'] = (call.Target cast MemberReferenceExpression).Name
			requirement['Args'] = JArray(call.Arguments.Select(ExpressionValue))
			return JsonStatement(JProperty('Requirement', requirement))
		
		return JsonStatement(PropertyList(id, body))
	
	return MakeListValue('Behavior', body)
