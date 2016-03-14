namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast

def ValuePairOf(value as MethodInvocationExpression) as ExpressionPair:
	if value.Arguments.Count != 1:
		raise "[ValuePairOf] Invalid expression: $value"
	return ExpressionPair(value.Target, value.Arguments.First)

def PropertyList(name as string, index as IntegerLiteralExpression, body as ExpressionStatement*) as MethodInvocationExpression:
	result = MethodInvocationExpression(ReferenceExpression(name))
	list = result.NamedArguments
	list.Add(ExpressionPair([|ID|], index))
	list.AddRange(body.Select({es | es.Expression}).Cast[of MethodInvocationExpression]().Select({e | ValuePairOf(e)}))
	return result

def PropertyListWithID(name as string, index as IntegerLiteralExpression, body as ExpressionStatement*) as MethodInvocationExpression:
	result = MethodInvocationExpression(ReferenceExpression(name))
	result.Arguments.Add(index)
	list = result.NamedArguments
	list.AddRange(body.Select({es | es.Expression}).Cast[of MethodInvocationExpression]().Select({e | ValuePairOf(e)}))
	return result

def MakeArrayValue(name as string, values as Expression*):
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(values)
	result = MethodInvocationExpression(ReferenceExpression(name))
	result.Arguments.Add(arr)
	return ExpressionStatement(result)

private def DoMakeListValue(name as string, baseType as string, values as ExpressionStatement*, listClass as ReferenceExpression):
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(values.Select({es | es.Expression}))
	str = SimpleTypeReference(baseType)
	constructorCall = [|$listClass[of $str]($arr)|]
	result = MethodInvocationExpression(ReferenceExpression(name))
	result.Arguments.Add(constructorCall)
	return ExpressionStatement(result)

def MakeDataListValue(name as string, baseType as string, values as ExpressionStatement*):
	return DoMakeListValue(name, baseType, values, [|turbu.classes.TRpgDataList|])

def MakeListValue(name as string, baseType as string, values as ExpressionStatement*):
	return DoMakeListValue(name, baseType, values, [|turbu.containers.TRpgObjectList|])

def Flatten(values as Statement*) as ExpressionStatement*:
	for value in values:
		if value isa Block:
			for sub in Flatten((value as Block).Statements):
				yield sub
		else:
			yield value cast ExpressionStatement

def Lambdify(e as Expression, i as IntegerLiteralExpression, typename as String):
	T = SimpleTypeReference(typename)
	
	return ExpressionStatement([|System.Collections.Generic.KeyValuePair[of int, System.Func[of $T]]($i, {return $e})|])

def Lambdify(name as string, index as IntegerLiteralExpression, body as ExpressionStatement*) as ExpressionStatement:
	return Lambdify(PropertyList(name, index, body), index, name)

def Lambdify(name as string, index as IntegerLiteralExpression, body as ExpressionStatement*, formalType as string) as ExpressionStatement:
	return Lambdify(PropertyList(name, index, body), index, formalType)

class EnumFiller(FastDepthFirstVisitor):
	
	private _mapping as Hash
	
	def constructor(mapping as Hash):
		_mapping = mapping
	
	override def OnExpressionPair(node as ExpressionPair):
		l = node.First as ReferenceExpression
		if l is null or not _mapping.ContainsKey(l.Name):
			super(node)
		else:
			r = node.Second cast ReferenceExpression
			node.Second = [|$(_mapping[l.Name] cast ReferenceExpression).$r|]

class PropRenamer(FastDepthFirstVisitor):
	
	private _mapping as Hash
	
	def constructor(mapping as Hash):
		_mapping = mapping
	
	override def OnExpressionPair(node as ExpressionPair):
		l = node.First as ReferenceExpression
		if l is not null and _mapping.ContainsKey(l.Name):
			node.First = ReferenceExpression(_mapping[l.Name] cast string)
