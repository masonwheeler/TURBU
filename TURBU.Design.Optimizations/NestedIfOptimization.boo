namespace TURBU.Design.Optimizations

import System
import Boo.Lang.Compiler.Ast

class NestedIfOptimization(FastDepthFirstVisitor):
	
	override def OnIfStatement(node as IfStatement):
		while node.FalseBlock is null and node.TrueBlock.Statements.Count == 1:
			ifs = node.TrueBlock.FirstStatement as IfStatement
			break if ifs is null or ifs.FalseBlock is not null
			node.TrueBlock = ifs.TrueBlock
			node.FalseBlock = null
			node.Condition = [|$(node.Condition) and $(ifs.Condition)|]
		super(node)