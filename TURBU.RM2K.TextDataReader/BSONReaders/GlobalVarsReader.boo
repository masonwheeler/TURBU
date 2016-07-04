namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Newtonsoft.Json.Linq

macro GlobalVars(body as Statement*):
	var result = PropertyList(body)
	AddResource('Variables', result)

macro GlobalVars.Switches(body as ExpressionStatement*):
	return JsonStatement(JProperty('Switches', body.Count))
	
macro GlobalVars.Variables(body as ExpressionStatement*):
	return JsonStatement(JProperty('Variables', body.Count))
