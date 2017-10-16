namespace TURBU.RM2K.TextDataReader

import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable
import System.Threading.Tasks
import Boo.Lang.Interpreter
import turbu.defs
import turbu.versioning
import TURBU.EngineBasis
import TURBU.MapInterface
import TURBU.PluginInterface
import TURBU.DataReader

class TBooReader(TRpgPlugBase, IDataReader):
	
	[Getter(Data)]
	private _data = TRpgMetadata('Boo Data Reader', TVersion(0, 1, 1))
	
	private _path as string
	
	private _loader as InteractiveInterpreter
	
	private _mapLoader as TMapLoader
	
	private _readers = {}
	
	private def Initialize():
		_loader = InteractiveInterpreter(/*Boo.Lang.Parser.BooParsingStep(),*/ Ducky: false, RememberLastValue: true, ReplaceSingleEmptyMacro: false)
		_loader.References.Add(typeof(turbu.defs.Turbu_defsModule).Assembly)
		_loader.References.Add(typeof(SG.defs.SG_DefsModule).Assembly)
		_loader.References.Add(typeof(IDataReader).Assembly)
		_loader.References.Add(typeof(SDL2.SDL).Assembly)
		_loader.Eval("""
import TURBU.RM2K.TextDataReader.Readers
import Pythia.Runtime
import turbu.defs
import SG.defs""")
		_loader.Pipeline.InsertBefore(Boo.Lang.Compiler.Steps.MacroAndAttributeExpansion, FixNegativeNumbers())
	
	public def GetMapLoader(environment as object) as IMapLoader:
		return _mapLoader if _mapLoader is not null and _mapLoader.Environment == environment
		_mapLoader = TMapLoader(environment, Directory.GetParent(_path).FullName)
		return _mapLoader
	
	def Initialize(path as string):
		Initialize() if _loader is null
		_path = path
	
	def GetReader[of T(IRpgObject)]() as IDataTypeReader[of T]:
		var TType = typeof(T)
		if _readers.ContainsKey(TType):
			return _readers[TType] cast IDataTypeReader[of T]
		
		_loader.References.Add(TType.Assembly)
		key = TType.GetCustomAttributes(false).OfType[of TableNameAttribute]().SingleOrDefault()
		if key is null:
			raise "Class $(TType.Name) has no TableName attribute registered"
		result = TDataFileReader[of T](Path.Combine(_path, "$(key.Name).tdb"), _loader)
		_readers.Add(TType, result)
		return result
	
	def Dispose() as Task:
		_loader = null
		return Task.FromResult(true)

private class TDataFileReader[of T(IRpgObject)](IDataTypeReader[of T]):
	
	private _store = Dictionary[of int, Func[of T]]()
	private _cache = Dictionary[of int, T]()
	private _loader as InteractiveInterpreter
	
	def constructor(filename as string, loader as InteractiveInterpreter):
		_loader = loader
		ctx = loader.Eval(File.ReadAllText(filename))
		if ctx.Errors.Count > 0:
			raise ctx.Errors.ToString()
		else:
			values as KeyValuePair[of int, Func[of T]]* = loader.LastValue
			_store = values.ToDictionary({kv | kv.Key}, {kv | kv.Value})
	
	def GetData(index as int) as T:
		lock _store:
			result as T
			return result if _cache.TryGetValue(index, result)
			loader as Func[of T]
			if _store.TryGetValue(index, loader):
				result = loader()
				_cache.Add(index, result)
				_store.Remove(index)
				return result
			else: raise KeyNotFoundException("Key value $index not found")
	
	def GetAll() as T*:
		lock _store:
			for kv in _store:
				value = kv.Value
				item = value()
				_cache.Add(kv.Key, item)
			_store.Clear()
			return _cache.Values.OrderBy({t | t.ID})
	
	Count as int:
		get: return _store.Count + _cache.Count

private class TMapLoader(IMapLoader):
	
	private _mapLoader as InteractiveInterpreter
	
	private _path as string
	
	[Getter(Environment)]
	private _environment as object
	
	def constructor(env as object, path as string):
		_path = path
		_environment = env
		_mapLoader = InteractiveInterpreter(Ducky: false, RememberLastValue: true)
		_mapLoader.Pipeline.Replace(AbstractInterpreter.ProcessVariableDeclarations, BooReaderEnvironmentStep(_mapLoader, env))
		_mapLoader.References.Add(typeof(SG.defs.SG_DefsModule).Assembly) //TURBU.SDL
		_mapLoader.References.Add(typeof(IDataReader).Assembly) //TURBU.EngineBasis
		_mapLoader.References.Add(typeof(turbu.defs.Turbu_defsModule).Assembly) //TURBU.RM2K
		_mapLoader.References.Add(typeof(TURBU.RM2K.RPGScript.Rs_messageModule).Assembly) //TURBU.RM2K.MapEngine
		_mapLoader.References.Add(typeof(TURBU.Meta.CaseOfMacro).Assembly) //TURBU.Meta
		_mapLoader.Eval("""
import TURBU.RM2K.TextDataReader.Readers
import Pythia.Runtime
import turbu.defs
import turbu.maps
import SG.defs
import TURBU.BattleEngine
import TURBU.MapObjects
import TURBU.Meta
import TURBU.RM2K.RPGScript""")
		_mapLoader.Pipeline.InsertBefore(Boo.Lang.Compiler.Steps.MacroAndAttributeExpansion, FixNegativeNumbers())
		_mapLoader.SetValue('Environment', env)
	
	def GetMap(data as IMapMetadata) as TURBU.MapInterface.IRpgMap:
		var name = data.Name
		mapFile = File.ReadAllLines(Path.Combine(_path, 'Maps', name + '.tmf'))
		scriptFile = File.ReadAllLines(Path.Combine(_path, 'Scripts', name + '.boo'))
		text = string.Join(System.Environment.NewLine, scriptFile.Concat(mapFile))
		ctx = _mapLoader.Eval(text)
		if ctx.Errors.Count > 0:
			raise ctx.Errors.ToString()
		return _mapLoader.LastValue cast TURBU.MapInterface.IRpgMap

	def GetGlobals() as TURBU.MapInterface.IRpgMapObject*:
		dbFile = File.ReadAllLines(Path.Combine(_path, 'Database', 'GlobalEvents.tdb'))
		scriptFile = File.ReadAllLines(Path.Combine(_path, 'Scripts', 'GlobalScripts.boo'))
		text = string.Join(System.Environment.NewLine, scriptFile.Concat(dbFile))
		ctx = _mapLoader.Eval(text)
		if ctx.Errors.Count > 0:
			raise ctx.Errors.ToString()
		return _mapLoader.LastValue cast TURBU.MapInterface.IRpgMapObject*
