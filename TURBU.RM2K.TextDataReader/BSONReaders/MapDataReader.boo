namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq

internal def AddValidators(clazz as ClassDefinition, methods as Method*):
	var result = [|
		public override def MapObjectValidPage(id as int) as System.Func of int:
			caseOf id:
				pass
			return null
	|]
	var caseBody = (result.Body.FirstStatement cast MacroStatement).Body
	for method in methods.OrderBy({n | n['ID'] cast int}):
		clazz.Members.Add(method)
		var methodID = method['ID'] cast int
		var thisCase = [|
			case $methodID: return $(ReferenceExpression(method.Name))
		|]
		caseBody.Add(thisCase)
	clazz.Members.Add(result)

internal def AddMoveScripts(clazz as ClassDefinition, methods as Method*):
	var result = [|
		protected override def InitializeRoutes():
			pass
	|]
	var body = result.Body
	for method in methods:
		var obj = method['Obj'] cast int
		var page = method['Page'] cast int
		body.Add([| FMapObjects.First({m | return m.ID == $obj}).Pages[$page].Path = $(ReferenceExpression(method.Name))() |])
		clazz.Members.Add(method)
	clazz.Members.Add(result)

macro MapData(id as int, body as Statement*):
	var result = PropertyList(id, body)
	AddResource('Maps', result)
	
	var methods = MapData.Tags.Get[of Method*]()
	if methods is not null:
		var name = ReferenceExpression("Map$(id.ToString('D4'))")
		var clazz = [|
			partial class $name:
				pass
		|]
		AddValidators(clazz, methods)
		var moveScripts = MapData['MoveScripts'] cast Method*
		if moveScripts is not null:
			AddMoveScripts(clazz, moveScripts)
			yield [| import System.Linq.Enumerable |]
		yield clazz

macro MapData.Size(x as int, y as int):
	return JsonStatement(JProperty('Size', JArray(x, y)))

macro MapData.Panning(hPan as ReferenceExpression, hPanSpeed as int, vPan as ReferenceExpression, vPanSpeed as int):
	yield JsonStatement(JProperty('HScroll', hPan.Name))
	yield JsonStatement(JProperty('VScroll', vPan.Name))
	yield JsonStatement(JProperty('ScrollSpeed', JArray(hPanSpeed, vPanSpeed)))

macro MapData.Background(usesBG as bool, bgName as string):
	yield JsonStatement(JProperty('HasBackground', usesBG))
	yield JsonStatement(JProperty('BgName', bgName))

macro MapData.Tiles(body as JsonStatement*):
	macro Layer(body as ExpressionStatement*):
		var layer = body.SelectMany({es | (es.Expression cast ArrayLiteralExpression).Items}) \
						.Cast[of IntegerLiteralExpression]() \
						.Select({i | i.Value})
		return JsonStatement(JArray(*layer.ToArray()))
		
	return JsonStatement(JProperty('TileMap', JArray(*body.Select({j | j.Value}).ToArray())))

macro MapData.MapObjects(body as Statement*):
	macro MapObject(id as int, body as Statement*):
		macro Position(x as int, y as int):
			return JsonStatement(JProperty('Location', JArray(x, y)))
		
		MapObjects.Body.Add(JsonStatement(PropertyList(id, body)))
		var ifst = body.OfType[of IfStatement]().Single()
		var name = "CheckObj$id"
		var validator = [|
			private def $name() as int:
				pass
		|]
		validator.Body.Add(ifst)
		validator['ID'] = id
		MapObjects.Body.Add(TypeMemberStatement(validator))
		var moves = body.OfType[of TypeMemberStatement]()
		for move in moves:
			var moveMethod = move.TypeMember cast Method
			moveMethod.Name = "Obj$(id)$(moveMethod.Name)"
			moveMethod['Obj'] = id
			var moveScripts = MapData['MoveScripts'] cast List[of Method]
			if moveScripts is null:
				moveScripts = List[of Method]()
				MapData['MoveScripts'] = moveScripts
			moveScripts.Add(moveMethod)
				
	MapData.Tags.Set[of Method*](body.OfType[of TypeMemberStatement]().Select({tm | tm.TypeMember}).Cast[of Method]())
	return MakeListValue('MapObjects', body.OfType[of JsonStatement]())

macro MapData.MapObjects.MapObject.Pages(body as Statement*):
	macro Page(id as int, body as Statement*):
		macro Sprite(filename as string, index as int, facing as ReferenceExpression, frame as int, transparent as bool):
			yield JsonStatement(JProperty('Name', filename))
			yield JsonStatement(JProperty('SpriteIndex', index))
			yield JsonStatement(JProperty('Direction', facing.Name))
			yield JsonStatement(JProperty('Frame', frame))
			yield JsonStatement(JProperty('Transparent', transparent))
		
		macro Move(moveType as ReferenceExpression, frequency as int, animType as ReferenceExpression, speed as int):
			yield JsonStatement(JProperty('MoveType', moveType.Name))
			yield JsonStatement(JProperty('MoveFrequency', frequency))
			yield JsonStatement(JProperty('AnimType', animType.Name))
			yield JsonStatement(JProperty('MoveSpeed', speed))
		
		macro Height(z as int, barrier as bool):
			yield JsonStatement(JProperty('ZOrder', z))
			yield JsonStatement(JProperty('IsBarrier', barrier))
		
		Pages.Body.Add(JsonStatement(PropertyList(id, body)))
		var cond = body.OfType[of IfStatement]().SingleOrDefault()
		if cond is null:
			cond = [|
				if true:
					pass
			|]
		cond.TrueBlock.Add([|return $id|])
		cond['ID'] = id
		Pages.Body.Add(cond)
		var moveScript = Page['MoveScript'] cast Method
		if moveScript is not null:
			moveScript.Name = "Page$(id.ToString('D3'))Move"
			moveScript['Page'] = id - 1
			MapObject.Body.Add(TypeMemberStatement(moveScript))
	
	MapObject.Body.Add(MakeListValue('Pages', body.OfType[of JsonStatement]()))
	var selector = Flatten(body).OfType[of IfStatement]().OrderByDescending({n | return n['ID'] cast int}).ToList()
	var ifst = selector[0]
	var current = ifst
	for value in selector.Skip(1):
		current.FalseBlock = Block()
		current.FalseBlock.Add(value)
		current = value
	current.FalseBlock = Block()
	current.FalseBlock.Add([|return 0|])
	MapObject.Body.Add(ifst)

macro MapData.MapObjects.MapObject.Pages.Page.Conditions(body as ExpressionStatement*):
	macro Switch(id as int):
		return ExpressionStatement([|Switch[$id]|])
	
	macro Variable(comp as BinaryExpression):
		be = BinaryExpression(comp.Operator, [|Ints[$(comp.Left)]|], comp.Right)
		return ExpressionStatement(be)
	
	macro Item(id as int):
		return ExpressionStatement([|HasItem($id)|])
	
	macro Hero(id as int):
		return ExpressionStatement([|HeroPresent($id)|])
	
	macro Timer1(value as int):
		return ExpressionStatement([|Timer.Time <= $value|])
	
	macro Timer2(value as int):
		return ExpressionStatement([|Timer2.Time <= $value|])
	
	result as Expression
	for line in body:
		result = (line.Expression if result is null else [|$result and $(line.Expression)|])
	result = [|true|] if result is null
	return [|
		if $result:
			pass
	|]

macro MapData.MapObjects.MapObject.Pages.Page.MoveScript(loop as bool, ignoreObstacles as bool, body as ExpressionStatement*):
	var bodyArr = ArrayLiteralExpression()
	bodyArr.Items.AddRange(body.Select({es | es.Expression}))
	var method = [|
		private def Name() as turbu.pathing.Path:
			return CreatePath($loop, $ignoreObstacles, $bodyArr)
	|]
	Page['MoveScript'] = method
