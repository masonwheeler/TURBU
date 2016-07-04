namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Conditions:
	pass

macro Conditions.Condition(index as int, body as Statement*):
	macro Damage(values as int*):
		return JsonStatement(JProperty('Standard', JArray(values)))
	
	result = PropertyList(index, body)
	AddResource('Conditions', result)
