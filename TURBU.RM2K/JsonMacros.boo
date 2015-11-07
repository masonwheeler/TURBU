namespace Newtonsoft.Json

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro writeJsonObject(writer as ReferenceExpression, body as Statement*):
	yield [|$writer.WriteStartObject()|]
	yieldAll body
	yield [|$writer.WriteEndObject()|]

macro writeJsonArray(writer as ReferenceExpression, body as Statement*):
	yield [|$writer.WriteStartArray()|]
	yieldAll body
	yield [|$writer.WriteEndArray()|]
	
macro writeJsonProperty(writer as ReferenceExpression, name as StringLiteralExpression, value as Expression):
	return [|
		$writer.WritePropertyName($name)
		$writer.WriteValue($value)
	|]