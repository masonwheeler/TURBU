namespace TURBU.RM2K.TextDataReader.Compiler

import System
import Boo.Lang.Compiler.Pipelines
import Boo.Lang.Compiler.Steps

class TURBUBuilderPipeline(CompileToFile):
	
	private _environmentStep = CompilerEnvironmentStep()
	
	public def constructor():
		super()
		self.InsertBefore(MacroAndAttributeExpansion, TURBU.RM2K.TextDataReader.FixNegativeNumbers())
		self.InsertBefore(ResolveImports, PrepareDataFiles())
		self.Replace(ProcessMethodBodiesWithDuckTyping, _environmentStep)
	
	public ModuleProcessed as Action[of Boo.Lang.Compiler.Ast.Module]:
		get: return _environmentStep.ModuleProcessed
		set: _environmentStep.ModuleProcessed = value
