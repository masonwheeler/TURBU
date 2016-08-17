namespace turbu.resists

import System
import Newtonsoft.Json.Linq
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
	private FStandard = array(int, 5)

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.ReadArray('Standard', FStandard)

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

	[Property(MagicReflect)]
	protected FMagicReflect as bool

	[Property(MagicCutoff)]
	protected FMagCutoff as int

	[Property(UsesMessages)]
	protected FUsesMessages as bool

	[Property(AllyMessage)]
	protected FAllyMessage = ''

	[Property(EnemyMessage)]
	protected FEnemyMessage = ''

	[Property(AlreadyMessage)]
	protected FAlreadyMessage = ''

	[Property(NormalMessage)]
	protected FNormalMessage = ''

	[Property(RecoveryMessage)]
	protected FRecoveryMessage = ''

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

	[Property(HPDot)]
	protected FHpDot as TDotEffect

	[Property(MPDot)]
	protected FMpDot as TDotEffect

	[Property(Tag)]
	protected FTag as (int)

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('OutOfBattle', FOutOfBattle)
		value.CheckRead('Color', FColor)
		value.CheckRead('Priority', FPriority)
		value.CheckReadEnum('AttackLimit', FAttackLimit)
		value.CheckRead('HealTurns', FHealTurns)
		value.CheckRead('HealTurnPercent', FHealPercent)
		value.CheckRead('HealShockPercent', FHealShock)
		value.CheckRead('Attack', FAttackStat)
		value.CheckRead('Defense', FDefenseStat)
		value.CheckRead('Mind', FMindStat)
		value.CheckRead('Speed', FSpeedStat)
		value.CheckRead('ToHitChange', FToHitChange)
		value.CheckRead('PhysBlock', FPhysBlock)
		value.CheckRead('PhysCutoff', FPhysCutoff)
		value.CheckRead('MagicReflect', FMagicReflect)
		value.CheckRead('MagicCutoff', FMagCutoff)
		value.CheckRead('UsesMessages', FUsesMessages)
		value.CheckRead('AllyMessage', FAllyMessage)
		value.CheckRead('EnemyMessage', FEnemyMessage)
		value.CheckRead('AlreadyMessage', FAlreadyMessage)
		value.CheckRead('NormalMessage', FNormalMessage)
		value.CheckRead('RecoveryMessage', FRecoveryMessage)
		value.CheckRead('HpTurnPercent', FHpTurnPercent)
		value.CheckRead('HpTurnFixed', FHpTurnFixed)
		value.CheckRead('HpStepCount', FHpStepCount)
		value.CheckRead('HpStepQuantity', FHpStepQuantity)
		value.CheckRead('MpTurnPercent', FMpTurnPercent)
		value.CheckRead('MpTurnFixed', FMpTurnFixed)
		value.CheckRead('MpStepCount', FMpStepCount)
		value.CheckRead('MpStepQuantity', FMpStepQuantity)
		value.CheckReadEnum('StatEffect', FStatEffect)
		value.CheckRead('Evade', FEvade)
		value.CheckRead('Reflect', FReflect)
		value.CheckRead('EqLock', FEqLock)
		value.CheckRead('Animation', FStatusAnimation)
		value.CheckReadEnum('HPDot', FHpDot)
		value.CheckReadEnum('MPDot', FMpDot)
		value.ReadArray('Tag', FTag)
		value.CheckEmpty()

class TAttributeTemplate(TRpgResistable):

	[Property(RequiredForSkills)]
	private FRequiredForSkills as bool
