namespace TURBU.RM2K.RPGScript

import System
import System.Linq.Enumerable
import Pythia.Runtime
import TURBU.Meta
import commons
import SG.defs
import sdl.sprite
import turbu.classes
import turbu.defs
import turbu.monsters
import turbu.Heroes
import turbu.RM2K.animations
import TURBU.RM2K

interface IBattleContext:

	def TurnsMatch(multiple as int, offset as int) as bool

	def MonstersPresent(minimum as int, maximum as int) as bool

	def HeroHPBetween(id as int, minimum as int, maximum as int) as bool

	def MonsterHPBetween(id as int, minimum as int, maximum as int) as bool

	def MonsterMPBetween(id as int, minimum as int, maximum as int) as bool

	def PartyLevelBetween(minimum as int, maximum as int) as bool

	def PartyExhaustionBetween(minimum as int, maximum as int) as bool

	def MonsterTurnsMatch(id as int, multiple as int, offset as int) as bool

	def HeroTurnsMatch(id as int, multiple as int, offset as int) as bool

	def HeroCommandUsed(id as int, command as int) as bool

	def GetMonster(i as int) as T2kMonster

	def IsTargetted(monster as T2kMonster) as bool

	def RetargetFor(monster as T2kMonster) as TRpgBattleCharacter

	def Terminate()

	def SetBackdrop(filename as string)

	Effects as SpriteEngine:
		get

class T2kMonster(TRpgBattleCharacter, IAnimTarget):

	[Getter(Monster)]
	private FMonster as TRpgMonster

	[Property(Slot)]
	private FSlot as int

	public def constructor(base as TRpgMonster):
		super(base)
		FMonster = base
		FName = base.Name
		FMaxHitPoints = base.Stats[0]
		FMaxManaPoints = base.Stats[1]
		for i in range(4):
			FStat[i, TStatComponents.Base] = base.Stats[i + 2]
		FHitPoints = FMaxHitPoints
		FManaPoints = FMaxManaPoints
		var conditions = GDatabase.value.Conditions.Count + 1
		FCondition = array(bool, conditions)
		FConditionModifier = array(int, conditions)
		for cond in base.Condition:
			FConditionModifier[cond.x] = cond.y if cond.x in range(conditions)

	public Condition[x as int] as bool:
		get: return GetCondition(x)
		set: SetCondition(x, value)

	public virtual def Transform(newBase as TRpgMonster):
		FMonster = newBase
		FName = newBase.Name
		FMaxHitPoints = newBase.Stats[0]
		FMaxManaPoints = newBase.Stats[1]
		for i in range(4):
			FStat[i, TStatComponents.Base] = newBase.Stats[i + 2]
		FHitPoints = Math.Min(FHitPoints, FMaxHitPoints)
		FManaPoints = FMaxManaPoints

	public MaxHP as int:
		get: return GetMHp()
		set: SetMaxHp(value)

	public MaxMP as int:
		get: return GetMMp()
		set: SetMaxMp(value)

	protected override def SetHP(value as int):
		return if FCondition[CTN_DEAD]
		FHitPoints = clamp(value, 0, GetMHp())
		self.Die() if FHitPoints == 0

	protected override def SetMP(value as int):
		FManaPoints = clamp(value, 0, GetMMp())

	protected override def SetMaxMp(value as int):
		FMaxManaPoints = Math.Max(value, 0)
		FManaPoints = Math.Min(FManaPoints, FMaxManaPoints)

	protected override def SetMaxHp(value as int):
		FMaxHitPoints = Math.Max(value, 1)
		FHitPoints = Math.Min(FHitPoints, FMaxHitPoints)

	public def SafeLoseHP(value as int):
		return if FCondition[CTN_DEAD]
		FHitPoints = Math.Max(FHitPoints - value, 1)

	public Targetted as bool:
		get: return BattleState.IsTargetted(self)

	public override def Retarget() as TRpgBattleCharacter:
		return BattleState.RetargetFor(self)

	public virtual def Show():
		pass

	public virtual def Flee(force as bool, ignoreIfSurrounded as bool):
		pass

	public virtual def Position(sign as int) as SgPoint:
		return SgPoint(0, 0)

	public virtual def Flash(r as int, g as int, b as int, power as int, time as int):
		pass

static class BattleState:

	[Property(Current)]
	private _current as IBattleContext

	private def Require() as IBattleContext:
		raise InvalidOperationException('There is no current battle.') if _current is null
		return _current

	def TurnsMatch(multiple as int, offset as int) as bool:
		return Require().TurnsMatch(multiple, offset)

	def MonstersPresent(minimum as int, maximum as int) as bool:
		return Require().MonstersPresent(minimum, maximum)

	def HeroHPBetween(id as int, minimum as int, maximum as int) as bool:
		return Require().HeroHPBetween(id, minimum, maximum)

	def MonsterHPBetween(id as int, minimum as int, maximum as int) as bool:
		return Require().MonsterHPBetween(id, minimum, maximum)

	def MonsterMPBetween(id as int, minimum as int, maximum as int) as bool:
		return Require().MonsterMPBetween(id, minimum, maximum)

	def PartyLevelBetween(minimum as int, maximum as int) as bool:
		return Require().PartyLevelBetween(minimum, maximum)

	def PartyExhaustionBetween(minimum as int, maximum as int) as bool:
		return Require().PartyExhaustionBetween(minimum, maximum)

	def MonsterTurnsMatch(id as int, multiple as int, offset as int) as bool:
		return Require().MonsterTurnsMatch(id, multiple, offset)

	def HeroTurnsMatch(id as int, multiple as int, offset as int) as bool:
		return Require().HeroTurnsMatch(id, multiple, offset)

	def HeroCommandUsed(id as int, command as int) as bool:
		return Require().HeroCommandUsed(id, command)

	def Evaluate(name as string, args as (int)) as bool:
		caseOf name:
			case 'TurnsMatch': return TurnsMatch(args[0], args[1])
			case 'MonstersPresent': return MonstersPresent(args[0], args[1])
			case 'HeroHPBetween': return HeroHPBetween(args[0], args[1], args[2])
			case 'MonsterHPBetween': return MonsterHPBetween(args[0], args[1], args[2])
			case 'MonsterMPBetween': return MonsterMPBetween(args[0], args[1], args[2])
			case 'PartyLevelBetween': return PartyLevelBetween(args[0], args[1])
			case 'PartyExhaustionBetween': return PartyExhaustionBetween(args[0], args[1])
			case 'MonsterTurnsMatch': return MonsterTurnsMatch(args[0], args[1], args[2])
			case 'HeroTurnsMatch': return HeroTurnsMatch(args[0], args[1], args[2])
			case 'HeroCommandUsed': return HeroCommandUsed(args[0], args[1])
			default: raise "Unknown behavior requirement '$name'"

	def GetMonster(i as int) as T2kMonster:
		return Require().GetMonster(i)

	internal def IsTargetted(monster as T2kMonster) as bool:
		return Require().IsTargetted(monster)

	internal def RetargetFor(monster as T2kMonster) as TRpgBattleCharacter:
		return Require().RetargetFor(monster)

	def Terminate():
		Require().Terminate()

	def SetBackdrop(filename as string):
		Require().SetBackdrop(filename)

	def IsActive() as bool:
		return _current is not null

	Effects as SpriteEngine:
		get: return (_current.Effects if _current is not null else null)
