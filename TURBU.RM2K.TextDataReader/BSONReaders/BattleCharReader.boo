namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro BattleChars:
	pass

macro BattleChars.BattleAnim(index as int, body as Statement*):
	macro AnimData(index as int, body as Statement*):
		return JsonStatement(PropertyList(index, body))
	
	macro Poses(body as JsonStatement*):
		return MakeListValue('Poses', body)
	
	macro Weapons(body as JsonStatement*):
		return MakeListValue('Weapons', body)
	
	var result = PropertyList(index, body)
	AddResource('BattleChars', result)
