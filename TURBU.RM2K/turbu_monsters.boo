namespace turbu.monsters

import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Threading.Tasks
import Newtonsoft.Json.Linq
import Pythia.Runtime
import TURBU.Meta
import SG.defs
import turbu.classes
import turbu.containers
import turbu.defs

enum TMonsterBehaviorAction:
	Attack
	DoubleAttack
	Defend
	Observe
	ChargeUp
	SelfDestruct
	Escape
	None

class TMonsterBehavior(TRpgDatafile):

	public def constructor(id as int):
		FId = id

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Priority', FPriority)
		value.CheckRead('SwitchOn', FSwitchOn)
		value.CheckRead('SwitchOff', FSwitchOff)
		value.CheckReadEnum('Action', FAction)
		value.CheckRead('Skill', FSkill)
		value.CheckRead('Transform', FTransform)
		item as JToken
		if value.TryGetValue('Requirement', item):
			var requirement = item cast JObject
			FRequirementName = requirement['Name'] cast string
			var args = requirement['Args'] cast JArray
			FRequirementArgs = array(int, args.Count)
			for i in range(args.Count):
				FRequirementArgs[i] = args[i] cast int
			value.Remove('Requirement')
		value.CheckEmpty()

	[Property(Priority)]
	private FPriority as int

	[Property(SwitchOn)]
	private FSwitchOn as int

	[Property(SwitchOff)]
	private FSwitchOff as int

	[Property(Action)]
	private FAction as TMonsterBehaviorAction

	[Property(Skill)]
	private FSkill as int

	[Property(Transform)]
	private FTransform as int

	[Property(Requirement)]
	private FRequirement as Func of bool

	[Property(RequirementName)]
	private FRequirementName as string

	[Property(RequirementArgs)]
	private FRequirementArgs as (int)

[TableName('Monsters')]
class TRpgMonster(TRpgDatafile):

	[Property(Filename)]
	protected FFilename as string

	[Property(Transparent)]
	protected FTransparent as bool

	[Property(Flying)]
	protected FFlying as bool

	[Property(ColorShift)]
	protected FColorShift as int

	[Property(Stats)]
	protected FStats as (int)

	[Property(Exp)]
	protected FExp as int

	[Property(Money)]
	protected FMoney as int

	[Property(Item)]
	protected FItem as int

	[Property(ItemChance)]
	protected FItemChance as int

	[Property(CanCrit)]
	protected FCanCrit as bool

	[Property(CritChance)]
	protected FCritChance as int

	[Property(OftenMiss)]
	protected FOftenMiss as bool

	[Property(Condition)]
	protected FConditions as (SgPoint)

	[Property(Resist)]
	protected FResists as (SgPoint)

	[Property(Behavior)]
	private FBehavior as (TMonsterBehavior)

	[Property(Tag)]
	protected FTag as (int)

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Filename', FFilename)
		value.CheckRead('Transparent', FTransparent)
		value.CheckRead('Flying', FFlying)
		value.CheckRead('ColorShift', FColorShift)
		value.ReadArray('Stats', FStats)
		value.CheckRead('Exp', FExp)
		value.CheckRead('Money', FMoney)
		value.CheckRead('Item', FItem)
		value.CheckRead('ItemChance', FItemChance)
		value.CheckRead('CanCrit', FCanCrit)
		value.CheckRead('CritChance', FCritChance)
		value.CheckRead('OftenMiss', FOftenMiss)
		FResists = ReadIndexed(value, 'Resist')
		FConditions = ReadIndexed(value, 'Condition')
		var behaviors = value['Behavior'] as JArray
		value.Remove('Behavior')
		FBehavior = array(TMonsterBehavior, (behaviors.Count if behaviors is not null else 0))
		for i in range(FBehavior.Length):
			FBehavior[i] = TMonsterBehavior(behaviors[i] cast JObject)
		value.ReadArray('Tag', FTag)
		value.CheckEmpty()

	private static def ReadIndexed(value as JObject, name as string) as (SgPoint):
		levels as (int)
		value.ReadArray(name, levels)
		result = array(SgPoint, (levels.Length if levels is not null else 0))
		for i in range(result.Length):
			result[i] = SgPoint(i + 1, levels[i])
		return result

class TRpgMonsterElement(TObject):

	[Getter(ID)]
	private FId as int

	[Getter(Monster)]
	private FMonster as int

	[Getter(Position)]
	private FPosition as SgPoint
	
	[Getter(Invisible)]
	private FInvisible as bool

	public def constructor(id as int, monster as int, position as SgPoint, invisible as bool):
		FId = id
		FMonster = monster
		FPosition = position
		FInvisible = invisible

	public def constructor(value as JObject):
		super()
		value.CheckRead('ID', FId)
		value.CheckRead('Monster', FMonster)
		value.CheckRead('Position', FPosition)
		value.CheckRead('Invisible', FInvisible)
		value.CheckEmpty()

class TPageCondition(TObject):

	[Getter(Kind)]
	private FKind as string

	[Getter(Args)]
	private FArgs as (int)

	public def constructor(kind as string, args as (int)):
		FKind = kind
		FArgs = args

	public def constructor(prop as JProperty):
		FKind = prop.Name
		var value = prop.Value
		caseOf value.Type:
			case JTokenType.Array:
				FArgs = value.Select({t | t cast int}).ToArray()
			case JTokenType.Object:
				//a variable that must be at least a given value: L is the variable, R the value
				FArgs = (value['L'] cast int, value['R'] cast int)
			default:
				FArgs = (value cast int,)

class TBattleEventPage(TObject):

	[Getter(ID)]
	protected FId as int

	[Property(Name)]
	protected FName as string

	[Property(Conditions)]
	protected FConditions as Func of bool

	[Property(Script)]
	protected FScript as Func of Task

	//all of these must hold for the page to run; none means that it runs at the start of the battle
	[Getter(Requirements)]
	protected FRequirements = array(TPageCondition, 0)

	public def constructor(id as int):
		super()
		FId = id

	public def constructor(value as JObject):
		super()
		value.CheckRead('ID', FId)
		value.CheckRead('Name', FName)
		var conditions = value['PageConditions'] as JObject
		if conditions is not null:
			FRequirements = conditions.Properties().Select({p | TPageCondition(p)}).ToArray()
			value.Remove('PageConditions')
		value.CheckEmpty()

[TableName('MonsterParties')]
class TRpgMonsterParty(TRpgDatafile):

	[Property(AutoAlign)]
	protected FAutoAlign as bool

	[Property(Random)]
	protected FRandom as bool

	[Property(Habitats)]
	protected FHabitats as (int)

	[Property(Monsters)]
	protected FMonsters = List[of TRpgMonsterElement]()

	[Property(Pages)]
	protected FPages = TRpgObjectList[of TBattleEventPage]()

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('AutoAlign', FAutoAlign)
		value.CheckRead('Random', FRandom)
		value.ReadArray('Habitats', FHabitats)
		var monsters = value['Monsters'] cast JArray
		value.Remove('Monsters')
		for monster in monsters.Cast[of JObject]():
			FMonsters.Add(TRpgMonsterElement(monster))
		var pages = value['Pages'] cast JArray
		value.Remove('Pages')
		for page in pages.Cast[of JObject]():
			FPages.Add(TBattleEventPage(page))
		value.CheckEmpty()
