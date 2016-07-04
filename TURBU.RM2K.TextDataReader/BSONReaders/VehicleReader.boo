namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Vehicles:
	pass

macro Vehicles.Vehicle(index as int, body as Statement*):
	macro Sprite(name as string, id as int):
		Vehicle.Body.Add(JsonStatement(JProperty('MapSprite', name)))
		Vehicle.Body.Add(JsonStatement(JProperty('SpriteIndex', id)))
	
	macro Music(name as string, v1 as int, v2 as int, v3 as int, v4 as int):
		return JsonStatement(JProperty('Music', JArray(name, v1, v2, v3, v4)))
	
	var result = PropertyList(index, body)
	AddResource('Vehicles', result)