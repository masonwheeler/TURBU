namespace Disharmony

import System
import Boo.Adt
import Boo.Lang.Compiler.Ast

macro DisharmonyImport:
	let StringType = SimpleTypeReference('string')
	args = DisharmonyImport.Arguments.ToArray()
	name = args[0] as ReferenceExpression
	importName = ReferenceExpression('Harmony' + name.Name)
	args = args[1:]
	noPublic = false
	if args.Length > 0 and args[0].Matches(ReferenceExpression('noPublic')):
		noPublic = true
		args = args[1:]
	returnType as TypeReference = null
	if args.Length > 0 and args[-1] isa ReferenceExpression:
		returnType = SimpleTypeReference((args[-1] cast ReferenceExpression).Name)
		args = args[:-1]
	importMethod = [|
		[DllImport('disharmony.dll', CallingConvention: CallingConvention.StdCall)]
		private static def $importName():
			pass
	|]
	unless noPublic:
		intfMethod = [|
			public def $name():
				pass
		|]
		intfCall = [|$importName()|]
		if returnType is null:
			intfMethod.Body.Add(ExpressionStatement(intfCall))
		else:
			intfMethod.ReturnType = returnType.CleanClone()
			intfMethod.Body.Add([|return $intfCall|])
	for tc as TryCastExpression in args:
		arg = ParameterDeclaration((tc.Target cast ReferenceExpression).Name, tc.Type)
		importArg = arg.CleanClone()
		if arg.Type.Matches(StringType):
			attr = Boo.Lang.Compiler.Ast.Attribute('MarshalAs')
			attr.Arguments.Add([|UnmanagedType.LPStr|])
			importArg.Attributes.Add(attr)
		importMethod.Parameters.Add(importArg)
		unless noPublic:
			intfMethod.Parameters.Add(arg)
			intfCall.Arguments.Add(tc.Target.CleanClone())
	importMethod.ReturnType = returnType
	yield importMethod
	yield intfMethod