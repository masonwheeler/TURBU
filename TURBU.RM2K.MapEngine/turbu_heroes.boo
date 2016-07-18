namespace turbu.Heroes

import turbu.classes
import turbu.defs
import turbu.characters
import turbu.constants
import TURBU.RM2K
import commons
import turbu.items
import turbu.skills
import turbu.pathing
import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import System.Linq.Enumerable
import turbu.mapchars
import turbu.map.sprites
import turbu.RM2K.items
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import turbu.RM2K.Item.types
import System.Drawing
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import TURBU.Meta
import SG.defs

enum TStatComponents:
	Base
	Bonus
	EqMod

class TRpgBattleCharacter(TRpgObject):
	
	static protected random = System.Random()
	
	def constructor(base as TRpgDatafile):
		super(base)

	[Property(Name)]
	protected FName as string

	protected FHitPoints as int

	protected FManaPoints as int

	protected FConditionModifier as (int)

	protected FCondition as (bool)

	protected FStat = matrix[of int](4, TStatComponents.EqMod + 1)

	protected FMaxHitPoints as int

	protected FMaxManaPoints as int

	protected FDtypeModifiers as (int)

	protected abstract def SetHP(value as int):
		pass

	protected abstract def SetMP(value as int):
		pass

	protected def GetCondition(x as int) as bool:
		return (FCondition[x] if x in range(1, FCondition.Length) else false)

	protected def GetHighCondition() as int:
		highCond = range(1, FCondition.Length).Where({i | FCondition[i]}).Select({i | GDatabase.value.Conditions[i]}).\
			OrderByDescending({c | c.Priority}).ThenByDescending({c | c.ID}).FirstOrDefault()
		return (0 if highCond is null else highCond.ID)

	protected def SetCondition(x as int, value as bool):
		if (x == CTN_DEAD) and (value == true):
			self.Die()
		elif x in range(1, FCondition.Length):
			FCondition[x] = value

	protected def Die():
		FCondition[CTN_DEAD] = true
		FHitPoints = 0

	protected def GetStat(which as int) as int:
		result = 0
		for i in range(TStatComponents.EqMod + 1):
			result += FStat[which - 1, i]
		return Math.Max(result, 0)

	protected def SetStat(which as int, value as int):
		FStat[which - 1, TStatComponents.Bonus] += self.Stat[which - 1] - value

	protected virtual def GetMHp() as int:
		return FMaxHitPoints

	protected virtual def GetMMp() as int:
		return FMaxManaPoints

	protected virtual def SetMaxHp(value as int):
		FMaxHitPoints = value

	protected virtual def SetMaxMp(value as int):
		FManaPoints = value

	public virtual def TakeDamage(power as int, pDefense as int, mDefense as int, variance as int) as int:
		defFactor as int = round(((self.Defense * pDefense) cast double) / 400.0)
		mDefFactor as int = round(((self.Mind * mDefense) cast double) / 800.0)
		variance *= 5
		power = round(((power * random.Next(100 - variance, 100 + variance)) cast double) / 100.0)
		power = Math.Max(power - (defFactor + mDefFactor), 1)
		HP -= power
		return power

	public def CanAct() as bool:
		assert false, 'Battle engine is not supported yet'

	[NoImport]
	public abstract def Retarget() as TRpgBattleCharacter:
		pass

	public HP as int:
		get:
			return FHitPoints
		set:
			SetHP(value)

	public MP as int:
		get:
			return FManaPoints
		set:
			SetMP(value)

	public MaxHp as int:
		get:
			return GetMHp()
		set:
			SetMaxHp(value)

	public MaxMp as int:
		get:
			return GetMMp()
		set:
			SetMaxMp(value)

	public Stat[x as int] as int:
		get: return GetStat(x)
		set: SetStat(x, value)

	public Attack as int:
		get: return GetStat(1)
		set: SetStat(1, value)

	public Defense as int:
		get: return GetStat(2)
		set: SetStat(2, value)

	public Mind as int:
		get: return GetStat(3)
		set: SetStat(3, value)

	public Agility as int:
		get: return GetStat(4)
		set: SetStat(4, value)

class TRpgHero(TRpgBattleCharacter):

	private static FLevelScripts = Dictionary[of string, TExpCalcEvent]()

	[Property(Title)]
	private FClass as string = ''

	[Getter(Sprite)]
	private FSprite as string = ''

	[Getter(SpriteIndex)]
	private FSpriteIndex as int

	private FTransparent as bool

	private FLevel as int

	private FCritRate as int

	private FFaceName as string = ''

	private FFaceNum as int

	internal FParty as TRpgParty

	[Getter(DualWield)]
	private FDualWield as TWeaponStyle

	private FStaticEq as bool

	[Getter(AIControlled)]
	private FComputerControlled as bool

	[Getter(StrongDefense)]
	private FStrongDefense as bool

	private FExpTable as (int)

	private FExpTotal as int

	private FEquipment = array(TRpgItem, 5)

	private FHpModifier as int

	private FMpModifier as int

	private FSkill as (bool)

	private FBattleCommands = List[of int]()

	private FLevelUpdated as bool

	private def CountSkills() as int:
		return FSkill.Skip(1).Count({s | return s})

	private def GainLevel():
		++FLevel
		LevelAdjustUp(FLevel - 1)

	private def GetEquipment(which as TSlot) as int:
		return (FEquipment[which].Template.ID if assigned(FEquipment[which]) else 0)

	private def GetExpNeeded() as int:
		return (-1 if FLevel == (Template cast THeroTemplate).MaxLevel else FExpTable[(FLevel + 1)] - FExpTotal)

	private def GetLevelUpdatedStatus() as bool:
		result = FLevelUpdated
		FLevelUpdated = false
		return result

	private def GetSkill(id as int) as bool:
		return (FSkill[id] if (id > 0) and (id < FSkill.Length) else false)

	private def LevelAdjustDown(before as int):
		base = Template cast THeroTemplate
		for skill in base.Skillset[1:]:
			if (skill.Style == TSkillFuncStyle.Level) and ((skill.Nums[1] > FLevel) and (skill.Nums[1] <= before)):
				FSkill[skill.ID] = false
		LevelStatAdjust()

	private def LevelAdjustUp(before as int):
		base = Template cast THeroTemplate
		for skill in base.Skillset[1:]:
			if (skill.Style == TSkillFuncStyle.Level) and ((skill.Nums[1] <= FLevel) and (skill.Nums[1] > before)):
				FSkill[skill.ID] = true
		LevelStatAdjust()

	private def LevelStatAdjust():
		base = Template cast THeroTemplate
		return if base.ID == 0
		FMaxHitPoints = base.StatBlocks[STAT_HP].Block[FLevel - 1]
		FMaxManaPoints = base.StatBlocks[STAT_MP].Block[FLevel - 1]
		FStat[0, TStatComponents.Base] = base.StatBlocks[STAT_STR].Block[FLevel - 1]
		FStat[1, TStatComponents.Base] = base.StatBlocks[STAT_DEF].Block[FLevel - 1]
		FStat[2, TStatComponents.Base] = base.StatBlocks[STAT_MIND].Block[FLevel - 1]
		FStat[3, TStatComponents.Base] = base.StatBlocks[STAT_AGI].Block[FLevel - 1]

	private def LoseLevel():
		--FLevel
		LevelAdjustDown(FLevel + 1)

	private def SetExp(value as int):
		FExpTotal = clamp(value, 0, MAXEXP)
		if FLevel < MAXLEVEL:
			if ExpNeeded <= 0:
				UpdateLevel(true)
			elif ExpNeeded > (FExpTable[(FLevel + 1)] - FExpTable[FLevel]):
				UpdateLevel(false)

	private def SetLevel(value as int):
		return if FLevel == value
		increasing as bool = FLevel < value
		oldlevel as int = FLevel
		FLevel = clamp(value, 0, MAXLEVEL)
		FExpTotal = FExpTable[FLevel]
		if increasing:
			LevelAdjustUp(oldlevel)
		else: LevelAdjustDown(oldlevel)

	private def SetSkill(id as int, value as bool):
		if (id > 0) and (id < FSkill.Length):
			FSkill[id] = value

	private def SetTransparent(value as bool):
		FTransparent = value
		if FParty[1] == self:
			party as TCharSprite = GSpriteEngine.value.CurrentParty
			party.Translucency = (3 if value else 0)
			party.Update(FSprite, value, FSpriteIndex)

	private def UpdateLevel(gain as bool):
		FLevelUpdated = true
		caseOf gain:
			case true:
				assert FExpTotal >= FExpTable[FLevel + 1]
				repeat:
					GainLevel()
					until FExpTotal < FExpTable[FLevel + 1]
			case false:
				assert FExpTotal <= FExpTable[FLevel]
				repeat:
					LoseLevel()
					until FExpTotal >= FExpTable[FLevel]

	private def GetTemplate() as TClassTemplate:
		return super.Template cast TClassTemplate

	private def GetSkillCommand() as string:
		return GDatabase.value.Command[self.Template.Command[2]].Name

	protected override def GetMHp() as int:
		result = FMaxHitPoints + FHpModifier
		if result < 1:
			FHpModifier -= result + 1
			result = 1
		return result

	protected override def GetMMp() as int:
		result = (FMaxManaPoints + FMpModifier)
		if result < 0:
			FMpModifier -= result
			result = 0
		return result

	protected override def SetMaxHp(value as int):
		FHpModifier += value - self.MaxHp

	protected override def SetMaxMp(value as int):
		FMpModifier += value - self.MaxMp

	protected override def SetHP(value as int):
		return if FCondition[CTN_DEAD]
		FHitPoints = Math.Max(value, 0)
		if FHitPoints == 0:
			if FParty.DeathPossible == true:
				self.Die()
			else: ++FHitPoints
		elif FHitPoints > self.MaxHp:
			FHitPoints = MaxHp

	protected override def SetMP(value as int):
		return if FCondition[CTN_DEAD]
		FManaPoints = value
		if FManaPoints < 0:
			FManaPoints = 0
		elif FManaPoints > self.MaxMp:
			FManaPoints = MaxMp

	[NoImport]
	public def constructor(base as TClassTemplate, party as TRpgParty):
		calc as TExpCalcEvent
		var template = base cast THeroTemplate
		super(base)
		return if base is null
		FParty = party
		FName = template.Name
		FClass = GDatabase.value.Classes[template.CharClass].Name
		FSprite = template.MapSprite
		FSpriteIndex = template.SpriteIndex
		FTransparent = template.Translucent
		Array.Resize[of int](FExpTable, Math.Max(template.MaxLevel, 1) + 1)
		if FLevelScripts.TryGetValue(template.ExpMethod, calc):
			for i in range(2, FExpTable.Length):
				FExpTable[i] = calc(i, template.ExpVars[0], template.ExpVars[1], template.ExpVars[2], template.ExpVars[3])
		FCritRate = (template.CritRate if template.CanCrit else 0)
		FFaceName = template.Portrait
		FFaceNum = template.PortraitIndex
		FDualWield = template.DualWield
		FStaticEq = template.StaticEq
		Array.Resize[of bool](FSkill, GDatabase.value.Skill.Count + 1)
		FLevel = 1
		self.LevelAdjustUp(0)
		Level = template.MinLevel
		FExpTotal = FExpTable[FLevel]
		for slot in range(FEquipment.Length):
			self.Equip(template.Eq[slot]) unless template.Eq[slot] == 0
		i = GDatabase.value.Conditions.Count
		Array.Resize[of int](FConditionModifier, i)
		Array.Resize[of bool](FCondition, i)
		for i in range(0, template.Condition.Length):
			cond as Point = template.Condition[i]
			FConditionModifier[cond.X] = cond.Y
		FHitPoints = MaxHp
		FManaPoints = MaxMp
		FComputerControlled = template.Guest
		FStrongDefense = template.StrongDef

	[NoImport]
	public def Serialize(writer as JsonWriter):
		base as THeroTemplate = self.Template cast THeroTemplate
		writeJsonObject writer:
			writer.CheckWrite('Name', FName, base.Name)
			writer.CheckWrite('Class', FClass, base.ClsName)
			writer.CheckWrite('Sprite', FSprite, base.MapSprite)
			writer.CheckWrite('SpriteIndex', FSpriteIndex, base.SpriteIndex)
			writer.CheckWrite('Transparent', FTransparent, base.Translucent)
			writer.CheckWrite('Level', FLevel, base.MinLevel)
			writer.CheckWrite('FaceName', FFaceName, base.Portrait)
			writer.CheckWrite('FaceNum', FFaceNum, base.PortraitIndex)
			writer.CheckWrite('ExpTotal', FExpTotal, 0)
			writer.WritePropertyName('Equipment')
			writeJsonArray writer:
				for slot in range(FEquipment.Length):
					if FEquipment[slot] == null:
						writer.WriteNull()
					else:
						writer.WriteValue(FEquipment[slot].ID)
			writer.WritePropertyName('Stat')
			writeJsonArray writer:
				for i in range(4):
					writer.WriteValue(FStat[i, TStatComponents.Bonus])
			writer.WritePropertyName('Condition')
			writeJsonArray writer:
				for i in range(1, FCondition.Length):
					if FCondition[i]:
						writer.WriteValue(i)
			writer.CheckWrite('HitPoints', FHitPoints, 0)
			writer.CheckWrite('ManaPoints', FManaPoints, 0)
			writer.CheckWrite('HpModifier', FHpModifier, 0)
			writer.CheckWrite('MpModifier', FMpModifier, 0)
			writer.WriteArray('Skill', FSkill)

	[NoImport]
	public def Deserialize(obj as JObject):
		obj.CheckRead('Name', FName)
		obj.CheckRead('Class', FClass)
		obj.CheckRead('Sprite', FSprite)
		obj.CheckRead('SpriteIndex', FSpriteIndex)
		obj.CheckRead('Transparent', FTransparent)
		obj.CheckRead('Level', FLevel)
		obj.CheckRead('FaceName', FFaceName)
		obj.CheckRead('FaceNum', FFaceNum)
		obj.CheckRead('ExpTotal', FExpTotal)
		obj.CheckRead('HitPoints', FHitPoints)
		obj.CheckRead('ManaPoints', FManaPoints)
		obj.CheckRead('HpModifier', FHpModifier)
		obj.CheckRead('MpModifier', FMpModifier)
		arr = (obj['Equipment'] cast JArray)
		for slot in range(FEquipment.Length):
			if arr[slot].Type == JTokenType.Null:
				self.Unequip(slot)
			else:
				self.EquipSlot(arr[slot] cast int, slot)
		obj.Remove('Equipment')
		arr = obj['Stat'] cast JArray
		for i in range(4):
			FStat[i, TStatComponents.Bonus] = arr[i] cast int
		obj.Remove('Stat')
		arr = obj['Condition'] cast JArray
		for i in range(0, arr.Count):
			FCondition[arr[i] cast int] = true
		obj.Remove('Condition')
		obj.ReadArray('Skill', FSkill)
		obj.CheckEmpty()

	[NoImport]
	public static def RegisterExpFunc(Name as string, routine as TExpCalcEvent):
		FLevelScripts.Add(Name, routine)

	public def Equip([Lookup('Items')] id as int):
		theItem as TRpgItem
		dummy as TItemType
		slot as TSlot
		return unless IsBetween(id, 0, GDatabase.value.Items.Count)
		theItem = TRpgItem.NewItem(id, 1)
		template = theItem.Template as TEquipmentTemplate
		return unless assigned(template) and (Template.ID in template.UsableByHero)
		dummy = theItem.Template.ItemType
		if (dummy == TItemType.Weapon) and (theItem.Template cast TWeaponTemplate).TwoHanded:
			Unequip(TSlot.Weapon)
			Unequip(TSlot.Shield)
			FEquipment[TSlot.Weapon] = theItem
			FEquipment[TSlot.Shield] = theItem
		else:
			slot = template.Slot
			Unequip(slot)
			FEquipment[slot] = theItem
		FParty.Inventory.Remove(id, 1)
		eq = theItem cast TEquipment
		FStat[0, TStatComponents.EqMod] += eq.Attack
		FStat[1, TStatComponents.EqMod] += eq.Defense
		FStat[2, TStatComponents.EqMod] += eq.Mind
		FStat[3, TStatComponents.EqMod] += eq.Speed

	public def EquipSlot(id as int, slot as TSlot):
		theItem as TRpgItem
		itemType as TItemType
		theItem = TRpgItem.NewItem(id, 1)
		assert theItem isa TEquipment
		itemType = theItem.Template.ItemType
		template = theItem.Template as TEquipmentTemplate
		return unless (assigned(template) and (self.Template.ID in template.UsableByHero))
		if (itemType == TItemType.Weapon) and (theItem.Template cast TWeaponTemplate).TwoHanded:
			Unequip(TSlot.Weapon)
			Unequip(TSlot.Shield)
			FEquipment[TSlot.Weapon] = theItem
			FEquipment[TSlot.Shield] = theItem
		else:
			Unequip(slot)
			FEquipment[slot] = theItem
		GEnvironment.value.Party.Inventory.Remove(id, 1)
		eq = theItem cast TEquipment
		FStat[0, TStatComponents.EqMod] += eq.Attack
		FStat[1, TStatComponents.EqMod] += eq.Defense
		FStat[2, TStatComponents.EqMod] += eq.Mind
		FStat[3, TStatComponents.EqMod] += eq.Speed

	public def Unequip(slot as TSlot):
		if FEquipment[slot] != null:
			FParty.Inventory.AddItem(FEquipment[slot])
			eq = FEquipment[slot] cast TEquipment
			FStat[0, TStatComponents.EqMod] -= eq.Attack
			FStat[1, TStatComponents.EqMod] -= eq.Defense
			FStat[2, TStatComponents.EqMod] -= eq.Mind
			FStat[3, TStatComponents.EqMod] -= eq.Speed
			if (slot in (TSlot.Weapon, TSlot.Shield)) and (FEquipment[slot].Template as TWeaponTemplate)?.TwoHanded:
				FEquipment[TSlot.Weapon] = null
				FEquipment[TSlot.Shield] = null
			else: FEquipment[slot] = null

	public def UnequipAll():
		for slot in range(FEquipment.Length):
			Unequip(slot)

	public def Equipped([Lookup('Items')] id as int) as bool:
		result = false
		for i as TSlot in range(FEquipment.Length):
			if (FEquipment[i] != null) and (FEquipment[i].Template.ID == id):
				result = true
		return result

	public def FullHeal():
		FHitPoints = FMaxHitPoints
		FManaPoints = FMaxManaPoints
		for i in range(1, FCondition.Length):
			FCondition[i] = false

	public override def TakeDamage(power as int, pDefense as int, mDefense as int, Variance as int) as int:
		FParty.DeathPossible = true
		return super.TakeDamage(power, pDefense, mDefense, Variance)

	[NoImport]
	public override def Retarget() as TRpgBattleCharacter:
		repeat :
			result = FParty[random.Next(FParty.Party.Length)]
			until assigned(result) and (result.HP > 0)
		return result

	public def SetSprite(filename as string, translucent as bool, spriteIndex as int):
		return unless ArchiveUtils.GraphicExists(filename, 'Sprites')
		FSprite = filename
		FSpriteIndex = spriteIndex
		FTransparent = translucent
		if FParty[1] == self:
			FParty.ChangeSprite(System.IO.Path.GetFileNameWithoutExtension(filename), translucent, FSpriteIndex)

	public def SetPortrait(filename as string, index as int):
		return unless index in range(1, 17)
		return unless ArchiveUtils.GraphicExists(filename, 'Portraits')
		FFaceName = filename
		FFaceNum = index
		GSpriteEngine.value.Images.EnsureImage('Portraits\\' + filename, filename, PORTRAIT_SIZE)

	public def InParty() as bool:
		return FParty.Any({h | h == self})

	public def PotentialStat(item as int, whichStat as int, slot as TSlot) as int:
		theItem as TItemTemplate = GDatabase.value.Items[item]
		assert item == 0 or theItem.ItemType in (TItemType.Weapon, TItemType.Armor)
		result = self.Stat[whichStat]
		if self.FEquipment[slot] != null:
			result -= (FEquipment[slot].Template cast TUsableItemTemplate).Stats[whichStat + 1]
		if item != 0:
			result += (theItem cast TUsableItemTemplate).Stats[whichStat + 1]
			if assigned(theItem) and (theItem.ItemType == TItemType.Weapon) and \
					(theItem cast TWeaponTemplate).TwoHanded and (FEquipment[2 - ord(slot)] != null):
				result -= (FEquipment[2 - ord(slot)].Template cast TUsableItemTemplate).Stats[whichStat + 1]
		return result

	public def ChangeHP(quantity as int, deathPossible as bool):
		FParty.DeathPossible = deathPossible
		SetHP(FHitPoints + quantity)

	public def ChangeMP(quantity as int):
		SetMP(FManaPoints + quantity)

	public def ChangeClass(id as int, retainLevel as bool, skillChange as int, statChange as int, showMessage as bool):
		pass
		//TODO: Implement this

	public def AddBattleCommand(which as int):
		if not FBattleCommands.Contains(which):
			FBattleCommands.Add(which)

	public def RemoveBattleCommand(which as int):
		FBattleCommands.Remove(which)

	public Transparent as bool:
		get: return FTransparent
		set: SetTransparent(value)

	public Level as int:
		get: return FLevel
		set: SetLevel(value)

	public Exp as int:
		get: return FExpTotal
		set: SetExp(value)

	public Equipment[x as TSlot] as int:
		get: return GetEquipment(x)

	public ExpNeeded as int:
		get: return GetExpNeeded()

	public LevelUpdated as bool:
		get:
			return GetLevelUpdatedStatus()

	public Skill[x as int] as bool:
		get: return GetSkill(x)
		set: SetSkill(x, value)

	public Skills as int:
		get: return CountSkills()

	[Lookup('Conditions')]
	public Condition[x as int] as bool:
		get: return GetCondition(x)
		set: SetCondition(x, value)

	public Dead as bool:
		get: return GetCondition(1)

	public HighCondition as int:
		get: return GetHighCondition()

	public Template as TClassTemplate:
		get: return GetTemplate()

	public SkillCommand as string:
		get: return GetSkillCommand()

class TRpgParty(TRpgCharacter, IEnumerable of TRpgHero):

	[Property(Money)]
	private FCash as int

	[Getter(Party)]
	private FParty as (TRpgHero)

	[Property(Inventory)]
	private FInventory as TRpgInventory

	[Getter(Sprite)]
	private FSprite as TMapSprite

	[Property(LevelNotify)]
	private FLevelNotify as bool

	[Property(DeathPossible)]
	private FDeathPossible as bool

	private def GetMap() as int:
		if assigned(GSpriteEngine.value):
			result = GSpriteEngine.value.MapID
		else:
			result = 0
		return result

	private def SetY(value as int):
		if assigned(FSprite):
			place = FSprite.Location
			FSprite.Location = sgPoint(place.x, value)

	private def SetX(value as int):
		if assigned(FSprite):
			place = FSprite.Location
			FSprite.Location = sgPoint(value, place.y)

	private Empty as bool:
		get:
			result = true
			for i in range(1, MAXPARTYSIZE + 1):
				if self[i] != GEnvironment.value.Heroes[0]:
					result = false
			return result

	private def GetTFacing() as TDirections:
		return FSprite.Facing

	private def First() as TRpgHero:
		var result = self.FirstOrDefault({h | h != GEnvironment.value.Heroes[0]})
		return (result if assigned(result) else self[1])

	protected override def GetX() as int:
		return (FSprite.Location.x if assigned(FSprite) else 0)

	protected override def GetY() as int:
		return (FSprite.Location.y if assigned(FSprite) else 0)

	protected override def GetTranslucency() as int:
		return (0 if self.Empty else super.GetTranslucency())

	protected override def SetTranslucency(value as int):
		super.SetTranslucency(value) unless self.Empty

	protected override def DoFlash(r as int, g as int, b as int, power as int, time as int):
		if assigned(GSpriteEngine.value.CurrentParty):
			GSpriteEngine.value.CurrentParty.Flash(r, g, b, power, time)

	protected override def GetBase() as TMapSprite:
		return FSprite

	[NoImport]
	public def constructor():
		FParty = array(TRpgHero, MAXPARTYSIZE)
		FInventory = TRpgInventory()
		FLevelNotify = true

	[NoImport]
	public def Serialize(writer as JsonWriter):
		i as int
		writeJsonObject writer:
			writer.WritePropertyName('Heroes')
			writeJsonArray writer:
				for i in range(MAXPARTYSIZE):
					if assigned(FParty[i]):
						writer.WriteValue(FParty[i].Template.ID)
					else:
						writer.WriteNull()
			writer.CheckWrite('Cash', FCash, 0)
			writer.WritePropertyName('Inventory')
			FInventory.Serialize(writer)
			writer.WritePropertyName('X')
			writer.WriteValue(GetX())
			writer.WritePropertyName('Y')
			writer.WriteValue(GetY())
			writer.WritePropertyName('Facing')
			writer.WriteValue(FacingValue)
			if assigned(FSprite.MoveOrder):
				writer.WritePropertyName('Path')
				FSprite.MoveOrder.Serialize(writer)
			writer.CheckWrite('MoveFreq', FSprite.MoveFreq, 1)
			writer.CheckWrite('MoveRate', FSprite.MoveRate, 1)

	[NoImport]
	public def Deserialize(obj as JObject):
		value as JToken
		value = obj['Heroes']
		for i in range(MAXPARTYSIZE):
			if value[i].Type == JTokenType.Null:
				self[i + 1] = null
			else:
				self[i + 1] = GEnvironment.value.Heroes[value[i] cast int]
		obj.Remove('Heroes')
		obj.CheckRead('Cash', FCash)
		value = obj['Inventory']
		FInventory.Deserialize(value cast JArray)
		obj.Remove('Inventory')
		value = obj['X']
		SetX(value cast int)
		obj.Remove('X')
		value = obj['Y']
		SetY(value cast int)
		obj.Remove('Y')
		value = obj['Facing']
		self.FacingValue = value cast int
		obj.Remove('Facing')
		value = obj['Path']
		if assigned(value):
			FSprite.MoveOrder = Path(value cast JObject)
			obj.Remove('Path')
		value = obj['MoveFreq']
		if assigned(value):
			FSprite.MoveFreq = value cast int
			obj.Remove('MoveFreq')
		value = obj['MoveRate']
		if assigned(value):
			FSprite.MoveRate = value cast int
			obj.Remove('MoveRate')
		obj.CheckEmpty()

	public def AddItem(id as int, number as int):
		FInventory.Add(id, number)

	public def RemoveItem(id as int, number as int):
		FInventory.Remove(id, number)

	public def HasItem([Lookup('Items')] id as int) as bool:
		result = self.Inventory.Contains(id)
		return result or FParty.Where({c | assigned(c)}).Any({c | c.Equipped(id)})

	public def AddExp(id as int, number as int):
		hero as TRpgHero
		if id == -1:
			for i in range(1, MAXPARTYSIZE + 1):
				if self[i] != GEnvironment.value.Heroes[0]:
					hero = GEnvironment.value.Heroes[self[i].Template.ID]
					hero.Exp += number
		else:
			self[id].Exp += number

	public def RemoveExp(id as int, number as int):
		hero as TRpgHero
		if id == -1:
			for i in range(1, MAXPARTYSIZE + 1):
				if self[i] != GEnvironment.value.Heroes[0]:
					hero = GEnvironment.value.Heroes[self[i].Template.ID]
					hero.Exp -= number
		else:
			self[id].Exp -= number

	public def AddLevels(id as int, number as int):
		hero as TRpgHero
		if id == -1:
			for i in range(1, (MAXPARTYSIZE + 1)):
				if self[i] != GEnvironment.value.Heroes[0]:
					hero = GEnvironment.value.Heroes[self[i].Template.ID]
					hero.Level += number
		else:
			self[id].Level += number

	public def RemoveLevels(id as int, number as int):
		hero as TRpgHero
		if id == -1:
			for i in range(1, (MAXPARTYSIZE + 1)):
				if self[i] != GEnvironment.value.Heroes[0]:
					hero = GEnvironment.value.Heroes[self[i].Template.ID]
					hero.Level = (hero.Level - number)
		else:
			self[id].Level = (self[id].Level - number)

	[NoImport]
	public def Pack():
		for i in range(MAXPARTYSIZE - 1):
			for j in range(i, MAXPARTYSIZE - 1):
				if FParty[j] == null:
					FParty[j] = FParty[j + 1]
					FParty[j + 1] = null

	[NoImport]
	public override def ChangeSprite(name as string, translucent as bool, spriteIndex as int):
		if assigned(FSprite):
			FSprite.Update(name, translucent, spriteIndex)

	[NoImport]
	public def SetSprite(value as TMapSprite):
		FSprite = value

	public def ResetSprite():
		h1 as TRpgHero = self.First()
		commons.runThreadsafe(true, { self.ChangeSprite(h1.Sprite, h1.Transparent, h1.SpriteIndex) })

	public def TakeDamage(power as int, pDefense as int, mDefense as int, Variance as int) as int:
		result = 0
		for i in range(1, MAXPARTYSIZE + 1):
			if self[i] != GEnvironment.value.Heroes[0]:
				result += FParty[i].TakeDamage(power, pDefense, mDefense, Variance)
		return result

	public OpenSlot as int:
		get:
			i = 1
			while (self[i] != GEnvironment.value.Heroes[0]) and (i <= MAXPARTYSIZE):
				++i
			result = (0 if i > MAXPARTYSIZE else i)
			return result

	public Size as int:
		get:
			result = 0
			for i in range(1, MAXPARTYSIZE + 1):
				++result if self[i] != GEnvironment.value.Heroes[0]
			return result

	public def IndexOf(who as TRpgHero) as int:
		var result = -1
		for i in range(1, MAXPARTYSIZE + 1):
			result = i if self[i] == who
		return result

	public self[x as int] as TRpgHero:
		get:
			result = (GEnvironment.value.Heroes[0] if ((x == 0) or (x >= MAXPARTYSIZE)) or (FParty[x - 1] == null) else FParty[x - 1])
			return result
		set:
			return if (x == 0) or (x > MAXPARTYSIZE)
			FParty[x - 1] = value
			value.FParty = self if assigned(value)
			ResetSprite()

	public FacingValue as int:
		get:
			result = 0
			caseOf FSprite.Facing:
				case TDirections.Up: result = 8
				case TDirections.Right: result = 6
				case TDirections.Down: result = 2
				case TDirections.Left: result = 4
			return result
		set:
			caseOf value:
				case 8: FSprite.Facing = TDirections.Up
				case 6: FSprite.Facing = TDirections.Right
				case 4: FSprite.Facing = TDirections.Left
				case 2: FSprite.Facing = TDirections.Down

	public Facing as TDirections:
		get: return GetTFacing()

	public XPos as int:
		get: return GetX()
		set: SetX(value)

	public YPos as int:
		get: return GetY()
		set: SetY(value)

	public MapID as int:
		get: return GetMap()
	
	def System.Collections.IEnumerable.GetEnumerator():
		return TPartyEnumerator(FParty)
	
	def GetEnumerator():
		return TPartyEnumerator(FParty)
	
	private class TPartyEnumerator(IEnumerator of TRpgHero):
		private FHeroes as (TRpgHero)
		
		private FIndex = -1
		
		def constructor(value as (TRpgHero)):
			FHeroes = value
		
		def MoveNext() as bool:
			repeat:
				++FIndex
				until FIndex >= FHeroes.Length or FHeroes[FIndex] is not null
			return FIndex < FHeroes.Length
		
		def Reset():
			FIndex = -1
		
		def IDisposable.Dispose():
			pass
		
		Current as TRpgHero:
			get: return FHeroes[FIndex]
		
		System.Collections.IEnumerator.Current as object:
			get: return FHeroes[FIndex]

let CTN_DEAD = 1
let WEAPON_SLOT = 0;
let SHIELD_SLOT = 1;
let ARMOR_SLOT = 2;
let HELMET_SLOT = 3;
let RELIC_SLOT = 4;

let STAT_HP = 0;
let STAT_MP = 1;
let STAT_STR = 2;
let STAT_DEF = 3;
let STAT_MIND = 4;
let STAT_AGI = 5;
