namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Newtonsoft.Json.Linq

macro Vocab(body as ExpressionStatement*):
	var result = JObject()
	for bin in body.Select({es | es.Expression}).Cast[of BinaryExpression]():
		assert bin.Operator = BinaryOperatorType.Assign
		var l = bin.Left cast StringLiteralExpression
		var r = bin.Right cast StringLiteralExpression
		result[l.Value] = r.Value
	AddResource('Vocab', result)