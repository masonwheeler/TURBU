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

	[Getter(id)]
	protected FID as int

	[Getter(conditions)]
	protected FConditions = TBattleEventConditions()

	[Getter(eventText)]
	protected FEventText as string

	public def constructor():
		super()

class TBattleEventList(TRpgObjectList[of TBattleEventPage]):
	pass

class TMonsterElementList(List[of TRpgMonsterElement]):
	pass

/*
[Pythia.Attributes.DelphiClass]
class HabitatUploadAttribute(TDBUploadAttribute):

	public override def upload(db as DataTable, field as TRttiField, instance as TObject):
		db.FieldByName('habitats').AsBytes = (instance cast TRpgMonsterParty).FHabitats

	public override def download(db as DataTable, field as TRttiField, instance as TObject):
		(instance cast TRpgMonsterParty).FHabitats = db.FieldByName('habitats').AsBytes
*/

[TableName('MonsterParties')]
class TRpgMonsterParty(TRpgDatafile):

	[Getter(AutoAlign)]
	protected FAutoAlign as bool

	[Getter(Random)]
	protected FRandom as bool

	[Getter(Habitats)]
	protected FHabitats as (byte)

	[Getter(Monsters)]
	protected FMonsters = TMonsterElementList()

	[Getter(Events)]
	protected FEvents = TBattleEventList()

	public def constructor():
		super()
