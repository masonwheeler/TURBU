namespace TURBU.RM2K.Import

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TClassConverter:
	def Convert(base as RMCharClass, db as LDB, is2k3 as bool) as MacroStatement:
		result = [|
			CharClass $(base.ID):
				Name $(base.Name)
				BattleSprite $(base.SpriteIndex)
				ExpFunc $(ReferenceExpression(('CalcExp2k3' if is2k3 else 'CalcExp2k')))($(base.ExpStandard), $(base.ExpAddition), $(base.ExpCorrection), 0)
				DualWield $(ReferenceExpression(('Dual' if base.DualWield else 'Shield')))
				StaticEq $(base.StaticEq)
				StrongDef $(base.StrongDefense)
				Guest $(base.ComputerControlled)
		|]
		commands = (base.BattleCommands cast (int)).TakeWhile({c | c != 0}).Select({i | Expression.Lift(i)}).ToArray()
		if commands.Length > 0:
			cmd = MacroStatement('Commands')
			cmd.Arguments.AddRange(commands)
			result.Body.Add(cmd)
		statBlock = MacroStatement('StatBlock')
		for i in range(6): //stat count
			statBlock.Body.Add(ConvertStatBlock(base.StatSection, i, is2k3))
		skillSet = MacroStatement('SkillSet')
		skillSet.Body.Statements.AddRange(base.SkillSection.Select({s | ConvertSkillRecord(s)}))
		attributes = MacroStatement('Attributes')
		for i in range(base.DTypeModifiers.Length):
			resistVal = -((base.DTypeModifiers cast (byte))[i] - 100)
			attributes.Body.Add([|Attribute $i, $resistVal|]) unless resistVal == db.Attributes[i].RateC
		conditions = MacroStatement('CondResists')
		for i in range(base.ConditionModifiers.Length):
			resistVal = -((base.ConditionModifiers cast (byte))[i] - 100)
			conditions.Body.Add([|Condition $i, $resistVal|]) unless resistVal == 0
		result.Body.Statements.AddRange((statBlock, skillSet, attributes, conditions))
		return result
	
	def Convert(base as RMHero, db as LDB, counter as int, is2k3 as bool, skillIndex as Func[of string, int]) as MacroStatement:
		result = [|
			CharClass $(base.ID):
				Name $(("$(base.Name) Class" if base.Class == 'None' or string.IsNullOrEmpty(base.Class) else base.Class))
				Sprite $(base.Sprite), $(base.SpriteIndex)
				BattleSprite $(base.BattleChar)
				Translucent $(base.Transparent)
				Portrait $(base.Portrait), $(base.PortraitIndex)
				ExpFunc $(ReferenceExpression(('CalcExp2k3' if is2k3 else 'CalcExp2k')))($(base.ExpStandard), $(base.ExpAddition), $(base.ExpCorrection), 0)
				DualWield $(ReferenceExpression(('Dual' if base.DualWield else 'Shield')))
				StaticEq $(base.StaticEq)
				StrongDef $(base.StrongDefense)
				Guest $(base.ComputerControlled)
				BattlePosition $(base.BattleX), $(base.BattleY)
		|]
		if (not is2k3) or base.ClassNum == 0:
			cmd = [|Commands 1, $(skillIndex(base.SkillCategoryName) if base.SkillRenamed else 2), 3, 4|]
		else:
			commands = (db.Classes[base.ClassNum - 1].BattleCommands cast (int)).TakeWhile({c | c != 0}).Select({i | Expression.Lift(i)}).ToArray()
			if commands.Length > 0:
				cmd = MacroStatement('Commands')
				cmd.Arguments.AddRange(commands)
		result.Body.Add(cmd) if cmd is not null
		statBlock = MacroStatement('StatBlock')
		for i in range(6): //stat count
			statBlock.Body.Add(ConvertStatBlock(base.StatSection, i, is2k3))
		skillSet = MacroStatement('SkillSet')
		skillSet.Body.Statements.AddRange(base.SkillSection.Select({s | ConvertSkillRecord(s)}))
		attributes = MacroStatement('Attributes')
		for i in range(base.DTypeModifiers.Length):
			resistVal = -((base.DTypeModifiers cast (byte))[i] - 100)
			attributes.Body.Add([|Attribute $i, $resistVal|]) unless resistVal == db.Attributes[i].RateC
		conditions = MacroStatement('CondResists')
		for i in range(base.ConditionModifiers.Length):
			resistVal = -((base.ConditionModifiers cast (byte))[i] - 100)
			conditions.Body.Add([|Condition $i, $resistVal|]) unless resistVal == 0
		eq = MacroStatement('Equipment')
		eq.Arguments.AddRange((base.InitialEq cast (int)).Select({e | Expression.Lift(e)}))
		result.Body.Statements.AddRange((statBlock, skillSet, attributes, conditions, eq))
		return result

static class THeroConverter:
	def Convert(base as RMHero, db as LDB, counter as int, is2k3 as bool, skillIndex as Func[of string, int], \
			table as Dictionary[of int, int]) as MacroStatement:
		result = TClassConverter.Convert(base, db, counter, is2k3, skillIndex)
		result.Name = 'Hero'
		result.Body.Statements.Cast[of MacroStatement]().Single({m | m.Name == 'Name'}).Arguments[0] = \
			Expression.Lift(base.Name)
		result.Body.Add([|Title $(base.Class)|])
		result.Body.Add([|MinLevel $(base.StartLevel)|])
		if (not is2k3) and (base.MaxLevel == 99):
			result.Body.Add([|MaxLevel 50|])
		else: result.Body.Add([|MaxLevel $(base.MaxLevel)|])
		result.Body.Add([|CharClass $(table[base.ID])|]) if base.ClassNum == 0 and table.ContainsKey(base.ID)
		result.Body.Add([|CanCrit $(base.CanCrit)|])
		result.Body.Add([|CritRate $(base.CritRate)|])
		return result

def ConvertSkillRecord(r as HeroSkillRecord) as MacroStatement:
	return [|SkillRecord Bool, $(r.Skill), ($(r.Level), 0, 0, 0)|]

def ConvertStatBlock(stats as (int), index as int, is2k3 as bool) as MacroStatement:
	blocksize = (99 if is2k3 else 50)
	start = blocksize * index
	block = stats[start:start + blocksize]
	assert block.Length == blocksize
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(block.Select({i | Expression.Lift(i)}))
	return [|Stats $(index + 1), $arr|]