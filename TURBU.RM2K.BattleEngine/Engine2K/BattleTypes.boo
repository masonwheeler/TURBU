namespace TURBU.RM2K.BattleEngine

enum TBattleActionKind:
	Basic = 0
	Skill = 1
	Transform = 2
	Item = 3
	Nothing = 4
	Auto = 5

enum TBasicAction:
	Attack = 0
	DoubleAttack = 1
	Defend = 2
	Observe = 3
	Charge = 4
	SelfDestruct = 5
	Escape = 6
	None = 7

enum TTargetKind:
	None = 0
	OneHero = 1
	AllHeroes = 2
	OneMonster = 3
	AllMonsters = 4

enum TSkillScope:
	OneEnemy = 0
	AllEnemies = 1
	Self = 2
	OneAlly = 3
	AllAllies = 4

enum TBattleOutcome:
	Won = 0
	Escaped = 1
	Lost = 2
	Stopped = 3

// What a battler has decided to do this turn.
class TBattleAction:

	property Kind as TBattleActionKind = TBattleActionKind.Nothing

	property Basic as TBasicAction

	property Skill as int

	property Transform as int

	property Item as int

	//where the list of skills was scrolled to in the menu
	property SkillTop as int

	property SwitchOn as int

	property SwitchOff as int

	property Targets as TTargetKind

	property Target as int

	public def Reset():
		Kind = TBattleActionKind.Nothing
		Basic = TBasicAction.Attack
		Skill = 0
		Transform = 0
		Item = 0
		SkillTop = 0
		SwitchOn = 0
		SwitchOff = 0
		Targets = TTargetKind.None
		Target = 0
