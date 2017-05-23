namespace TURBU.DataReader

import System
import TURBU.Engines
import TURBU.EngineBasis
import TURBU.MapInterface
import TURBU.PluginInterface

interface IDataReader(ITurbuEngine):
	def Initialize(path as string)
	
	def GetReader[of T(IRpgObject)]() as IDataTypeReader[of T]
	
	def GetMapLoader(environment as object) as IMapLoader
	
	Data as TRpgMetadata:
		get

interface IDataTypeReader[of T(IRpgObject)]:
	def GetData(index as int) as T
	
	def GetAll() as T*

	Count as int:
		get

interface IMapLoader:
	def GetMap(data as IMapMetadata) as TURBU.MapInterface.IRpgMap
	def GetGlobals() as TURBU.MapInterface.IRpgMapObject*

interface IGlobalScriptProvider:
	Value[x as int] as System.Func[of System.Threading.Tasks.Task]:
		get
	
	def GetConditions(switch as int) as System.Func[of bool]