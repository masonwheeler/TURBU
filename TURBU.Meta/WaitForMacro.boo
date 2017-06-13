import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro waitFor(cond as Expression):
	var cc = CompilerContext.Current
	var tcsName = ReferenceExpression(cc.GetUniqueName('tcs'))
	return [|
		var $tcsName = System.Threading.Tasks.TaskCompletionSource[of bool](GScriptEngine.value.CurrentObject)
		await GScriptEngine.value.WaitTask($tcsName, $cond)
	|]

[Meta]
def Wait(duration as Expression) as MethodInvocationExpression:
	return [|await(Sleep($duration))|]