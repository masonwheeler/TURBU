namespace TURBU.RM2K.Import.LCF

import System

LCFObject RMMonsterParty:
	hasID
	1    = Name('') as string
	2    = Monsters as (MonsterElement)
	3    = AutoAlign(false) as bool
	4    = HabitatCount(0) as int
	5    = Habitats as boolArray
	6    = Random(false) as bool
	0x0B = Events as (BattleEventPage)

LCFObject MonsterElement:
	hasID
	1 = Monster(1) as int
	2 = X as int
	3 = Y as int
	4 = Invisible(false) as bool

LCFObject BattleEventPage:
	hasID
	2    = Conditions as BattleEventConditions
	0x0B = CommandCount as int
	0x0C = Commands as EventCommand*

/*
LCFObject BattleEventConditions:
	1    = Conditions as LCFWord
	2    = Switch1(1) as int
	3    = Switch2(1) as int
	4    = Variable(1) as int
	5    = VarValue(0) as int
	6    = TurnsMultiple(0) as int
	7    = TurnsConst(0) as int
	8    = ExhaustionMin(0) as int
	9    = ExhaustionMax(100) as int
	0x0A = MonsterHPID(0) as int
	0x0B = MonsterHPMin(0) as int
	0x0C = MonsterHPMax(100) as int
	0x0D = HeroHP(1) as int
	0x0E = HeroHPMin(0) as int
	0x0F = HeroHPMax(100) as int
	0x10 = MonsterTurnID(0) as int
	0x11 = MonsterTurnsMultiple(0) as int
	0x12 = MonsterTurnsConst(0) as int
	0x13 = HeroTurn(1) as int
	0x14 = HeroTurnsMultiple(0) as int
	0x15 = HeroTurnsConst(0) as int
	0x16 = HeroCommandWho(1) as int
	0x17 = HeroCommandWhich(1) as int
*/

class BattleEventConditions(ILCFObject):

	private _Conditions as LCFWord

	private _Switch1 as int

	private _Switch2 as int

	private _Variable as int

	private _VarValue as int

	private _TurnsMultiple as int

	private _TurnsConst as int

	private _ExhaustionMin as int

	private _ExhaustionMax as int

	private _MonsterHPID as int

	private _MonsterHPMin as int

	private _MonsterHPMax as int

	private _HeroHP as int

	private _HeroHPMin as int

	private _HeroHPMax as int

	private _MonsterTurnID as int

	private _MonsterTurnsMultiple as int

	private _MonsterTurnsConst as int

	private _HeroTurn as int

	private _HeroTurnsMultiple as int

	private _HeroTurnsConst as int

	private _HeroCommandWho as int

	private _HeroCommandWhich as int

	public def constructor(input as System.IO.Stream):
		current = BERInt(input)
		if current == 1:
			_Conditions = LCFWord(input)
			current = BERInt(input)
		elif (current < 1) and (current > 0):
			raise LCFUnexpectedSection(current, 1, BattleEventConditions)
		if current == 2:
			_Switch1 = LCFInt(input)
			current = BERInt(input)
		elif (current < 2) and (current > 0):
			raise LCFUnexpectedSection(current, 2, BattleEventConditions)
		else:
			_Switch1 = LCFInt(1)
		if current == 3:
			_Switch2 = LCFInt(input)
			current = BERInt(input)
		elif (current < 3) and (current > 0):
			raise LCFUnexpectedSection(current, 3, BattleEventConditions)
		else:
			_Switch2 = LCFInt(1)
		if current == 4:
			_Variable = LCFInt(input)
			current = BERInt(input)
		elif (current < 4) and (current > 0):
			raise LCFUnexpectedSection(current, 4, BattleEventConditions)
		else:
			_Variable = LCFInt(1)
		if current == 5:
			_VarValue = LCFInt(input)
			current = BERInt(input)
		elif (current < 5) and (current > 0):
			raise LCFUnexpectedSection(current, 5, BattleEventConditions)
		else:
			_VarValue = LCFInt(0)
		if current == 6:
			_TurnsMultiple = LCFInt(input)
			current = BERInt(input)
		elif (current < 6) and (current > 0):
			raise LCFUnexpectedSection(current, 6, BattleEventConditions)
		else:
			_TurnsMultiple = LCFInt(0)
		if current == 7:
			_TurnsConst = LCFInt(input)
			current = BERInt(input)
		elif (current < 7) and (current > 0):
			raise LCFUnexpectedSection(current, 7, BattleEventConditions)
		else:
			_TurnsConst = LCFInt(0)
		if current == 8:
			_ExhaustionMin = LCFInt(input)
			current = BERInt(input)
		elif (current < 8) and (current > 0):
			raise LCFUnexpectedSection(current, 8, BattleEventConditions)
		else:
			_ExhaustionMin = LCFInt(0)
		if current == 9:
			_ExhaustionMax = LCFInt(input)
			current = BERInt(input)
		elif (current < 9) and (current > 0):
			raise LCFUnexpectedSection(current, 9, BattleEventConditions)
		else:
			_ExhaustionMax = LCFInt(100)
		if current == 10:
			_MonsterHPID = LCFInt(input)
			current = BERInt(input)
		elif (current < 10) and (current > 0):
			raise LCFUnexpectedSection(current, 10, BattleEventConditions)
		else:
			_MonsterHPID = LCFInt(0)
		if current == 11:
			_MonsterHPMin = LCFInt(input)
			current = BERInt(input)
		elif (current < 11) and (current > 0):
			raise LCFUnexpectedSection(current, 11, BattleEventConditions)
		else:
			_MonsterHPMin = LCFInt(0)
		if current == 12:
			_MonsterHPMax = LCFInt(input)
			current = BERInt(input)
		elif (current < 12) and (current > 0):
			raise LCFUnexpectedSection(current, 12, BattleEventConditions)
		else:
			_MonsterHPMax = LCFInt(100)
		if current == 13:
			_HeroHP = LCFInt(input)
			current = BERInt(input)
		elif (current < 13) and (current > 0):
			raise LCFUnexpectedSection(current, 13, BattleEventConditions)
		else:
			_HeroHP = LCFInt(1)
		if current == 14:
			_HeroHPMin = LCFInt(input)
			current = BERInt(input)
		elif (current < 14) and (current > 0):
			raise LCFUnexpectedSection(current, 14, BattleEventConditions)
		else:
			_HeroHPMin = LCFInt(0)
		if current == 15:
			_HeroHPMax = LCFInt(input)
			current = BERInt(input)
		elif (current < 15) and (current > 0):
			raise LCFUnexpectedSection(current, 15, BattleEventConditions)
		else:
			_HeroHPMax = LCFInt(100)
		if current == 16:
			_MonsterTurnID = LCFInt(input)
			current = BERInt(input)
		elif (current < 16) and (current > 0):
			raise LCFUnexpectedSection(current, 16, BattleEventConditions)
		else:
			_MonsterTurnID = LCFInt(0)
		if current == 17:
			_MonsterTurnsMultiple = LCFInt(input)
			current = BERInt(input)
		elif (current < 17) and (current > 0):
			raise LCFUnexpectedSection(current, 17, BattleEventConditions)
		else:
			_MonsterTurnsMultiple = LCFInt(0)
		if current == 18:
			_MonsterTurnsConst = LCFInt(input)
			current = BERInt(input)
		elif (current < 18) and (current > 0):
			raise LCFUnexpectedSection(current, 18, BattleEventConditions)
		else:
			_MonsterTurnsConst = LCFInt(0)
		if current == 19:
			_HeroTurn = LCFInt(input)
			current = BERInt(input)
		elif (current < 19) and (current > 0):
			raise LCFUnexpectedSection(current, 19, BattleEventConditions)
		else:
			_HeroTurn = LCFInt(1)
		if current == 20:
			_HeroTurnsMultiple = LCFInt(input)
			current = BERInt(input)
		elif (current < 20) and (current > 0):
			raise LCFUnexpectedSection(current, 20, BattleEventConditions)
		else:
			_HeroTurnsMultiple = LCFInt(0)
		if current == 21:
			_HeroTurnsConst = LCFInt(input)
			current = BERInt(input)
		elif (current < 21) and (current > 0):
			raise LCFUnexpectedSection(current, 21, BattleEventConditions)
		else:
			_HeroTurnsConst = LCFInt(0)
		if current == 22:
			_HeroCommandWho = LCFInt(input)
			current = BERInt(input)
		elif (current < 22) and (current > 0):
			raise LCFUnexpectedSection(current, 22, BattleEventConditions)
		else:
			_HeroCommandWho = LCFInt(1)
		if current == 23:
			_HeroCommandWhich = LCFInt(input)
			current = BERInt(input)
		elif (current < 23) and (current > 0):
			raise LCFUnexpectedSection(current, 23, BattleEventConditions)
		else:
			_HeroCommandWhich = LCFInt(1)
		unless current == 0:
			raise Boo.Lang.Runtime.AssertionFailedException("Ending 0 not found at offset $(input.Position.ToString('X'))")

	public def Save(output as System.IO.Stream):
		WriteBERInt(output, 1)
		WriteValue(output, _Conditions)
		unless _Switch1 == 1:
			WriteBERInt(output, 2)
			WriteValue(output, _Switch1)
		unless _Switch2 == 1:
			WriteBERInt(output, 3)
			WriteValue(output, _Switch2)
		unless _Variable == 1:
			WriteBERInt(output, 4)
			WriteValue(output, _Variable)
		unless _VarValue == 0:
			WriteBERInt(output, 5)
			WriteValue(output, _VarValue)
		unless _TurnsMultiple == 0:
			WriteBERInt(output, 6)
			WriteValue(output, _TurnsMultiple)
		unless _TurnsConst == 0:
			WriteBERInt(output, 7)
			WriteValue(output, _TurnsConst)
		unless _ExhaustionMin == 0:
			WriteBERInt(output, 8)
			WriteValue(output, _ExhaustionMin)
		unless _ExhaustionMax == 100:
			WriteBERInt(output, 9)
			WriteValue(output, _ExhaustionMax)
		unless _MonsterHPID == 0:
			WriteBERInt(output, 10)
			WriteValue(output, _MonsterHPID)
		unless _MonsterHPMin == 0:
			WriteBERInt(output, 11)
			WriteValue(output, _MonsterHPMin)
		unless _MonsterHPMax == 100:
			WriteBERInt(output, 12)
			WriteValue(output, _MonsterHPMax)
		unless _HeroHP == 1:
			WriteBERInt(output, 13)
			WriteValue(output, _HeroHP)
		unless _HeroHPMin == 0:
			WriteBERInt(output, 14)
			WriteValue(output, _HeroHPMin)
		unless _HeroHPMax == 100:
			WriteBERInt(output, 15)
			WriteValue(output, _HeroHPMax)
		unless _MonsterTurnID == 0:
			WriteBERInt(output, 16)
			WriteValue(output, _MonsterTurnID)
		unless _MonsterTurnsMultiple == 0:
			WriteBERInt(output, 17)
			WriteValue(output, _MonsterTurnsMultiple)
		unless _MonsterTurnsConst == 0:
			WriteBERInt(output, 18)
			WriteValue(output, _MonsterTurnsConst)
		unless _HeroTurn == 1:
			WriteBERInt(output, 19)
			WriteValue(output, _HeroTurn)
		unless _HeroTurnsMultiple == 0:
			WriteBERInt(output, 20)
			WriteValue(output, _HeroTurnsMultiple)
		unless _HeroTurnsConst == 0:
			WriteBERInt(output, 21)
			WriteValue(output, _HeroTurnsConst)
		unless _HeroCommandWho == 1:
			WriteBERInt(output, 22)
			WriteValue(output, _HeroCommandWho)
		unless _HeroCommandWhich == 1:
			WriteBERInt(output, 23)
			WriteValue(output, _HeroCommandWhich)
		output.WriteByte(0)

	public Conditions as LCFWord:
		get:
			return _Conditions
		set:
			self._Conditions = value

	public Switch1 as int:
		get:
			return _Switch1
		set:
			self._Switch1 = value

	public Switch2 as int:
		get:
			return _Switch2
		set:
			self._Switch2 = value

	public Variable as int:
		get:
			return _Variable
		set:
			self._Variable = value

	public VarValue as int:
		get:
			return _VarValue
		set:
			self._VarValue = value

	public TurnsMultiple as int:
		get:
			return _TurnsMultiple
		set:
			self._TurnsMultiple = value

	public TurnsConst as int:
		get:
			return _TurnsConst
		set:
			self._TurnsConst = value

	public ExhaustionMin as int:
		get:
			return _ExhaustionMin
		set:
			self._ExhaustionMin = value

	public ExhaustionMax as int:
		get:
			return _ExhaustionMax
		set:
			self._ExhaustionMax = value

	public MonsterHPID as int:
		get:
			return _MonsterHPID
		set:
			self._MonsterHPID = value

	public MonsterHPMin as int:
		get:
			return _MonsterHPMin
		set:
			self._MonsterHPMin = value

	public MonsterHPMax as int:
		get:
			return _MonsterHPMax
		set:
			self._MonsterHPMax = value

	public HeroHP as int:
		get:
			return _HeroHP
		set:
			self._HeroHP = value

	public HeroHPMin as int:
		get:
			return _HeroHPMin
		set:
			self._HeroHPMin = value

	public HeroHPMax as int:
		get:
			return _HeroHPMax
		set:
			self._HeroHPMax = value

	public MonsterTurnID as int:
		get:
			return _MonsterTurnID
		set:
			self._MonsterTurnID = value

	public MonsterTurnsMultiple as int:
		get:
			return _MonsterTurnsMultiple
		set:
			self._MonsterTurnsMultiple = value

	public MonsterTurnsConst as int:
		get:
			return _MonsterTurnsConst
		set:
			self._MonsterTurnsConst = value

	public HeroTurn as int:
		get:
			return _HeroTurn
		set:
			self._HeroTurn = value

	public HeroTurnsMultiple as int:
		get:
			return _HeroTurnsMultiple
		set:
			self._HeroTurnsMultiple = value

	public HeroTurnsConst as int:
		get:
			return _HeroTurnsConst
		set:
			self._HeroTurnsConst = value

	public HeroCommandWho as int:
		get:
			return _HeroCommandWho
		set:
			self._HeroCommandWho = value

	public HeroCommandWhich as int:
		get:
			return _HeroCommandWhich
		set:
			self._HeroCommandWhich = value
