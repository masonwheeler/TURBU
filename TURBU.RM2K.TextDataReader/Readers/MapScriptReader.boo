namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast

macro MapCode(id as IntegerLiteralExpression, body as TypeMemberStatement*):
	var name = ReferenceExpression("Map$(id.Value.ToString('D4'))")
	var result = [|
		partial class $name(turbu.maps.TRpgMap):
			pass
	|]
	
	result.Members.AddRange(body.Select({tm | tm.TypeMember}).Cast[of Method]())
	var scriptList = MapCode['scriptList'] cast Dictionary[of int, string]
	result.Members.Add(BuildScriptMap(scriptList))
	yield result
	yield [|import System.Linq.Enumerable|]

macro MapCode.PageScript(id as int, page as int):
	var name = "Event$(id.ToString('D4'))Page$(page.ToString('D3'))"
	var result = [|
		internal def $name() as System.Threading.Tasks.Task:
			$(PageScript.Body)
	|]
	var scriptList = MapCode['scriptList'] cast Dictionary[of int, string]
	if scriptList is null:
		scriptList = Dictionary[of int, string]()
		MapCode['scriptList'] = scriptList
	scriptList.Add(id << 16 + page, name)
	result.Accept(ScriptProcessor())
	return TypeMemberStatement(result)

macro BattleScripts(body as TypeMemberStatement*):
	var result = [|
		static class BattleScripts:
			pass
	|]
	
	result.Members.AddRange(body.Select({tm | tm.TypeMember}).Cast[of Method]())
	// TODO: Some version of this will be needed eventually, but for now it's implemented wrong and breaking things
	# var scriptList = BattleScripts['scriptList'] cast Dictionary[of int, string]
	# var scriptMap = BuildScriptMap(scriptList)
	# scriptMap.Modifiers = TypeMemberModifiers.Public
	# result.Members.Add(scriptMap)
	yield result
	yield [|import System.Linq.Enumerable|]

macro BattleScripts.BattleScript(id as int, page as int):
	var name = "BattleScript$(id.ToString('D4'))Page$(page.ToString('D3'))"
	var result = [|
		public def $name():
			$(BattleScript.Body)
	|]
	var scriptList = BattleScripts['scriptList'] cast Dictionary[of int, string]
	if scriptList is null:
		scriptList = Dictionary[of int, string]()
		BattleScripts['scriptList'] = scriptList
	scriptList.Add(id << 16 + page, name)
	result.Accept(ScriptProcessor())
	return TypeMemberStatement(result)

macro BattleScripts.BattleGlobal(id as int):
	var name = "BattleGlobal$(id.ToString('D4'))"
	var result = [|
		public def $name():
			$(BattleGlobal.Body)
	|]
	result.Accept(ScriptProcessor())
	return TypeMemberStatement(result)

internal def BuildScriptMap(values as Dictionary[of int, string]) as Method:
	result = [|
		protected override def MapScripts():
			pass
	|]
	body = result.Body
	if values is not null:
		for pair in values:
			k = pair.Key
			id = k >> 16
			page = k % (2**16)
			body.Add([|MapObjects.Single({o | return o.ID == $id}).Pages.Single({p | return p.ID == $page}).Script = $(ReferenceExpression(pair.Value))|])
	return result

class ScriptProcessor(DepthFirstTransformer):
	
	private _seenAwait as bool

	override def OnMethod(node as Method):
		_seenAwait = false
		super.OnMethod(node)
		if _seenAwait:
			node.Attributes.Add(Boo.Lang.Compiler.Ast.Attribute('async'))
		else: node.Body.Add([|return System.Threading.Tasks.Task.FromResult(true)|])


	override def OnMethodInvocationExpression(node as MethodInvocationExpression):
		var target = node.Target
		if target.NodeType == NodeType.ReferenceExpression and target.ToString() in ('await', 'Wait'):
			_seenAwait = true
		super.OnMethodInvocationExpression(node)
	

macro comment:
	pass