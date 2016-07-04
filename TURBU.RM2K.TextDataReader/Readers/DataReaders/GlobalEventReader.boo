namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro GlobalEvents(body as ExpressionStatement*):
	result = (MakeListValue('', 'TRpgMapObject', body).Expression cast MethodInvocationExpression).Arguments[0]
	result.Accept(EnumFiller( {'Trigger': [|TStartCondition|]} ))
	return ExpressionStatement(result)

macro GlobalEvents.Script(id as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Switch(id as int):
		return ExpressionStatement([| Conditions({return Switch[$id]}) |])
	
	var page = PropertyListWithID('TRpgEventPage', [|1|], body)
	page.NamedArguments.Add(ExpressionPair([|Script|], ReferenceExpression("GS$(id.Value.ToString('D4'))")))
	var pages = MakeListValue('Pages', 'TRpgEventPage', (ExpressionStatement(page),))
	var result = ExpressionStatement(PropertyList('TRpgMapObject', id, (pages,)))
	return result
