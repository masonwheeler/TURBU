namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Terrains:
	pass

macro Terrains.Terrain(index as int, body as Statement*):
	macro Vehicles(value as bool*):
		return JsonStatement(JProperty('VehiclePass', JArray(value)))
	
	var result = PropertyList(index, body)
	AddResource('Terrains', result)