namespace TURBU.MapInterface

import Pythia.Runtime
import System
import System.Collections.Generic
import TURBU.EngineBasis

[System.Runtime.InteropServices.GuidAttribute('911ee905-1e43-4b26-9f7b-de094f59ef9b')]
interface IRpgMapObject(IRpgObject):

	PageCount as int:
		get

[System.Runtime.InteropServices.GuidAttribute('8b9cdcc2-afb6-408c-88c3-2e50d145c901')]
interface IRpgMap(IRpgObject):

	def GetMapObjects() as TStringList

	def GetScript() as string

	Tileset as int:
		get
		set

[System.Runtime.InteropServices.GuidAttribute('2028afba-6e31-4b5d-92a0-8375da9aec53')]
interface IMapMetadata(IRpgObject):

	Parent as int:
		get

	TreeOpen as bool:
		get

	MapEngine as string:
		get

[System.Runtime.InteropServices.GuidAttribute('4fd5cc25-13b8-4127-a67e-668909c3b977')]
interface IMapMetadataEnumerator(IEnumerator[of IMapMetadata]):
	pass

[System.Runtime.InteropServices.GuidAttribute('abb814b1-412e-4520-a6b0-a53c04200dfd')]
interface IMapTree:

	def GetEnumerator() as IMapMetadataEnumerator

	CurrentMap as int:
		get

	def Get(x as int) as IMapMetadata
	
	Count as int:
		get

	self[x as int] as IMapMetadata:
		get

