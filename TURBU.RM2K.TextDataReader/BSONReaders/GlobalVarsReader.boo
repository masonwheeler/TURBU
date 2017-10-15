namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Newtonsoft.Json.Linq

macro GlobalVars(body as Statement*):
	var result = PropertyList(body)
	AddResource('Variables', result)

macro GlobalVars.Switches(body as ExpressionStatement*):
	if body.Count > 0:
		return JsonStatement(JProperty('Switches', MaxGlobalValue(body)))
	
macro GlobalVars.Variables(body as ExpressionStatement*):
	if body.Count > 0:
		return JsonStatement(JProperty('Variables', MaxGlobalValue(body)))

internal def MaxGlobalValue(values as ExpressionStatement*):
	return values.Select({es | ((es.Expression cast BinaryExpression).Left cast IntegerLiteralExpression).Value}).Max()