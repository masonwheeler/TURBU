namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TVehicleConverter:
	public def Convert(base as RMSystemRecord) as MacroStatement:
		result = [|
			Vehicles:
				Vehicle 1:
					Name 'Boat'
					Sprite $(base.BoatGraphic), $(base.BoatIndex)
					Translucent false
					ShallowWater true
					MovementStyle Surface
					$(TMusicConverter.Convert(base.BoatMusic, 'Music'))
				Vehicle 2:
					Name 'Ship'
					Sprite $(base.ShipGraphic), $(base.ShipIndex)
					Translucent false
					DeepWater true
					MovementStyle Surface
					$(TMusicConverter.Convert(base.ShipMusic, 'Music'))
				Vehicle 3:
					Name 'Airship'
					Sprite $(base.AirshipGraphic), $(base.AirshipIndex)
					Translucent false
					MovementStyle Fly
					$(TMusicConverter.Convert(base.AirshipMusic, 'Music'))
		|]
		return result
