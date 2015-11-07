namespace turbu.RM2K.Item.types

import System
import turbu.items
import turbu.constants
import turbu.defs
import TURBU.RM2K
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
		get: return (Template cast TEquipmentTemplate).Stat[2]

	public Defense as short:
		get: return (Template cast TEquipmentTemplate).Stat[3]

	public Mind as short:
		get: return (Template cast TEquipmentTemplate).Stat[4]

	public Speed as short:
		get: return (Template cast TEquipmentTemplate).Stat[5]

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
		return (Template cast TMedicineTemplate).AreaMedicine

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
		med as TMedicineTemplate
		result = false
		return result unless super.UsableBy(hero)
		med = self.Template cast TMedicineTemplate
		if med.HpPercent > 0 or med.HpHeal > 0:
			result = result or GEnvironment.value.Party[hero].HP < GEnvironment.value.Party[hero].MaxHp
		if med.MpPercent > 0 or med.MpHeal > 0:
			result = result or GEnvironment.value.Party[hero].MP < GEnvironment.value.Party[hero].MaxMp
		if GEnvironment.value.Heroes[hero].Dead:
			result = result and (CTN_DEAD in med.Condition)
		elif med.DeadOnly:
			result = false
		return result

	public override def Use(target as TRpgHero):
		med as TMedicineTemplate
		fraction as single
		med = Template cast TMedicineTemplate
		for i in range(1, GDatabase.value.Conditions.Count):
			if i in med.Condition:
				target.Condition[i] = false
		if med.HpPercent != 0:
			fraction = (med.HpPercent cast double) / 100.0
			target.HP += Math.Truncate(target.MaxHp * fraction)
		if med.MpPercent != 0:
			fraction = (med.MpPercent cast double) / 100.0
			target.MP += Math.Truncate(target.MaxMp * fraction)
		target.HP += med.HpHeal
		target.MP += med.MpHeal
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
		target.MaxHp += (Template cast TUsableItemTemplate).Stat[0]
		target.MaxMp += (Template cast TUsableItemTemplate).Stat[1]
		target.Attack += (Template cast TUsableItemTemplate).Stat[2]
		target.Defense += (Template cast TUsableItemTemplate).Stat[3]
		target.Mind += (Template cast TUsableItemTemplate).Stat[4]
		target.Agility += (Template cast TUsableItemTemplate).Stat[5]
		super.Use(target)

	def constructor(Item as int, Quantity as int):
		super(Item, Quantity)

class TSkillItem(TAppliedItem):

	[Getter(Skill)]
	private FSkill as TRpgSkill

	protected override def GetOnField() as bool:
		return (FSkill.Template.UsableWhere == TUsableWhere.Field)

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

