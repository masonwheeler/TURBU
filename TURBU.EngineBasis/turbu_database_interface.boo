namespace TURBU.DatabaseInterface

import TURBU.MapInterface

interface IRpgDatabase:

	MapTree as IMapTree:
		get

interface IRpgDatastore:

	def NameLookup(name as string, id as int) as string

	def NameLookup(name as string, key as int, id as int) as string
