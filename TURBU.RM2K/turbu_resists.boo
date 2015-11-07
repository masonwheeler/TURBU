namespace turbu.resists

import System
import Pythia.Runtime
import turbu.classes
import turbu.defs

enum TAttackLimitation:
	None
	Paralyze
	Berserk
	Charm

[EnumSet]
enum TConditionMessages:
	None = 0
	Ally = 1
	Enemy = 2
	Already = 4
	Normal = 8
	End = 0x10

enum TStatEffect:
	Half
	Double
	None

enum TDotEffect:
	None
	Regen
	Damage

class TRpgResistable(TRpgDatafile):
	[Property(Standard)]
	private FStandard = array(short, 7)

[TableName('Conditions')]
class TConditionTemplate(TRpgResistable):

	[Property(OutOfBattle)]
	protected FOutOfBattle as bool

	[Property(Color)]
	protected FColor as int

	[Property(Priority)]
	protected FPriority as int

	[Property(AttackLimit)]
	protected FAttackLimit as TAttackLimitation

	[Property(HealTurns)]
	protected FHealTurns as int

	[Property(HealTurnPercent)]
	protected FHealPercent as int

	[Property(HealShockPercent)]
	protected FHealShock as int

	[Property(Attack)]
	protected FAttackStat as bool

	[Property(Defense)]
	protected FDefenseStat as bool

	[Property(Mind)]
	protected FMindStat as bool

	[Property(Speed)]
	protected FSpeedStat as bool

	[Property(ToHitChange)]
	protected FToHitChange as int

	[Property(PhysBlock)]
	protected FPhysBlock as bool

	[Property(PhysCutoff)]
	protected FPhysCutoff as int

	[Property(MagBlock)]
	protected FMagBlock as bool

	[Property(MagCutoff)]
	protected FMagCutoff as int

	[Property(ConditionMessages)]
	protected FConditionMessages as TConditionMessages

	[Property(UsesConditionMessages)]
	protected FUsesConditionMessages as bool

	[Property(HpTurnPercent)]
	protected FHpTurnPercent as int

	[Property(HpTurnFixed)]
	protected FHpTurnFixed as int

	[Property(HpStepCount)]
	protected FHpStepCount as int

	[Property(HpStepQuantity)]
	protected FHpStepQuantity as int

	[Property(MpTurnPercent)]
	protected FMpTurnPercent as int

	[Property(MpTurnFixed)]
	protected FMpTurnFixed as int

	[Property(MpStepCount)]
	protected FMpStepCount as int

	[Property(MpStepQuantity)]
	protected FMpStepQuantity as int

	[Property(StatEffect)]
	protected FStatEffect as TStatEffect

	[Property(Evade)]
	protected FEvade as bool

	[Property(Reflect)]
	protected FReflect as bool

	[Property(EqLock)]
	protected FEqLock as bool

	[Property(Animation)]
	protected FStatusAnimation as int

	[Property(HpDot)]
	protected FHpDot as TDotEffect

	[Property(MpDot)]
	protected FMpDot as TDotEffect

	[Property(Tag)]
	protected FTag as (int)

class TAttributeTemplate(TRpgResistable):

	[Property(RequiredForSkills)]
	private FRequiredForSkills as bool
