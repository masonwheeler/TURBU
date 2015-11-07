namespace TURBU.RM2K.Import.LCF

import System
import System.IO
import System.Linq.Enumerable
import System.Text
import TURBU.Meta

class LCFInt:
	private final _value as int
	
	def constructor(input as Stream):
		length = input.ReadByte()
		if length == 1:
			_value = input.ReadByte()
		else:
			_value = BERInt(input)
	
	def constructor(value as int):
		_value = value
	
	public static def op_Implicit(l as LCFInt) as int:
		return l._value
	
	public override def ToString():
		return _value.ToString()

class LCFWord(ILCFObject):
	private final _value as int
	
	[Property(Is2k3)]
	private static _is2k3 as bool
	
	def constructor(input as Stream):
		if _is2k3:
			bytes = array(byte, 2)
			input.Read(bytes, 0, 2)
			_value = BitConverter.ToInt16(bytes, 0)
		else: _value = LCFInt(input)
	
	def Save(output as Stream):
		if _is2k3:
			bytes = BitConverter.GetBytes(_value cast short)
			output.Write(bytes, 0, 2)
		else: WriteBERInt(output, _value)
	
	def constructor(value as int):
		_value = value
	
	public static def op_Implicit(l as LCFWord) as int:
		return l._value
	
	public override def ToString():
		return _value.ToString()


class LCFString:
	private final _value as string
	
	def constructor(input as Stream):
		_value = ReadLCFString(input)
	
	def constructor(value as string):
		_value = value
	
	public static def op_Implicit(l as LCFString) as string:
		return l._value

	public override def ToString():
		return _value.ToString()

class LCFBool:
	private final _value as bool
	
	def constructor(input as Stream):
		length = input.ReadByte()
		assert length == 1
		_value = input.ReadByte() != 0
	
	def constructor(value as bool):
		_value = value
	
	public static def op_Implicit(l as LCFBool) as bool:
		return l._value
	
	public override def ToString():
		return _value.ToString()

class LCFByteArray:
	private final _value as (byte)
	
	def constructor(input as Stream):
		length = BERInt(input)
		_value = array(byte, length)
		input.Read(_value, 0, length)
	
	def Save(output as Stream):
		WriteBERInt(output, _value.Length)
		for value in _value:
			output.WriteByte(value)
	
	public static def op_Implicit(l as LCFByteArray) as (byte):
		return l._value
	
	Length as int:
		get: return _value.Length

class LCFUshortArray:
	private final _value as (int)
	
	def constructor(input as Stream):
		length = BERInt(input)
		buffer = array(byte, length)
		input.Read(buffer, 0, length)
		_value = array(int, length / 2)
		for i in range(length / 2):
			_value[i] = BitConverter.ToUInt16(buffer, i * 2)
	
	def Save(output as Stream):
		WriteBERInt(output, _value.Length * 2)
		for value in _value:
			arr = BitConverter.GetBytes(value)
			output.Write(arr, 0, 2)
	
	public static def op_Implicit(l as LCFUshortArray) as (int):
		return l._value
	
	Length as int:
		get: return _value.Length

class LCFIntArray:
	private final _value as (int)
	
	def constructor(input as Stream):
		length = BERInt(input)
		buffer = array(byte, length)
		input.Read(buffer, 0, length)
		_value = array(int, length / 4)
		for i in range(length / 4):
			_value[i] = BitConverter.ToInt32(buffer, i * 4)
	
	def Save(output as Stream):
		WriteBERInt(output, _value.Length * 4)
		for value in _value:
			arr = BitConverter.GetBytes(value)
			output.Write(arr, 0, 4)
	
	public static def op_Implicit(l as LCFIntArray) as (int):
		return l._value
	
	Length as int:
		get: return _value.Length

class LCFBoolArray:
	private final _value as (bool)
	
	def constructor(input as Stream):
		length = BERInt(input)
		buffer = array(byte, length)
		input.Read(buffer, 0, length)
		_value = array(bool, length)
		for i in range(length):
			_value[i] = buffer[i] != 0
	
	def Save(output as Stream):
		WriteBERInt(output, _value.Length)
		for value in _value:
			output.WriteByte((1 if value else 0))
	
	public static def op_Implicit(l as LCFBoolArray) as (bool):
		return l._value
	
	Length as int:
		get: return _value.Length

internal def BERInt(input as Stream) as int:
	result = 0
	repeat:
		value = input.ReadByte()
		result = (result << 7) + (value % 128)
		until value < 128
	return result

internal def WriteBERInt(output as Stream, value as int):
	if value < 128 and value >= 0:
		output.WriteByte(value)
	else:
		dividend as uint = 128
		base as byte
		unchecked: unsigned = value cast uint
		stack = List[of byte]()
		i = 0
		while unsigned != 0:
			base = unsigned % dividend
			stack.Add((base if i == 0 else base | 128))
			++i
			unsigned /= dividend
		output.Write(stack.Reversed.ToArray(), 0, stack.Count)
	
internal def WriteByteArray(output as Stream, value as (byte)):
	WriteBERInt(output, value.Length)
	output.Write(value, 0, value.Length)

internal def ReadLCFString(input as Stream) as string:
	length = BERInt(input)
	buffer = array(byte, length)
	input.Read(buffer, 0, length)
	return Encoding.Default.GetString(buffer)

public def WriteList[of T(ILCFObject)](output as Stream, list as System.Collections.Generic.List[of T]):
	subStream = MemoryStream()
	WriteBERInt(subStream, list.Count)
	for item in list:
		item.Save(subStream)
	WriteByteArray(output, subStream.ToArray())

public def WriteSequence[of T(ILCFObject)](output as Stream, list as System.Collections.Generic.List[of T]):
	subStream = MemoryStream()
	for item in list:
		item.Save(subStream)
	WriteByteArray(output, subStream.ToArray())

internal def WriteValue(output as Stream, value as ILCFObject):
	subStream = MemoryStream()
	value.Save(subStream)
	WriteByteArray(output, subStream.ToArray())

internal def WriteValue(output as Stream, value as int):
	subStream = MemoryStream()
	WriteBERInt(subStream, value)
	WriteByteArray(output, subStream.ToArray())

internal def WriteValue(output as Stream, value as string):
	utf8 = (array(byte, 0) if value is null else Encoding.Default.GetBytes(value))
	WriteByteArray(output, utf8)

internal def WriteValue(output as Stream, value as bool):
	output.WriteByte(1)
	output.WriteByte((1 if value else 0))

internal def WriteValue(output as Stream, value as LCFIntArray):
	if value is not null:
		value.Save(output)
	else: output.WriteByte(0)

internal def WriteValue(output as Stream, value as LCFUshortArray):
	if value is not null:
		value.Save(output)
	else: output.WriteByte(0)

internal def WriteValue(output as Stream, value as LCFByteArray):
	if value is not null:
		value.Save(output)
	else: output.WriteByte(0)

internal def WriteValue(output as Stream, value as LCFBoolArray):
	if value is not null:
		value.Save(output)
	else: output.WriteByte(0)

internal class LCFUnexpectedSection(Exception):
	
	def constructor(current as int, id as int, name as Type):
		super("While parsing $name, expected section $id but found $current")