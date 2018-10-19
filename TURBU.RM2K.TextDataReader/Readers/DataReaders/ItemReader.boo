namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Items(body as ExpressionStatement*):
	macro UsableByHero(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByHero', values)
	
	macro Classes(values as IntegerLiteralExpression*):
		return MakeArrayValue('UsableByClass', values)
	
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TItemTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller({'Usable': [|TUsableWhere|], 'Slot': [|TSlot|] }))
	result.Accept(PropRenamer({'Usable': 'UsableWhere', 'SkillMessage': 'CustomSkillMessage'}))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.items|]

macro Items.JunkItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TJunkTemplate', index, body, 'TItemTemplate')

macro Items.MedicineItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Conditions(values as IntegerLiteralExpression*):
		return MakeArrayValue('Conditions', values)
	
	return Lambdify('TMedicineTemplate', index, body, 'TItemTemplate')

macro Items.UpgradeItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Stats(values as IntegerLiteralExpression*):
		return MakeArrayValue('Stats', values)
	
	return Lambdify('TStatItemTemplate', index, body, 'TItemTemplate')

macro Items.ArmorItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TArmorTemplate', index, body, 'TItemTemplate')

macro Items.ArmorItem.Attributes(body as ExpressionStatement*):
	macro Attribute(l as IntegerLiteralExpression, r as IntegerLiteralExpression):
		return ExpressionStatement([|$l = $r|])
	
	result = ArrayLiteralExpression()
	for pair in body:
		match pair.Expression:
			case [|$l = $r|]:
				result.Items.Add([|SgPoint($l, $r)|])
	return ExpressionStatement([|Attributes($result)|])

macro Items.WeaponItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TWeaponTemplate', index, body, 'TItemTemplate')

macro Items.WeaponItem.Attributes(body as ExpressionStatement*):
	macro Attribute(l as IntegerLiteralExpression, r as IntegerLiteralExpression):
		return ExpressionStatement([|$l = $r|])
	
	result = ArrayLiteralExpression()
	for pair in body:
		match pair.Expression:
			case [|$l = $r|]:
				result.Items.Add([|SgPoint($l, $r)|])
	return ExpressionStatement([|Attributes($result)|])

macro Items.WeaponItem.Animations(body as ExpressionStatement*):
	macro Anim(id as IntegerLiteralExpression, body as ExpressionStatement*):
		return ExpressionStatement(PropertyList('TWeaponAnimData', id, body))
	
	result = MakeArrayValue('AnimData', body.Select({e | e.Expression}))
	result.Accept(EnumFiller({'AnimType': [|TWeaponAnimType|], 'MovementMode': [|TMovementMode|] }))
	return result

macro Items.SkillItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TSkillItemTemplate', index, body, 'TItemTemplate')

macro Items.SwitchItem(index as IntegerLiteralExpression, body as Statement*):
	macro Value(typ as ReferenceExpression, id as IntegerLiteralExpression):
		yield ExpressionStatement([|Which($id)|])
		yield ExpressionStatement([|Style(TVarSets.$typ)|])
	
	return Lambdify('TVariableItemTemplate', index, Flatten(body), 'TItemTemplate')

macro Items.BookItem(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return Lambdify('TSkillBookTemplate', index, body, 'TItemTemplate')
