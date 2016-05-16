namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro MonsterParties(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgMonsterParty]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	#result.Accept(EnumFiller( {'DualWield': [|TWeaponStyle|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.monsters|]

macro MonsterParties.MonsterParty(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Habitats:
		return MakeArrayValue('Habitats', MonsterParty.Arguments)
	
	return Lambdify('TRpgMonsterParty', index, body)

macro MonsterParties.MonsterParty.Monsters(body as ExpressionStatement*):
	macro MonsterElement(id as IntegerLiteralExpression, body as ExpressionStatement*):
		var monster = SubMacroValue(body, 'Monster')
		var pos = SubMacroNamed(body, 'Position', 'TSgPoint')
		var inv = SubMacroValue(body, 'Invisible')
		return ExpressionStatement([|TRpgMonsterElement($id, $monster, $pos, $inv)|])
	
	return MakeGenericListValue('Monsters', 'TRpgMonsterElement', body)

macro MonsterParties.MonsterParty.Pages(body as ExpressionStatement*):
	macro Page(id as IntegerLiteralExpression, body as ExpressionStatement*):
		return ExpressionStatement(PropertyListWithID('TBattleEventPage', id, body))
	
	return MakeListValue('Pages', 'TBattleEventPage', body)

macro MonsterParties.MonsterParty.Pages.Page.PageConditions(body as ExpressionStatement*):
	macro Switch(id as int):
		return ExpressionStatement([|Switch[$id]|])
	
	macro Variable(comp as BinaryExpression):
		be = BinaryExpression(comp.Operator, [|Ints[$(comp.Left)]|], comp.Right)
		return ExpressionStatement(be)
	
	macro Item(id as int):
		return ExpressionStatement([|HasItem($id)|])
	
	macro Hero(id as int):
		return ExpressionStatement([|HeroPresent($id)|])
	
	macro Timer1(value as int):
		return ExpressionStatement([|Timer.Time <= ($value)|])
	
	macro Timer2(value as int):
		return ExpressionStatement([|Timer2.Time <= ($value)|])
	
	macro Turns(mult as int, constant as int):
		return ExpressionStatement([|BattleState.TurnsMatch($mult, $constant)|])
	
	macro HeroHP(id as int, min as int, max as int):
		return ExpressionStatement([|BattleState.HeroHPBetween($id, $min, $max)|])
	
	macro MonsterHP(id as int, min as int, max as int):
		return ExpressionStatement([|BattleState.MonsterHPBetween($id, $min, $max)|])
	
	result as Expression
	for line in body:
		result = (line.Expression if result is null else [|$result and $(line.Expression)|])
	return ExpressionStatement([| Conditions({return $result}) |])
