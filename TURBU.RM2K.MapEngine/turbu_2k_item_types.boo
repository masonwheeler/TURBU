namespace turbu.RM2K.Item.types

import System
import turbu.items
import turbu.constants
import turbu.defs
import turbu.RM2K.items
import turbu.Heroes
import turbu.RM2K.skills
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import TURBU.Meta

class TJunkItem(TRpgItem):

	protected override def GetOnField() as bool:
		return false

	public override def UsableBy(hero as int) as bool:
		return false

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TEquipment(TRpgItem):

	protected override def GetOnField() as bool:
		return false

	public override def UsableBy(hero as int) as bool:
		return hero in (Template cast TUsableItemTemplate).UsableByHero

	public Attack as short:
		get: return (Template cast TEquipmentTemplate).Stats[2]

	public Defense as short:
		get: return (Template cast TEquipmentTemplate).Stats[3]

	public Mind as short:
		get: return (Template cast TEquipmentTemplate).Stats[4]

	public Speed as short:
		get: return (Template cast TEquipmentTemplate).Stats[5]

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

abstract class TAppliedItem(TRpgItem):

	protected override def GetOnField() as bool:
		return true

	public override def UsableBy(hero as int) as bool:
		return UsableByHypothetical(hero)

	public override def UsableByHypothetical(hero as int) as bool:
		uit = Template cast TUsableItemTemplate
		result = hero in uit.UsableByHero
		caseOf uit.UsableWhere:
			case TUsableWhere.None:
				result = false
			case TUsableWhere.Field:
				result = result and (GSpriteEngine.value.State != TGameState.Battle)
			case TUsableWhere.Battle:
				result = result and (GSpriteEngine.value.State == TGameState.Battle)
			case TUsableWhere.Both:
				pass
		return result

	public UsableArea as bool:
		get:
			result = false
			for i in range(1, MAXPARTYSIZE + 1):
				if GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
					result = result or UsableBy(GEnvironment.value.Party[i].Template.ID)
			return result

	public virtual def AreaItem() as bool:
		return (Template cast TMedicineTemplate).AreaEffect

	public virtual def Use(target as TRpgHero):
		self.UseOnce() unless self.AreaItem()

	public def UseArea():
		for i in range(1, MAXPARTYSIZE + 1):
			if GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
				self.Use(GEnvironment.value.Party[i])
		self.UseOnce()

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TRecoveryItem(TAppliedItem):

	public override def UsableBy(hero as int) as bool:
		result = false
		return result unless super.UsableBy(hero)
		var med = self.Template cast TMedicineTemplate
		if med.HPPercent > 0 or med.HPHeal > 0:
			result = result or GEnvironment.value.Party[hero].HP < GEnvironment.value.Party[hero].MaxHp
		if med.MPPercent > 0 or med.MPHeal > 0:
			result = result or GEnvironment.value.Party[hero].MP < GEnvironment.value.Party[hero].MaxMp
		if GEnvironment.value.Heroes[hero].Dead:
			result = result and (CTN_DEAD in med.Conditions)
		elif med.DeadOnly:
			result = false
		return result

	public override def Use(target as TRpgHero):
		fraction as single
		var med = Template cast TMedicineTemplate
		for i in med.Conditions:
			target.Condition[i] = false
		if med.HPPercent != 0:
			fraction = med.HPPercent / 100.0
			target.HP += Math.Truncate(target.MaxHp * fraction)
		if med.MPPercent != 0:
			fraction = med.MPPercent / 100.0
			target.MP += Math.Truncate(target.MaxMp * fraction)
		target.HP += med.HPHeal
		target.MP += med.MPHeal
		super.Use(target)

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TBookItem(TAppliedItem):

	public override def UsableBy(hero as int) as bool:
		return super.UsableBy(hero) and (not GEnvironment.value.Heroes[hero].Skill[(Template cast TSkillBookTemplate).Skill])

	public override def Use(target as TRpgHero):
		target.Skill[(Template cast TSkillBookTemplate).Skill] = true
		super.Use(target)

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TStatItem(TAppliedItem):

	public override def UsableBy(hero as int) as bool:
		result = false
		if not super.UsableBy(hero):
			return result
		//TODO: Check for other conditions here
		return result

	public override def Use(target as TRpgHero):
		target.MaxHp += (Template cast TUsableItemTemplate).Stats[0]
		target.MaxMp += (Template cast TUsableItemTemplate).Stats[1]
		target.Attack += (Template cast TUsableItemTemplate).Stats[2]
		target.Defense += (Template cast TUsableItemTemplate).Stats[3]
		target.Mind += (Template cast TUsableItemTemplate).Stats[4]
		target.Agility += (Template cast TUsableItemTemplate).Stats[5]
		super.Use(target)

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TSkillItem(TAppliedItem):

	[Getter(Skill)]
	private FSkill as TRpgSkill

	protected override def GetOnField() as bool:
		return (FSkill.Template.Usable == TUsableWhere.Field)

	public def constructor(Item as int, Quantity as int):
		super(Item, Quantity)
		FSkill = TRpgSkill((Template cast TSkillItemTemplate).Skill)

	public override def UsableBy(hero as int) as bool:
		return super.UsableBy(hero) and FSkill.UsableOn(hero)

	public override def AreaItem() as bool:
		return FSkill.AreaSkill

	public override def Use(target as TRpgHero):
		FSkill.UseHero(target, target)
		super.Use(target)

class TSwitchItem(TRpgItem):

	protected override def GetOnField() as bool:
		return (Template cast TUsableItemTemplate).UsableWhere in (TUsableWhere.Field, TUsableWhere.Both)

	public override def UsableBy(hero as int) as bool:
		return false

	public def Use():
		GEnvironment.value.Switch[(Template cast TVariableItemTemplate).Which] = true
		self.UseOnce()

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

