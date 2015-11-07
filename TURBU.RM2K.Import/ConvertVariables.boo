namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TVariableConverter:
	public def Convert(switches as RMVariable*, variables as RMVariable*) as Block:
		result = Block()
		swMacro = MacroStatement('Switches')
		result.Add(swMacro)
		for variable in switches.Where({v | not string.IsNullOrEmpty(v.Name)}):
			swMacro.Body.Add([|$(variable.ID) = $(variable.Name)|])
		varMacro = MacroStatement('Variables')
		result.Add(varMacro)
		for variable in variables.Where({v | not string.IsNullOrEmpty(v.Name)}):
			varMacro.Body.Add([|$(variable.ID) = $(variable.Name)|])
		return result
