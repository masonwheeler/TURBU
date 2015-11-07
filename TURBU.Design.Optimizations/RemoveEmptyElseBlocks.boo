namespace TURBU.Design.Optimizations

import System
import Boo.Lang.Compiler.Ast

class RemoveEmptyElseBlocks(FastDepthFirstVisitor):
	override public def OnIfStatement(node as IfStatement):
		node.FalseBlock = null if node.FalseBlock is not null and node.FalseBlock.IsEmpty
		super(node)
