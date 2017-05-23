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

[Disposable(Destroy, true)]
private class TEngineDict(Dictionary[of TRpgMetadata, ITurbuEngine]):
	
	private def Destroy():
		for engine in self:
			engine.Value.Dispose()

static class TTurbuEngines:

	private FEngineList = Dictionary[of TEngineStyle, TEngineDict]()

	private FMetadataList = List[of TRpgMetadata]()

	def RegisterEngine(value as TRpgMetadata):
		FMetadataList.Add(value)

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
/*	
	private def LoadEngine(data as TEngineData):
		base = data.Engine.Create()
		if data.Style == TEngineStyle.Map:
			mapEngine = base cast IMapEngine
			TTurbuEngines.AddEngine(data.Style, mapEngine.Data, mapEngine)
		elif data.Style == TEngineStyle.Battle:
			battleEngine = base cast IBattleEngine
			TTurbuEngines.AddEngine(data.Style, battleEngine.Data, battleEngine)
		elif data.Style == TEngineStyle.Data:
			dataEngine = base cast IDataReader
			TTurbuEngines.AddEngine(data.Style, dataEngine.Data, dataEngine)
		else: raise "Engine style '$(Enum.GetName(TEngineStyle, data.Style))' is not supported yet."
*/
	
	def CleanupEngines():
		for list in FEngineList:
			list.Value.Dispose()
