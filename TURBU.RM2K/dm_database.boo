namespace TURBU.RM2K

import Boo.Adt
import Pythia.Runtime
import TURBU.DataReader
import TURBU.MapInterface

let BAD_LOOKUP = ''

class TdmDatabase(TDataModule):
	
	[Getter(Reader)]
	private _reader as IDataReader
	
	[Getter(MapLoader)]
	private _mapLoader as IMapLoader
	
	override def Initialize():
		pass
	
	def NameLookup(name as string, id as int) as string:
		assert false
	
	def NameLookup(name as string, id as int, key as int) as string:
		assert false
	
	public def Load(reader as IDataReader):
		_reader = reader
	
	public def RegisterEnvironment(env as object):
		_mapLoader = _reader.GetMapLoader(env)
	
	public def LoadMap(data as IMapMetadata) as turbu.maps.TRpgMap:
		return _mapLoader.GetMap(data)

static class dmDatabase:
	public value as TdmDatabase