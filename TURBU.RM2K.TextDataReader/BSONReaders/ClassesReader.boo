namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

macro Classes:
	AddResource('Classes', JObject()) //so we don't end up with none at all

//TODO: Finish this when working on a test game that actually uses Classes
macro Classes.Class(index as int, body as Statement*):
	var result = PropertyList(index, body)
	AddResource('Classes', result)
