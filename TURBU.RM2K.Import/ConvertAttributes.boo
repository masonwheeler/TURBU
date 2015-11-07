namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TAttributeConverter:
	def Convert(base as RMAttribute) as MacroStatement:
		result = [|
			Attribute $(base.ID):
				Name $(base.Name)
				Magic $(base.MagicAttribute)
				Damage $(base.RateA), $(base.RateB), $(base.RateC), $(base.RateD), $(base.RateE)
		|]
		return result