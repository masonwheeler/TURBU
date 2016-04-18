namespace TURBU.RM2K.TextDataReader.Compiler

import System
import Boo.Lang.Compiler.Pipelines
import Boo.Lang.Compiler.Steps

class TURBUBuilderPipeline(CompileToFile):
	public def constructor():
		super()
		self.InsertBefore(MacroAndAttributeExpansion, TURBU.RM2K.TextDataReader.FixNegativeNumbers())
		self.InsertBefore(ResolveImports, PrepareDataFiles())
		self.Replace(ProcessMethodBodiesWithDuckTyping, CompilerEnvironmentStep())
		#System.Threading.Thread.Sleep(10000)
