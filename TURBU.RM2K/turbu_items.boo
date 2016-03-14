namespace turbu.items

import System
import System.Linq.Enumerable
import Pythia.Runtime
import SG.defs
import turbu.operators
import turbu.defs
import turbu.classes

enum TItemType:
	Junk
	Weapon
	Armor
	Medicine
	Upgrade
	Book
	Skill
	Variable
	Script

enum TWeaponAnimType:
	Weapon
	BattleAnim

enum TMovementMode:
	None
	StepForward
	JumpTo
	WalkTo

class ItemTypeAttribute(System.Attribute):

	[Getter(itemType)]
	private FType as TItemType

	public def constructor(it as TItemType):
		FType = it

class TWeaponAnimData(TRpgDatafile):

	[Property(AnimType)]
	protected FAnimType as TWeaponAnimType

	[Property(Weapon)]
	protected FWhichWeapon as int

	[Property(MovementMode)]
	protected FMovementMode as TMovementMode

	[Property(AfterImage)]
	protected FAfterimage as bool

	[Property(AttackNum)]
	protected FAttackNum as int

	[Property(Ranged)]
	protected FRanged as bool

	[Property(RangedProjectile)]
	protected FRangedProjectile as int

	[Property(RangedSpeed)]
	protected FRangedSpeed as int

	[Property(BattleAnim)]
	protected FBattleAnim as int

	def constructor():
		super()

[TableName('Items')]
class TItemTemplate(TRpgDatafile):

	[Property(Desc)]
	private FDescription as string

	[Property(Cost)]
	private FCost as int

	[Property(Tag)]
	private FTag as (int)

	public def constructor():
		super()

	public ItemType as TItemType:
		get:
			att as ItemTypeAttribute
			att = self.GetType().GetCustomAttributes(ItemTypeAttribute, true).SingleOrDefault()
			raise Exception("No ItemTypeAttr found on $(self.ClassName).") unless assigned(att)
			return att.itemType

[ItemType(TItemType.Junk)]
class TJunkTemplate(TItemTemplate):
	pass

abstract class TUsableItemTemplate(TItemTemplate):

	[Property(UsesLeft)]
	private FUsesLeft as int

	[Property(UsableWhere)]
	private FUsableWhere as TUsableWhere

	[Property(UsableByHero)]
	private FUsableByHero = array(int, 0)

	[Property(UsableByClass)]
	private FUsableByClass = array(int, 0)

	[Property(Stats)]
	protected FStat = array(int, 6)

abstract class TEquipmentTemplate(TUsableItemTemplate):

	[Property(Evasion)]
	private FEvasion as bool

	[Property(ToHit)]
	private FToHit as int

	[Property(CritChance)]
	private FCritChance as int

	[Property(CritPrevent)]
	private FCritPrevent as int

	[Property(Preemptive)]
	private FPreemptive as int

	[Property(MpReduction)]
	private FMpReduction as int

	[Property(NoTerrainDamage)]
	private FNoTerrainDamage as bool

	[Property(Condition)]
	private FConditions = array(int, 0)

	[Property(Skill)]
	private FSkill as int

	[Property(InvokeSkill)]
	private FInvokeSkill as bool

	[Property(Cursed)]
	private FCursed as bool

	[Property(InflictReversed)]
	private FInflictReversed as bool

	[Property(Slot)]
	private FSlot as TSlot

	[Property(Attributes)]
	protected FAttributes as (TSgPoint)

[ItemType(TItemType.Weapon)]
class TWeaponTemplate(TEquipmentTemplate):

	[Property(TwoHanded)]
	private FTwoHanded as bool

	[Property(AttackTwice)]
	private FAttackTwice as bool

	[Property(AreaHit)]
	private FAreaHit as bool

	[Property(BattleAnim)]
	private FBattleAnim as ushort

	[Property(MpCost)]
	private FMPCost as ushort

	[Property(ConditionChance)]
	private FConditionChance as byte

	[Property(AnimData)]
	private FAnimData = array(TWeaponAnimData, 0)

	[Property(Animation)]
	private FAnimation as int

	[Property(Trajectory)]
	private FTrajectory as int

	[Property(Target)]
	private FTarget as int

	public def constructor():
		super()

[ItemType(TItemType.Armor)]
class TArmorTemplate(TEquipmentTemplate):
	pass

[ItemType(TItemType.Medicine)]
class TMedicineTemplate(TUsableItemTemplate):

	[Property(AreaEffect)]
	private FAreaMedicine as bool

	[Property(HPPercent)]
	private FHPPercent as byte

	[Property(MPPercent)]
	private FMPPercent as byte

	[Property(DeadOnly)]
	private FDeadHeroesOnly as bool

	[Property(OutOfBattle)]
	private FOutOfBattle as bool

	[Property(Conditions)]
	private FConditions = array(int, 0)

	public HPHeal as int:
		get: return FStat[1]
		set: FStat[1] = value

	public MPHeal as int:
		get: return FStat[2]
		set: FStat[2] = value

[ItemType(TItemType.Book)]
class TSkillBookTemplate(TUsableItemTemplate):

	[Property(Skill)]
	private FSkill as ushort

[ItemType(TItemType.Skill)]
class TSkillItemTemplate(TSkillBookTemplate):

	[Property(CustomSkillMessage)]
	private FCustomSkillMessage as bool

[ItemType(TItemType.Upgrade)]
class TStatItemTemplate(TUsableItemTemplate):
	pass

[ItemType(TItemType.Variable)]
class TVariableItemTemplate(TUsableItemTemplate):

	[Property(Which)]
	private FWhich as ushort

	[Property(Magnitude)]
	private FMagnitude as short

	[Property(Style)]
	private FStyle as TVarSets

	[Property(Operation)]
	private FOperation = TBinaryOp.Equals

[ItemType(TItemType.Script)]
class TScriptItemTemplate(TUsableItemTemplate):

	[Property(Event)]
	private FEvent as string
