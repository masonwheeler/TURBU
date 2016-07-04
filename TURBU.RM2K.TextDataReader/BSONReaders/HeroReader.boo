namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Heroes:
	pass

macro Heroes.Hero(index as int, body as Statement*):
	var result = PropertyList(index, body)
	AddResource('Heroes', result)

macro Heroes.Hero.ExpFunc(value as MethodInvocationExpression):
	Hero.Body.Add(JsonStatement(JProperty('ExpMethod', value.Target.ToString())))
	var vars = JArray(value.Arguments.Select(ExpressionValue))
	Hero.Body.Add(JsonStatement(JProperty('ExpVars', vars)))

macro Heroes.Hero.Sprite(name as string, index as int):
	Hero.Body.Add(JsonStatement(JProperty('MapSprite', name)))
	Hero.Body.Add(JsonStatement(JProperty('SpriteIndex', index)))

macro Heroes.Hero.Portrait(name as string, index as int):
	Hero.Body.Add(JsonStatement(JProperty('Portrait', name)))
	Hero.Body.Add(JsonStatement(JProperty('PortraitIndex', index)))

macro Heroes.Hero.BattlePosition(x as int, y as int):
	return JsonStatement(JProperty('BattlePos', JArray(x, y)))

macro Heroes.Hero.Commands(values as int*):
	return JsonStatement(JProperty('Commands', JArray(values)))

macro Heroes.Hero.Equipment(values as int*):
	return JsonStatement(JProperty('Equipment', JArray(values)))

macro Heroes.Hero.SkillSet(body as JsonStatement*):
	macro SkillRecord(skillType as ReferenceExpression, id as int, args as ArrayLiteralExpression):
		var result = JObject()
		result['Skill'] = id
		result['Style'] = skillType.Name
		result['Nums'] = ExpressionValue(args)
		return JsonStatement(result)
	
	return MakeListValue('Skillset', body)

macro Heroes.Hero.Attributes(body as JsonStatement*):
	macro Attribute(id as int, percentage as int):
		return JsonStatement(JArray(id, percentage))
	
	return MakeListValue('Resist', body)

macro Heroes.Hero.CondResists(body as JsonStatement*):
	macro Condition(id as int, percentage as int):
		return JsonStatement(JArray(id, percentage))
	
	return MakeListValue('Condition', body)

macro Heroes.Hero.StatBlock(body as JsonStatement*):
	macro Stats(id as int, block as ArrayLiteralExpression):
		var result = JObject()
		result['ID'] = id
		result['Block'] = ExpressionValue(block)
		return JsonStatement(result)
	
	return MakeListValue('StatBlocks', body)
