namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Items:
	macro UsableByHero(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	macro Attributes(values as int*):
		result = JArray()
		for value in values:
			result.Add(value)
		return JsonStatement(JProperty('Attributes', result))

macro Items.JunkItem(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['ItemType'] = 'Junk'
	AddResource('Items', result)

macro Items.MedicineItem(index as int, body as Statement*):
	macro Conditions(values as IntegerLiteralExpression*):
		return MakeArrayValue('Conditions', values)
	
	var result = PropertyList(index, body)
	result['ItemType'] = 'Medicine'
	AddResource('Items', result)

macro Items.UpgradeItem(index as int, body as Statement*):
	macro Stats(values as IntegerLiteralExpression*):
		return MakeArrayValue('Stats', values)
	
	var result = PropertyList(index, body)
	result['ItemType'] = 'Upgrade'
	AddResource('Items', result)

macro Items.ArmorItem(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['ItemType'] = 'Armor'
	AddResource('Items', result)

macro Items.WeaponItem(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['ItemType'] = 'Weapon'
	AddResource('Items', result)

macro Items.WeaponItem.Animations(body as JsonStatement*):
	macro Anim(id as int, body as Statement*):
		return JsonStatement(PropertyList(id, body))
	
	result = MakeListValue('AnimData', body)
	return result

macro Items.SkillItem(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['ItemType'] = 'Skill'
	AddResource('Items', result)

macro Items.SwitchItem(index as int, body as Statement*):
	macro Value(typ as ReferenceExpression, id as int):
		yield JsonStatement(JProperty('Which', id))
		yield JsonStatement(JProperty('Style', typ.Name))
	
	var result = PropertyList(index, body)
	result['ItemType'] = 'Variable'
	AddResource('Items', result)

macro Items.BookItem(index as int, body as Statement*):
	var result = PropertyList(index, body)
	result['ItemType'] = 'Book'
	AddResource('Items', result)
