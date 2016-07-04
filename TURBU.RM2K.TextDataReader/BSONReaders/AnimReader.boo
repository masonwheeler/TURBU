namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Animations:
	macro Color(r as int, g as int, b as int, sat as int):
		return JsonStatement(JProperty('Color', JArray(r, g, b, sat)))

macro Animations.Animation(index as int, body as Statement*):
	macro CellSize(w as int, h as int):
		return JsonStatement(JProperty('CellSize', JArray(h, w)))
	
	var result = PropertyList(index, body)
	AddResource('Animations', result)

macro Animations.Animation.Frames(body as JsonStatement*):
	macro Cell(frameID as int, cellID as int, body as Statement*):
		macro Position(x as int, y as int):
			return JsonStatement(JProperty('Position', JArray(x, y)))
		
		var result = PropertyList(cellID, body)
		result['Frame'] = frameID
		return JsonStatement(result)
	
	return MakeListValue('Frames', body)

macro Animations.Animation.Effects(body as JsonStatement*):
	macro Effect(frameID as int, ID as int, body as Statement*):
		result = PropertyList(ID, body)
		result['Frame'] = frameID
		return JsonStatement(result)
	
	return MakeListValue('Effects', body)