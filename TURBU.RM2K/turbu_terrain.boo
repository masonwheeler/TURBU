namespace turbu.terrain

import System

import Pythia.Runtime
import turbu.classes
import turbu.defs
import turbu.sounds

[EnumSet]
enum SpecialBattleTypes:
	None = 0
	Initiative = 1
	Back = 2
	Side = 4
	Pincer = 8

[TableName('Terrains')]
class TRpgTerrain(TRpgDatafile):

	[Property(Damage)]
	protected FDamage as int

	[Property(EncounterMultiplier)]
	protected FEncounterMultiplier as int
	
	[Property(BattleBG)]
	protected FBattleBg as string

	[Property(VehiclePass)]
	protected FVehiclePass as (bool)

	[Property(AirshipLanding)]
	protected FAirshipLanding as bool

	[Property(Concealment)]
	protected FConcealment as TConcealmentFactor

	[Property(SoundEffect)]
	protected FSoundEffect as TRpgSound

	[Property(Frame)]
	protected FFrame as string
