namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF
import turbu.terrain

static class TTerrainConverter:
	def Convert(base as RMTerrain, is2k3 as bool) as MacroStatement:
		result = [|
			Terrain $(base.ID):
				Name $(base.Name)
				Damage $(base.Damage)
				EncounterMultiplier $(base.EncounterMultiplier)
				BattleBG $(base.BattleBG)
				Concealment $(ReferenceExpression(Enum.GetName(turbu.defs.TConcealmentFactor, base.Concealment)))
				Vehicles $(base.BoatPass), $(base.ShipPass), $(base.AirshipPass)
				AirshipLanding $(base.AirshipLanding)
		|]
		if is2k3:
			if base.DamageSound and base.SoundEffect is not null:
				result.Body.Add(TMusicConverter.Convert(base.SoundEffect, 'DamageSound'))
			if base.BGAssociation > 0:
				extraData as Block = [|
					Grid $(base.GridPosition), $(base.GridValue1), $(base.GridValue2), $(base.GridValue3)
					Frame1 $(base.Frame1), $(base.Frame1ScrollXSpeed if base.Frame1ScrollX else 0), \
							 $(base.Frame1ScrollYSpeed if base.Frame1ScrollY else 0)
				|]
				if base.UseFrame2:
					extraData.Add([|Frame2 $(base.Frame2), $(base.Frame2ScrollXSpeed if base.Frame2ScrollX else 0), \
							 $(base.Frame2ScrollYSpeed if base.Frame2ScrollY else 0)|])
				result.Body.Add(extraData)
				battleTypes as SpecialBattleTypes = base.SpecialFlags
				result.Body.Add([|Initiative $(base.Initiative)|]) if SpecialBattleTypes.Initiative in battleTypes
				result.Body.Add([|BackAttack $(base.BackAttack)|]) if SpecialBattleTypes.Back in battleTypes
				result.Body.Add([|SideAttack $(base.SideAttack)|]) if SpecialBattleTypes.Side in battleTypes
				result.Body.Add([|PincerAttack $(base.PincerAttack)|]) if SpecialBattleTypes.Pincer in battleTypes
		return result
