namespace Pythia.Runtime

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

class EnumSetAttribute(AbstractAstAttribute):
	
	override def Apply(node as Node):
		eNode = node as EnumDefinition
		assert eNode is not null
		eNode.Attributes.Add(Attribute('Flags'))
		mod = node.GetAncestor[of Module]()
		
		inOperator = [|
			[Boo.Lang.Compiler.Extension]
			static def op_Member(left as $(SimpleTypeReference(eNode.Name)), right as $(SimpleTypeReference(eNode.Name))) as bool:
				return left & right != $(ReferenceExpression(eNode.Name)).None
		|]
		inOperator.LexicalInfo = node.LexicalInfo
		mod.Members.Add(inOperator)
		
		values = [|
			[Boo.Lang.Compiler.Extension]
			static def Values(base as $(SimpleTypeReference(eNode.Name))) as $(SimpleTypeReference(eNode.Name))*:
				for value as $(SimpleTypeReference(eNode.Name)) in Enum.GetValues($(ReferenceExpression(eNode.Name))):
					if value in base:
						yield value
		|]
		mod.Members.Add(values)
