namespace ArchiveUtils

import System
import System.IO
import archiveInterface

def ArchiveFileExists(archive as int, filename as string, folder as string) as bool:
	return GArchives[archive].FileExists("$folder\\$filename")

def GraphicExists(ref filename as string, folder as string) as bool:
	result = ArchiveFileExists(IMAGE_ARCHIVE, filename, folder)
	if (result == false) and (Path.GetExtension(filename) == ''):
		if ArchiveFileExists(IMAGE_ARCHIVE, (filename + '.png'), folder):
			filename = (filename + '.png')
			return true
		else:
			result = false
	return result

def SoundExists(ref filename as string) as bool:
	files as (string)
	result = ArchiveFileExists(SFX_ARCHIVE, filename, '')
	if result == false:
		if Path.GetExtension(filename) == '':
			if filename.Contains('['):
				filename = filename.Replace('[', '[[]')
			files = Directory.GetFiles(GArchives[SFX_ARCHIVE].Root, (filename + '.*'))
			if files.Length == 1:
				filename = Path.GetFileName(files[0])
				return true
			else:
				result = false
		elif ArchiveFileExists(SFX_ARCHIVE, (filename + '.wav'), ''):
			result = true
			filename = (filename + '.wav')
	return result

def MusicExists(ref filename as string) as bool:
	files as (string)
	result = ArchiveFileExists(MUSIC_ARCHIVE, filename, '')
	if (result == false) and (Path.GetExtension(filename) == ''):
		if filename.Contains('['):
			filename = filename.Replace('[', '[[]')
		files = Directory.GetFiles(GArchives[MUSIC_ARCHIVE].Root, (filename + '.*'))
		if files.Length == 1:
			filename = Path.GetFileName(files[0])
			return true
		else:
			result = false
	return result

