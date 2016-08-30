namespace TURBU.RM2K.CompiledDataReader

import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable
import System.Reflection
import System.Resources
import Newtonsoft.Json.Bson
import Newtonsoft.Json.Linq
import turbu.defs
import turbu.versioning
import TURBU.EngineBasis
import TURBU.MapInterface
import TURBU.PluginInterface
import TURBU.DataReader

class TDllReader(TRpgPlugBase, IDataReader):
	
	[Getter(Data)]
	private _data = TRpgMetadata('Compiled Data Reader', TVersion(0, 1, 1))
	
	private _asm as Assembly
	
	private _mapLoader as TMapLoader
	
	private _readers = {}
	
	public def GetMapLoader(environment as object) as IMapLoader:
		return _mapLoader if _mapLoader is not null and _mapLoader.Environment == environment
		_mapLoader = TMapLoader(environment, _asm)
		return _mapLoader
	
	def Initialize(path as string):
		path = Path.GetDirectoryName(path) //up one level
		var pathBase = Path.GetFileName(path)
		var filenames = Directory.EnumerateFiles(path, '*.turbu').ToArray()
		var filename = filenames.SingleOrDefault()
		raise ArgumentException("Compiled data file \"$(pathBase).turbu\" not found") if filename is null
		_asm = System.Reflection.Assembly.LoadFrom(filename)
	
	def GetReader[of T(IRpgObject)]() as IDataTypeReader[of T]:
		var TType = typeof(T)
		if _readers.ContainsKey(TType):
			return _readers[TType] cast IDataTypeReader[of T]
		
		var key = TType.GetCustomAttributes(false).OfType[of TableNameAttribute]().SingleOrDefault()
		if key is null:
			raise "Class $(TType.Name) has no TableName attribute registered"
		var result = TDllValueReader[of T](key.Name, _asm)
		_readers.Add(TType, result)
		return result
	
	def Dispose():
		_readers = null
	
private class TDllValueReader[of T(IRpgObject)](IDataTypeReader[of T]):
	
	private _cache = Dictionary[of int, T]()
	private _reader as ResourceReader
	private _factory as Func[of JObject, T]
	
	def constructor(tableName as string, asm as Assembly):
		var stream = asm.GetManifestResourceStream(tableName)
		if stream is null:
			raise "No reader found for '$tableName'"
		_reader = ResourceReader(stream)
		factoryMethod as System.Reflection.MethodInfo = typeof(T).GetMethod('Create', (JObject,))
		_factory = factoryMethod.CreateDelegate(typeof(Func[of JObject, T])) if factoryMethod is not null
	
	def GetData(index as int) as T:
		lock _cache:
			result as T
			return result if _cache.TryGetValue(index, result)
			
			var o = GetBSON(_reader, index)
			result = (_factory(o) if _factory is not null else Activator.CreateInstance(typeof(T), o) cast T)
			_cache.Add(index, result)
			return result
	
	private def Keys() as int*:
		using dict = _reader.GetEnumerator():
			var result = List[of int]()
			while dict.MoveNext():
				result.Add(int.Parse(dict.Key.ToString()))
			return result
	
	def GetAll() as T*:
		lock _cache:
			if _reader is not null:
				for key in Keys().Except(_cache.Keys):
					GetData(key)
				_reader.Dispose()
				_reader = null
			return _cache.Values.OrderBy({t | t.ID})
	
	Count as int:
		get: return (Keys().Count() if _reader is not null else _cache.Count)

private class TMapLoader(IMapLoader):
	
	private _asm as Assembly
	
	private _reader as ResourceReader
	
	private _globalScripts as IGlobalScriptProvider
	
	[Getter(Environment)]
	private _environment as object
	
	def constructor(env as object, asm as Assembly):
		var stream = asm.GetManifestResourceStream('Maps')
		_reader = ResourceReader(stream)
		_asm = asm
		_environment = env
		var gs = asm.GetType('GlobalScripts')
		_globalScripts = gs() cast IGlobalScriptProvider
		asm.GetType('EnvModule').GetMethod('ProvideEnvironment').Invoke(null, (env,))

	def GetMap(data as IMapMetadata) as TURBU.MapInterface.IRpgMap:
		var map = data cast IRpgObject
		var name = "Map$(data.ID.ToString('D4'))"
		var mapType = _asm.GetType(name)
		var result = mapType() cast turbu.maps.TRpgMap
		var json = GetBSON(_reader, map.ID)
		result.LoadFromJSON(json)
		return result

	def GetGlobals() as TURBU.MapInterface.IRpgMapObject*:
		var stream = _asm.GetManifestResourceStream('GlobalScript')
		var result = List[of TURBU.MapInterface.IRpgMapObject]()
		using reader = ResourceReader(stream):
			var values = List[of int]()
			using dict = reader.GetEnumerator():
				while dict.MoveNext():
					values.Add(int.Parse(dict.Key.ToString()))
			for id in values.OrderBy({i | return i}):
				var json = GetBSON(reader, id)
				result.Add(TURBU.MapObjects.TRpgMapObject(json, _globalScripts))
		return result

internal def GetBSON(reader as ResourceReader, id as int) as JObject:
	dummy as string
	data as (byte)
	reader.GetResourceData(id.ToString(), dummy, data)
	using ms = MemoryStream(data):
		using sizeReader = BinaryReader(ms, System.Text.Encoding.UTF8, true):
			var size = sizeReader.ReadInt32()
			assert data.Length == size + sizeof(size)
		using bReader = BsonReader(ms):
			return JToken.ReadFrom(bReader) cast JObject