namespace TURBU.Design.Optimizations

import System
import TURBU.Meta
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

class ConsecutiveImageOptimization(FastDepthFirstVisitor):
	
	private def IsImage(node as Statement) as bool:
		es = node as ExpressionStatement
		return false if es is null
		match es.Expression:
			case [|$_ = NewImage($_, $_, $_, $_, $_, $_, $_)|]:
				return true
			otherwise: return false
	
	override def OnBlock(node as Block):
		return if node.ParentNode isa MacroStatement and (node.ParentNode as MacroStatement).Name == 'RenderPause'
		repeat:
			loop = false
			for i as int, child as Statement in enumerate(node.Statements.ToArray()[:-1]):
				if IsImage(child) and IsImage(node.Statements[i + 1]):
					j = i + 2
					++j while j < node.Statements.Count and IsImage(node.Statements[j])
					pause = MacroStatement('RenderPause')
					for iter in range(i, j):
						pause.Body.Add(node.Statements[i])
						node.Statements.RemoveAt(i)
					node.Statements.Insert(i, pause)
					loop = true
					break
			until loop == false