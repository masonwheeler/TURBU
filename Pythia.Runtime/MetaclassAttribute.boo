namespace Pythia.Runtime

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

class MetaclassAttribute(AbstractAstAttribute):
	_singletonType as ClassDefinition
	_singletonLock as ReferenceExpression = [|___singletonLock|]
	_base as string
	_baseType as TypeofExpression

	def constructor(baseClass as GenericReferenceExpression):
		_base = baseClass.ToString()
		_baseType = TypeofExpression(Type: GenericTypeReference(baseClass.Target.ToString(), GenericArguments: baseClass.GenericArguments))

	def constructor(baseClass as ReferenceExpression):
		_base = baseClass.Name
		_baseType = TypeofExpression(Type: SimpleTypeReference(_base))

	override def Apply(node as Node):
		assert node isa ClassDefinition

		_singletonType = node as ClassDefinition

		MakeConstructor()

	private def MakeConstructor():
		for member in _singletonType.Members:
			ctor = member as Constructor

			if ctor is not null:
				ctorFound = true

		assert not ctorFound
		ctor = Constructor(
			LexicalInfo: LexicalInfo,
			Modifiers: TypeMemberModifiers.Public)
		ctor.Body.Add(ExpressionStatement([|_className = $_base|]))
		ctor.Body.Add(ExpressionStatement([|_classType = $_baseType|]))
		_singletonType.Members.Add(ctor)
