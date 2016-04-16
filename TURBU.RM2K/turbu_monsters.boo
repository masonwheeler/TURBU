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

enum TMonsterBehaviorCondition:
	None
	Switch
	Turns
	MonstersPresent
	MonsterHP
	MonsterMP
	PartyLevel
	PartyExhaustion

enum TMonsterBehaviorAction:
	Attack
	DoubleAttack
	Defend
	Observe
	ChargeUp
	SelfDestruct
	Escape
	None

class TRpgMonster(TRpgDatafile):

	[Getter(Filename)]
	protected FFilename as string

	[Getter(Transparent)]
	protected FTransparent as bool

	[Getter(Flying)]
	protected FFlying as bool

	[Getter(ColorShift)]
	protected FColorShift as int

	protected FStats as (int)

	[Getter(Exp)]
	protected FExp as int

	[Getter(Money)]
	protected FMoney as int

	[Getter(Item)]
	protected FItem as int

	[Getter(ItemChance)]
	protected FItemChance as int

	[Getter(CanCrit)]
	protected FCanCrit as bool

	[Getter(CritChance)]
	protected FCritChance as int

	[Getter(OftenMiss)]
	protected FOftenMiss as bool

	[Getter(Condition)]
	protected FConditions as (Point)

	[Getter(Resist)]
	protected FResists as (Point)

	[Getter(Tag)]
	protected FTag as (int)

	protected def getStat(i as byte) as int:
		return FStats[i]

	public Stat[i as byte] as int:
		get:
			return getStat(i)

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
