namespace TURBU.RM2K.BattleEngine

import System
import Boo.Adt
import commons
import System.Collections.Generic
import System.Linq.Enumerable
import System.Threading
import System.Threading.Tasks
import Pythia.Runtime
import SG.defs
import sdl.sprite
import turbu.defs
import turbu.constants
import turbu.characters
import turbu.items
import turbu.monsters
import turbu.skills
import turbu.resists
import turbu.battles
import turbu.Heroes
import turbu.RM2K.environment
import turbu.RM2K.animations
import turbu.script.engine
import TURBU.BattleEngine
import TURBU.Meta
import TURBU.RM2K
import TURBU.RM2K.Menus
import TURBU.RM2K.MapEngine
import TURBU.RM2K.RPGScript
import TURBU.Timing
import timing

let MESSAGE_MIN = 20
let MESSAGE_MAX = 60
let ANNOUNCE_MIN = 30
let ANNOUNCE_MAX = 70
let ACTION_TICKS = 18
let DEFAULT_ESCAPE_BONUS = 10

// The place where a hero's animation is shown
class THeroTarget(IAnimTarget):

	private _row as int

	private _page as TBattlePage

	public def constructor(row as int, page as TBattlePage):
		_row = row
		_page = page

	public def Position(sign as int) as SgPoint:
		return SgPoint(COMMAND_WIDTH + 122, 168 + (_row * 16) + (sign * 8))

	public def Flash(r as int, g as int, b as int, power as int, time as int):
		_page.FlashScreen(r, g, b, power, time * 6)

class TBattleScene(IBattleContext):

	private _party as TRpgParty

	private _monsterParty as TRpgMonsterParty

	private _conditions as TBattleConditions

	private _field as TBattleField

	private _page as TBattlePage

	private _pool = TMessagePool()

	private _outcome = TBattleOutcome.Stopped

	private _pages as (TBattleEventPage)

	private _pageActive as (bool)

	private _escapeBonus as int

	private _stopped as bool

	private _activeMonsters = List[of int]()

	private _skillList as (int)

	public def constructor(party as TRpgParty, monsters as TRpgMonsterParty, conditions as TBattleConditions):
		_party = party
		_monsterParty = monsters
		_conditions = conditions
		_field = TBattleField(party)

	//---- waiting

	private def SkipHeld() as bool:
		return (GGameEngine.value.ReadKeyboardState() & TButtonCode.Enter) != TButtonCode.None

	//Waits for the longer duration, or the shorter if the user holds the confirm key
	[async]
	def Pause(minTicks as int, maxTicks as int) as Task:
		var limit = Timestamp.FromTicks(maxTicks)
		var earliest = Timestamp.FromTicks(minTicks)
		waitFor { limit.TimeRemaining == 0 or (earliest.TimeRemaining == 0 and SkipHeld()) }

	//---- Text

	private def Line(text as string):
		return if string.IsNullOrEmpty(text)
		var lines = List[of string]()
		TBattleText.SplitLines(TBattleText.Wrap(text, MESSAGE_COLUMNS), lines)
		_page.Messages.Visible = true
		for line in lines:
			_page.Messages.Add(line)

	private def StatName(which as int) as string:
		caseOf which:
			case 2: return TBattleText.Vocab(V_STAT_ATTACK)
			case 3: return TBattleText.Vocab(V_STAT_DEFENSE)
			case 4: return TBattleText.Vocab(V_STAT_MIND)
			default: return TBattleText.Vocab(V_STAT_SPEED)

	private def EndNarration():
		_page.Messages.ClearLines()
		_page.Messages.Visible = false

	//---- the fighters

	private def Units() as TBattleUnit*:
		return _field.Heroes.Cast[of TBattleUnit]().Concat(_field.Monsters.Cast[of TBattleUnit]())

	private def HeroUnits() as TBattleUnit*:
		return _field.Heroes.Cast[of TBattleUnit]()

	private def MonsterUnits() as TBattleUnit*:
		return _field.Monsters.Cast[of TBattleUnit]()

	private def TargetOf(unit as TBattleUnit) as IAnimTarget:
		var monster = unit as TMonsterUnit
		return monster.Body if monster is not null
		return THeroTarget(_field.Heroes.IndexOf(unit cast THeroUnit), _page)

	private def BuildUnits():
		for i in range(1, MAXPARTYSIZE + 1):
			var hero = _party[i]
			continue if hero is null or hero == GEnvironment.value.Heroes[0]
			_field.Heroes.Add(THeroUnit(_field, hero))
		var index = 0
		for element in _monsterParty.Monsters:
			var template = GDatabase.value.Monsters[element.Monster]
			var body = TBattleMonster(template, element.Position, element.Invisible)
			body.Slot = index + 1
			var unit = TMonsterUnit(_field, body, index)
			body.Unit = unit
			unit.Present = not element.Invisible
			_field.Monsters.Add(unit)
			_page.Monsters.Add(body)
			++index
		_page.Status.Heroes.AddRange(_field.Heroes)

	//---- battle

	[async]
	def Run() as Task of TBattleResult:
		BattleState.Current = self
		var deathPossible = _party.DeathPossible
		_party.DeathPossible = true
		try:
			_page = GMenuEngine.Value.EnsurePage('Battle', classOf(TBattlePage), '[]') cast TBattlePage
			_page.BeginBattle()
			_page.SetBackdrop(_conditions.Background)
			BuildUnits()
			var pages = List[of TBattleEventPage]()
			for page in _monsterParty.Pages:
				BindPage(page)
				pages.Add(page)
			_pages = pages.ToArray()
			_pageActive = array(bool, _pages.Length)
			GMenuEngine.Value.SetBattleDrawer(_page.DrawScene)
			GMenuEngine.Value.MenuInt = 0
			GMenuEngine.Value.OpenMenuEx('Battle', null)
			_page.Status.Visible = true
			_page.Release()
			await ShowScreenDefault(TTransitionTypes.BattleStartShow)
			_outcome = await(Fight())
			await Conclude()
			if _outcome != TBattleOutcome.Lost or (TBattleResult.Defeated in _conditions.Results):
				await EraseScreenDefault(TTransitionTypes.BattleEndErase)
		ensure:
			Teardown(deathPossible)
		return ResultOf(_outcome)

	//gives a page of battle events its script and the test of its conditions, which the data only describes
	private def BindPage(page as TBattleEventPage):
		page.Script = GDatabase.value.GetBattleScript(_monsterParty.ID, page.ID) if page.Script is null
		if page.Conditions is null and page.Requirements.Length > 0:
			var requirements = page.Requirements
			page.Conditions = { return PageConditionsMet(requirements) }

	private def PageConditionsMet(requirements as (TPageCondition)) as bool:
		for condition in requirements:
			var a = condition.Args
			caseOf condition.Kind:
				case 'Switch', 'Switch2': return false unless GEnvironment.value.Switch[a[0]]
				case 'Variable': return false unless GEnvironment.value.Ints[a[0]] >= a[1]
				case 'Turns': return false unless BattleState.TurnsMatch(a[0], a[1])
				case 'HeroHP': return false unless BattleState.HeroHPBetween(a[0], a[1], a[2])
				case 'MonsterHP': return false unless BattleState.MonsterHPBetween(a[0], a[1], a[2])
				case 'HeroTime': return false unless BattleState.HeroTurnsMatch(a[0], a[1], a[2])
				case 'MonsterTime': return false unless BattleState.MonsterTurnsMatch(a[0], a[1], a[2])
				case 'Exhaustion': return false unless BattleState.PartyExhaustionBetween(a[0], a[1])
				case 'CommandUsed': return false unless BattleState.HeroCommandUsed(a[0], a[1])
				default: raise "Unknown battle page condition '$(condition.Kind)'"
		return true

	private def ResultOf(outcome as TBattleOutcome) as TBattleResult:
		caseOf outcome:
			case TBattleOutcome.Won: return TBattleResult.Victory
			case TBattleOutcome.Lost: return TBattleResult.Defeated
			default: return TBattleResult.Escaped

	private def Teardown(deathPossible as bool):
		GMenuEngine.Value.SetBattleDrawer(null)
		for hero in _field.Heroes:
			hero.ResetAfterBattle()
		if _page is not null:
			_page.Release()
			_page.EndBattle()
			_page.Finish()
		_party.DeathPossible = deathPossible
		BattleState.Current = null

	[async]
	def Fight() as Task of TBattleOutcome?:
		await Announce()
		await RunPages()
		while true:
			outcome = await(Round())
			return outcome unless outcome == null

	[async]
	def Announce() as Task:
		var first = _field.Monsters.FirstOrDefault({m | m.Present})
		Line(TBattleText.SayPlain(V_BATTLE_APPEAR, (first.Name if first is not null else '')))
		if _conditions.Formation in (TBattleFormation.FirstStrike, TBattleFormation.Initiative):
			Line(TBattleText.SayPlain('Battle-Surprise Attack', ''))
		await Pause(ANNOUNCE_MIN, ANNOUNCE_MAX)
		EndNarration()

	private def CheckEnd() as TBattleOutcome?:
		return TBattleOutcome.Lost unless _field.Heroes.Any({h | h.IsAlive})
		return TBattleOutcome.Won if _field.AliveMonsterCount == 0
		return TBattleOutcome.Stopped if _stopped
		return null

	//---- battle events

	[async]
	def RunPages() as Task:
		for i in range(_pages.Length):
			var page = _pages[i]
			var active = true
			try:
				active = (page.Conditions is null or page.Conditions())
			except:
				active = false
			var fire = (active and not _pageActive[i])
			_pageActive[i] = active
			if fire and page.Script is not null:
				_page.Suspend()
				try:
					await page.Script()
				ensure:
					_page.Resume()
				return unless CheckEnd() == null

	//---- a round: the commands, then the actions

	private FirstRound as bool:
		get: return _field.Turns == 0

	[async]
	def Round() as Task of TBattleOutcome?:
		for unit in Units():
			unit.Defending = false
			unit.ResetAction()
			unit.LastCommand = -1
			++unit.TurnsTaken if unit.IsAlive
		await RunPages()
		var result = CheckEnd()
		return result unless result == null
		result = await(ChooseCommands())
		return result unless result == null
		result = await(Execute())
		++_field.Turns
		return null

	//---- the commands of the party

	private def ChooseMonsterActions():
		var firstStrike = (FirstRound and _conditions.Formation in (TBattleFormation.FirstStrike, TBattleFormation.Initiative))
		for monster in _field.Monsters:
			continue unless monster.IsAlive
			if firstStrike:
				monster.Action.Kind = TBattleActionKind.Nothing
			else: monster.ChooseAction()

	//what the heroes that the player does not control do
	private def ChooseAutomaticActions():
		var surprised = (FirstRound and _conditions.Formation == TBattleFormation.Surprised)
		for hero in _field.Heroes:
			continue unless hero.IsAlive
			if surprised:
				hero.Action.Kind = TBattleActionKind.Nothing
			elif not hero.CanChooseCommand:
				hero.ChooseAction()

	[async]
	def ChooseCommands() as Task of TBattleOutcome?:
		ChooseMonsterActions()
		ChooseAutomaticActions()
		if FirstRound and _conditions.Formation == TBattleFormation.Surprised:
			return null
		if not _field.AnyHeroCanChooseCommand:
			return null
		var position = 0
		while true:
			var names = List[of string]()
			names.Add(TBattleText.Vocab(V_BATTLE_FIGHT))
			names.Add(TBattleText.Vocab(V_BATTLE_AUTO))
			names.Add(TBattleText.Vocab(V_BATTLE_FLEE))
			_page.Commands.SetItems(names, null, null)
			_page.Commands.CanCancel = false
			choice = await(Pick(_page.Commands, position))
			position = Math.Max(choice, 0)
			if choice == 0:
				done = await(ChooseForParty())
				return null if done
			elif choice == 1:
				for hero in _field.Heroes:
					hero.ChooseAction() if hero.IsAlive and hero.CanChooseCommand
				return null
			elif choice == 2:
				escape = await(TryEscape())
				if escape == 2:
					for hero in _field.Heroes:
						hero.ResetAction()
				elif escape == 1: return TBattleOutcome.Escaped

	//the main commands slide out to the left and the commands of the hero slide in from the right, or the other way
	[async]
	def Slide(inward as bool) as Task:
		_page.Commands.Visible = true
		_page.ActorCommands.Visible = true
		for i in range(1, SLIDE_LENGTH + 1):
			_page.SlideTo((i if inward else SLIDE_LENGTH - i))
			await Pause(1, 1)

	//what the party looks like when it is not choosing: the main commands in place, the others out of sight
	private def ResetCommandBoxes():
		_page.SlideTo(0)
		_page.ActorCommands.Close()
		_page.ActorCommands.Visible = false
		_page.Commands.Visible = false

	[async]
	def ChooseForParty() as Task of bool:
		var candidates = _field.Heroes.Where({h | h.IsAlive and h.CanChooseCommand}).ToList()
		return true if candidates.Count == 0
		var i = 0
		PrepareActorCommands(candidates[0])
		_page.Status.ActiveRow = _field.Heroes.IndexOf(candidates[0])
		await Slide(true)
		while i < candidates.Count:
			var hero = candidates[i]
			hero.ResetAction()
			ok = await(ChooseForHero(hero))
			if ok:
				++i
			elif i == 0:
				_page.Status.ActiveRow = -1
				await Slide(false)
				ResetCommandBoxes()
				return false
			else: --i
		_page.Status.ActiveRow = -1
		ResetCommandBoxes()
		return true

	//0: not allowed, 1: got away (ends the battle), 2: tried and failed
	[async]
	def TryEscape() as Task of int:
		if not (TBattleResult.Escaped in _conditions.Results):
			PlaySystemSound(TSfxTypes.Buzzer)
			return 0
		var chance = TBattleMath.EscapeChance(_field.AverageHeroAgility, _field.AverageMonsterAgility) + _escapeBonus
		if _conditions.Formation in (TBattleFormation.FirstStrike, TBattleFormation.Initiative) and FirstRound:
			chance = 100
		if TBattleMath.Roll(100) < chance:
			PlaySystemSound(TSfxTypes.Escape)
			Line(TBattleText.SayPlain('Battle-Fled', ''))
			await Pause(ANNOUNCE_MIN, ANNOUNCE_MAX)
			return 1
		_escapeBonus += DEFAULT_ESCAPE_BONUS
		Line(TBattleText.SayPlain('Battle-Failed Escape', ''))
		await Pause(ANNOUNCE_MIN, ANNOUNCE_MAX)
		EndNarration()
		return 2

	//the list of the box is opened; what comes back is the row that was chosen, or -1
	[async]
	def Pick(box as TBattleListBox, position as int) as Task of int:
		box.Begin()
		_page.Open(box, position)
		waitFor {box.Done}
		var result = box.Result
		box.Close()
		_page.Release()
		return result

	//a hero from the party, or all of them
	[async]
	def PickHero(all as bool) as Task of int:
		_page.Status.BeginSelect(all)
		_page.Open(_page.Status, 0)
		waitFor {_page.Status.Done}
		var result = _page.Status.Result
		_page.Status.EndSelect()
		_page.Release()
		return result

	private def HighlightMonster(index as int):
		for i in range(_field.Monsters.Count):
			_field.Monsters[i].Body.Highlighted = (i == index)

	private def OnEnemyCursor(position as short, box as TGameMenuBox, page as TMenuPage):
		HighlightMonster(_activeMonsters[position]) if position >= 0 and position < _activeMonsters.Count

	//the monster to aim at: its number among the monsters of the battle, or -1
	[async]
	def PickMonster() as Task of int:
		var names = List[of string]()
		_activeMonsters.Clear()
		for i in range(_field.Monsters.Count):
			if _field.Monsters[i].IsAlive:
				names.Add(_field.Monsters[i].Name)
				_activeMonsters.Add(i)
		return -1 if names.Count == 0
		_page.Enemies.SetItems(names, null, null)
		_page.Enemies.OnCursor = self.OnEnemyCursor
		choice = await(Pick(_page.Enemies, 0))
		_page.Enemies.OnCursor = null
		HighlightMonster(-1)
		return (-1 if choice < 0 else _activeMonsters[choice])

	//fills the box of the commands of a hero
	private def PrepareActorCommands(hero as THeroUnit):
		var names = List[of string]()
		names.Add(TBattleText.Vocab(V_BATTLE_ATTACK))
		names.Add((hero.SkillCommandName if not string.IsNullOrEmpty(hero.SkillCommandName) else TBattleText.Vocab(V_BATTLE_SKILL)))
		names.Add(TBattleText.Vocab(V_BATTLE_DEFEND))
		names.Add(TBattleText.Vocab(V_BATTLE_ITEM))
		var enabled = List[of bool]()
		enabled.Add(true)
		enabled.Add(hero.KnownSkills().Length > 0)
		enabled.Add(true)
		enabled.Add(GEnvironment.value.Party.Inventory.Count > 0)
		_page.ActorCommands.SetItems(names, enabled, null)
		_page.ActorCommands.CanCancel = true

	[async]
	def ChooseForHero(hero as THeroUnit) as Task of bool:
		_page.Status.ActiveRow = _field.Heroes.IndexOf(hero)
		var position = 0
		while true:
			PrepareActorCommands(hero)
			choice = await(Pick(_page.ActorCommands, position))
			return false if choice < 0
			position = choice
			var ok = false
			if choice == 0:
				ok = await(ChooseAttack(hero))
			elif choice == 1:
				ok = await(ChooseSkill(hero))
			elif choice == 2:
				hero.Action.Kind = TBattleActionKind.Basic
				hero.Action.Basic = TBasicAction.Defend
				ok = true
			else: ok = await(ChooseItem(hero))
			if ok:
				hero.LastCommand = choice
				return true
			hero.ResetAction()

	[async]
	def ChooseAttack(hero as THeroUnit) as Task of bool:
		var action = hero.Action
		action.Kind = TBattleActionKind.Basic
		action.Basic = hero.BasicAttack()
		if hero.AttackAll:
			action.Targets = TTargetKind.AllMonsters
			return true
		index = await(PickMonster())
		return false if index < 0
		action.Targets = TTargetKind.OneMonster
		action.Target = index
		return true

	private def OnSkillCursor(position as short, box as TGameMenuBox, page as TMenuPage):
		if position >= 0 and position < _skillList.Length:
			_page.Help.Text = TBattleData.Skill(_skillList[position]).Desc

	[async]
	def ChooseSkill(hero as THeroUnit) as Task of bool:
		_skillList = hero.KnownSkills()
		var names = List[of string]()
		var costs = List[of string]()
		var enabled = List[of bool]()
		for id in _skillList:
			names.Add(TBattleData.Skill(id).Name)
			costs.Add(hero.SkillCostFor(id).ToString())
			enabled.Add(hero.CanUseSkill(id))
		_page.Skills.SetItems(names, enabled, costs)
		_page.Skills.OnCursor = self.OnSkillCursor
		_page.Help.Visible = true
		choice = await(Pick(_page.Skills, hero.Action.SkillTop))
		_page.Skills.OnCursor = null
		_page.Help.Visible = false
		return false if choice < 0
		hero.Action.SkillTop = choice
		return await(ChooseSkillTargets(hero, _skillList[choice]))

	[async]
	def ChooseSkillTargets(hero as THeroUnit, skillId as int) as Task of bool:
		var action = hero.Action
		var template = TBattleData.Skill(skillId)
		action.Kind = TBattleActionKind.Skill
		action.Skill = skillId
		action.Targets = TTargetKind.None
		return true unless TBattleData.SkillKind(template) == 0
		var scope = TBattleData.SkillScope(template cast TNormalSkillTemplate)
		if scope == TSkillScope.OneEnemy:
			index = await(PickMonster())
			return false if index < 0
			action.Targets = TTargetKind.OneMonster
			action.Target = index
		elif scope == TSkillScope.AllEnemies:
			action.Targets = TTargetKind.AllMonsters
		elif scope == TSkillScope.Self:
			action.Targets = TTargetKind.OneHero
			action.Target = _field.Heroes.IndexOf(hero)
		elif scope == TSkillScope.OneAlly:
			index2 = await(PickHero(false))
			return false if index2 < 0
			action.Targets = TTargetKind.OneHero
			action.Target = index2
		else: action.Targets = TTargetKind.AllHeroes
		return true

	private _itemList as (int)

	private def OnItemCursor(position as short, box as TGameMenuBox, page as TMenuPage):
		if position >= 0 and position < _itemList.Length:
			_page.Help.Text = TBattleData.Item(_itemList[position]).Desc

	[async]
	def ChooseItem(hero as THeroUnit) as Task of bool:
		var inventory = GEnvironment.value.Party.Inventory
		inventory.Sort()
		var ids = List[of int]()
		var names = List[of string]()
		var counts = List[of string]()
		var enabled = List[of bool]()
		for i in range(inventory.Count):
			var item = inventory[i]
			ids.Add(item.Template.ID)
			names.Add(item.Template.Name)
			counts.Add(item.Quantity.ToString())
			enabled.Add(hero.CanUseItem(item.Template.ID))
		_itemList = ids.ToArray()
		_page.Items.SetItems(names, enabled, counts)
		_page.Items.OnCursor = self.OnItemCursor
		_page.Help.Visible = true
		choice = await(Pick(_page.Items, 0))
		_page.Items.OnCursor = null
		_page.Help.Visible = false
		return false if choice < 0
		var action = hero.Action
		action.Kind = TBattleActionKind.Item
		action.Item = _itemList[choice]
		action.Targets = TTargetKind.None
		var template = TBattleData.Item(action.Item)
		var medicine = template as TMedicineTemplate
		var skillItem = template as TSkillItemTemplate
		if medicine is not null:
			if medicine.AreaEffect:
				action.Targets = TTargetKind.AllHeroes
			else:
				index = await(PickHero(false))
				return false if index < 0
				action.Targets = TTargetKind.OneHero
				action.Target = index
		elif skillItem is not null and TBattleData.SkillKind(TBattleData.Skill(skillItem.Skill)) == 0:
			var skill = TBattleData.Skill(skillItem.Skill) cast TNormalSkillTemplate
			var scope = TBattleData.SkillScope(skill)
			if scope == TSkillScope.OneEnemy:
				index3 = await(PickMonster())
				return false if index3 < 0
				action.Targets = TTargetKind.OneMonster
				action.Target = index3
			elif scope == TSkillScope.AllEnemies:
				action.Targets = TTargetKind.AllMonsters
			elif scope == TSkillScope.OneAlly:
				index2 = await(PickHero(false))
				return false if index2 < 0
				action.Targets = TTargetKind.OneHero
				action.Target = index2
			elif scope == TSkillScope.AllAllies:
				action.Targets = TTargetKind.AllHeroes
			else:
				action.Targets = TTargetKind.OneHero
				action.Target = _field.Heroes.IndexOf(hero)
		return true

	//---- the actions, in the order of the gauges

	[async]
	def Execute() as Task of TBattleOutcome?:
		_page.Messages.ClearLines()
		var order = List[of TBattleUnit]()
		for unit in Units():
			if unit.Present:
				unit.RollGauge()
				order.Add(unit)
		var sorted = order.OrderByDescending({u | u.Initiative}).ToList()
		for unit in sorted:
			continue unless unit.IsAlive
			_page.Messages.ClearLines()
			var result = await(Act(unit))
			return result unless result == null
			if unit.IsAlive:
				await Settle(unit)
			result = CheckEnd()
			return result unless result == null
			await RunPages()
			result = CheckEnd()
			return result unless result == null
		await Pause(ACTION_TICKS, ACTION_TICKS)
		EndNarration()
		return null

	[async]
	def Act(unit as TBattleUnit) as Task of TBattleOutcome?:
		var action = unit.Action
		return unless unit.CanAct
		return if action.Kind in (TBattleActionKind.Nothing, TBattleActionKind.Auto)
		_page.Status.ActiveRow = -1
		if action.Kind == TBattleActionKind.Basic:
			await DoBasic(unit)
		elif action.Kind == TBattleActionKind.Skill:
			var result = await(UseSkill(unit, action.Skill, action))
			return result unless result == null
		elif action.Kind == TBattleActionKind.Transform:
			await DoTransform(unit)
		elif action.Kind == TBattleActionKind.Item:
			await DoItem(unit)
		GEnvironment.value.Switch[action.SwitchOn] = true if action.SwitchOn > 0
		GEnvironment.value.Switch[action.SwitchOff] = false if action.SwitchOff > 0

	//who a basic attack or a skill goes to: the targets that the action names, and a living one when the first is gone
	private def TargetsFor(user as TBattleUnit, action as TBattleAction, attack as bool) as List[of TBattleUnit]:
		side as TBattleUnit*
		var one = false
		caseOf action.Targets:
			case TTargetKind.OneHero:
				side = HeroUnits()
				one = true
			case TTargetKind.AllHeroes: side = HeroUnits()
			case TTargetKind.OneMonster:
				side = MonsterUnits()
				one = true
			case TTargetKind.AllMonsters: side = MonsterUnits()
			default: pass
		var result = List[of TBattleUnit]()
		if one:
			var units = side.ToArray()
			if action.Target >= 0 and action.Target < units.Length:
				var chosen = units[action.Target]
				if chosen.IsAlive or not attack:
					result.Add(chosen)
				else:
					var living = side.Where({u | u.IsAlive}).ToList()
					result.Add(living[TBattleMath.Roll(living.Count)]) if living.Count > 0
		else:
			for unit in side:
				result.Add(unit) if unit.IsAlive or not attack
		return result

	[async]
	def PlayAnimation(animation as int, targets as List[of TBattleUnit]) as Task:
		return if animation <= 0 or targets.Count == 0
		var signals = List[of TaskCompletionSource]()
		for target in targets:
			var signal = TaskCompletionSource()
			signals.Add(signal)
			ShowBattleAnimT(BattleEngineFor(), animation, TargetOf(target), false, signal)
		await Task.WhenAll(signals.Select({s | s.Task}).ToArray())

	//---- basic actions

	[async]
	def DoBasic(unit as TBattleUnit) as Task:
		var action = unit.Action
		caseOf action.Basic:
			case TBasicAction.Attack, TBasicAction.DoubleAttack:
				await DoAttack(unit)
			case TBasicAction.Defend:
				unit.Defending = true
				Line(TBattleText.SayPlain('Battle-Ally Defends', unit.Name))
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
			case TBasicAction.Observe:
				Line(TBattleText.SayPlain('Battle-Enemy Defends', unit.Name))
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
			case TBasicAction.Charge:
				unit.Charged = true
				Line(TBattleText.SayPlain('Battle-Enemy Building Strength', unit.Name))
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
			case TBasicAction.SelfDestruct:
				await DoExplode(unit)
			case TBasicAction.Escape:
				await DoFlee(unit)
			default: pass

	[async]
	def DoAttack(unit as TBattleUnit) as Task:
		var action = unit.Action
		var targets = TargetsFor(unit, action, true)
		return if targets.Count == 0
		//the weapon takes its points of skill
		if unit.AttackCost > 0:
			unit.DamageSp(unit.AttackCost)
		Line(TBattleText.SayPlain(V_BATTLE_DO_ATTACK, unit.Name))
		var hero = unit as THeroUnit
		var passes = (2 if action.Basic == TBasicAction.DoubleAttack else 1)
		for attackPass in range(passes):
			var animation = 0
			if hero is not null:
				animation = (hero.BattleAnimation if attackPass == 0 or hero.SecondWeaponAnimation == 0 else hero.SecondWeaponAnimation)
			else: PlaySystemSound(TSfxTypes.EnemyAttack)
			await PlayAnimation(animation, targets)
			for target in targets:
				if target.IsAlive:
					await AttackOnce(unit, target)
			targets = targets.Where({t | t.IsAlive}).ToList()
			break if targets.Count == 0
		unit.Charged = false

	[async]
	def AttackOnce(user as TBattleUnit, target as TBattleUnit) as Task:
		var miss = TBattleMath.MissChance(user.HitRate, user.HitRatio, user.Agility, target.Agility, user.IgnoreEvasion, \
				target.RaiseEvasion, target.CanAct)
		if not TBattleMath.RollHit(miss):
			PlaySystemSound(TSfxTypes.Evade)
			Line(TBattleText.SayPlain((V_BATTLE_ENEMY_MISSED if target.IsMonster else V_BATTLE_ALLY_MISSED), target.Name))
			await Pause(MESSAGE_MIN, MESSAGE_MAX)
			return
		var damage = user.AttackDamage(target)
		damage *= 2 if user.Charged
		var critical = false
		if (not target.PreventCritical) and TBattleMath.RollCritical(user.CriticalChance):
			critical = true
			damage *= 3
		damage = TBattleMath.AttackSpread(damage)
		damage = TBattleMath.DamageAfterDefending(damage, target.SuperGuard) if target.Defending
		damage = Math.Max(damage, 0)
		if critical:
			Line(TBattleText.SayPlain(('Battle-Ally Crit' if user.IsHero else 'Battle-Enemy Crit'), user.Name))
		await TakeDamage(target, damage)
		await WeaponConditions(user, target)

	[async]
	def TakeDamage(target as TBattleUnit, damage as int) as Task:
		target.DamageHp(damage, true)
		Impact(target)
		Line(TBattleText.Say((V_BATTLE_ENEMY_INJURED if target.IsMonster else V_BATTLE_ALLY_INJURED), target.Name, \
				TBattleText.ValueObject, damage.ToString(), TBattleText.Vocab(V_STAT_HP)))
		await Pause(MESSAGE_MIN, MESSAGE_MAX)
		await Died(target) if target.Hp == 0

	private def Impact(target as TBattleUnit):
		var monster = target as TMonsterUnit
		if monster is not null:
			PlaySystemSound(TSfxTypes.EnemyDamage)
			monster.Body.Blink(12)
		else:
			PlaySystemSound(TSfxTypes.AllyDamage)
			_page.FlashScreen(255, 255, 255, 20, 8)

	[async]
	def Died(target as TBattleUnit) as Task:
		ShowAdded(target, CTN_DEAD)
		var monster = target as TMonsterUnit
		if monster is not null:
			PlaySystemSound(TSfxTypes.EnemyDies)
			monster.Body.DieFade()
			waitFor {not monster.Body.Animating}
		else: await Pause(MESSAGE_MIN, MESSAGE_MAX)

	private def ShowAdded(target as TBattleUnit, id as int):
		var cond = TBattleData.Condition(id)
		var message = (cond.EnemyMessage if target.IsMonster else cond.AllyMessage)
		Line(TBattleText.SayTemplate(message, target.Name))

	private def ShowRecovered(target as TBattleUnit, id as int):
		Line(TBattleText.SayTemplate(TBattleData.Condition(id).RecoveryMessage, target.Name))

	private def TryInflict(target as TBattleUnit, id as int, baseChance as int) as bool:
		return false if target.HasCondition(id)
		return false if id == CTN_DEAD and target.IsAlive == false
		return false if TBattleMath.Roll(100) < target.ArmorConditionChance(id)
		var chance = (baseChance * TBattleData.ConditionRate(id, target.BaseConditionRank(id))) / 100
		return false unless TBattleMath.Roll(100) < chance
		target.AddCondition(id)
		return true

	[async]
	def WeaponConditions(user as TBattleUnit, target as TBattleUnit) as Task:
		for id in range(1, TBattleData.ConditionCount + 1):
			chance = user.WeaponConditionChance(id)
			continue unless chance > 0 and target.IsAlive
			if TryInflict(target, id, chance):
				ShowAdded(target, id)
				await Pause(MESSAGE_MIN, MESSAGE_MAX)

	[async]
	def DoExplode(unit as TBattleUnit) as Task:
		Line(TBattleText.SayPlain('Battle-Explodes', unit.Name))
		PlaySystemSound(TSfxTypes.EnemyAttack)
		await Pause(MESSAGE_MIN, MESSAGE_MAX)
		for target in _field.Heroes.Where({h | h.IsAlive}).ToList():
			var damage = TBattleMath.ExplosionDamage(unit.Attack, target.Defense)
			damage = TBattleMath.DamageAfterDefending(damage, target.SuperGuard) if target.Defending
			await TakeDamage(target, damage)
		var monster = unit as TMonsterUnit
		unit.Hp = 0
		monster.Body.DieFade() if monster is not null
		unit.Present = false

	[async]
	def DoFlee(unit as TBattleUnit) as Task:
		Line(TBattleText.SayPlain('Battle-Enemy Flees', unit.Name))
		PlaySystemSound(TSfxTypes.Escape)
		var monster = unit as TMonsterUnit
		monster.Body.Flee(false, false) if monster is not null
		unit.Present = false
		await Pause(MESSAGE_MIN, MESSAGE_MAX)

	[async]
	def DoTransform(unit as TBattleUnit) as Task:
		var monster = unit as TMonsterUnit
		return if monster is null
		var oldName = monster.Name
		monster.Body.Transform(GDatabase.value.Monsters[unit.Action.Transform])
		Line(TBattleText.Say('Battle-Enemy Transforms', oldName, monster.Name))
		await Pause(MESSAGE_MIN, MESSAGE_MAX)

	//---- skills

	[async]
	def UseSkill(user as TBattleUnit, skillId as int, action as TBattleAction) as Task of TBattleOutcome?:
		var template = TBattleData.Skill(skillId)
		return null if template is null or not user.CanUseSkill(skillId)
		user.DamageSp(user.SkillCostFor(skillId))
		Line(TBattleText.SayTemplate(template.UseString, user.Name)) if not string.IsNullOrEmpty(template.UseString)
		unless string.IsNullOrEmpty(template.UseString2):
			Line(TBattleText.SayPlain(template.UseString2, user.Name, TBattleText.NoValue, TBattleText.NoValue, TBattleText.NoValue))
		Line(user.Name + ' ' + template.Name) if string.IsNullOrEmpty(template.UseString) and string.IsNullOrEmpty(template.UseString2)
		await Pause(MESSAGE_MIN, MESSAGE_MAX)
		var kind = TBattleData.SkillKind(template)
		if kind == 0:
			await UseNormalSkill(user, template cast TNormalSkillTemplate, action)
		elif kind == 2:
			return TBattleOutcome.Escaped
		elif kind == 3:
			await UseSwitchSkill(template)
		return null

	[async]
	def UseSwitchSkill(template as TSkillTemplate) as Task:
		var variable = template as TVariableSkillTemplate
		var sound = template.FirstSound
		PlaySoundData(sound) if sound is not null and not string.IsNullOrEmpty(sound.Filename)
		if variable is not null and not variable.IsVariable:
			GEnvironment.value.Switch[variable.Which] = true
		await Pause(MESSAGE_MIN, MESSAGE_MAX)

	[async]
	def UseNormalSkill(user as TBattleUnit, skill as TNormalSkillTemplate, action as TBattleAction) as Task:
		var scope = TBattleData.SkillScope(skill)
		var targets = TargetsFor(user, action, false).Where({t | t.SkillWorksOn(skill.ID)}).ToList()
		if targets.Count == 0:
			Line(TBattleText.SayPlain(SkillFailureKey(skill), user.Name))
			await Pause(MESSAGE_MIN, MESSAGE_MAX)
			return
		await PlayAnimation(skill.Animation, targets)
		var anyEffect = false
		for target in targets:
			worked = await(ApplySkill(user, skill, target))
			anyEffect = anyEffect or worked
		if not anyEffect:
			Line(TBattleText.SayPlain(SkillFailureKey(skill), user.Name))
			await Pause(MESSAGE_MIN, MESSAGE_MAX)

	private def SkillFailureKey(skill as TNormalSkillTemplate) as string:
		return 'Battle-Skill Failed ' + (Math.Max(Math.Min(skill.FailureMessage, 2), 0) + 1).ToString()

	[async]
	def ApplySkill(user as TBattleUnit, skill as TNormalSkillTemplate, target as TBattleUnit) as Task of bool:
		var offensive = TBattleData.SkillScope(skill) in (TSkillScope.OneEnemy, TSkillScope.AllEnemies)
		var chance = skill.SuccessRate
		if offensive:
			chance = TBattleMath.SkillHitChance(chance, user.HitRatio, user.Agility, target.Agility, false, target.RaiseEvasion, target.CanAct)
		if TBattleMath.Roll(100) >= chance:
			PlaySystemSound(TSfxTypes.Evade)
			Line(TBattleText.SayPlain('Battle-Dodge', target.Name))
			await Pause(MESSAGE_MIN, MESSAGE_MAX)
			return true //a dodged skill is a skill that did something, as far as the failure message goes
		var worked = false
		var reversed = skill.InflictReversed
		//the conditions: a skill either inflicts or, when reversed, cures
		if skill.Condition is not null:
			for id in skill.Condition:
				if (offensive and not reversed) or (not offensive and not reversed and id != CTN_DEAD):
					if (offensive and TryInflict(target, id, 100)) or ((not offensive) and not target.HasCondition(id) and TryInflict(target, id, 100)):
						ShowAdded(target, id)
						worked = true
						await Pause(MESSAGE_MIN, MESSAGE_MAX)
				elif target.HasCondition(id) and (not offensive or reversed):
					target.RemoveCondition(id)
					ShowRecovered(target, id)
					worked = true
					await Pause(MESSAGE_MIN, MESSAGE_MAX)
		var amount = 0
		if skill.HP or skill.MP or skill.Attack or skill.Defense or skill.Mind or skill.Speed:
			amount = user.SkillDamage(skill.ID, target)
		if skill.HP and amount > 0 or (skill.HP and not offensive):
			if offensive:
				var dealt = Math.Min(amount, target.Hp)
				await TakeDamage(target, amount)
				worked = true
				await Drain(user, target, dealt, true, skill)
			else:
				var gained = target.HealHp(amount)
				Line(TBattleText.Say('Battle-Recovery', target.Name, TBattleText.ValueObject, gained.ToString(), TBattleText.Vocab(V_STAT_HP)))
				worked = true
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
		if skill.MP and amount > 0:
			if offensive:
				var taken = target.DamageSp(amount)
				Line(TBattleText.Say('Battle-Ability Down', target.Name, TBattleText.Vocab(V_STAT_MP), taken.ToString(), ''))
				worked = true
				await Drain(user, target, taken, false, skill)
			else:
				var gainedMp = target.HealSp(amount)
				Line(TBattleText.Say('Battle-Recovery', target.Name, TBattleText.ValueObject, gainedMp.ToString(), TBattleText.Vocab(V_STAT_MP)))
				worked = true
			await Pause(MESSAGE_MIN, MESSAGE_MAX)
		for which in range(2, 6):
			continue unless (which == 2 and skill.Attack) or (which == 3 and skill.Defense) or (which == 4 and skill.Mind) or (which == 5 and skill.Speed)
			continue unless amount > 0
			if offensive:
				var lowered = target.ReduceStat(which, amount)
				continue unless lowered > 0
				Line(TBattleText.Say('Battle-Ability Down', target.Name, StatName(which), lowered.ToString(), ''))
			else:
				var raised = target.ChangeStat(which, amount)
				continue unless raised > 0
				Line(TBattleText.Say('Battle-Ability Up', target.Name, StatName(which), raised.ToString(), ''))
			worked = true
			await Pause(MESSAGE_MIN, MESSAGE_MAX)
		if skill.ResistMod and skill.Attributes is not null:
			for pair in skill.Attributes:
				var changed = (target.LowerAttributeRank(pair.x) if offensive else target.RaiseAttributeRank(pair.x))
				continue unless changed
				var attributeName = GDatabase.value.Attributes[pair.x].Name
				Line(TBattleText.Say(('Battle-Defense Down' if offensive else 'Battle-Defense Up'), target.Name, attributeName))
				worked = true
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
		return worked

	[async]
	def Drain(user as TBattleUnit, target as TBattleUnit, amount as int, hitPoints as bool, skill as TNormalSkillTemplate) as Task:
		return unless skill.Drain and amount > 0 and user.IsAlive
		var gained = (user.HealHp(amount) if hitPoints else user.HealSp(amount))
		var unitName = TBattleText.Vocab((V_STAT_HP if hitPoints else V_STAT_MP))
		Line(TBattleText.Say(('Battle-Ally Absorb' if user.IsHero else 'Battle-Enemy Absorb'), user.Name, TBattleText.ValueObject, \
				gained.ToString(), unitName))
		await Pause(MESSAGE_MIN, MESSAGE_MAX)

	//---- items

	[async]
	def DoItem(user as TBattleUnit) as Task:
		var action = user.Action
		var template = TBattleData.Item(action.Item)
		return if template is null or not user.CanUseItem(action.Item)
		Line(TBattleText.Say('Battle-Uses Item', user.Name, template.Name))
		var usable = template as TUsableItemTemplate
		GEnvironment.value.Party.Inventory.Remove(template.ID, 1) if usable is null or usable.UsesLeft != 0
		await Pause(MESSAGE_MIN, MESSAGE_MAX)
		caseOf template.ItemType:
			case TItemType.Medicine:
				for target in TargetsFor(user, action, false):
					await Medicate(template, target)
			case TItemType.Skill:
				await DoSkillFromItem(user, template, action)
			case TItemType.Variable:
				var variable = template cast TVariableItemTemplate
				GEnvironment.value.Switch[variable.Which] = true if variable.Style == TVarSets.Switch

	[async]
	def DoSkillFromItem(user as TBattleUnit, item as TSkillItemTemplate, action as TBattleAction) as Task:
		var skill = TBattleData.Skill(item.Skill)
		return if skill is null
		var kind = TBattleData.SkillKind(skill)
		if kind == 0:
			await UseNormalSkill(user, skill cast TNormalSkillTemplate, action)
		elif kind == 3:
			await UseSwitchSkill(skill)

	[async]
	def Medicate(medicine as TMedicineTemplate, target as TBattleUnit) as Task:
		if medicine.DeadOnly != (not target.IsAlive):
			return
		var worked = false
		for id in medicine.Conditions:
			if target.HasCondition(id):
				target.RemoveCondition(id)
				worked = true
				ShowRecovered(target, id)
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
		if target.IsAlive:
			var hp = ((target.MaxHp * medicine.HPPercent) / 100) + medicine.Stats[0]
			if hp > 0:
				var gained = target.HealHp(hp)
				Line(TBattleText.Say('Battle-Recovery', target.Name, TBattleText.ValueObject, gained.ToString(), TBattleText.Vocab(V_STAT_HP)))
				worked = true
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
			var mp = ((target.MaxSp * medicine.MPPercent) / 100) + medicine.Stats[1]
			if mp > 0:
				var gainedMp = target.HealSp(mp)
				Line(TBattleText.Say('Battle-Recovery', target.Name, TBattleText.ValueObject, gainedMp.ToString(), TBattleText.Vocab(V_STAT_MP)))
				worked = true
				await Pause(MESSAGE_MIN, MESSAGE_MAX)
		if not worked:
			Line(TBattleText.SayPlain('Battle-Skill Failed 1', target.Name))
			await Pause(MESSAGE_MIN, MESSAGE_MAX)

	//---- the end of a fighter's turn: what its conditions do

	[async]
	def Settle(unit as TBattleUnit) as Task:
		for id in range(1, TBattleData.ConditionCount + 1):
			var age = unit.ConditionAge(id)
			continue if age == 0 or id == CTN_DEAD
			var cond = TBattleData.Condition(id)
			unit.SetConditionAge(id, age + 1)
			var hpChange = TBattleMath.ChangePerTurn(unit.MaxHp, cond.HpTurnPercent, cond.HpTurnFixed)
			if hpChange > 0:
				await TakeDamage(unit, hpChange)
				break unless unit.IsAlive
			elif hpChange < 0:
				unit.HealHp(-hpChange)
			var mpChange = TBattleMath.ChangePerTurn(unit.MaxSp, cond.MpTurnPercent, cond.MpTurnFixed)
			if mpChange > 0:
				unit.DamageSp(mpChange)
			elif mpChange < 0:
				unit.HealSp(-mpChange)
			if cond.HealTurnPercent > 0 and age + 1 > cond.HealTurns and TBattleMath.Roll(100) < cond.HealTurnPercent:
				unit.RemoveCondition(id)
				ShowRecovered(unit, id)
				await Pause(MESSAGE_MIN, MESSAGE_MAX)

	//---- ending

	[async]
	def Conclude() as Task:
		if _outcome == TBattleOutcome.Won:
			await Victory()
		elif _outcome == TBattleOutcome.Lost:
			await Defeat()

	[async]
	def Victory() as Task:
		_page.HideBoxes()
		_page.Status.Visible = true
		PlaySystemMusic(TBgmTypes.Victory)
		var defeated = _field.Monsters.Where({m | m.Hp == 0}).ToList()
		var exp = defeated.Sum({m | m.Exp})
		var gold = defeated.Sum({m | m.Gold})
		var heroes = _field.Heroes.Where({h | h.IsAlive}).ToList()
		_pool.Clear()
		_pool.AddWrapped(TBattleText.SayPlain('Battle-Victory', (_field.Heroes[0].Name if _field.Heroes.Count > 0 else '')), MESSAGE_COLUMNS)
		if exp > 0 and heroes.Count > 0:
			_pool.AddWrapped(TBattleText.Say('Battle-Exp Gained', TBattleText.NoValue, TBattleText.ValueObject, exp.ToString(), \
					TBattleText.Vocab(V_STAT_EXP)), MESSAGE_COLUMNS)
		if gold > 0:
			_pool.AddWrapped(TBattleText.Say('Battle-Found Gold', TBattleText.NoValue, TBattleText.ValueObject, gold.ToString(), \
					TBattleText.Vocab(V_MONEY_NAME)), MESSAGE_COLUMNS)
			_party.Money = _party.Money + gold
		for monster in defeated:
			if monster.DropItem > 0 and TBattleMath.Roll(100) < monster.DropChance:
				_party.Inventory.Add(monster.DropItem, 1)
				_pool.AddWrapped(TBattleText.Say('Battle-Found Item', TBattleData.Item(monster.DropItem).Name), MESSAGE_COLUMNS)
		_pool.AddBreak()
		if exp > 0 and heroes.Count > 0:
			var share = exp / heroes.Count
			for hero in heroes:
				hero.GainExp(share, _pool)
		await ShowPool()

	[async]
	def Defeat() as Task:
		_page.HideBoxes()
		_page.Status.Visible = true
		PlaySystemMusic(TBgmTypes.GameOver)
		_pool.Clear()
		_pool.AddWrapped(TBattleText.SayPlain('Battle-Defeat', ''), MESSAGE_COLUMNS)
		await ShowPool()
		GEnvironment.value.GameOver() unless TBattleResult.Defeated in _conditions.Results

	[async]
	def ShowPool() as Task:
		var box = _page.Messages
		while _pool.Count > 0:
			var lines = List[of string]()
			while lines.Count < MESSAGE_ROWS and _pool.Count > 0:
				var text = _pool.TakeLine()
				if text == '':
					break if lines.Count > 0
				else: lines.Add(text)
			continue if lines.Count == 0
			box.SetLines(lines)
			box.Visible = true
			box.BeginWait()
			_page.Focus(box)
			waitFor {box.Done}
		box.ClearLines()
		box.Visible = false
		_page.Release()

	//---- scripting API

	def TurnsMatch(multiple as int, offset as int) as bool:
		return TBattleMath.TurnMatches(_field.Turns, multiple, offset)

	def MonstersPresent(minimum as int, maximum as int) as bool:
		var count = _field.AliveMonsterCount
		return count >= minimum and count <= maximum

	private def HeroById(id as int) as THeroUnit:
		return _field.Heroes.FirstOrDefault({h | h.ID == id})

	private def MonsterAt(id as int) as TMonsterUnit:
		var currentMonster = _field.CurrentMonster as TMonsterUnit
		return currentMonster if currentMonster is not null
		return (_field.Monsters[id] if id >= 0 and id < _field.Monsters.Count else null)

	def HeroHPBetween(id as int, minimum as int, maximum as int) as bool:
		var hero = HeroById(id)
		return false if hero is null
		var percent = TBattleMath.PercentOf(hero.Hp, hero.MaxHp)
		return percent >= minimum and percent <= maximum

	def MonsterHPBetween(id as int, minimum as int, maximum as int) as bool:
		var monster = MonsterAt(id)
		return false if monster is null
		var percent = TBattleMath.PercentOf(monster.Hp, monster.MaxHp)
		return percent >= minimum and percent <= maximum

	def MonsterMPBetween(id as int, minimum as int, maximum as int) as bool:
		var monster = MonsterAt(id)
		return false if monster is null
		var percent = TBattleMath.PercentOf(monster.Sp, monster.MaxSp)
		return percent >= minimum and percent <= maximum

	def PartyLevelBetween(minimum as int, maximum as int) as bool:
		var level = _field.AverageLevel
		return level >= minimum and level <= maximum

	def PartyExhaustionBetween(minimum as int, maximum as int) as bool:
		var loss = _field.HealthLoss
		return loss >= minimum and loss <= maximum

	def MonsterTurnsMatch(id as int, multiple as int, offset as int) as bool:
		var monster = (_field.Monsters[id] if id >= 0 and id < _field.Monsters.Count else null)
		return false if monster is null or not monster.Present
		return TBattleMath.TurnMatches(monster.TurnsTaken - 1, multiple, offset)

	def HeroTurnsMatch(id as int, multiple as int, offset as int) as bool:
		var hero = HeroById(id)
		return false if hero is null
		return TBattleMath.TurnMatches(hero.TurnsTaken - 1, multiple, offset)

	def HeroCommandUsed(id as int, command as int) as bool:
		var hero = HeroById(id)
		return hero is not null and hero.LastCommand == command

	def GetMonster(i as int) as T2kMonster:
		return (_field.Monsters[i - 1].Body if i >= 1 and i <= _field.Monsters.Count else null)

	def IsTargetted(monster as T2kMonster) as bool:
		var index = monster.Slot - 1
		for hero in _field.Heroes:
			var action = hero.Action
			continue unless hero.IsAlive
			return true if action.Targets == TTargetKind.AllMonsters
			return true if action.Targets == TTargetKind.OneMonster and action.Target == index
		return false

	def RetargetFor(monster as T2kMonster) as TRpgBattleCharacter:
		var living = _field.Heroes.Where({h | h.IsAlive}).ToList()
		return (living[TBattleMath.Roll(living.Count)].Character if living.Count > 0 else null)

	def Terminate():
		_stopped = true

	def SetBackdrop(filename as string):
		_page.SetBackdrop(filename)

	Effects as SpriteEngine:
		get: return (_page.Effects if _page is not null else null)
