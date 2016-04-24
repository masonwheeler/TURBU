namespace TURBU.Design.Optimizations

import System
import Boo.Lang.Compiler.Ast

class IfFalseFlipper(FastDepthFirstVisitor):
	
	override def OnIfStatement(node as IfStatement):
		if node.TrueBlock.IsEmpty and node.FalseBlock is not null and node.FalseBlock.Statements.Count > 0:
			node.TrueBlock = node.FalseBlock
			node.FalseBlock = null
			node.Condition = Invert(node.Condition)
		super(node)
	
	private def Invert(cond as Expression):
		bl = cond as BoolLiteralExpression
		if bl is not null:
			bl.Value = not bl.Value
			return bl
		ue = cond as UnaryExpression
		if ue is not null and ue.Operator == UnaryOperatorType.LogicalNot:
			return ue.Operand
		be = cond as BinaryExpression
		if be is not null and be.Operator == BinaryOperatorType.Equality:
			bl = be.Right as BoolLiteralExpression
			if bl is not null:
				bl.Value = not bl.Value
				return cond
		return [|not $cond|]