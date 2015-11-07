namespace TURBU.RM2K

import project.folder
import Pythia.Runtime
import System
import System.IO

static class logs:
	private textLog as StreamWriter
	
	def logText(data as string):
		if textLog is null:
			textLog = StreamWriter(FileStream(logName(), FileMode.Create))
		textLog.Write(data)
	
	def closeLog():
		if assigned(textLog):
			textLog.Dispose()
			textLog = null
	
	def logName() as string:
		return Path.Combine(GProjectFolder.value, 'TURBU log.txt')

finalization :
	logs.closeLog()