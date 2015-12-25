namespace TURBU.RM2K.Import

import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable
import Boo.Adt
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import TURBU.Design.Optimizations

class TDatabaseConverter:
	private _2k3 as bool
	private _ldb as LCF.LDB
	private _report as IConversionReport
	private _scripts as string
	private _database as string
	private _resources as Block
	private _terminated as Func[of bool]
	private _classTable = Dictionary[of int, int]()
	private _heroClassTable = Dictionary[of int, int]()
	private _scanner as Action[of LCF.EventCommand*]

	private def constructor(db as LCF.LDB, dbPath as string, scriptPath as string, resources as Block, \
			report as IConversionReport, is2K3 as bool, isTerminated as Func[of bool], \
			scanner as Action[of LCF.EventCommand*]):
		_ldb = db
		_database = dbPath
		_scripts = scriptPath
		_resources = resources
		_report = report
		_2k3 = is2K3
		_terminated = isTerminated
		_scanner = scanner

	DBConverter:
		task "Resource Check":
			GatherResources(_ldb)
			GatherResourceNames(_ldb)
			if _2k3:
				_resources.Add([|BattleEngine 'Active-time battle engine'|])
			else: _resources.Add([|BattleEngine 'First-person battle engine'|])
			_resources.Add([|MapEngine 'TURBU basic map engine'|])
		
		task "Converting Battle Commands":
			command = MacroStatement('Commands')
			if _2k3:
				i = 0
				for cmd in self._ldb.BattleLayout.Commands:
					++i
					style = ('Weapon', 'Skill', 'Skill', 'Defend', 'Item', 'Flee', 'Special')[cmd.Style]
					newCmd = [|
						Command $i:
							Name $(cmd.Name)
							Style $(ReferenceExpression(style))
							Value $(-1 if cmd.Style == 1 else cmd.ID)
					|]
					command.Body.Add(newCmd)
			else:
				for i in range(4):
					command.Body.Add(Setup2kCommand(_ldb, i + 1))
				for hero in self._ldb.Heroes.Where({h | h.SkillRenamed}):
					++i
					newCmd = [|
						Command $(i + i):
							Name $(hero.SkillCategoryName)
							Style SkillGroup
							Value $(command.Body.Statements.Count)
					|]
					command.Body.Add(newCmd)
			File.WriteAllText(Path.Combine(self._database, 'Commands.tdb'), command.ToCodeString())
			classes = MacroStatement('Classes')
			ConvertClasses(classes) if _2k3
			commandIndex =  do(skillName as string):
				result as int = -1
				base = Expression.Lift(skillName)
				def filter(s as Statement, i as int) as bool:
					m = s cast MacroStatement
					if m.Arguments[0].Matches(base) and m.Arguments[1].Matches([|SkillGroup|]):
						result = i
						return true
					else: return false
				command.Body.Statements.Where(filter)
				return result
			ConvertHeroClasses(classes, commandIndex)
			File.WriteAllText(Path.Combine(self._database, 'Classes.tdb'), classes.ToCodeString())
			heroes = MacroStatement('Heroes')
			ConvertHeroes(heroes, commandIndex)
			File.WriteAllText(Path.Combine(self._database, 'Heroes.tdb'), heroes.ToCodeString())
	
		task "Converting Items":
			items = MacroStatement('Items')
			for item in _ldb.Items:
				items.Body.Add(TItemConverter.Convert(item, _ldb))
			File.WriteAllText(Path.Combine(self._database, 'Items.tdb'), items.ToCodeString())
	
		task "Converting Skills":
			skills = MacroStatement('Skills')
			for skill in _ldb.Skills:
				skills.Body.Add(TSkillConverter.Convert(skill))
			File.WriteAllText(Path.Combine(self._database, 'Skills.tdb'), skills.ToCodeString())
		
		task "Converting Attributes and Conditions":
			attributes = MacroStatement('Attributes')
			for attr in _ldb.Attributes:
				attributes.Body.Add(TAttributeConverter.Convert(attr))
			File.WriteAllText(Path.Combine(self._database, 'Attributes.tdb'), attributes.ToCodeString())
			
			conditions = MacroStatement('Conditions')
			for cond in _ldb.Conditions:
				conditions.Body.Add(TConditionConverter.Convert(cond, _2k3))
			File.WriteAllText(Path.Combine(self._database, 'Conditions.tdb'), conditions.ToCodeString())
		
		task "Converting Tilesets":
			tilesets = MacroStatement('Tilesets')
			tilesetFiles = HashSet[of string]()
			for tileset in _ldb.Tilesets:
				tilesets.Body.Add(TTilesetConverter.Convert(tileset, tilesetFiles))
			File.WriteAllText(Path.Combine(self._database, 'Tilesets.tdb'), tilesets.ToCodeString())
			_resources.Statements.AddRange(tilesetFiles.Select({s | [|Tileset $s|]}))
		
		task "Converting Monsters":
			monsters = MacroStatement('Monsters')
			for monster in _ldb.Monsters:
				monsters.Body.Add(TMonsterConverter.Convert(monster))
			File.WriteAllText(Path.Combine(self._database, 'Monsters.tdb'), monsters.ToCodeString())
		
		task "Converting Monster Parties":
			battleGlobals = ScanMPartiesForDuplicates(_ldb.MParties)
			battleScripts = MacroStatement('BattleScripts')
			saveScript = do (value as Statement):
				battleScripts.Body.Add(value)
			parties = MacroStatement('MonsterParties')
			for party in _ldb.MParties:
				parties.Body.Add(TMonsterPartyConverter.Convert(party, saveScript, _scanner, _report))
			for id as int, global as LCF.EventCommand* in enumerate(battleGlobals):
				scriptName = "battleGlobal$((id + 1).ToString('D4'))"
				gScript = [|
					BattleScript $(ReferenceExpression(scriptName)):
						$(PageScriptBlock(global, {m | _report.MakeNotice("$m while converting repeated battle script $scriptName", 3)}))
				|]
				battleScripts.Body.Add(gScript)
			File.WriteAllText(Path.Combine(self._database, 'MonsterParties.tdb'), parties.ToCodeString())
			File.WriteAllText(Path.Combine(self._scripts, 'battleScripts.boo'), battleScripts.ToScriptString())
		
		task "Converting Battle Animations":
			anims = MacroStatement('Animations')
			for anim in _ldb.Animations:
				anims.Body.Add(TAnimConverter.Convert(anim))
			File.WriteAllText(Path.Combine(self._database, 'Animations.tdb'), anims.ToCodeString())
		
		task "Converting Battle Char data":
			bChars = MacroStatement('BattleChars')
			for bChar in _ldb.BattleAnims:
				bChars.Body.Add(TBattleAnimConverter.Convert(bChar))
			File.WriteAllText(Path.Combine(self._database, 'BattleChars.tdb'), bChars.ToCodeString())

		task "Converting Terrain":
			terrains = MacroStatement('Terrains')
			for terrain in _ldb.Terrains:
				terrains.Body.Add(TTerrainConverter.Convert(terrain, _2k3))
			File.WriteAllText(Path.Combine(self._database, 'Terrains.tdb'), terrains.ToCodeString())
		
		task "Converting System Data":
			sysData = TSysDataConverter.Convert(_ldb.SysData, _ldb.BattleLayout, _2k3)
			File.WriteAllText(Path.Combine(self._database, 'SystemData.tdb'), sysData.ToCodeString())
			vehicles = TVehicleConverter.Convert(_ldb.SysData)
			File.WriteAllText(Path.Combine(self._database, 'Vehicles.tdb'), vehicles.ToCodeString())
			sysSounds = TSysSoundConverter.Convert(_ldb.SysData)
			File.WriteAllText(Path.Combine(self._database, 'SysSounds.tdb'), sysSounds.ToCodeString())
			sysMusic = TSysMusicConverter.Convert(_ldb.SysData)
			File.WriteAllText(Path.Combine(self._database, 'SysMusic.tdb'), sysMusic.ToCodeString())
			variables = TVariableConverter.Convert(_ldb.Switches, _ldb.Variables)
			File.WriteAllText(Path.Combine(self._database, 'Variables.tdb'), variables.ToCodeString())
			vocab = TVocabConverter.Convert(_ldb.Vocab, _2k3)
			File.WriteAllText(Path.Combine(self._database, 'Vocab.tdb'), vocab.ToCodeString())
			
		task "Converting Global Scripts":
			globals = MacroStatement('GlobalEvents')
			globalScripts = MacroStatement('GlobalScripts')
			def SaveScript(value as Node):
				globalScripts.Body.Add(value cast MacroStatement)
			for global in _ldb.GlobalEvents.Where({g | not (g.Name == '' and g.Script.Count == 1)}):
				globals.Body.Add(ConvertGlobalEvent(global, _scanner, SaveScript, {msg, id, page | _report.MakeNotice("$msg at global script #$id.", 3)}))
			File.WriteAllText(Path.Combine(self._database, 'GlobalEvents.tdb'), globals.ToCodeString())
			File.WriteAllText(Path.Combine(self._scripts, 'GlobalScripts.boo'), globalScripts.ToScriptString())
	
	def ScanMPartiesForDuplicates(MParties as LCF.RMMonsterParty*):
		dict = Dictionary[of string, LCF.BattleEventPage]()
		dupes = HashSet[of LCF.BattleEventPage]()
		counter = 0
		globals = List[of List[of LCF.EventCommand]]()
		bePage as LCF.BattleEventPage
		pages as LCF.BattleEventPage* = MParties.SelectMany({p | p.Events}).Where({e | e.Commands.Count > 1})
		for page in pages:
			script = join(page.Commands, ' ')
			if dict.TryGetValue(script, bePage):
				unless dupes.Contains(bePage):
					dupes.Add(bePage)
					newList = List[of LCF.EventCommand](bePage.Commands)
					globals.Add(newList)
					bePage.Commands.Clear()
					bePage.Commands.Add(LCF.EventCommand(12330, 3, globals.Count))
					bePage.Commands.Add(LCF.EventCommand(0))
				page.Commands.Clear()
				page.Commands.AddRange(bePage.Commands)
				++counter
			else: dict.Add(script, page)
		if counter > 0:
			_report.MakeHint("Found $counter exact duplicates of $(globals.Count) battle script pages; moved to global battle scripts section.", 1)
		return globals
	
	private def ConvertClasses(value as MacroStatement):
		for cls in _ldb.Classes.Where({c | not IsEmpty(c)}):
			counter = value.Body.Statements.Count
			value.Body.Add(TClassConverter.Convert(cls, _ldb, _2k3))
			_classTable.Add(cls.ID, cls.ID - counter)
	
	private def ConvertHeroClasses(value as MacroStatement, skillIndex as Func[of string, int]):
		for hero in _ldb.Heroes.Where({h | (h.ClassNum > 0) and (not IsEmpty(h))}):
			counter = value.Body.Statements.Count
			value.Body.Add(TClassConverter.Convert(hero, _ldb, counter, _2k3, skillIndex))
			_heroClassTable.Add(hero.ID, counter)
	
	private def ConvertHeroes(value as MacroStatement, skillIndex as Func[of string, int]):
		table as Dictionary[of int, int]
		for hero in _ldb.Heroes:
			counter = value.Body.Statements.Count
			table = (_heroClassTable if hero.ClassNum == 0 else _classTable)
			value.Body.Add(THeroConverter.Convert(hero, _ldb, counter, _2k3, skillIndex, table))
	
	private def GatherResources(db as LCF.LDB):
		res = Block()
		for ter in db.Terrains:
			res.Add([|BattleBG $(ter.BattleBG)|]) unless string.IsNullOrEmpty(ter.BattleBG)
			res.Add([|Sound $(ter.SoundEffect.Filename)|]) unless ter.SoundEffect is null
			res.Add([|Frame $(ter.Frame1)|]) unless string.IsNullOrEmpty(ter.Frame1)
			res.Add([|Frame $(ter.Frame2)|]) unless string.IsNullOrEmpty(ter.Frame2)
		for monster in db.Monsters:
			res.Add([|Monster $(monster.Filename)|])
		sys = db.SysData
		res.Add([|BattleBG $(sys.BattleSysGraphic)|])
		res.Add([|SysTile $(sys.SystemGraphic)|])
		res.Add([|Frame $(sys.Frame)|]) unless string.IsNullOrEmpty(sys.Frame)
		for song in (sys.TitleMusic, sys.BattleMusic, sys.VictoryMusic, sys.InnMusic, sys.BoatMusic, \
				sys.ShipMusic, sys.AirshipMusic, sys.GameOverMusic):
			res.Add([|Music $(song.Filename)|]) unless song is null
			System.Diagnostics.Debugger.Break() if song.Filename == 'se-torrent'
		for sfx in (sys.CursorSound, sys.AcceptSound, sys.CancelSound, sys.BuzzerSound, sys.BattleStartSound, \
				sys.EscapeSound, sys.EnemyAttackSound, sys.EnemyDamageSound, sys.AllyDamageSound, sys.EvadeSound,
				sys.EnemyDiesSound, sys.ItemUsedSound):
			res.Add([|Sound $(sfx.Filename)|]) unless sfx is null
		_resources.Add(res)
	
	private def GatherResourceNames(db as LCF.LDB):
		res = Block()
		for hero in db.Heroes:
			res.Add([|Sprite $(hero.Sprite)|]) unless string.IsNullOrEmpty(hero.Sprite)
			res.Add([|Portrait $(hero.Portrait)|]) unless string.IsNullOrEmpty(hero.Portrait)
		for anim in db.Animations.Where({a | not string.IsNullOrEmpty(a.Filename)}):
			if anim.LargeAnim:
				res.Add([|LargeAnim $(anim.Filename)|])
			else: res.Add([|Anim $(anim.Filename)|])
		for sfx in db.Animations.SelectMany({a | a.Timing}).Select({e | e.Sound}).Where({s | s is not null}):
			res.Add([|Sound $(sfx.Filename)|])
		for sprite in (db.SysData.BoatGraphic, db.SysData.ShipGraphic, db.SysData.AirshipGraphic):
			res.Add([|Sprite $sprite|]) unless string.IsNullOrEmpty(sprite)
		for bAnim in db.BattleAnims:
			for pose in bAnim.Poses: res.Add([|BattleSprite $(pose.Filename)|])
			for weapon in bAnim.Weapons: res.Add([|BattleWeapon $(weapon.Filename)|])
		_resources.Add(res)

def Setup2kCommand(db as LCF.LDB, value as int) as MacroStatement:
	style = ReferenceExpression(('Weapon', 'Skill', 'Defend', 'Item')[value - 1])
	return [|
		Command $value:
			Name $(db.Vocab[0x67 + value])
			Style $style
			Value $(-1 if value == 4 else value)
	|]

def IsEmpty(value as LCF.RMHero) as bool:
	result = string.IsNullOrEmpty(value.Sprite) and string.IsNullOrEmpty(value.Portrait) \
		and string.IsNullOrEmpty(value.Name) and (string.IsNullOrEmpty(value.Class) or (value.Class == 'None')) \
		and (value.SkillSection is null or value.SkillSection.Count == 0) \
		and (value.ConditionModifiers is null or value.ConditionModifiers.Length == 0) \
		and (value.DTypeModifiers is null or value.DTypeModifiers.Length == 0)
	return result

def IsEmpty(value as LCF.RMCharClass) as bool:
	result = string.IsNullOrEmpty(value.Name) and value.SpriteIndex == 0 \
		and (value.SkillSection is null or value.SkillSection.Count == 0) \
		and (value.ConditionModifiers is null or value.ConditionModifiers.Length == 0) \
		and (value.DTypeModifiers is null or value.DTypeModifiers.Length == 0)
	return result

macro DBConverter:
	macro task(name as string, init as Expression*):
		tasks = DBConverter['tasks'] as List[of Method]
		if tasks is null:
			tasks = List[of Method]()
			DBConverter['tasks'] = tasks
		taskName = "Task$((tasks.Count + 1).ToString('D2'))"
		result = Method(taskName)
		inits = init.ToArray()
		if inits.Length == 0:
			sct = [|_report.NewStep($name)|]
		else:
			lenExpr = inits[-1]
			sct = [|_report.SetCurrentTask($name, $lenExpr)|]
			for expr in inits[:-1]:
				result.Body.Add(expr)
		result.Body.Add(sct)
		result.Body.Add(task.Body)
		tasks.Add(result)
	
	tasks = DBConverter['tasks'] as List[of Method]
	yield [|
		public static def Convert(db as LCF.LDB, dbPath as string, scriptPath as string, \
				resources as Block, report as IConversionReport, is2K3 as bool,\
				isTerminated as Func[of bool], scanner as Action[of LCF.EventCommand*]):
			TDatabaseConverter(db, dbPath, scriptPath, resources, report, is2K3, isTerminated, scanner).Convert()
	|]
	result = [|
		internal def Convert():
			pass
	|]
	tryBlock = [|
		try:
			pass
		except e as Exception:
			_report.Fatal(e)
	|]
	for task in tasks:
		yield task
		tryBlock.ProtectedBlock.Add([|$task()|])
		tryBlock.ProtectedBlock.Add([|return if self._terminated()|])
	result.Body.Add(tryBlock)
	yield result
	yield [|let STEPS = $(tasks.Count)|]

[Extension]
def SubMacro(base as MacroStatement, name as string) as MacroStatement:
	return base.Body.Statements.OfType[of MacroStatement]().FirstOrDefault({ms | ms.Name == name})