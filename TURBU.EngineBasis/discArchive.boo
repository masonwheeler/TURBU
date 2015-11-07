namespace TURBU.EngineBasis

import System.IO
import System.Linq.Enumerable
import archiveInterface

class TDiscArchive(IArchive):
	
	[Getter(Root)]
	private FRoot as string
	
	static public def OpenFolder(pathName as string) as IArchive:
		raise EArchiveError("Unable to open project folder '$pathName'") unless Directory.Exists(pathName)
		return TDiscArchive(pathName)
	
	static public def NewFolder(pathName as string) as IArchive:
		raise EArchiveError("Project folder '$pathName' already exists; unable to create") if Directory.Exists(pathName)
		Directory.CreateDirectory(pathName)
		return TDiscArchive(pathName)

	private def constructor(root as string):
		FRoot = root

	private def AdjustFilename(name as string):
		return (name if name.StartsWith(FRoot) else Path.Combine(FRoot, name))
	
	public def FileExists(name as string) as bool:
		key = AdjustFilename(name)
		return File.Exists(key)

	public def GetFile(name as string) as Stream:
		key = AdjustFilename(name)
		using fs = File.OpenRead(key):
			try:
				result = MemoryStream(fs.Length)
				fs.CopyTo(result)
				result.Position = 0
				return result
			except e as System.Exception:
				raise EArchiveError(e.Message)

	public def WriteFile(key as string, theFile as Stream):
		filePos = theFile.Position
		filename = Path.Combine(FRoot, key)
		if Path.DirectorySeparatorChar in key:
			folderName = Path.GetDirectoryName(filename)
			Directory.CreateDirectory(folderName)
		using fs = File.Create(filename):
			try:
				theFile.Position = 0
				theFile.CopyTo(fs)
			ensure:
				theFile.Position = filePos

	public def AllFiles(folder as string) as string*:
		if folder.Contains('.'):
			filter = Path.GetFileName(folder)
			folder = Path.GetDirectoryName(folder)
		else: filter = '*.*'
		folder = Path.Combine(FRoot, folder)
		result = do():
			for filename in Directory.GetFiles(folder, filter):
				yield filename[folder.Length:]
		return result()

	public def CountFiles(filter as string) as int:
		return AllFiles(filter).ToArray().Length

	public def DeleteFile(name as string):
		key = AdjustFilename(name)
		File.Delete(key)

	public def CreateFolder(name as string):
		Directory.CreateDirectory(Path.Combine(FRoot, name))
