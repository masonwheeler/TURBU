namespace turbu.terrain

import System

import Newtonsoft.Json.Linq
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

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Damage', FDamage)
		value.CheckRead('EncounterMultiplier', FEncounterMultiplier)
		value.CheckRead('BattleBG', FBattleBg)
		value.ReadArray('VehiclePass', FVehiclePass)
		value.CheckRead('AirshipLanding', FAirshipLanding)
		value.CheckReadEnum('Concealment', FConcealment)
		// the RM2K3 extras (damage sound, battle frames, special battle types) are not read yet
