namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Items(body as ExpressionStatement*):
	result = [|
		def Data() as TItemTemplate:
			pass
	|]
	value = body.Select({e | e.Expression}).Single()
	result.Body.Statements.Add([|return $value|])
	result.Accept(EnumFiller({'Usable': [|TUsableWhere|], 'Slot': [|TSlot|] }))
	result.Accept(PropRenamer({'Usable': 'UsableWhere', 'SkillMessage': 'CustomSkillMessage'}))
	yield result
	yield ExpressionStatement([|Data()|])

macro Items.JunkItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return ExpressionStatement(PropertyList('TJunkTemplate', index, body))

macro Items.ArmorItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Heroes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	return ExpressionStatement(PropertyList('TArmorTemplate', index, body))

macro Items.ArmorItem.Attributes(body as ExpressionStatement*):
	macro Attribute(l as IntegerLiteralExpression, r as IntegerLiteralExpression):
		return ExpressionStatement([|$l = $r|])
	
	result = ArrayLiteralExpression()
	for pair in body:
		match pair.Expression:
			case [|$l = $r|]:
				result.Items.Add([|sgPoint($l, $r)|])
	return ExpressionStatement([|Attributes($result)|])

macro Items.WeaponItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Heroes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	return ExpressionStatement(PropertyList('TWeaponTemplate', index, body))

macro Items.WeaponItem.Attributes(body as ExpressionStatement*):
	macro Attribute(l as IntegerLiteralExpression, r as IntegerLiteralExpression):
		return ExpressionStatement([|$l = $r|])
	
	result = ArrayLiteralExpression()
	for pair in body:
		match pair.Expression:
			case [|$l = $r|]:
				result.Items.Add([|sgPoint($l, $r)|])
	return ExpressionStatement([|Attributes($result)|])

macro Items.WeaponItem.Animations(body as ExpressionStatement*):
	macro Anim(id as IntegerLiteralExpression, body as ExpressionStatement*):
		return ExpressionStatement(PropertyList('TWeaponAnimData', id, body))
	
	result = MakeArrayValue('AnimData', body.Select({e | e.Expression}))
	result.Accept(EnumFiller({'AnimType': [|TWeaponAnimType|], 'MovementMode': [|TMovementMode|] }))
	return result

macro Items.SkillItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Heroes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	return ExpressionStatement(PropertyList('TSkillItemTemplate', index, body))

macro Items.SwitchItem(index as IntegerLiteralExpression, body as Statement*):
	macro Heroes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	macro Value(typ as ReferenceExpression, id as IntegerLiteralExpression):
		yield ExpressionStatement([|Which($id)|])
		yield ExpressionStatement([|Style(TVarSets.$typ)|])
	
	return ExpressionStatement(PropertyList('TVariableItemTemplate', index, Flatten(body)))
