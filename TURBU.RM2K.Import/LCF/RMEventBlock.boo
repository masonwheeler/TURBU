namespace TURBU.RM2K.Import.LCF

import System

LCFObject MapEvent:
	hasID
	1 = Name as string
	2 = X(0) as int
	3 = Y(0) as int
	5 = Pages as (EventPage)

LCFObject GlobalEvent:
	hasID
	1    = Name('') as string
	0x0B = StartCondition as int
	0x0C = UsesSwitch(false) as bool
	0x0D = Switch(1) as int
	0x15 = CommandCount as int
	0x16 = Script as EventCommand*

LCFObject EventPage:
	hasID
	2    = Conditions as EventConditions
	0x15 = GraphicFile('') as string
	0x16 = Graphic(0) as int
	0x17 = Direction as int
	0x18 = Frame(1) as int
	0x19 = Transparent as bool
	0x1F = MoveType as int
	0x20 = MoveFrequency(3) as int
	0x21 = StartCondition as int
	0x22 = EventHeight as int
	0x23 = NoOverlap as bool
	0x24 = AnimType as int
	0x25 = MoveSpeed(3) as int
	0x29 = MoveScript as EventMoveBlock
	0x33 = ScriptSize as int
	0x34 = Script as EventCommand*

LCFObject EventConditions:
	1   = Conditions as int
	2   = Switch1(1) as int
	3   = Switch2(1) as int
	4   = Variable(1) as int
	5   = VarValue(0) as int
	6   = Item(1) as int
	7   = Hero as int
	8   = Clock(0) as int
	9   = Clock2(0) as int
	0xA = VarOperator(1) as int

LCFObject EventMoveBlock:
	0xB  = MoveOrderSize(0) as int
	0xC  = MoveOrder as MoveOpcode*
	0x15 = Loop(false) as bool
	0x16 = Ignore(false) as bool

class EventCommand(ILCFObject):

	[Getter(Opcode)]
	private final _Opcode as int

	[Getter(Depth)]
	private final _Depth as int

	[Property(Name)]
	private _Name as string

	[Getter(Data)]
	private final _Data = System.Collections.Generic.List[of int]()

	def constructor(input as System.IO.Stream):
		_Opcode = BERInt(input)
		_Depth = BERInt(input)
		_Name = LCFString(input)
		for i in range(BERInt(input)):
			_Data.Add(BERInt(input))
	
	def constructor(opcode as int, *args as (int)):
		_Opcode = opcode
		_Depth = 0
		_Name = ''
		_Data.AddRange(args)
	
	def Save(output as System.IO.Stream):
		WriteBERInt(output, _Opcode)
		WriteBERInt(output, _Depth)
		WriteValue(output, _Name)
		WriteBERInt(output, _Data.Count)
		for i in _Data:
			WriteBERInt(output, i)
	
	override def ToString() as string:
		return "(Op: $_Opcode, Depth: $_Depth, Name: '$_Name', Data: $(join(_Data, ', ')))"

class MoveOpcode(ILCFObject):
	[Getter(Code)]
	private final _code as int
	
	[Property(Name)]
	private _name as string
	
	[Getter(Data)]
	private final _data = System.Collections.Generic.List[of int]()
	
	def constructor(input as System.IO.Stream):
		_code = input.ReadByte()
		assert _code in range(0, 0x2A)
		if _code in (0x20, 0x21):
			_data.Add(BERInt(input))
		elif _code == 0x22:
			_name = LCFString(input)
			_data.Add(BERInt(input))
		elif _code == 0x23:
			_name = LCFString(input)
			for i in range(3):
				_data.Add(BERInt(input))
		else: _data = null

	def Save(output as System.IO.Stream):
		output.WriteByte(_code)
		if _code in (0x22, 0x23):
			WriteValue(output, _name)
		if _data is not null:
			for value in _data:
				WriteBERInt(output, value)
