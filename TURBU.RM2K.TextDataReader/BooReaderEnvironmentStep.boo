namespace TURBU.RM2K.TextDataReader

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Reflection
import Boo.Lang.Environments
import Boo.Lang.Interpreter

class BooReaderEnvironmentNamespace(AbstractInterpreter.InterpreterNamespace):
	private _environment as object
	
	[Getter(EnvType)]
	private _envType as ExternalType
	
	private _entities = Dictionary[of string, IEntity]()
	
	public def constructor(env as object, parent as INamespace):
		super(null, null, parent)
		_environment = env
		type = env.GetType()
		while type != typeof(object):
			envType = My[of ReflectionTypeSystemProvider].Instance.Map(type) cast ExternalType
			_envType = envType if _envType is null
			for member in envType.GetMembers():
				_entities.Add(member.Name, member) unless _entities.ContainsKey(member.Name)
			type = type.BaseType
	
	override def Resolve(targetList as System.Collections.Generic.ICollection of IEntity, name as string, flags as EntityType) as bool:
		return false unless flags == EntityType.Any
		
		entity as IEntity
		if _entities.TryGetValue(name, entity):
			targetList.Add(entity)
			return true
		
		return false

class BooReaderEnvironmentStep(AbstractInterpreter.ProcessVariableDeclarations):
	
	private _environment as object
	
	private _envType as ExternalType
	
	private _moduleClass as IType
	
	private _environmentField as IField
	
	private static final EnvFieldName = '$EnvironmentField$'
	
	def constructor(interpreter, environment):
		super(interpreter)
		_environment = environment
	
	override public def Run():
		_moduleClass = null
		_environmentField = null
		super.Run()
	
	override public def OnModule(node as Module):
		//process the module class first
		mc = node.Members.Single({m | Boo.Lang.Compiler.Steps.IntroduceModuleClasses.IsModuleClass(m)})
		unless node.Members.IndexOf(mc) == 0:
			node.Members.Remove(mc)
			node.Members.Insert(0, mc)
		super.OnModule(node)
	
	override public def OnClassDefinition(node as ClassDefinition):
		return if WasVisited(node)
		
		if Boo.Lang.Compiler.Steps.IntroduceModuleClasses.IsModuleClass(node):
			assert _moduleClass is null
			env = CodeBuilder.CreateField(EnvFieldName, _envType)
			env.Modifiers = TypeMemberModifiers.Public | TypeMemberModifiers.Static
			node.Members.Add(env)
			_moduleClass = (node.Entity cast ITypedEntity).Type
			_environmentField = env.Entity cast IField
		super.OnClassDefinition(node)
	
	override public def OnMethod(node as Method):
		super(node)
		if node == _entryPoint:
			node.Body.Statements.Insert(0,
				ExpressionStatement(
					CodeBuilder.CreateAssignment(
						CodeBuilder.CreateReference(_environmentField),
						CodeBuilder.CreateReference(AbstractInterpreter.InterpreterEntity('Environment', _envType)))))
	
	override def Initialize(context as CompilerContext):
		super.Initialize(context)
		newNS =  BooReaderEnvironmentNamespace(_environment, _namespace.ParentNamespace)
		_namespace = newNS
		NameResolutionService.GlobalNamespace = _namespace
		_envType = newNS.EnvType
		
	override def CreateMemberReferenceTarget(sourceNode as Node, member as IMember) as Expression:
		target as Expression = null

		if member.IsStatic:
			target = CodeBuilder.CreateReference(sourceNode.LexicalInfo, member.DeclaringType)
		elif member.DeclaringType.IsAssignableFrom(_envType):
			module = CodeBuilder.CreateReference(sourceNode.LexicalInfo, _moduleClass)
			target = CodeBuilder.CreateMemberReference(sourceNode.LexicalInfo, module, _environmentField)
		else:
			//check if found entity can't possibly be a member of self:
			if member.DeclaringType != CurrentType and not (CurrentType.IsSubclassOf(member.DeclaringType)):
				Error(CompilerErrorFactory.InstanceRequired(sourceNode, member))
			target = SelfLiteralExpression(sourceNode.LexicalInfo)
		BindExpressionType(target, member.DeclaringType)
		return target
