namespace turbu.pathing

import Boo.Adt
import Pythia.Runtime
import System.Collections.Generic
import System
import turbu.defs
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import turbu.classes

[Obsolete]
struct TMoveStep:
	Opcode as int
	Name as string
	Data as (ushort)

	def constructor(Opcode as byte):
		self.Opcode = Opcode
		Array.Resize[of ushort](Data, 3)
		Data[0] = 0
		Data[1] = 0
		Data[2] = 0

	def constructor(Opcode as byte, value as ushort):
		self.Opcode = Opcode
		Array.Resize[of ushort](Data, 3)
		Data[0] = value
		Data[1] = 0
		Data[2] = 0

class TMoveList(List[of TMoveStep]):
	def constructor():
		super()
	
	def constructor(collection as TMoveStep*):
		super(collection)

class Path(TObject):

	[Getter(Opcodes)]
	private FOpcodes = TMoveList()

	[Getter(Base)]
	private FBase as string

	[Property(Cursor)]
	private FCursor as int

	private FLoopLength as int

	[Getter(Loop)]
	private FLoop as bool

	[Property(Looped)]
	private FLooped as bool

	private FSteps as IEnumerator of Func of bool

	public def constructor():
		super()

	public def constructor(Data as Func[of Path, Func[of bool]*]):
		super()
		try:
			FSteps = Data(self).GetEnumerator()
		except e as Exception:
			System.Diagnostics.Debugger.Break()

	public def constructor(copy as Path):
		FBase = copy.Base
		FOpcodes = TMoveList(copy.Opcodes)
		FLoop = copy.Loop

	public def Clone() as Path:
		result = Path(self)
		result.FCursor = self.FCursor
		result.FLooped = self.FLooped
		return result

	public def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('Path', FBase, '')
			writer.CheckWrite('Cursor', FCursor, 0)
			writer.CheckWrite('Looped', FLooped, false)

	public def constructor(obj as JObject):
		obj.CheckRead('Path', FBase)
		obj.CheckRead('Cursor', FCursor)
		obj.CheckRead('Looped', FLooped)
		obj.CheckEmpty()

	public def NextCommand() as Func of bool:
		var wasLooped = self.FLooped
		result as Func of bool = (FSteps.Current if FSteps.MoveNext() else null)
		if assigned(result):
			if FLooped and not wasLooped:
				FLoopLength = FCursor
				FCursor = 0
			elif FLooped and (FCursor > FLoopLength):
				FCursor = 0
			else: ++FCursor
		return result

	public def SetDirection(direction as TDirections):
		FLoop = false
		FOpcodes.Clear()
		newStep = TMoveStep(ord(direction))
		FOpcodes.Add(newStep)
		FCursor = 0
