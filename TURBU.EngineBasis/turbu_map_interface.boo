namespace TURBU.MapInterface

import System
import System.Collections.Generic
import TURBU.EngineBasis

interface IRpgMapObject(IRpgObject):

	PageCount as int:
		get

interface IRpgMap(IRpgObject):

	def GetMapObjects() as IRpgMapObject*

	Tileset as int:
		get
		set

interface IMapMetadata(IRpgObject):

	Parent as int:
		get

	TreeOpen as bool:
		get

	MapEngine as string:
		get

interface IMapMetadataEnumerator(IEnumerator[of IMapMetadata]):
	pass

interface IMapTree:

	def GetEnumerator() as IMapMetadataEnumerator

	CurrentMap as int:
		get

	def Get(x as int) as IMapMetadata
	
	Count as int:
		get

	self[x as int] as IMapMetadata:
		get

