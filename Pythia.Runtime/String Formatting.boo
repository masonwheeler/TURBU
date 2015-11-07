namespace Pythia.Runtime

import System
import Boo.Adt
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

[Meta]
def StringReplace(value as Expression, before as Expression, after as Expression, modifiers as ListLiteralExpression):
	replaceAll = false
	for mod as ReferenceExpression in modifiers.Items:
		if mod.Matches([|rfReplaceAll|]):
			replaceAll = true
	if replaceAll:
		return [|$value.Replace($before, $after)|]
	else:
		return [|$value.ReplaceFirst($before, $after)|]

[Extension]
def ReplaceFirst(text as string, search as string, replace as string) as string:
	pos as int = text.IndexOf(search)
	return text if (pos < 0)
	return text.Substring(0, pos) + replace + text.Substring(pos + search.Length);

def QuotedStr(text as string) as string:
	using tw = System.IO.StringWriter():
		Boo.Lang.Compiler.Ast.Visitors.BooPrinterVisitor.WriteStringLiteral(text, tw)
		return tw.ToString()

def AnsiDequotedStr(text as string) as string:
	let SPECIAL_CHARS = {char('r'): char('\r'), char('n'): char('\n'), char('t'): char('\t'), char('\\'): char('\\'), 
		char('a'): char('\a'), char('b'): char('\b'), char('f'): char('\f'), char('0'): char('\0'), char('\''): char('\'')}
	unless text.StartsWith("'") and text.EndsWith("'"):
		return ''
	text = text[1:-1]
	using sb = System.Text.StringBuilder(text.Length):
		i = 0
		while i < text.Length:
			if text[i] == char('\\'):
				++i
				unescaped = SPECIAL_CHARS[text[i]]
				if unescaped isa char:
					sb.Append(unescaped cast char)
				else: raise "Unknown escape character: $(text[i])"
			else: sb.Append(text[i])
			++i
		return sb.ToString()