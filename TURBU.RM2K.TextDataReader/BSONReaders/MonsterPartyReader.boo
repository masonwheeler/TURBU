namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro MonsterParties:
	pass

macro MonsterParties.MonsterParty(index as int, body as Statement*):
	macro Habitats:
		return JsonStatement(JProperty('Habitats', JArray(Habitats.Arguments.Select(ExpressionValue))))
	
	var result = PropertyList(index, body)
	AddResource('MonsterParties', result)

macro MonsterParties.MonsterParty.Monsters(body as JsonStatement*):
	macro MonsterElement(id as int, body as Statement*):
		macro Position(x as int, y as int):
			return JsonStatement(JProperty('Position', JArray(x, y)))
		
		return JsonStatement(PropertyList(id, body))
	
	return MakeListValue('Monsters', body)

macro MonsterParties.MonsterParty.Pages(body as JsonStatement*):
	macro Page(id as int, body as Statement*):
		return JsonStatement(PropertyList(id, body))
	
	return MakeListValue('Pages', body)

macro MonsterParties.MonsterParty.Pages.Page.PageConditions(body as JsonStatement*):
	macro Switch(id as int):
		return JsonStatement(JProperty('Switch', id))
	
	macro Switch2(id as int):
		return JsonStatement(JProperty('Switch2', id))
	
	macro Variable(comp as BinaryExpression):
		result = JObject()
		result['L'] = ExpressionValue(comp.Left)
		result['R'] = ExpressionValue(comp.Right)
		result['Op'] = comp.Operator.ToString()
		return JsonStatement(JProperty('Variable', result))
	
	macro Item(id as int):
		return JsonStatement(JProperty('HasItem', id))
	
	macro Hero(id as int):
		return JsonStatement(JProperty('HeroPresent', id))
	
	macro Timer1(value as int):
		return JsonStatement(JProperty('Timer1', value))
	
	macro Timer2(value as int):
		return JsonStatement(JProperty('Timer2', value))
	
	macro Turns(mult as int, constant as int):
		return JsonStatement(JProperty('Turns', JArray(mult, constant)))
	
	macro HeroHP(id as int, min as int, max as int):
		return JsonStatement(JProperty('HeroHP', JArray(id, min, max)))
	
	macro MonsterHP(id as int, min as int, max as int):
		return JsonStatement(JProperty('MonsterHP', JArray(id, min, max)))
	
	macro HeroTime(id as int, multiplier as int, base as int):
		return JsonStatement(JProperty('HeroTime', JArray(id, multiplier, base)))
	
	macro MonsterTime(id as int, multiplier as int, base as int):
		return JsonStatement(JProperty('MonsterTime', JArray(id, multiplier, base)))
	
	return JsonStatement(JProperty('PageConditions', PropertyList(body)))
