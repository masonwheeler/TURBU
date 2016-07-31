namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler 
import Boo.Lang.Compiler.Ast
import Newtonsoft.Json.Linq
import TURBU.Meta

class JsonStatement(CustomStatement):
	[Getter(Value)]
	private _value as JToken

	def constructor(value as JToken):
		_value = value
	
	override def ToString() as string:
		return _value.ToString()

def ExpressionValue(value as Expression) as JToken:
	caseOf value.NodeType:
		case NodeType.IntegerLiteralExpression:
			return (value cast IntegerLiteralExpression).Value
		case NodeType.StringLiteralExpression:
			return (value cast StringLiteralExpression).Value
		case NodeType.ReferenceExpression:
			return value.ToString()
		case NodeType.DoubleLiteralExpression:
			return (value cast DoubleLiteralExpression).Value
		case NodeType.BoolLiteralExpression:
			return (value cast BoolLiteralExpression).Value
		case NodeType.ListLiteralExpression, NodeType.ArrayLiteralExpression:
			var items = (value cast ListLiteralExpression).Items
			return JArray(items.Select(ExpressionValue))
		case NodeType.NullLiteralExpression:
			return null
		default: 
			raise "Unknown node type $(value.NodeType)"

private def ValuePairOf(value as MethodInvocationExpression) as JProperty:
	if value.Arguments.Count != 1:
		raise "[ValuePairOf] Invalid expression: $value"
	var arg = value.Arguments.First
	var name = value.Target.ToString()
	return JProperty(name, ExpressionValue(arg))

def Flatten(body as Statement*) as Statement*:
	for value in body:
		if value.NodeType == NodeType.Block:
			yieldAll cast(Block, value).Statements
		else: yield value

private def MakePropertyList(body as Statement*) as JObject:
	var result = JObject()
	var mies = body.OfType[of ExpressionStatement]().Select({es | es.Expression}).Cast[of MethodInvocationExpression]()
	var props = body.OfType[of JsonStatement]().Select({js | js.Value}).Cast[of JProperty]()
	result.Add(props)
	result.Add(mies.Select({mie | ValuePairOf(mie)}))
	return result

def PropertyList(body as Statement*) as JObject:
	return MakePropertyList(Flatten(body))

def PropertyList(id as int, body as Statement*) as JObject:
	var result = PropertyList(body)
	result.Add('ID', id)
	return result

def MakeListValue(name as string, body as JsonStatement*) as JsonStatement:
	return JsonStatement(JProperty(name, body.Select({js | js.Value})))

def MakeArrayValue(name as string, body as Expression*) as JsonStatement:
	return JsonStatement(JProperty(name, body.Select({e | ExpressionValue(e)})))

private class BSONResourceData:
	
	private _value as JObject
	
	def constructor(value as JObject):
		_value = value
	
	def WriteResource(rWriter as System.Resources.IResourceWriter) as void:
		using ms = System.IO.MemoryStream(), writer = Newtonsoft.Json.Bson.BsonWriter(ms):
			_value.WriteTo(writer)
			var id = _value['ID']
			rWriter.AddResource((id.ToString() if id is not null else '0'), ms.ToArray())

private class BSONResource(ICompilerResource)
	[Getter(Name)]
	private _name as string
	
	private _resources = List[of BSONResourceData]()
	
	def constructor(name as string):
		_name = name
	
	def Add(value as JObject):
		_resources.Add(BSONResourceData(value))
	
	def WriteResource(service as IResourceService) as void:
		var writer = service.DefineResource(_name, _name)
		for value in _resources:
			value.WriteResource(writer)

def AddResource(name as string, value as JObject):
	var cc = CompilerContext.Current
	var res = cc.Parameters.Resources.OfType[of BSONResource]().FirstOrDefault({b | b.Name == name})
	if res == null:
		res = BSONResource(name)
		cc.Parameters.Resources.Add(res)
	res.Add(value)
	
[Extension]
def SubMacro(base as MacroStatement, name as string) as MacroStatement:
	return base.Body.Statements.OfType[of MacroStatement]().FirstOrDefault({ms | ms.Name == name})