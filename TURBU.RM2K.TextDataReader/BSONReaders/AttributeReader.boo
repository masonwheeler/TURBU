namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Attributes:
	pass

macro Attributes.Attribute(index as int, body as Statement*):
	macro Damage(values as int*):
		return JsonStatement(JProperty('Standard', JArray(values)))
	
	var result = PropertyList(index, body)
	AddResource('Attributes', result)
