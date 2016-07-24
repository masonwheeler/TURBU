namespace turbu.items

import System
import System.Linq.Enumerable

import Newtonsoft.Json.Linq
import Pythia.Runtime
import turbu.operators
import turbu.defs
import turbu.classes
import TURBU.Meta

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

	[Getter(ItemType)]
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

	public def constructor(value as JObject):
		super(value)
		value.CheckReadEnum('AnimType', FAnimType)
		value.CheckRead('Weapon', FWhichWeapon)
		value.CheckReadEnum('MovementMode', FMovementMode)
		value.CheckRead('AfterImage', FAfterimage)
		value.CheckRead('AttackNum', FAttackNum)
		value.CheckRead('Ranged', FRanged)
		value.CheckRead('RangedProjectile', FRangedProjectile)
		value.CheckRead('RangedSpeed', FRangedSpeed)
		value.CheckRead('BattleAnim', FBattleAnim)
		value.CheckEmpty()

[TableName('Items')]
class TItemTemplate(TRpgDatafile):

	static def Create(value as JObject) as TItemTemplate:
		it as TItemType
		value.CheckReadEnum('ItemType', it)
		caseOf it:
			case TItemType.Junk:
				return TJunkTemplate(value)
			case TItemType.Weapon:
				return TWeaponTemplate(value)
			case TItemType.Armor:
				return TArmorTemplate(value)
			case TItemType.Medicine:
				return TMedicineTemplate(value)
			case TItemType.Book:
				return TSkillBookTemplate(value)
			case TItemType.Skill:
				return TSkillBookTemplate(value)
			case TItemType.Upgrade:
				return TStatItemTemplate(value)
			case TItemType.Variable:
				return TVariableItemTemplate(value)
			case TItemType.Script:
				return TScriptItemTemplate(value)
			default: raise "Unknown item type: $it"

	[Property(Desc)]
	private FDescription as string

	[Property(Cost)]
	private FCost as int

	[Property(Tag)]
	private FTag as (int)

	public def constructor():
		super()
	
	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Desc', FDescription)
		value.CheckRead('Cost', FCost)
		value.ReadArray('Tag', FTag)

	public ItemType as TItemType:
		get:
			att as ItemTypeAttribute = self.GetType().GetCustomAttributes(ItemTypeAttribute, true).SingleOrDefault()
			raise Exception("No ItemTypeAttr found on $(self.ClassName).") unless assigned(att)
			return att.ItemType

[ItemType(TItemType.Junk)]
class TJunkTemplate(TItemTemplate):
	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckEmpty()

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

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('UsesLeft', FUsesLeft)
		value.CheckReadEnum('Usable', FUsableWhere)
		value.ReadArray('UsableByHero', FUsableByHero)
		value.ReadArray('UsableByClass', FUsableByClass)
		value.ReadArray('Stats', FStat)

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
	protected FAttributes as (int)

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Evasion', FEvasion)
		value.CheckRead('ToHit', FToHit)
		value.CheckRead('CritChance', FCritChance)
		value.CheckRead('CritPrevent', FCritPrevent)
		value.CheckRead('Preemptive', FPreemptive)
		value.CheckRead('MpReduction', FMpReduction)
		value.CheckRead('NoTerrainDamage', FNoTerrainDamage)
		value.ReadArray('Condition', FConditions)
		value.CheckRead('Skill', FSkill)
		value.CheckRead('InvokeSkill', FInvokeSkill)
		value.CheckRead('Cursed', FCursed)
		value.CheckRead('InflictReversed', FInflictReversed)
		value.CheckReadEnum('Slot', FSlot)
		value.ReadArray('Attributes', FAttributes)

[ItemType(TItemType.Weapon)]
class TWeaponTemplate(TEquipmentTemplate):

	[Property(TwoHanded)]
	private FTwoHanded as bool

	[Property(AttackTwice)]
	private FAttackTwice as bool

	[Property(AreaHit)]
	private FAreaHit as bool

	[Property(BattleAnim)]
	private FBattleAnim as int

	[Property(MpCost)]
	private FMPCost as int

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

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('TwoHanded', FTwoHanded)
		value.CheckRead('AttackTwice', FAttackTwice)
		value.CheckRead('AreaHit', FAreaHit)
		value.CheckRead('BattleAnim', FBattleAnim)
		value.CheckRead('MpCost', FMPCost)
		value.CheckRead('ConditionChance', FConditionChance)
		var ad = value['AnimData'] cast JArray
		if assigned(ad):
			value.Remove('AnimData')
			Array.Resize[of TWeaponAnimData](FAnimData, ad.Count)
			for i in range(ad.Count):
				FAnimData[i] = TWeaponAnimData(ad[i] cast JObject)
		value.CheckRead('Animation', FAnimation)
		value.CheckRead('Trajectory', FTrajectory)
		value.CheckRead('Target', FTarget)
		value.CheckEmpty()

[ItemType(TItemType.Armor)]
class TArmorTemplate(TEquipmentTemplate):
	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckEmpty()

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

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('HPHeal', FStat[0])
		value.CheckRead('MPHeal', FStat[1])
		value.CheckRead('AreaEffect', FAreaMedicine)
		value.CheckRead('HPPercent', FHPPercent)
		value.CheckRead('MPPercent', FMPPercent)
		value.CheckRead('DeadOnly', FDeadHeroesOnly)
		value.CheckRead('OutOfBattle', FOutOfBattle)
		value.ReadArray('Conditions', FConditions)
		value.CheckEmpty()

	public HPHeal as int:
		get: return FStat[0]
		set: FStat[0] = value

	public MPHeal as int:
		get: return FStat[1]
		set: FStat[1] = value

[ItemType(TItemType.Book)]
class TSkillBookTemplate(TUsableItemTemplate):

	[Property(Skill)]
	private FSkill as int

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Skill', FSkill)
		value.CheckEmpty()

[ItemType(TItemType.Skill)]
class TSkillItemTemplate(TSkillBookTemplate):

	[Property(CustomSkillMessage)]
	private FCustomSkillMessage as bool

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('CustomSkillMessage', FCustomSkillMessage)
		value.CheckEmpty()

[ItemType(TItemType.Upgrade)]
class TStatItemTemplate(TUsableItemTemplate):
	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckEmpty()

[ItemType(TItemType.Variable)]
class TVariableItemTemplate(TUsableItemTemplate):

	[Property(Which)]
	private FWhich as int

	[Property(Magnitude)]
	private FMagnitude as int

	[Property(Style)]
	private FStyle as TVarSets

	[Property(Operation)]
	private FOperation = TBinaryOp.Equals

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Which', FWhich)
		value.CheckRead('Magnitude', FMagnitude)
		value.CheckReadEnum('Style', FStyle)
		value.CheckReadEnum('Operation', FOperation)
		value.CheckEmpty()

[ItemType(TItemType.Script)]
class TScriptItemTemplate(TUsableItemTemplate):

	[Property(Event)]
	private FEvent as string

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Event', FEvent)
		value.CheckEmpty()
