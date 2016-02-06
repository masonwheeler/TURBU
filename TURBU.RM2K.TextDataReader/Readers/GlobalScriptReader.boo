namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro GlobalScripts(body as TypeMemberStatement*):
	YieldAll body.Select({tm | tm.TypeMember})

macro GlobalScripts.GlobalScript(id as int):
	name = "GS$(id.ToString('D4'))"
	result = [|
		internal def $name():
			$(GlobalScript.Body)
	|]
	result.Accept(ScriptProcessor())
	return TypeMemberStatement(result)