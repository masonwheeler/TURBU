namespace TURBU.RM2K.TextDataReader

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

class FixNegativeNumbers(AbstractTransformerCompilerStep):
	override def OnUnaryExpression(node as UnaryExpression):
		if node.Operator == UnaryOperatorType.UnaryNegation and node.Operand.NodeType == NodeType.IntegerLiteralExpression:
			il = node.Operand as IntegerLiteralExpression
			il.Value = il.Value * -1
			ReplaceCurrentNode(il)
		else: super.OnUnaryExpression(node)

