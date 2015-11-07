namespace Pythia.Runtime

import System.Linq.Enumerable

class TObject:
	[Property(Metaclass, ProtectedSetter: true)]
	protected static _metaclass as TClass
	
	public ClassName as string:
		get: return self.GetType().Name

class TClass:
	[Getter(ClassName)]
	protected _className as string
	
	[Getter(ClassType)]
	protected _classType as System.Type
	
	def constructor():
		_className = 'TObject'

	private static ___instance = System.Collections.Generic.Dictionary[of System.Type, TClass]()
	
	public static def Instance[of T(TClass, constructor)]() as T:
		lock ___instance:
			unless ___instance.ContainsKey(T):
				___instance.Add(T, System.Activator.CreateInstance of T())
			return ___instance[T]
	
	protected def GetAttribute[of T(System.Attribute)]():
		return self.ClassType.GetCustomAttributes(T, true).FirstOrDefault() cast T

[Meta]
def classOf(cls as Boo.Lang.Compiler.Ast.ReferenceExpression) as Boo.Lang.Compiler.Ast.MethodInvocationExpression:
	unless cls.Name.EndsWith('Class'):
		cls.Name += 'Class'
	return [|TClass.Instance of $cls()|]