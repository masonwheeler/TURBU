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

	private FIterationCursor as int

	[Getter(Loop)]
	private FLoop as bool

	[Property(Looped)]
	private FLooped as bool

	private def GetLast() as int:
		return FOpcodes.Count - 1
	
	private FSteps as Func[of bool]*

	public def constructor():
		super()

	public def constructor(Data as Func[of Path, Func[of bool]*]):
		super()
		try:
			FSteps = Data(self)
		except e as Exception:
			System.Diagnostics.Debugger.Break()

	public def constructor(direction as TDirections):
		step = TMoveStep(ord(direction))
		FOpcodes.Add(step)

	public def constructor(copy as Path):
		FBase = copy.Base
		FOpcodes = TMoveList(copy.Opcodes)
		FLoop = copy.Loop

	public def Clone() as Path:
		result = Path(self)
		result.FCursor = self.FCursor
		result.FIterationCursor = self.FIterationCursor
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

	public def NextCommand() as TMoveStep:
		result as TMoveStep
		if FCursor >= FOpcodes.Count:
			if Loop:
				FCursor = 0
				FLooped = true
			else:
				result.Opcode = 48
				return result
		result = FOpcodes[FCursor]
		++FIterationCursor
		if (result.Opcode in CODES_WITH_PARAMS) or (FIterationCursor >= result.Data[1]):
			++FCursor
			FIterationCursor = 0
		return result

	public def SetDirection(direction as TDirections):
		FLoop = false
		FOpcodes.Clear()
		newStep = TMoveStep(ord(direction))
		FOpcodes.Add(newStep)
		FCursor = 0

	public Last as int:
		get:
			return GetLast()

def LookupMoveCode(Opcode as string) as int:
	result as int
	return (result if moveDic.TryGetValue(Opcode.ToUpperInvariant(), result) else -1)

let MOVE_CODES = ('Up', 'Right', 'Down', 'Left', 'UpRight', 'DownRight', 'DownLeft', 'UpLeft', 'RandomStep', 'TowardsHero', 'AwayFromHero', 'MoveForward', 'FaceUp', 'FaceRight', 'FaceDown', 'FaceLeft', 'TurnRight', 'TurnLeft', 'Turn180', 'Turn90', 'FaceRandom', 'FaceHero', 'FaceAwayFromHero', 'Pause', 'StartJump', 'EndJump', 'FacingFixed', 'FacingFree', 'SpeedUp', 'SpeedDown', 'FreqUp', 'FreqDown', 'SwitchOn', 'SwitchOff', 'ChangeSprite', 'PlaySfx', 'ClipOff', 'ClipOn', 'AnimStop', 'AnimResume', 'TransparencyUp', 'TransparencyDown')
let CODES_WITH_PARAMS = (0x20, 0x21, 0x22, 0x23)
let MOVECODE_RANDOM = 8
let MOVECODE_CHASE = 9
let MOVECODE_FLEE = 10
let MOVECODE_CHANGE_SPRITE = 0x22
let MOVECODE_PLAY_SFX = 0x23
let moveDic = Dictionary[of string, int](pred(MOVE_CODES.Length) * 2)
let OP_CLEAR = 0xC0; //arbitrary value
initialization :
	for i in range(MOVE_CODES.Length):
		moveDic.Add(MOVE_CODES[i].ToUpperInvariant(), i)
