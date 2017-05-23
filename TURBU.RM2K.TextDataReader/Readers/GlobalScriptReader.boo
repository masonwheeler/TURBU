namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro GlobalScripts(body as TypeMemberStatement*):
	var result = [|
		class GlobalScripts(TURBU.DataReader.IGlobalScriptProvider):
			private _lookup = System.Collections.Generic.Dictionary[of int, System.Func[of System.Threading.Tasks.Task]]()
			
			public Value[x as int] as System.Func[of System.Threading.Tasks.Task]:
				get: 
					result as System.Func[of System.Threading.Tasks.Task]
					unless _lookup.TryGetValue(x, result):
						result = do(): pass
					return result
			
			def GetConditions(switch as int) as System.Func[of bool]:
				return ({return turbu.RM2K.environment.GEnvironment.value.Switch[switch]} if switch > 0 else {return true})
	|]
	var methods = body.Select({tm | tm.TypeMember}).ToArray()
	result.Members.AddRange(methods)
	var init = [|
		def constructor():
			pass
	|]
	var b = init.Body
	for m in methods:
		b.Add([| _lookup.Add($(m['ID'] cast int), $(ReferenceExpression(m.Name))) |])
	result.Members.Add(init)
	return TypeMemberStatement(result)

macro GlobalScripts.GlobalScript(id as int):
	var name = "GS$(id.ToString('D4'))"
	var result = [|
		internal def $name():
			$(GlobalScript.Body)
	|]
	result.Accept(ScriptProcessor())
	result['ID'] = id
	return TypeMemberStatement(result)
