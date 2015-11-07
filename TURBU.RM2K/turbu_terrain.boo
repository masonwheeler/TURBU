namespace turbu.terrain

import turbu.classes
import turbu.sounds
import turbu.defs
import System
import Pythia.Runtime

[EnumSet]
enum SpecialBattleTypes:
	None = 0
	Initiative = 1
	Back = 2
	Side = 4
	Pincer = 8

[TableName('Terrains')]
class TRpgTerrain(TRpgDatafile):

	[Getter(Damage)]
	protected FDamage as int

	[Getter(EncounterMultiplier)]
	protected FEncounterMultiplier as int
	
	[Getter(BattleBG)]
	protected FBattleBg as string

	[Getter(VehiclePass)]
	protected FVehiclePass as (bool)

	[Getter(AirshipLanding)]
	protected FAirshipLanding as bool

	[Getter(Concealment)]
	protected FConcealment as TConcealmentFactor

	[Getter(SoundEffect)]
	protected FSoundEffect as TRpgSound

	[Getter(Frame)]
	protected FFrame as string
