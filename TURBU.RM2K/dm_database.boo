﻿namespace TURBU.RM2K

import Boo.Adt
import Pythia.Runtime
import TURBU.DataReader

let BAD_LOOKUP = ''

class TdmDatabase(TDataModule):
	
	[Getter(Reader)]
	private _reader as IDataReader
	
	private _mapLoader as IMapLoader
	
	override def Initialize():
		pass
	
	public def ScriptLookup(id as int) as string:
		assert false
	
	def NameLookup(name as string, id as int) as string:
		assert false
	
	def NameLookup(name as string, id as int, key as int) as string:
		assert false
	
	public def Load(reader as IDataReader):
		_reader = reader
	
	public def RegisterEnvironment(env as object):
		_mapLoader = _reader.GetMapLoader(env)
	
	public def LoadMap(name as string) as turbu.maps.TRpgMap:
		return _mapLoader.GetMap(name)

static class dmDatabase:
	public value as TdmDatabase