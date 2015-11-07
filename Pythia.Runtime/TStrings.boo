namespace Pythia.Runtime

import System
import System.Collections.Generic

class TStrings(List[of string]):
	[Property(Delimiter)]
	protected _delimiter as char
	
	[Property(QuoteChar)]
	protected _quoteChar as char
	
	DelimitedText as string:
		get:
			raise "Not implemented"

enum TDuplicates:
	Accept
	Ignore
	Error

class TStringList(TStrings):
	
	private _sorted as bool
	
	[Property(Duplicates)]
	private _duplicates as TDuplicates
	
	[Property(StrictDelimiter)]
	private _strictDelimiter as bool
	
	private _objects as (object)
	
	public CommaText as string:
		get: return string.Join(',', self)
		set:
			self.Clear()
			self.AddRange(value.Split(*(char(','),)))
	
	public Text as string:
		get: return string.Join(Environment.NewLine, self)
		set:
			self.Clear()
			self.AddRange(value.Split((Environment.NewLine,), StringSplitOptions.None))
	
	public Sorted as bool:
		get: return _sorted
		set:
			_sorted = value
			self.Sort() if value
	
	def IndexOfName(name as string) as int:
		nameEq = name + '='
		for i in range(0, self.Count):
			if self[i].StartsWith(nameEq):
				return i
		return -1
	
	Values[name as string] as string:
		get:
			idx = IndexOfName(name)
			return '' if idx == -1
			return self[idx][name.Length + 1:]
		set:
			idx = IndexOfName(name)
			line = "$name=$value"
			if idx == -1:
				self.Add(line)
			else: self[idx] = line
	
	private def CheckObjectSync():
		if _objects is null or _objects.Length != self.Count:
			Array.Resize[of object](_objects, self.Count)
	
	Objects[index as int] as object:
		get:
			CheckObjectSync()
			return _objects[index]
		set:
			CheckObjectSync()
			_objects[index] = value
	
	new def Add(value as string):
		AddObject(value, null)
	
	def AddObject(value as string, obj as object):
		if _sorted:
			AddSorted(value, obj)
		else:
			super.Add(value)
			CheckObjectSync()
			_objects[_objects.Length - 1] = obj
	
	private def AddSorted(value as string, obj as object):
		idx = IndexOf(value)
		if idx != -1 and _duplicates == TDuplicates.Error:
			raise "Duplicate value '$value' added to TStringList"
		elif idx != -1  and _duplicates == TDuplicates.Ignore:
			_objects[idx] = obj
		else:
			idx = BinarySearch(value)
			assert idx < 0
			idx = ~idx;
			self.Insert(idx, value)
			CheckObjectSync()
			for i in range(_objects.Length - 2, idx - 1, -1):
				_objects[i + 1] = _objects[i]
			_objects[idx] = obj
	
	ValueFromIndex[idx as int] as string:
		get:
			line = self[idx]
			pos = line.IndexOf(char('='))
			return line[pos + 1:]
	
	def SaveToFile(filename as string):
		System.IO.File.WriteAllLines(filename, self, System.Text.Encoding.UTF8)
	
	def AddStrings(other as TStringList):
		AddRange(other)
		l = _objects.Length
		CheckObjectSync()
		for i in range(0, other._objects.Length):
			_objects[i + l] = other._objects[i]