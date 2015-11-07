namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Heroes(body as ExpressionStatement*):
	result = [|
		def Data() as THeroTemplate:
			pass
	|]
	value = body.Select({e | e.Expression}).Single()
	result.Body.Statements.Add([|return $value|])
	result.Accept(EnumFiller( {'DualWield': [|TWeaponStyle|]} ))
	yield result
	yield ExpressionStatement([|Data()|])

macro Heroes.Hero(index as IntegerLiteralExpression, body as ExpressionStatement*):
	return ExpressionStatement(PropertyList('THeroTemplate', index, body))

macro Heroes.Hero.ExpFunc(value as MethodInvocationExpression):
	Hero.Body.Add(ExpressionStatement([|ExpMethod($(value.Target.ToString()))|]))
	vars = ArrayLiteralExpression()
	vars.Items.AddRange(value.Arguments)
	Hero.Body.Add(ExpressionStatement([|ExpVars($vars)|]))

macro Heroes.Hero.Sprite(name as StringLiteralExpression, index as IntegerLiteralExpression):
	Hero.Body.Add(ExpressionStatement([|MapSprite($name)|]))
	Hero.Body.Add(ExpressionStatement([|SpriteIndex($index)|]))

macro Heroes.Hero.Portrait(name as StringLiteralExpression, index as IntegerLiteralExpression):
	Hero.Body.Add(ExpressionStatement([|Portrait($name)|]))
	Hero.Body.Add(ExpressionStatement([|PortraitIndex($index)|]))

macro Heroes.Hero.BattlePosition(x as IntegerLiteralExpression, y as IntegerLiteralExpression):
	yield ExpressionStatement([|BattlePos(sgPoint($x, $y))|])

macro Heroes.Hero.Commands(values as IntegerLiteralExpression*):
	vars = ArrayLiteralExpression()
	vars.Items.AddRange(values)
	Hero.Body.Add(ExpressionStatement([|Commands($vars)|]))

macro Heroes.Hero.Equipment(values as IntegerLiteralExpression*):
	vars = ArrayLiteralExpression()
	vars.Items.AddRange(values)
	Hero.Body.Add(ExpressionStatement([|Equipment($vars)|]))

macro Heroes.Hero.SkillSet(body as ExpressionStatement*):
	macro SkillRecord(skillType as ReferenceExpression, id as IntegerLiteralExpression, args as ArrayLiteralExpression):
		return ExpressionStatement([|TSkillGainInfo(Skill: $id, Style: TSkillFuncStyle.$skillType, Nums: $args)|])
	
	return MakeArrayValue('Skillset', body.Select({e | e.Expression}))

macro Heroes.Hero.Attributes(body as ExpressionStatement*):
	macro Attribute(id as IntegerLiteralExpression, percentage as IntegerLiteralExpression):
		return ExpressionStatement([|sgPoint($id, $percentage)|])
	
	return MakeArrayValue('Resist', body.Select({e | e.Expression}))

macro Heroes.Hero.Conditions(body as ExpressionStatement*):
	macro Attribute(id as IntegerLiteralExpression, percentage as IntegerLiteralExpression):
		return ExpressionStatement([|sgPoint($id, $percentage)|])
	
	return MakeArrayValue('Condition', body.Select({e | e.Expression}))

macro Heroes.Hero.StatBlock(body as ExpressionStatement*):
	macro Stats(id as IntegerLiteralExpression, block as ArrayLiteralExpression):
		return ExpressionStatement([|TStatBlock(Index: $id, Block: $block)|])
	
	return MakeArrayValue('StatBlocks', body.Select({e | e.Expression}))
