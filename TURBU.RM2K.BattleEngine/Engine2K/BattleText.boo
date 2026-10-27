namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import Boo.Adt
import TURBU.Meta
import commons
import System.Collections.Generic
import System.Text
import TURBU.RM2K
import turbu.constants

static class TBattleText:

	let NoValue = '???'

	//as the object of a message: "the value, with its unit in front of it"
	public ValueObject = char(1).ToString()

	public def Vocab(key as string) as string:
		return '' unless GDatabase.value.HasVocab(key)
		return GDatabase.value.Vocab[key]

	private def ReplaceCode(source as string, letter as char, replacement as string) as string:
		result = StringBuilder()
		i = 0
		while i < source.Length:
			if (source[i] == char('%')) and (i < source.Length - 1) and (char.ToUpper(source[i + 1]) == letter):
				result.Append(replacement)
				i += 2
			else:
				result.Append(source[i])
				++i
		return result.ToString()

	public def Expand(template as string, subject as string, obj as string, value as string, unitText as string) as string:
		return '' if string.IsNullOrEmpty(template)
		var o = obj
		if o == ValueObject:
			o = (value if unitText == '' else unitText + ' ' + value)
		if template.Contains('%'):
			var result = ReplaceCode(template, char('S'), subject)
			result = ReplaceCode(result, char('O'), o)
			result = ReplaceCode(result, char('V'), value)
			return ReplaceCode(result, char('U'), unitText)
		if template.Contains('?n') or template.Contains('?c'):
			var one = (subject if subject != NoValue else value)
			return template.Replace('?n1', subject).Replace('?n2', o).Replace('?c', value).Replace("?n", one)
		return subject + template

	public def Say(key as string, subject as string, obj as string, value as string, unitText as string) as string:
		return Expand(Vocab(key), subject, obj, value, unitText)

	public def Say(key as string, subject as string) as string:
		return Expand(Vocab(key), subject, NoValue, NoValue, NoValue)

	public def Say(key as string, subject as string, obj as string) as string:
		return Expand(Vocab(key), subject, obj, NoValue, NoValue)

	public def SayPlain(template as string, subject as string, obj as string, value as string, unitText as string) as string:
		return '' if string.IsNullOrEmpty(template)
		return template unless template.Contains('%') or template.Contains('?n') or template.Contains('?c')
		return Expand(template, subject, obj, value, unitText)

	public def SayPlain(key as string, subject as string) as string:
		return SayPlain(Vocab(key), subject, NoValue, NoValue, NoValue)

	public def SayTemplate(template as string, subject as string, obj as string, value as string, unitText as string) as string:
		return Expand(template, subject, obj, value, unitText)

	public def SayTemplate(template as string, subject as string) as string:
		return Expand(template, subject, NoValue, NoValue, NoValue)

	public def Wrap(line as string, maxCol as int) as string:
		let breakStr = "\r\n"
		let quoteChars = "'\""
		col = 1
		pos = 1
		linePos = 1
		breakPos = 0
		quoteChar = char(' ')
		existingBreak = false
		lineLen = line.Length
		result = StringBuilder()
		while pos <= lineLen:
			cur = line[pos - 1]
			if cur == char('\r'):
				if quoteChar == char(' '):
					existingBreak = (pos < lineLen) and (line[pos] == char('\n'))
					if existingBreak:
						++pos
						breakPos = pos
			elif IsBreakChar(cur):
				breakPos = pos if quoteChar == char(' ')
			elif quoteChars.IndexOf(cur) >= 0:
				if cur == quoteChar:
					quoteChar = char(' ')
				elif quoteChar == char(' '):
					quoteChar = cur
			++pos
			++col
			if (quoteChars.IndexOf(quoteChar) < 0) and (existingBreak or ((col > maxCol) and (breakPos > linePos))):
				col = pos - breakPos
				result.Append(line.Substring(linePos - 1, breakPos - linePos + 1))
				if quoteChars.IndexOf(cur) < 0:
					while pos <= lineLen:
						if IsBreakChar(line[pos - 1]):
							++pos
						elif (pos < lineLen) and (line[pos - 1] == char('\r')) and (line[pos] == char('\n')):
							pos += 2
						else:
							break
				result.Append(breakStr) if (not existingBreak) and (pos < lineLen)
				++breakPos
				linePos = breakPos
				existingBreak = false
		result.Append(line.Substring(linePos - 1)) if linePos <= lineLen
		return result.ToString()

	private def IsBreakChar(value as char) as bool:
		return value in (char(' '), char('-'), char('\t'))

	public def SplitLines(text as string, lines as List[of string]):
		i = 0
		start = 0
		while i < text.Length:
			if (text[i] == char('\r')) or (text[i] == char('\n')):
				lines.Add(text.Substring(start, i - start))
				++i if (text[i] == char('\r')) and (i < text.Length - 1) and (text[i + 1] == char('\n'))
				start = i + 1
			++i
		lines.Add(text.Substring(start)) if start < text.Length

class TMessagePool:

	[Getter(Lines)]
	private _lines = List[of string]()

	public Count as int:
		get: return _lines.Count

	public def Clear():
		_lines.Clear()

	public def AddBreak():
		_lines.Add('')

	public def AddWrapped(text as string, columns as int):
		wrapped = TBattleText.Wrap(text, columns)
		if wrapped == '':
			_lines.Add('')
		else:
			TBattleText.SplitLines(wrapped, _lines)

	public def TakeLine() as string:
		return '' if _lines.Count == 0
		var result = _lines[0]
		_lines.RemoveAt(0)
		return result
