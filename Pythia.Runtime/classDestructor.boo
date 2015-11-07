namespace Pythia.Runtime

import Boo.Lang.Compiler.Ast

macro classDestructor:
	body = classDestructor.Body
	cls = body.GetAncestor of ClassDefinition()
	cdName = ReferenceExpression(Context.GetUniqueName(cls.Name, 'classDestructor'))
	field = Field(
		Name: Context.GetUniqueName('finalizer'),
		Type: SimpleTypeReference(cdName.Name),
		Initializer: [|$(cdName.CleanClone())(OnCleanup: $(BlockExpression(body)))|]
	)
	yield field
	yield [|
		private class $cdName:
			[Property(OnCleanup)]
			_onCleanup as Action
			
			def destructor():
				_onCleanup()
	|]
	