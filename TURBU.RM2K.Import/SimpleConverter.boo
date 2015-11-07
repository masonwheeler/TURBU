namespace TURBU.RM2K.Import

import Boo.Lang.Compiler.Ast

macro simpleConverter(name as ReferenceExpression):
	private class LocalScanner(Boo.Lang.Compiler.Ast.FastDepthFirstVisitor):
		[Getter(Name)]
		_name as bool
		
		[Getter(Values)]
		_values as bool
		
		[Getter(Result)]
		_result as bool
		
		override def OnReferenceExpression(node as ReferenceExpression):
			if node.Name == 'name':
				_name = true
			elif node.Name == 'values':
				_values = true
			elif node.Name == 'result':
				_result = true
		
		override def OnQuasiquoteExpression(node as QuasiquoteExpression):
			Visit(node.Node)
	
	result = [|
		private static def $name(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
			$(simpleConverter.Body)
			return null
	|]
	ls = LocalScanner()
	simpleConverter.Body.Accept(ls)
	if ls.Name:
		result.Body.Insert(0, ExpressionStatement([|name = ec.Name|]))
	if ls.Values:
		result.Body.Insert(0, ExpressionStatement([|values = ec.Data|]))
	if ls.Result:
		result.Body.Insert(0, DeclarationStatement(Declaration('result', SimpleTypeReference('Expression')), null))
		result.Body.Insert(result.Body.Statements.Count - 1, ExpressionStatement([|parent.Add(result)|]))
	yield result
