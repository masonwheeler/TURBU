namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TMusicConverter:
	public def Convert(music as RMMusic, prefix as string) as MacroStatement:
		result = MacroStatement(prefix)
		result.Arguments.AddRange((Expression.Lift(music.Filename), Expression.Lift(music.FadeIn),
			Expression.Lift(music.Volume), Expression.Lift(music.Tempo), Expression.Lift(music.Balance)))
		return result
