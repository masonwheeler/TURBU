namespace TURBU.Meta

import Boo.Lang.Compiler.Ast

macro repeat():
	internal class UntilStatement(Boo.Lang.Compiler.Ast.CustomStatement):
		[Property(Cond)]
		_cond as Boo.Lang.Compiler.Ast.Expression
		
		def constructor(base as Expression):
			_cond = base	
	
	internal class UntilChecker(Boo.Lang.Compiler.Ast.DepthFirstVisitor):
		[Property(Bad)]
		_bad as bool = false
		
		override public def OnCustomStatement(node as CustomStatement):
			_bad = true if node isa UntilStatement			
				
		static def Validate(node as Node) as bool:
			visitor = UntilChecker()	
			visitor.Visit(node)
			return not visitor.Bad
	
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