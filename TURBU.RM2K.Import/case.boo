namespace TURBU.Meta

import System.Collections.Generic
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro caseOf(caseValue as Expression):
	private struct CaseBlock:
		[Property(Expr)]
		_expr as Expression
		[Property(Body)]
		_body as Block
	
	private static def MakeIf(name as string, data as CaseBlock) as IfStatement:
		result = IfStatement(data.Expr.LexicalInfo)
		if data.Expr isa ListLiteralExpression:
			result.Condition = [| $(ReferenceExpression(name)) in $(data.Expr) |]
		else: result.Condition = [| $(ReferenceExpression(name)) == $(data.Expr) |]
		result.TrueBlock = data.Body
		return result
	
	macro case(args as Expression*):
		if args.Count == 0:
			Context.Errors.Add(CompilerError(case, 'Each case label must have at least one argument'))
			return
		caseList = caseOf['List'] as List[of CaseBlock]
		if not caseList:
			caseOf['List'] = caseList = List[of CaseBlock]()
		expr as Expression
		if args.Count == 1:
			expr = args[0]
		else:
			ll = ListLiteralExpression()
			expr = ll
			ll.Items.AddRange(args)
		caseList.Add(CaseBlock(Expr: expr, Body: case.Body))
	
	macro default:
		caseOf['default'] = default.Body
	
	caseList = caseOf['List'] as List[of CaseBlock]
	if caseList is null:
		Context.Errors.Add(CompilerError(caseOf, 'At least one case must be specified'))
		return
	
	unless caseOf.Body.IsEmpty:
		Context.Errors.Add(CompilerError(caseOf, 'Body must only contain case and default blocks'))
		return
	
	result = Block(caseOf.LexicalInfo)
	temp = Context.GetUniqueName('caseVar')
	result.Add([| $(ReferenceExpression(temp)) = $caseValue|])
	tail = MakeIf(temp, caseList[0])
	result.Add(tail)
	caseList.RemoveAt(0)
	for block in caseList:
		newCase = MakeIf(temp, block)
		tail.FalseBlock = Block((newCase))
		tail = newCase
	
	defaultCase = caseOf['default'] as Statement
	if(defaultCase):
		tail.FalseBlock = Block((defaultCase))
	
	return result