namespace turbu.pathing

import Pythia.Runtime
import System.Collections.Generic
import System
import turbu.defs
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import turbu.classes

class Path:

	[Property(Cursor)]
	private FCursor as int

	private FLoopLength as int

	[Property(Looped)]
	private FLooped as bool

	private FSteps as IEnumerator of Func[of TObject, bool]

	[Getter(Skip)]
	private FSkip as bool

	private _data as Func[of Path, Func[of TObject, bool]*]

	public def constructor(skip as bool, data as Func[of Path, Func[of TObject, bool]*]):
		super()
		FSkip = skip
		_data = data
		GetSteps()

	public def constructor(copy as Path):
		self(copy.Skip, copy._data)

	public def Clone() as Path:
		var result = Path(self)
		result.FCursor = self.FCursor
		result.FLooped = self.FLooped
		return result

	private def GetSteps():
		try:
			FSteps = _data(self).GetEnumerator()
		except e as Exception:
			System.Diagnostics.Debugger.Break()

	public def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('Cursor', FCursor, 0)
			writer.CheckWrite('Looped', FLooped, false)

	public def constructor(obj as JObject):
		obj.CheckRead('Cursor', FCursor)
		obj.CheckRead('Looped', FLooped)
		obj.CheckEmpty()

	public def NextCommand() as Func[of TObject, bool]:
		var wasLooped = self.FLooped
		result as Func[of TObject, bool] = (FSteps.Current if FSteps.MoveNext() else null)
		if assigned(result):
			if FLooped and not wasLooped:
				FLoopLength = FCursor
				FCursor = 0
			elif FLooped and (FCursor > FLoopLength):
				FCursor = 0
			else: ++FCursor
		return result
