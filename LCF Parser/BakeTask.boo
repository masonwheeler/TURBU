namespace LCF_Parser

import System
import System.IO
import System.Linq.Enumerable
import Bake.Engine.Builder
import Boo.Lang.Compiler.Ast

private def ExecuteScript(script as string):
	using outputResult = System.IO.StringWriter():
		Console.SetOut(outputResult)
		Console.SetError(outputResult)
		try:
			using stream = System.IO.MemoryStream(System.Text.Encoding.UTF8.GetBytes(script)), f = StreamReader(stream):
				builder = BakeEngineBuilder(f)
				engine = builder.Build({})
				if engine:
					engine.Execute()
				else:
					raise builder.Errors.ToString()
		except ex:
			raise Exception(outputResult.ToString(), ex)

	return true

public def RunBake(basepath as string, TurbuPath as string, projectName as string):
	var sources = ("$(basepath)/Database/*.tdb", "$(basepath)/Maps/*.tmf", "$(basepath)/Scripts/*.boo")
	var sourcesList = ListLiteralExpression()
	sourcesList.Items.AddRange(sources.Select({s | StringLiteralExpression(s)}))
	var output = "$(basepath)/$(projectName).turbu"
	var refs = (
		"$(TurbuPath)/boo.lang.useful.dll",
		"$(TurbuPath)/boo.lang.extensions.dll",
		"$(TurbuPath)/turbu.meta.dll",
		"$(TurbuPath)/pythia.runtime.dll",
		"$(TurbuPath)/TURBU.EngineBasis.dll",
		"$(TurbuPath)/TURBU.RM2K.dll",
		"$(TurbuPath)/TURBU.RM2K.MapEngine.dll",
		"$(TurbuPath)/TURBU.RM2K.TextDataReader.dll",
		"$(TurbuPath)/TURBU.SDL.dll"
		)
	var refsList = ListLiteralExpression()
	refsList.Items.AddRange(refs.Select({s | StringLiteralExpression(s)}))
	var pipeline = "TURBU.RM2K.TextDataReader.Compiler.TURBUBuilderPipeline,TURBU.RM2K.TextDataReader"
	var define = "ProjectBasePath=$(basepath)"

	var script = [|
		import Bake.Compiler.Extensions
		
		Task "default":
			Booc(
				SourcesSet   : $sourcesList,
				OutputFile   : $output,
				OutputTarget : TargetType.Library,
				ReferencesSet: $refsList,
				Pipeline     : $pipeline,
				Define       : $define
				).Execute()
	|]
	ExecuteScript(script.ToCodeString())