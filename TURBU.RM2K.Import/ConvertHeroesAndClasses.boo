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
			rank = (base.DTypeModifiers cast (byte))[i] //the rank, 0 (A) to 4 (E)
			attributes.Body.Add([|Attribute $(i + 1), $rank|]) unless rank == 2 //rank C by default
		conditions = MacroStatement('CondResists')
		for i in range(base.ConditionModifiers.Length):
			rank = (base.ConditionModifiers cast (byte))[i]
			conditions.Body.Add([|Condition $(i + 1), $rank|]) unless rank == 2
		result.Body.Statements.AddRange((statBlock, skillSet, attributes, conditions))
		return result
	
	def Convert(base as RMHero, db as LDB, counter as int, is2k3 as bool, skillIndex as Func[of string, int], \
			report as IConversionReport) as MacroStatement:
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
			rank = (base.DTypeModifiers cast (byte))[i] //the rank, 0 (A) to 4 (E)
			attributes.Body.Add([|Attribute $(i + 1), $rank|]) unless rank == 2 //rank C by default
		conditions = MacroStatement('CondResists')
		for i in range(base.ConditionModifiers.Length):
			rank = (base.ConditionModifiers cast (byte))[i]
			conditions.Body.Add([|Condition $(i + 1), $rank|]) unless rank == 2
		eq = MacroStatement('Equipment')
		eq.Arguments.AddRange(ValidateStartingEquipment(base, db, report).Select({e | Expression.Lift(e)}))
		result.Body.Statements.AddRange((statBlock, skillSet, attributes, conditions, eq))
		return result

	//a hero's starting equipment can name items that no longer exist or no longer fit the slot (the author
	//changed the item and never cleaned up the hero); those entries become 0
	private def ValidateStartingEquipment(base as RMHero, db as LDB, report as IConversionReport) as (int):
		result = (base.InitialEq cast (int)).ToArray()
		return result if db is null
		for slot in range(result.Length):
			id = result[slot]
			continue if id == 0
			item = db.Items.FirstOrDefault({i | i.ID == id})
			//item types: 1 weapon, 2 shield, 3 armor, 4 helmet, 5 accessory
			valid = (item is not null) and (item.ItemType == slot + 1 or (slot == 1 and base.DualWield and item.ItemType == 1))
			continue if valid
			report.MakeNotice("Hero $(base.ID) ($(base.Name)) starts with item $id in equipment slot $(slot + 1), which is not valid for that slot; nothing will be equipped there", 4) if report is not null
			result[slot] = 0
		return result

static class THeroConverter:
	def Convert(base as RMHero, db as LDB, counter as int, is2k3 as bool, skillIndex as Func[of string, int], \
			table as Dictionary[of int, int], report as IConversionReport) as MacroStatement:
		result = TClassConverter.Convert(base, db, counter, is2k3, skillIndex, report)
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
	return [|SkillRecord Level, $(r.Skill), ($(r.Level), 0, 0, 0)|]

def ConvertStatBlock(stats as (int), index as int, is2k3 as bool) as MacroStatement:
	blocksize = (99 if is2k3 else 50)
	start = blocksize * index
	block = stats[start:start + blocksize]
	assert block.Length == blocksize
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(block.Select({i | Expression.Lift(i)}))
	return [|Stats $(index + 1), $arr|]