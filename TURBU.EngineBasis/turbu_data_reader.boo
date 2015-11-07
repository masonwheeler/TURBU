namespace TURBU.DataReader

import System
import TURBU.Engines
import TURBU.EngineBasis
import TURBU.PluginInterface

interface IDataReader(ITurbuEngine):
	def Initialize(path as string)
	
	def GetReader[of T(IRpgObject)](eager as bool) as IDataTypeReader[of T]
	
	def GetMapLoader(environment as object) as IMapLoader
	
	Data as TRpgMetadata:
		get

interface IDataTypeReader[of T(IRpgObject)]:
	def GetData(index as int) as T
	
	def GetAll() as T*

	Count as int:
		get

interface IMapLoader:
	def GetMap(name as string) as TURBU.MapInterface.IRpgMap
