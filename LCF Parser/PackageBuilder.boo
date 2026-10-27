namespace LCF_Parser

import System
import System.Collections.Generic
import System.Diagnostics
import System.IO
import System.Reflection
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.IO
import Pythia.Runtime
import TURBU.Meta
import TURBU.RM2K.Import
import TURBU.RM2K.TextDataReader.Compiler

// An input that calls a callback when the compiler starts to read it. The parser reads the inputs
// one at a time; this is used to track progress through the parsing stage.
class ProgressInput(ICompilerInput):

	private _inner as ICompilerInput
	private _opened as Action

	public def constructor(inner as ICompilerInput, opened as Action):
		_inner = inner
		_opened = opened

	public Name as string:
		get: return _inner.Name

	public def Open() as TextReader:
		_opened()
		return _inner.Open()

// Compiles the converted project into its TURBU package: the files that the converter generated (the database, the
// maps and the scripts) are the sources, and the pipeline of the text data reader makes them into one assembly.
static class PackageBuilder:

	//the number of steps that the progress bar is made of
	public static final ProgressUnits = 1000

	private static final References = (
		'Boo.Lang.Useful', 'Boo.Lang.Extensions', 'TURBU.Meta', 'Pythia.Runtime', 'TURBU.EngineBasis', 'TURBU.RM2K',
		'TURBU.RM2K.MapEngine', 'TURBU.RM2K.TextDataReader', 'TURBU.SDL', 'SDL2-CS')

	private static def SourceFiles(basepath as string) as (string):
		result = List[of string]()
		for pair in (('Database', '*.tdb'), ('Maps', '*.tmf'), ('Scripts', '*.boo')):
			folder = Path.Combine(basepath, pair[0])
			continue unless Directory.Exists(folder)
			files = Directory.GetFiles(folder, pair[1])
			Array.Sort(files, StringComparer.Ordinal)
			result.AddRange(files)
		return result.ToArray()

	public def Build(basepath as string, projectName as string, report as IConversionReport):
		var pipeline = TURBUBuilderPipeline()
		var files = SourceFiles(basepath)
		var progress = BuildProgress(report, ProgressUnits, pipeline, files.Length)
		var compiler = BooCompiler()
		var parameters = compiler.Parameters
		for file in files:
			parameters.Input.Add(ProgressInput(FileInput(file), progress.FileParsed))
		parameters.OutputAssembly = Path.Combine(basepath, projectName + '.turbu')
		parameters.OutputType = CompilerOutputType.Library
		parameters.Debug = true
		parameters.NoWarn = true
		parameters.Defines['ProjectBasePath'] = basepath
		parameters.Pipeline = pipeline
		for name in References:
			parameters.AddAssembly(Assembly.LoadFrom(Path.Combine(AppContext.BaseDirectory, name + '.dll')))
		pipeline.BeforeStep += progress.StepStarting
		pipeline.AfterStep += progress.StepDone
		pipeline.ModuleProcessed = progress.ModuleProcessed
		var result = compiler.Run()
		progress.Finish()
		if result.Errors.Count > 0:
			for error in result.Errors:
				report.MakeError(error.ToString(), 9999)
			raise "The TURBU package could not be built: $(result.Errors.Count) error(s)."

// Turns the compiler's progress into steps of the progress bar. Every step of the pipeline is a
// share of the whole bar, and the two that take most of the time, Parsing and ProcessMethodBodies,
// report on every file as well.
class BuildProgress:

	private _report as IConversionReport
	private _total as int
	private _shown = 0
	private _label = ''
	private _steps as (ICompilerStep)
	private _starts as (double)		//how much of the whole is done when a step starts, in percent
	private _share as (double)		//how much of the whole a step is, in percent
	private _current = -1
	private _files as int
	private _filesParsed = 0
	private _modules = 1
	private _modulesProcessed = 0

	public def constructor(report as IConversionReport, total as int, pipeline as CompilerPipeline, files as int):
		_report = report
		_total = total
		_files = Math.Max(files, 1)
		_steps = array(ICompilerStep, pipeline.Count)
		weights = array(double, _steps.Length)
		sum = 0.0
		for i in range(_steps.Length):
			_steps[i] = pipeline[i]
			weights[i] = Weight(_steps[i].GetType().Name)
			sum += weights[i]
		_starts = array(double, _steps.Length)
		_share = array(double, _steps.Length)
		done = 0.0
		for i in range(_steps.Length):
			_starts[i] = done
			_share[i] = (weights[i] * 100.0) / sum
			done += _share[i]
		_report.NewStep('')

	private static def Weight(name as string) as double:
		caseOf name:
			case 'Parsing': return 30.0
			case 'MacroAndAttributeExpansion': return 25.0
			case 'CompilerEnvironmentStep': return 25.0
			default: return 1.0

	private def Reach(percent as double):
		target = Math.Min(cast(int, (percent * _total) / 100.0), _total)
		while _shown < target:
			_report.NewStep(_label)
			++_shown

	public def StepStarting(sender as object, args as CompilerStepEventArgs):
		_current = Array.IndexOf(_steps, args.Step)
		_label = args.Step.GetType().Name
		if args.Step.GetType().Name == 'CompilerEnvironmentStep':
			_modules = Math.Max(args.Context.CompileUnit.Modules.Count, 1)
		Reach(_starts[_current]) if _current >= 0

	public def StepDone(sender as object, args as CompilerStepEventArgs):
		index = Array.IndexOf(_steps, args.Step)
		Reach(_starts[index] + _share[index]) if index >= 0

	public def FileParsed():
		++_filesParsed
		return if _current < 0 and _filesParsed > _files
		start = (_starts[_current] if _current >= 0 else 0.0)
		share = (_share[_current] if _current >= 0 else 0.0)
		Reach(start + (share * _filesParsed) / _files)

	public def ModuleProcessed(module as Boo.Lang.Compiler.Ast.Module):
		++_modulesProcessed
		return if _current < 0
		Reach(_starts[_current] + (_share[_current] * _modulesProcessed) / _modules)

	public def Finish():
		_label = 'Done'
		Reach(100.0)
