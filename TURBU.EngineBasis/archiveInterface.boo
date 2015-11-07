namespace archiveInterface

import Boo.Adt
import System
import System.Collections.Generic
import System.IO

class EArchiveError(Exception):
	def constructor (msg as string):
		super(msg)

struct TFilenameData:
	Name as string
	Duplicates as int

interface IArchive:

	def FileExists(name as string) as bool

	def GetFile(key as string) as Stream

	def WriteFile(key as string, theFile as Stream)

	def AllFiles(folder as string) as string*

	def CountFiles(filter as string) as int

	def DeleteFile(name as string)

	def CreateFolder(name as string)

	Root as string:
		get

class TArchiveList(List[of IArchive]):

	public def clearFrom(value as uint):
		self.RemoveRange(value, self.Count - value)

let GArchives = TArchiveList()
//let BASE_ARCHIVE = 0
let MAP_ARCHIVE = 0
let IMAGE_ARCHIVE = 1
let SCRIPT_ARCHIVE = 2
let MUSIC_ARCHIVE = 3
let SFX_ARCHIVE = 4
let VIDEO_ARCHIVE = 5

let MAP_DB = 'Maps'
let IMAGE_DB = 'Images'
let SCRIPT_DB = 'Scripts'
let MUSIC_DB = 'Music'
let SFX_DB = 'Sound'
let VIDEO_DB = 'Movies'
