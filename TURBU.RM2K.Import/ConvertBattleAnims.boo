namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TBattleAnimConverter:
	public def Convert(base as RM2K3AttackAnimation) as MacroStatement:
		result = [|
			BattleAnim $(base.ID):
				Name $(base.Name)
				Speed $(base.Speed)
				Poses
				Weapons
		|]
		result.SubMacro('Poses').Body.Statements.AddRange(base.Poses.Select({p | ConvertAttackData(p)}))
		result.SubMacro('Weapons').Body.Statements.AddRange(base.Weapons.Select({w | ConvertAttackData(w)}))
		return result
	
	private def ConvertAttackData(base as RM2K3AttackData) as MacroStatement:
		result = [|
			AnimData $(base.ID):
				Filename $(base.Filename)
				Frame $(base.Frame)
				AnimType $(base.AnimType)
				AnimNum $(base.AnimNum)
		|]
		return result