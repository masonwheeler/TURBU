namespace TURBU.Meta

import Boo.Lang.Compiler.Ast

internal class UntilStatement(CustomStatement):
	[Property(Cond)]
	_cond as Boo.Lang.Compiler.Ast.Expression
	
	def constructor(base as Expression):
		_cond = base	

internal class UntilChecker(DepthFirstVisitor):
	[Property(Bad)]
	_bad as bool = false
	
	override public def OnCustomStatement(node as CustomStatement):
		_bad = true if node isa UntilStatement			
			
	static def Validate(node as Node) as bool:
		visitor = UntilChecker()	
		visitor.Visit(node)
		return not visitor.Bad

macro repeat():
	macro until(arg as Expression):
		return UntilStatement(arg)
		
	body as Block = repeat.Body
	last = body.Statements.Last
	unless last isa UntilStatement:
		Context.Errors.Add(Compiler.CompilerError(last, 'Repeat statement must end with a Until statement'))
		return null
	body.Statements.Remove(last) 
	last = [|
		break if $((last as UntilStatement).Cond)
	|]
	body.Statements.Add(last)
	unless UntilChecker.Validate(body):
		Context.Errors.Add(Compiler.CompilerError(last, 'Until statement can only come at the end of a Repeat statement'))
		return null		
	return [|
		while true:
			$body
	|]