namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Commands:
	pass

macro Commands.Command(index as int, body as Statement*):
	var result = PropertyList(index, body)
	AddResource('Commands', result)
