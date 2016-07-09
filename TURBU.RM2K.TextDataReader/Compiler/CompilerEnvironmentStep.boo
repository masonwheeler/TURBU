namespace TURBU.RM2K.TextDataReader.Compiler

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Reflection
import Boo.Lang.Environments

class CompilerEnvironmentNamespace(AbstractNamespace):
	[getter(ParentNamespace)]
	_parent as INamespace
	
	[Getter(EnvType)]
	private _envType as ExternalType
	
	private _entities = Dictionary[of string, IEntity]()
	
	public def constructor(envType as ExternalType, parent as INamespace):
		super()
		_parent = parent
		_envType = envType
		var typeClass = envType
		var ot = My[of TypeSystemServices].Instance.ObjectType
		while typeClass != ot:
			for member in typeClass.GetMembers():
				_entities.Add(member.Name, member) unless _entities.ContainsKey(member.Name)
			typeClass = typeClass.BaseType
	
	override def Resolve(targetList as System.Collections.Generic.ICollection of IEntity, name as string, flags as EntityType) as bool:
		return false unless flags == EntityType.Any
		
		entity as IEntity
		if _entities.TryGetValue(name, entity):
			targetList.Add(entity)
			return true
		
		return false
	
	override def GetMembers() as IEnumerable of IEntity:
		return _entities.Values

class CompilerEnvironmentStep(ProcessMethodBodiesWithDuckTyping):
	
	[Property(EnvironmentType)]
	private static _environmentType as Type = turbu.RM2K.environment.T2kEnvironment
	
	private _envType as ExternalType
	
	private _moduleClass as IType
	
	private _environmentField as IField
	
	private _namespace as CompilerEnvironmentNamespace
	
	private static final EnvFieldName = '$EnvironmentField$'
	
	override public def Run():
		_moduleClass = null
		_environmentField = null
		super.Run()
	
	private def BuildEnvModule(node as CompileUnit):
		var init = CodeBuilder.CreateModule('Env', null)
		node.Modules.Insert(0, init)
		var provideEnvironment = CodeBuilder.CreateMethod('ProvideEnvironment', TypeSystemServices.VoidType, TypeMemberModifiers.Public)
		_envType = TypeSystemServices.Map(_environmentType)
		var p1 = CodeBuilder.CreateParameterDeclaration(0, 'value', _envType)
		provideEnvironment.Parameters.Add(p1)
		var envField = CodeBuilder.CreateField(EnvFieldName, _envType)
		envField.Modifiers = TypeMemberModifiers.Internal
		init.Members.Add(envField)
		_environmentField = envField.Entity cast IField
		init.Members.Add(provideEnvironment)
		init.Accept(Context.Parameters.Pipeline.Get(IntroduceModuleClasses))
		provideEnvironment.Body.Add(CodeBuilder.CreateFieldAssignmentExpression(_environmentField, CodeBuilder.CreateReference(p1.Entity)))
		var moduleClass = init.Members.Single({m | IntroduceModuleClasses.IsModuleClass(m)}) cast ClassDefinition
		_moduleClass = (moduleClass.Entity cast ITypedEntity).Type
		My[of Boo.Lang.Compiler.TypeSystem.Internal.InternalTypeSystemProvider].Instance.EntityFor(
			moduleClass.Members.OfType[of Constructor]().Single())
		moduleClass.BaseTypes.Add(CodeBuilder.CreateTypeReference(object))
	
	override public def OnCompileUnit(node as CompileUnit):
		BuildEnvModule(node)
		super.OnCompileUnit(node)
	
	override public def OnModule(node as Module):
		//process the module class first
		mc = node.Members.SingleOrDefault({m | Boo.Lang.Compiler.Steps.IntroduceModuleClasses.IsModuleClass(m)})
		if mc is not null:
			unless node.Members.IndexOf(mc) == 0:
				node.Members.Remove(mc)
				node.Members.Insert(0, mc)
		super.OnModule(node)
	
	override def Initialize(context as CompilerContext):
		super.Initialize(context)
		_envType = My[of ReflectionTypeSystemProvider].Instance.Map(_environmentType) cast ExternalType
		_namespace =  CompilerEnvironmentNamespace(_envType, NameResolutionService.GlobalNamespace)
		NameResolutionService.GlobalNamespace = _namespace
		_envType = _namespace.EnvType
		
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

macro EnvironmentClass(value as TypeReference):
""" Can be used in a config file (to be implemented later) to override the environment type """
	var entity = value.Entity cast ExternalType
	CompilerEnvironmentStep.EnvironmentType = entity.ActualType