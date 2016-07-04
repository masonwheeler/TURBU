namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Newtonsoft.Json.Linq

macro GlobalEvents:
	pass

macro GlobalEvents.Script(id as int, body as Statement*):
	macro Switch(id as int):
		return JsonStatement(JProperty('Switch', id))
	
	var result = PropertyList(id, body)
	AddResource('GlobalScript', result)
