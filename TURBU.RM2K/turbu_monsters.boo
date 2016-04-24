namespace turbu.monsters

import System
import System.Collections.Generic
import System.Drawing
import Pythia.Runtime
import SG.defs
import turbu.classes
import turbu.containers
import turbu.defs
import TURBU.MapObjects

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

	[Property(Priority)]
	private FPriority as int

	[Property(Action)]
	private FAction as TMonsterBehaviorAction

	[Property(Skill)]
	private FSkill as int

	[Property(Requirement)]
	private FRequirement as Func of bool

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
	protected FConditions as (TSgPoint)

	[Property(Resist)]
	protected FResists as (TSgPoint)

	[Property(Behavior)]
	private FBehavior as (TMonsterBehavior)

	[Property(Tag)]
	protected FTag as (int)

class TRpgMonsterElement(TObject):

	[Getter(ID)]
	private FId as int

	[Getter(Monster)]
	private FMonster as int

	[Getter(Position)]
	private FPosition as TSgPoint
	
	[Getter(Invisible)]
	private FInvisible as bool

	public def constructor(id as int, monster as int, position as TSgPoint, invisible as bool):
		FId = id
		FMonster = monster
		FPosition = position
		FInvisible = invisible

class TBattleEventPage(TObject):

	[Getter(ID)]
	protected FID as int

	[Property(Name)]
	protected FName as string

	[Property(Conditions)]
	protected FConditions as Func of bool

	public def constructor(id as int):
		super()
		FID = id

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
