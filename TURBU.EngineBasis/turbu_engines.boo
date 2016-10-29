namespace TURBU.Engines

import Pythia.Runtime
import System
import TURBU.PluginInterface
import turbu.versioning
import System.Collections.Generic

class EMissingPlugin(Exception):
	def constructor(message as string):
		super(message)

interface ITurbuEngine(IDisposable):
	pass

[Disposable(Destroy)]
private class TEngineDict(Dictionary[of TRpgMetadata, ITurbuEngine]):
	
	private def Destroy():
		for engine in self:
			engine.Value.Dispose()

static class TTurbuEngines:

	private FEngineList = Dictionary[of TEngineStyle, TEngineDict]()

	def AddEngine(slot as TEngineStyle, value as TRpgMetadata, engine as ITurbuEngine):
		unless FEngineList.ContainsKey(slot):
			FEngineList[slot] = TEngineDict()
		FEngineList[slot].Add(value, engine)
	
	def RequireEngine(slot as TEngineStyle, name as string, version as TVersion) as TRpgMetadata:
		result as TRpgMetadata = null
		if FEngineList.ContainsKey(slot):
			for enumerator in FEngineList[slot].Keys:
				if enumerator.Name == name:
					result = enumerator
					break
		if assigned(result):
			if result.Version < version:
				raise EMissingPlugin("This project requires the \"$name\" plugin at version $(version.Name) or higher, but found version $(result.Version.Name)")
			else:
				return result
		else:
			raise EMissingPlugin("Unable to load \"$name\", which is required for this project.")
		return result
	
	def RetrieveEngine(slot as TEngineStyle, name as string, version as TVersion) as ITurbuEngine:
		return RetrieveEngine(slot, RequireEngine(slot, name, version))
	
	def RetrieveEngine(slot as TEngineStyle, value as TRpgMetadata) as ITurbuEngine:
		return FEngineList[slot][value]
	
	def CleanupEngines():
		for list in FEngineList:
			list.Value.Dispose()
