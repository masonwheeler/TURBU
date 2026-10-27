namespace turbu.pathing

import Pythia.Runtime
import System.Collections.Generic
import System
import turbu.defs
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import turbu.classes

struct PathStep:
	public Count as int
	public Action as Func[of TObject, bool]

	public def constructor(count as int, action as Func[of TObject, bool]):
		Count = count
		Action = action

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

	private _steps as (PathStep)

	private _loop as bool

	public def constructor(skip as bool, data as Func[of Path, Func[of TObject, bool]*]):
		super()
		FSkip = skip
		_data = data
		GetSteps()

	public def constructor(skip as bool, loop as bool, *steps as (PathStep)):
		super()
		FSkip = skip
		_steps = steps
		_loop = loop
		GetSteps()

	public def constructor(copy as Path):
		super()
		FSkip = copy.Skip
		_data = copy._data
		_steps = copy._steps
		_loop = copy._loop
		GetSteps()

	public def Clone() as Path:
		var result = Path(self)
		result.FCursor = self.FCursor
		result.FLooped = self.FLooped
		return result

	private def FixedSteps() as Func[of TObject, bool]*:
		return if _steps.Length == 0
		while true:
			for i in range(_steps.Length):
				for j in range(_steps[i].Count):
					yield _steps[i].Action
			break unless _loop
			self.FLooped = true

	private def GetSteps():
		try:
			FSteps = (FixedSteps() if _steps is not null else _data(self)).GetEnumerator()
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
