namespace TURBU.RM2K.Import

import Boo.Adt
import Boo.Lang.Compiler.Ast
import System
import System.Collections.Generic
import System.IO
import System.Linq.Enumerable
import commons
import EventBuilder
import turbu.defs
import TURBU.Meta
import TURBU.RM2K.Import.LCF

def ConvertMapScripts(id as int, events as MapEvent*, ScanScript as Action[of EventCommand*], \
		saveScript as Action[of Node], makeWarning as Action [of string, int, int]):
	ms as MacroStatement = [|
		MapCode $id:
			pass
	|]
	for e as MapEvent in events:
		for p in e.Pages.Where({p | p.Script.Count > 1}):
			ms.Body.Add(ConvertPageScript(e.ID, p.ID, p.Script, ScanScript, makeWarning))
	saveScript(ms)

def ConvertBattleScripts(id as int, events as BattleEventPage, ScanScript as Action[of EventCommand*], \
		saveScript as Action[of Node], makeWarning as Action [of string, int, int]):
	if events.Commands.Count > 1:
		script = ConvertPageScript(id, events.ID, events.Commands, ScanScript, makeWarning)
		script.Name = 'BattleScript'
		saveScript(script)

def ConvertGlobalEvent(value as GlobalEvent, ScanScript as Action[of EventCommand*], saveScript as Action[of Node],
		makeWarning as Action [of string, int, int]):
	name = SanitizeScriptName(value.Name)
	script = ConvertPageScript(value.ID, 1, value.Script, ScanScript, makeWarning)
	script.Name = 'GlobalScript'
	script.Arguments.RemoveAt(script.Arguments.Count - 1)
	script.Body.Clear() if value.Script.Count == 1
	saveScript(script)
	result = [|
		Script $(value.ID):
			Name $(StringLiteralExpression(name))
	|]
	caseOf value.StartCondition:
		case 3: cond = [|Automatic|]
		case 4: cond = [|Parallel|]
		case 5: cond = [|Call|]
		default: assert false
	result.Body.Add([|Trigger $cond|])
	result.Body.Add([|Switch $(value.Switch)|]) if value.UsesSwitch
	return result

private def SanitizeScriptName(name as string) as string:
	return name if name == ''
	chars = name.Where({c | char.IsLetterOrDigit(c) or c == '_'}).ToList()
	if char.IsDigit(chars[0]):
		chars.Insert(0, char('G'))
	return string(chars.ToArray())

private def ConvertPageScript(id as int, page as int, script as EventCommand*, \
		ScanScript as Action[of EventCommand*], makeWarning as Action [of string, int, int]) as MacroStatement:
	let REMFUDGE = (20141, 20151, 20713, 20722, 20732)
	ScanScript(script)
	result as MacroStatement = [|
		PageScript $id, $page:
			$(PageScriptBlock(script, {m | makeWarning(m, id, page)}))
	|]
	return result

def PageScriptBlock(script as EventCommand*, makeWarning as Action of string) as Block:
	fudgeFactor = 0
	stack = Stack[of Block]()
	result = Block()
	converter = TScriptConverter(makeWarning)
	try:
		last as Block = result
		for command in script:
			--fudgeFactor if command.Opcode in REMFUDGE
			if command.Depth + fudgeFactor >= stack.Count:
				stack.Push(last)
			elif command.Depth + fudgeFactor < stack.Count - 1:
				stack.Pop()
			if command.Opcode in (20110, 22410): //additional message line
				converter.ConvertOpcode(command, last)
			else:
				newItem = converter.ConvertOpcode(command, stack.Peek())
				last = (newItem if newItem is not null else stack.Peek())
			if (command.Opcode == 10140) or \
				((command.Opcode == 10710) and ((command.Data[3] == 2) or (command.Data[4] != 0))) or \
				((command.Opcode in (10720, 10730)) and (command.Data[2] != 0)):
				++fudgeFactor
		assert stack.Count == 1
		assert fudgeFactor == 0
	failure:
		pass //block.SaveScript()
	return result
	
/*
	      PerformOptimizations(result, converter.LabelGotoCount);
*/

class TScriptConverter:
	
	private callable TConvertRoutine(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block
	
	[Getter(BlockStack)]
	private _blockStack = Stack[of int]()
	
	[Getter(IfStack)]
	private _ifStack = Stack[of IfStatement]()
	
	private _tally = Dictionary[of int, int]()
	
	[Property(LoopDepth)]
	private _loopDepth as int
	
	[Getter(LabelGotoCount)]
	private _labelGotoCount as int
	
	[Getter(MakeWarning)]
	private _makeWarning as Action of string
	
	def constructor(makeWarning as Action of string):
		_makeWarning = makeWarning
	
	private static final _opcodeDictionary = Dictionary[of int, TConvertRoutine](){
		0: Cleanup, 10: {return null}, 20713: {return null}, 20720: {return null}, 20730: {return null}, 
		10110: ConvertShowMessage, 20110: {c, e, p | p.Add(Expression.Lift(e.Name))}, 10130: ConvertPortrait,
		11410: {c, e, p | p.Add([|Wait($(e.Data[0]))|])}, 10230: ConvertTimer, 10310: ConvertMoney,
		10150: {c, e, p | p.Add([|Ints[$(e.Data[1])] = await(InputNumber($(e.Name), $(e.Data[0])))|])},
		10410: ConvertExperience, 10420: ConvertLevel, 10500: ConvertTakeDamage, 10910: ConvertTerrainID,
		10610: {c, e, p | p.Add([|Heroes[$(e.Data[0])].Name = $(e.Name)|])}, 10920: ConvertObjectID,
		10620: {c, e, p | p.Add([|Heroes[$(e.Data[0])].Title = $(e.Name)|])}, 11060: ConvertPanScreen,
		10670: {c, e, p | p.Add([|SetSystemSound(TSfxTypes.$(ReferenceExpression(Enum.GetName(TSfxTypes, e.Data[0]))), $(e.Name), $(e.Data[1]), $(e.Data[2]), $(e.Data[3]))|])},
		10680: {c, e, p | p.Add([|SetSkin($(e.Name), $(e.Data[0] != 0))|])}, 10840: {c, e, p | p.Add([|RideVehicle()|])},
		10820: {c, e, p | p.Add([|MemorizeLocation($(e.Data[0]), $(e.Data[1]), $(e.Data[2]))|])},
		10830: {c, e, p | p.Add([| await(Teleport(Ints[$(e.Data[0])], Ints[$(e.Data[1])], Ints[$(e.Data[2])])) |])},
		11030: ConvertTintScreen,
		11070: {c, e, p | p.Add([|SetWeather(TWeatherEffects.$(ReferenceExpression(Enum.GetName(TWeatherEffects, e.Data[0]))), $(e.Data[1]))|])},
		11340: {c, e, p | p.Add([|await(WaitUntilMoved())|])}, 11350: {c, e, p | p.Add([|StopMoveScripts()|])},
		11510: {c, e, p | p.Add([|PlayMusic($(e.Name), $(e.Data[0]), $(e.Data[1]), $(e.Data[2]), $(e.Data[3]))|])},
		11520: {c, e, p | p.Add([|FadeOutMusic($(e.Data[0]))|])}, 11560: ConvertPlayMovie, 11610: ConvertInput,
		11530: {c, e, p | p.Add([|MemorizeBGM()|])}, 11540: {c, e, p | p.Add([|PlayMemorizedBGM()|])},
		11550: {c, e, p | p.Add([|PlaySound($(e.Name), $(e.Data[0]), $(e.Data[1]), $(e.Data[2]))|])},
		11710: {c, e, p | p.Add([|ChangeTileset($(e.Data[0]))|])}, 11720: ConvertChangeBG, 11810: ConvertTeleportLoc,
		11130: {c, e, p | p.Add([|Image[$(e.Data[0])].Erase()|])}, 11830: ConvertEscapeLoc, 10490: ConvertFullHeal,
		11750: {c, e, p | p.Add([|SubstituteTiles($(e.Data[0] + 1), $(e.Data[1]), $(e.Data[2]))|])},
		11820: {c, e, p | p.Add([|EnableTeleport($(e.Data[0] != 0))|])}, 1006: ConvertForceFlee,
		11840: {c, e, p | p.Add([|EnableEscape($(e.Data[0] != 0))|])}, 11910: {c, e, p | p.Add([|await(SaveMenu())|])},
		11930: {c, e, p | p.Add([|EnableSave($(e.Data[0] != 0))|])}, 11950: {c, e, p | p.Add([|await(OpenMenu())|])},
		11960: {c, e, p | p.Add([|MenuEnabled = $(e.Data[0] != 0)|])}, 12310: {c, e, p | p.Add(ReturnStatement())},
		12410: ConvertComment, 22410: {c, e, p | p.Add(Expression.Lift(e.Name))}, 10210: ConvertSwitch,
		12420: {c, e, p | p.Add([|GameOver()|])}, 12510: {c, e, p | p.Add([|TitleScreen()|])}, 10220: ConvertVar,
		13210: {c, e, p | p.Add([|SetBattleBG($(e.Name))|])}, 13410: {c, e, p | p.Add([|EndBattle()|])},
		1007: {c, e, p | p.Add([|EnableCombo(Heroes[$(e.Data[0])], $(e.Data[1]), $(e.Data[2]))|])},
		13260: ConvertShowAnimBattle,
		10120: ConvertMessageOptions, 10140: ConvertCase, 20140: ConvertCaseItem, 20141: ConvertEndCase,
		12010: ConvertIf, 22010: ConvertIfElse, 22011: ConvertEndIf, 10710: ConvertBattle, 20710: ConvertVictory,
		20711: ConvertEscape, 20712: ConvertDefeat, 10320: ConvertInventory, 10330: ConvertParty, 10430: ConvertStats,
		10440: ConvertSkills, 10450: ConvertEquipment, 10460: ConvertHP, 10470: ConvertMP, 10480: ConvertStatus,
		10640: {c, e, p | p.Add([|Heroes[$(e.Data[0])].SetPortrait($(e.Name), $(e.Data[1] + 1))|])},
		10650: {c, e, p | p.Add([|Vehicles[$(e.Data[0])].SetSprite(e.Name, $(e.Data[1] != 0))|])},
		10720: ConvertShop, 20721: ConvertIfElse, 20722: ConvertEndIf, 20731: ConvertIfElse, 20732: ConvertEndIf,
		10730: {c, e, p | return SetupMif(c, e, p, [|await(Inn($(e.Data[0]), $(e.Data[1])))|])}, 11110: ConvertNewImage,
		10850: ConvertTeleportVehicle, 10860: ConvertTeleportEvent, 11040: ConvertFlashScreen, 10630: ConvertSprite,
		10870: {c, e, p | p.Add([|SwapMapObjects($(EventDeref(e.Data[0])), $(EventDeref(e.Data[1])))|])},
		11120: ConvertMoveImage, 11210: ConvertShowAnim, 11330: ConvertMove, 12210: ConvertWhileLoop,
		11310: {c, e, p | p.Add([|Party.Translucency = $(30 if e.Data[0] == 0 else 0)|])}, 22210: ConvertLoopEnd,
		11320: ConvertCharacterFlash,
		11740: {c, e, p | p.Add([|SetEncounterRate(1, $(e.Data[0]))|])}, 1008: ConvertClassChange,
		12220: {c, e, p | p.Add((BreakStatement() if c.LoopDepth > 0 else ReturnStatement()))},
		12320: {c, e, p | p.Add([|DeleteObject(false)|])}, 1009: ConvertBattleCommand, 10660: ConvertSysBGM,
		11050: ConvertShakeScreen, 13110: ConvertMonsterHP, 13120: ConvertMonsterMP, 13310: ConvertBattleIf,
		13130: {c, e, p | p.Add([|Monster[$(e.Data[0] + 1)].Condition[$(e.Data[2])] = $(e.Data[1] == 0)|])},
		13150: {c, e, p | p.Add([|Monster[$(e.Data[0] + 1)].Show()|])}, 23310: ConvertIfElse, 23311: ConvertEndIf,
		1005: {c, e, p | p.Add([|CallGlobalScript($(e.Data[0]))|])}, 10740: ConvertInputHeroName,
		11010: {c, e, p | p.Add([| await(EraseScreen(TTransitions.$(ReferenceExpression(Enum.GetName(TTransitions, e.Data[0] + 1))))) |])},
		11020: {c, e, p | p.Add([| await(ShowScreen(TTransitions.$(ReferenceExpression(Enum.GetName(TTransitions, e.Data[0] + 1))))) |])},
		10690: {c, e, p | p.Add([|SetTransition(TTransitionTypes.$(ReferenceExpression(Enum.GetName(TTransitionTypes, e.Data[0]))), TTransitions.$(ReferenceExpression(Enum.GetName(TTransitions, e.Data[1] + 1))))|])},
		12110: {c, e, p | p.Add(LabelStatement(LexicalInfo.Empty, "L$(e.Data[0])"))}, 10810: ConvertTeleport,
		12120: {c, e, p | p.Add(GotoStatement(LexicalInfo.Empty, ReferenceExpression("L$(e.Data[0])")))}, 12330: ConvertCallEvent
	}
	
	simpleConverter ConvertSprite:
		result = [|Heroes[$(values[0])].SetSprite($name, $(values[2] != 0), $(values[1]))|]
	
	simpleConverter ConvertCallEvent:
		caseOf values[0]:
			case 0: result = [|CallGlobalScript($(values[1]))|]
			case 1: 
				if values[1] in (0, 10005):
					result = [|CallScript(ThisObject.ID, $(values[2]))|]
				else: result = [|CallScript($(values[1]), $(values[2]))|]
			case 2: result = [|CallScript(Ints[$(values[1])], Ints[$(values[2])])|]
			case 3:
				bgs = "BattleGlobal$(values[1].ToString('D4'))"
				result = [|$(ReferenceExpression(bgs))()|]
			default: raise ERpgScriptError("Unknown CallEvent values[0] value: $(values[0])")
	
	simpleConverter ConvertTeleport:
		if values.Count == 3:
			values.Add(0)
		result = [|await(Teleport($(values[0]), $(values[1]), $(values[2]), $(values[3])))|]
	
	simpleConverter ConvertInputHeroName:
		result = [|Heroes[$(values[0])].Name = InputText($name, $(values[0]))|]
	
	private static def ConvertBattleIf(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		left as Expression
		caseOf ec.Data[0]:
			case 0, 1: return ConvertIf(converter, ec, parent)
			case 2: left = [|Heroes[$(ec.Data[1])].CanAct|]
			case 3: left = [|Monster[$(ec.Data[1])].CanAct|]
			case 4: left = [|Monster[$(ec.Data[1])].Targetted|]
			case 5: left = [|Heroes[$(ec.Data[1]).UsesCommand($(ec.Data[2]))]|]
			default: raise ERpgScriptError("Unknown data[0] value $(ec.Data[0])")
		result = [|
			if $left:
				pass
		|]
		parent.Add(result)
		converter.BlockStack.Push(-1)
		converter.IfStack.Push(result)
		return result.TrueBlock
	
	simpleConverter ConvertMonsterMP:
		value as Expression
		monster = [|Monster[$(values[0] + 1)].MP|]
		op = (BinaryOperatorType.InPlaceAddition, BinaryOperatorType.InPlaceSubtraction)[values[1]]
		caseOf values[2]:
			case 0: value = Expression.Lift(values[3])
			case 1: value = [|Ints[$(values[3])]|]
			default: raise ERpgScriptError("Unknown monster MP value 2: $(values[2])")
		result = BinaryExpression(op, monster, value)
	
	simpleConverter ConvertMonsterHP:
		value as Expression
		monster = [|Monster[$(values[0] + 1)].HP|]
		op = (BinaryOperatorType.InPlaceAddition, BinaryOperatorType.InPlaceSubtraction, BinaryOperatorType.Assign)[values[1]]
		caseOf values[2]:
			case 0: value = Expression.Lift(values[3])
			case 1: value = [|Ints[$(values[3])]|]
			case 2: value = [|Monster[$(values[0])].MaxHP * $(values[3] / 100.0)|]
			default: raise ERpgScriptError("Unknown monster HP value 2: $(values[2])")
		if values[1] == 1 and values[4] == 1:
			result = [|$(monster.Target).SafeLoseHP($value)|]
		else: result = BinaryExpression(op, monster, value)
	
	simpleConverter ConvertShakeScreen:
		assert values.Count in (4, 5)
		if values.Count == 5 and values[4] == 2:
			result = [|EndShakeScreen()|]
		else:
			if values.Count == 4:
				values.Add(0)
			if values[3] == 0:
				result = [|ShakeScreen($(values[0]), $(values[1]), $(values[2]), $(values[4] != 0))|]
			else:
				result = [|await(ShakeScreenAndWait($(values[0]), $(values[1]), $(values[2])))|]
	
	simpleConverter ConvertSysBGM:
		caseOf values[0]:
			case 0, 1, 2, 6:
				values[0] = 3 if values[0] == 6
				result = [|SetSystemMusic(TBgmTypes.$(ReferenceExpression(Enum.GetName(TBgmTypes, values[0]))), $name, $(values[1]), $(values[2]), 
												  $(values[3]), $(values[4]))|]
			case 3, 4, 5:
				result = [|Vehicles[$(values[0])].SetMusic($name, $(values[1]), $(values[2]), 
												$(values[3]), $(values[4]))|]
			default: raise ERpgScriptError("Unknown BGM index $(values[0])")
	
	simpleConverter ConvertBattleCommand:
		assert values[0] == 1
		if values[3] == 1:
			result = [|Heroes[$(values[1])].AddBattleCommand($(values[2]))|]
		else: result = [|Heroes[$(values[1])].RemoveBattleCommand($(values[2]))|]
	
	simpleConverter ConvertClassChange:
		assert values[0] == 1
		result = [|Heroes[$(values[1])].ChangeClass($(values[2]), $(values[3] != 0), $(values[4]), $(values[5]), \
						$(values[6] != 0))|]
	
	private static def ConvertLoopEnd(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		--converter.LoopDepth
		return null
		
	private static def ConvertWhileLoop(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		ms = [|
			while true:
				pass
		|]
		++converter.LoopDepth
		parent.Add(ms)
		return ms.Block
	
	simpleConverter ConvertMove:
		moveString = values.Skip(4).Select({value | return value cast byte}).ToArray()
		ms = System.IO.MemoryStream(moveString)
		orders = List[of MoveOpcode]()
		while ms.Position < ms.Length:
			orders.Add(MoveOpcode(ms))
		blk = Block()
		ConvertMoveOrders(orders, blk, converter.MakeWarning)
		moveScript = ArrayLiteralExpression()
		moveScript.Items.AddRange(blk.Statements.Cast[of ExpressionStatement]().Select({es | es.Expression}))
		if moveScript.Items.Count == 0:
			converter.MakeWarning('Move command contains no movements')
		result = [|MoveMapObject($(EventDeref(values[0])), $(values[1]), $(values[2] != 0), $(values[3] != 0), $moveScript)|]
	
	simpleConverter ConvertShowAnim:
		a2 as Expression = (EventDeref(values[1]) if values[3] == 0 else [|null|])
		if (values[2] == 0):
			result = [|ShowBattleAnim($(values[0]), $a2, $(values[3] != 0))|]
		else: result = [|await(ShowBattleAnimAndWait($(values[0]), $a2, $(values[3] != 0)))|]
	
	simpleConverter ConvertShowAnimBattle:
		a2 as Expression = ([| Monster[$(values[1])] |] if values[1] != 0 else [|null|])
		if (values[2] == 0):
			result = [| ShowBattleAnimB($(values[0]), $a2, $(values[1] != 0)) |]
		else: result = [| await(ShowBattleAnimBAndWait($(values[0]), $a2, $(values[1] != 0))) |]
	
	simpleConverter ConvertMoveImage:
		assert values[4] == 0
		assert values[7] == 0
		assert values.Count in (16, 17)
		blk = Block()
		sub = [|Image[$(values[0])].MoveTo($(GetIntScript(values[1], values[2])), \
					$(GetIntScript(values[1], values[3])), $(values[5]), $(values[6]), $(values[14]))|]
		blk.Add(sub)
		ProcessImageBlock(blk, values)
		if values[15] != 0:
			blk.Add([|await(Image[$(values[0])].WaitFor())|])
		parent.Add(blk)
	
	simpleConverter ConvertNewImage:
		blk = Block() 
		sub as Expression
		sub = [|Image[$(values[0])] = NewImage($name, $(GetIntScript(values[1], values[2])), \
						$(GetIntScript(values[1], values[3])), $(values[5]), $(values[6]), \
						$(values[4] != 0), $(values[7] != 0))|]
		blk.Add(sub)
		ProcessImageBlock(blk, values)
		parent.Add(blk)
	
	private static def ProcessImageBlock(blk as Block, values as List[of int]):
		effect = false
		for i in range(8, 12):
			effect = effect or (values[i] != 100)
		if effect:
			sub = [|Image[$(values[0])].ApplyImageColors($(values[8]), $(values[9]), $(values[10]), $(values[11]))|]
			blk.Add(sub)
		if values[12] != 0:
			sub = [|Image[$(values[0])].ApplyImageEffect($(values[12]), $(values[13]))|]
			blk.Add(sub)
	
	simpleConverter ConvertFlashScreen:
		assert values.Count in (6, 7)
		if values.Count == 7 and values[6] == 2:
			result = [|EndFlashScreen()|]
		else:
			if values[5] == 0:
				result = [|FlashScreen($(RGB32(values[0])), $(RGB32(values[1])), $(RGB32(values[2])), \
										$(RGB32(values[3])), $(values[4]))|]
				if values.Count == 7:
					(result cast MethodInvocationExpression).Arguments.Add([|$(values[6] != 0)|])
				else: (result cast MethodInvocationExpression).Arguments.Add([|false|])
			else result = [|await(FlashScreenAndWait($(RGB32(values[0])), $(RGB32(values[1])), $(RGB32(values[2])), \
													$(RGB32(values[3])), $(values[4])))|]
	
	simpleConverter ConvertTintScreen:
		if values[5] == 0:
			result = [|TintScreen($(values[0]), $(values[1]), $(values[2]), $(values[3]), $(values[4]))|]
		else: result = [|await(TintScreenAndWait($(values[0]), $(values[1]), $(values[2]), $(values[3]), $(values[4])))|]
	
	simpleConverter ConvertCharacterFlash:
		if values[6] == 0:
			result = [|$(EventDeref(values[0])).Flash($(RGB32(values[1])), $(RGB32(values[2])), \
						$(RGB32(values[3])), $(RGB32(values[4])), $(values[5]))|]
		else: result = [| await($(EventDeref(values[0])).FlashAndWait($(RGB32(values[1])), $(RGB32(values[2])), \
						$(RGB32(values[3])), $(RGB32(values[4])), $(values[5]))) |]
	
	private static def RGB32(value as int) as int:
		return round(value * (255.0 / 31.0))
	
	simpleConverter ConvertTeleportEvent:
		result = [|TeleportMapObject($(EventDeref(values[0])), $(GetIntScript(values[1], values[2])),\
											  $(GetIntScript(values[1], values[3])))|]
	
	simpleConverter ConvertTeleportVehicle:
		result = [|TeleportVehicle(Vehicles[$(values[0])], $(GetIntScript(values[1], values[2])),\
											$(GetIntScript(values[1], values[3])), $(GetIntScript(values[1], values[4])))|]
	
	private static def ConvertShop(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		items = ArrayLiteralExpression()
		for i in range(4, ec.Data.Count):
			items.Items.Add(Expression.Lift(ec.Data[i]))
		return SetupMif(converter, ec, parent, [|await(Shop(TShopTypes.$(ReferenceExpression(Enum.GetName(TShopTypes, ec.Data[0]))), $(ec.Data[1] + 1), $items))|])
	
	private static def SetupMif(converter as TScriptConverter, ec as EventCommand, parent as Block, \
										 expr as Expression) as Block:
		if ec.Data[2] != 0:
			converter.BlockStack.Push(-1)
			ifst = [|
				if $expr:
					pass
			|]
			parent.Add(ifst)
			converter.IfStack.Push(ifst)
			return ifst.TrueBlock
		else: parent.Add(expr)
	
	simpleConverter ConvertFullHeal:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			return [|$subscript.FullHeal()|]
	
	simpleConverter ConvertStatus:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			return [|$subscript.Condition[$(values[3])] = $(values[2] != 0)|]
	
	simpleConverter ConvertMP:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			expr = GetIntScript(values[3], values[4])
			if values[2] == 1:
				expr = [|-$expr|]
			return [|$subscript.ChangeMP($expr)|]
	
	simpleConverter ConvertHP:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			expr = GetIntScript(values[3], values[4])
			if values[2] == 1:
				expr = [|-$expr|]
			return [|$subscript.ChangeHP($expr, $(values[5] != 0))|]
	
	simpleConverter ConvertEquipment:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			expr as Expression
			if values[2] != 0:
				expr = ([|TSlot.Weapon|], [|TSlot.Shield|], [|TSlot.Armor|], [|TSlot.Helmet|], [|TSlot.Relic|], \
						  [|TSlot.All|])[values[3]]
			else: expr = GetIntScript(values[3], values[4])
			return ([|$subscript.Equip($expr)|] if values[2] == 0 else [|$subscript.Unequip(expr)|])
	
	simpleConverter ConvertSkills:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			expr = GetIntScript(values[3], values[4])
			return [|$subscript.Skill[$expr] = $(values[2] != 0)|]
	
	simpleConverter ConvertStats:
		SetupPartySubscript(values[0], values[1], parent) do (subscript as Expression) as Expression:
			stat = ReferenceExpression(('MaxHp', 'MaxMp', 'Attack', 'Defense', 'Mind', 'Agility')[values[3]])
			expr = GetIntScript(values[4], values[5])
			op = (BinaryOperatorType.InPlaceAddition, BinaryOperatorType.InPlaceSubtraction)[values[2]]
			return BinaryExpression(op, [|$subscript.$stat|], expr)
	
	private static def SetupPartySubscript(mode as int, value as int, parent as Block, work as Func[of Expression, Expression]):
		subscript as Expression
		caseOf mode:
			case 0: subscript = [|hero|]
			case 1: subscript = [|Heroes[$value]|]
			case 2: subscript = [|Heroes[Ints[$value]]|]
			default: raise ERpgScriptError("Unknown subscript data value: $mode!")
		result = work(subscript)
		if mode == 0:
			CreateForInLoop(parent, [|Party|], [|hero|], result)
		else: parent.Add(result)
	
	simpleConverter ConvertParty:
		param = GetIntScript(values[1], values[2])
		if values[0] == 0:
			result = [|HeroJoin($param)|]
		else: result = [|HeroLeave($param)|]
	
	simpleConverter ConvertInventory:
		p1 = GetIntScript(values[1], values[2])
		caseOf values[0]:
			case 0: result = [|AddItem($p1, $(GetIntScript(values[3], values[4])))|]
			case 1: result = [|RemoveItem($p1, $(GetIntScript(values[3], values[4])))|]
			case 2: result = [|RemoveItem($p1, -1)|]
	
	private static def ConvertVar(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		left = CreateSubscript(ec.Data[0], ec.Data[1])
		right as Expression; prop as Expression
		caseOf ec.Data[4]:
			case 0: right = Expression.Lift(ec.Data[5])
			case 1: right = [|Ints[$(ec.Data[5])]|]
			case 2: right = [|Ints[Ints[$(ec.Data[5])]]|]
			case 3: right = [|Random($(ec.Data[5]), $(ec.Data[6]))|]
			case 4: right = [|HeldItems($(ec.Data[5]), $(ec.Data[6] == 1))|]
			case 5:
				if ec.Data[6] in range(6):
					prop = ReferenceExpression(('Level', 'Exp', 'HP', 'MP', 'MaxHP', 'MaxMP')[ec.Data[6]])
				elif ec.Data[6] in range(6, 10):
					prop = [|Stat[$(ec.Data[6] - 5)]|]
				elif ec.Data[6] in range(10, 15):
					prop = [|Equipment[$(ec.Data[6] - 9)]|]
				else: raise ERpgScriptError("Unknown variable data 6 value: $(ec.Data[6])!")
				right = [|Heroes[$(ec.Data[5])].$prop|]
			case 6:
				prop = ReferenceExpression(('MapID', 'XPos', 'YPos', 'FacingValue', 'ScreenX', 'ScreenY')[ec.Data[6]])
				right = [|$(EventDeref(ec.Data[5])).$prop|]
			case 7:
				prop = ([|Money|], [|Timer.Time|], [|PartySize|], [|SaveCount|], [|BattleCount|], [|Victories|],
						  [|Losses|], [|Flees|], [|Bgm.Position|], [|Timer2.Time|])[ec.Data[5]]
				right = [|$prop|]
			case 8:
				caseOf ec.Data[6]:
					case 0, 1, 2, 3: 
						prop = ReferenceExpression(('HP', 'MP', 'MaxHP', 'MaxMP')[ec.Data[6]])
						right = [|Monster[$(ec.Data[5])].$prop|]
					case 4, 5, 6, 7: right = [|Monster[$(ec.Data[5])].Stat[$(ec.Data[6] - 4)]|]
					default: raise ERpgScriptError("Unknown variable data 6 value: $(ec.Data[6])!")
			default: raise ERpgScriptError("Unknown variable data 4 value: $(ec.Data[4])!")
		if ec.Data[3] > 0:
			op = (BinaryOperatorType.Addition, BinaryOperatorType.Subtraction, BinaryOperatorType.Multiply, 
					BinaryOperatorType.Division, BinaryOperatorType.Modulus)[ec.Data[3] - 1]
			right = BinaryExpression(op, [|Ints[$(CreateSubscript(ec.Data[0], ec.Data[1]))]|], right)
		result = [|Ints[$left] = $right|]
		if ec.Data[0] == 1:
			CreateForLoop(parent, result, ec.Data[1], ec.Data[2])
		else: parent.Add(result)

	private static def ConvertSwitch(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		val = CreateSubscript(ec.Data[0], ec.Data[1])
		raise ERpgScriptError("Unknown switch Data 3 value: $(ec.Data[3])!") unless IsBetween(ec.Data[3], 0, 2)
		left = [|Switch[$(val)]|]
		caseOf ec.Data[3]:
			case 0: result = [|$left = true|]
			case 1: result = [|$left = false|]
			//Parser doesn't like NOT + splice [|$left = not $left|]
			case 2: result = BinaryExpression(BinaryOperatorType.Assign, left, UnaryExpression(UnaryOperatorType.LogicalNot, left.CleanClone()))
		if ec.Data[0] == 1:
			CreateForLoop(parent, result, ec.Data[1], ec.Data[2])
		else: parent.Add(result)
	
	private static def CreateSubscript(mode as int, data as int) as Expression:
		caseOf mode:
			case 0: return Expression.Lift(data)
			case 1: return [|num|]
			case 2: return [|Ints[$data]|]
			default: raise ERpgScriptError("Unknown subscript mode value: $(mode)!")
	
	private static def CreateForLoop(parent as Block, child as Expression, lBound as int, uBound as int):
		result = [|
			for num in range($lBound, $(uBound + 1)):
				$child
		|]
		parent.Add(result)
	
	private static def CreateForInLoop(parent as Block, collection as Expression, iter as ReferenceExpression, \
												  child as Expression):
		result = ForStatement(collection)
		result.Declarations.Add(Declaration(iter.Name, null))
		result.Block.Add(child)
		parent.Add(result)
	
	private static def ConvertVictory(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		result = [|
			case TBattleResult.Victory:
				pass
		|]
		parent.Add(result)
		return result.Body
	
	private static def ConvertEscape(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		result = [|
			case TBattleResult.Escaped:
				pass
		|]
		parent.Add(result)
		return result.Body
	
	private static def ConvertDefeat(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		result = [|
			case TBattleResult.Defeated:
				pass
		|]
		parent.Add(result)
		return result.Body
	
	private static def ConvertBattle(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		battleResult as Expression = [|TBattleResult.Victory|]
		def AddBattleResult(value as ReferenceExpression):
			battleResult = [|$battleResult | TBattleResult.$value|]

		bx = ec.Data.Count > 6
		result = ([|await(BattleEx())|] if bx else [|await(Battle())|])
		var battleCmd = result.Arguments[0] cast MethodInvocationExpression
		battleCmd.Arguments.AddRange((GetIntScript(ec.Data[0], ec.Data[1]), [|$(ec.Name if ec.Data[2] == 1 else '')|]))
		battleCmd.Arguments.Add(([|TBattleFormation.$(ReferenceExpression(Enum.GetName(TBattleFormation, ec.Data[2])))|] if bx else [|$(ec.Data[5] != 0)|]))
		if bx:
			if ec.Data[5] == 1:
				battleCmd.Arguments.Add([|5|])
			else: battleCmd.Arguments.Add([|$(ec.Data[6])|])
			caseOf ec.Data[2]:
				case 0: battleCmd.Arguments.Add([|0|])
				case 1: battleCmd.Arguments.Add([|$(ec.Data[7] - 1)|])
				case 2: battleCmd.Arguments.Add([|$(ec.Data[8])|])
		AddBattleResult([|Escaped|]) if ec.Data[3] != 0
		AddBattleResult([|Defeated|]) if ec.Data[4] != 0
		battleCmd.Arguments.Add(battleResult)
		
		if ec.Data[3] != 0 or ec.Data[4] != 0:
			cb = [|
				caseOf $result:
					pass
			|]
			if ec.Data[3] == 1:
				escaped = [|
					case TBattleResult.Escaped: return
				|]
				cb.Body.Add(escaped)
			parent.Add(cb)
			return cb.Body
		else: parent.Add(result)

	private static def ConvertEndIf(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		assert converter.BlockStack.Pop() == -1
		converter.IfStack.Pop()
		return null
	
	private static def ConvertIfElse(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		assert converter.BlockStack.Peek() == -1
		return converter.IfStack.Peek().FalseBlock
	
	private static final COMPARISON_OP = (BinaryOperatorType.Equality, BinaryOperatorType.GreaterThanOrEqual, 
		BinaryOperatorType.LessThanOrEqual, BinaryOperatorType.GreaterThan, BinaryOperatorType.LessThan,
		BinaryOperatorType.Inequality)
	
	//this should be part of ConvertIf, but there was enough work involved to extract
	//it into its own routine for readability purposes.
	private static def PrepareHeroIf(d2 as int, d3 as int, name as string, ref left as Expression, \
												ref right as Expression, ref op as BinaryOperatorType):
		caseOf d2:
			case 0: left = [|InParty|]
			case 1:
				left = [|Name|]
				right = Expression.Lift(name)
			case 2:
				left = [|Level|]
				right = Expression.Lift(d3)
			case 3:
				left = [|HP|]
				right = Expression.Lift(d3)
			case 4: left = [|Skill[$d3]|]
			case 5:
				left = [|Equipped($d3)|]
			case 6: left = [|Condition[$d3]|]
		op = (BinaryOperatorType.GreaterThanOrEqual if d2 in (2, 3) else BinaryOperatorType.Equality)
	
	private static def EventDeref(data as int) as Expression:
		caseOf data:
			case 10001: return [|Party|]
			case 10002, 10003, 10004: return [|Vehicles[$(data - 10001)]|]
			case 10005: return [|ThisObject|]
			default: return [|MapObject[$data]|]
	
	private static def ConvertIf(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		op = BinaryOperatorType.Equality
		left as Expression; right as Expression
		caseOf ec.Data[0]:
			case 0:
				left = [|Switch[$(ec.Data[1])]|]
				right = BoolLiteralExpression(ec.Data[2] == 0)
			case 1:
				left = [|Ints[$(ec.Data[1])]|]
				right = GetIntScript(ec.Data[2], ec.Data[3])
				op = COMPARISON_OP[ec.Data[4]]
			case 2, 3, 10:
				if ec.Data[0] == 2:
					left = [|Timer.Time|]
				elif ec.Data[0] == 3:
					left = [|Party.Money|]
				else: left = [|Timer2.Time|]
				right = IntegerLiteralExpression(ec.Data[1])
				op = (BinaryOperatorType.GreaterThanOrEqual if ec.Data[2] == 0 else BinaryOperatorType.LessThanOrEqual)
			case 4:
				left = [|Party.HasItem($(ec.Data[1]))|]
				right = BoolLiteralExpression(ec.Data[2] == 0)
			case 5:
				PrepareHeroIf(ec.Data[2], ec.Data[3], ec.Name, left, right, op)
				left = [|Heroes[$(ec.Data[1])].$left|]
			case 6:
				right = [|TDirections.$(ReferenceExpression(Enum.GetName(TDirections, ec.Data[2])))|]
				left = [|$(EventDeref(ec.Data[1])).Facing|]
			case 7: left = [|$(EventDeref(ec.Data[1] + 10002)).InUse|]
			case 8: left = [|StartedWithButton|]
			case 9: left = [|Bgm.Looped|]
			default: raise ERpgScriptError("Unknown Data[0] value $(ec.Data[0])")
		result = IfStatement((left if right is null else BinaryExpression(op, left, right)), Block(), Block())
		parent.Add(result)
		converter.BlockStack.Push(-1)
		converter.IfStack.Push(result)
		return result.TrueBlock
	
	private static def ConvertEndCase(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		assert converter.BlockStack.Pop() >= 0
		return parent
	
	private static def ConvertCaseItem(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		if string.IsNullOrEmpty(ec.Name):
			assert converter.BlockStack.Peek() >= 0
			result = MacroStatement('default')
		else:
			index = converter.BlockStack.Pop()
			try:
				assert index >= 0
				result = [|
					case $(ec.Data[0]):
						pass
				|]
			ensure:
				converter.BlockStack.Push(index + 1)
		parent.Add(result)
		return result.Body
	
	private static def ConvertCase(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		choices = ArrayLiteralExpression()
		values = ec.Name.Split(*(char('/'),)).ToList()
		if values.Count > 0 and string.IsNullOrEmpty(values [0]) and ec.Name.StartsWith('/'):
			values.RemoveAt(0)
		choices.Items.AddRange(values.Select({c | Expression.Lift(c)}))
		result = [|
			caseOf await(ShowChoice("", $choices, $(values[0] != 0))):
				pass
		|]
		converter.BlockStack.Push(0)
		parent.Add(result)
		return result.Body
	
	simpleConverter ConvertMessageOptions:
		result = [|MessageOptions($(values[0] == 0), TMboxLocation.$(ReferenceExpression(Enum.GetName(TMboxLocation, values[1]))), \
										  $(values[2] != 0), $(values[3] == 0))|] //yes, 2 of the booleans are backwards
	
	simpleConverter ConvertForceFlee:
		caseOf values[0]:
			case 0: result = [|PartyFlee($(values[2] != 0))|]
			case 1: result = [|MonsterPartyFlee($(values[2] != 0))|]
			case 2: result = [|Monster[$(values[1])].Flee(true, $(values[2] != 0))|]
			default: raise ERpgScriptError("Unknown ForceFlee Value #0: $(values[0])")
	
	simpleConverter ConvertEscapeLoc:
		switch = (0 if values[3] == 0 else values[4])
		result = [|SetEscape($(values[0]), $(values[1]), $(values[2]), $switch)|]
	
	simpleConverter ConvertTeleportLoc:
		if values[0] == 0:
			switch = (0 if values[4] == 0 else values[5])
			result = [|AddTeleport($(values[1]), $(values[2]), $(values[3]), $switch)|]
		else: result = [|DeleteTeleport($(values[1]), $(values[2]), $(values[3]))|]
	
	simpleConverter ConvertChangeBG:
		def GetScrollType(v1 as int, v2 as int):
			if v1 == 0:
				return [|TMapScrollType.None|]
			elif v2 == 0:
				return [|TMapScrollType.Scroll|]
			else: return [|TMapScrollType.Autoscroll|]
		
		result = [|SetBGImage($name, $(values[3]), $(values[5]), $(GetScrollType(values[0], values[2])), \
									$(GetScrollType(values[1], values[4])))|]
	
	simpleConverter ConvertInput:
		mask as Expression
		def AddMask(value as ReferenceExpression):
			if mask is null:
				mask = [|TButtonCode.$value|]
			else: mask = [|$mask | TButtonCode.$value|]
		
		if values[2] != 0 and values[3] != 0 and values[4] != 0:
			AddMask([|All|])
		else:
			AddMask([|Dirs|]) if values[2] != 0
			AddMask([|Enter|]) if values[3] != 0
			AddMask([|Cancel|]) if values[4] != 0
		result = [|Ints[$(values[0])] = await(KeyScan($mask, $(values[1] != 0)))|]
		//TODO: This should support more input, for RM2K3
	
	simpleConverter ConvertPlayMovie:
		if values[0] == 0:
			result = [|PlayMovie($name, $(values[1]), $(values[2]), $(values[3]), $(values[4]))|]
		else: result = [|PlayMovie($name, Ints[$(values[1])], Ints[$(values[2])], $(values[3]), $(values[4]))|]
	
	simpleConverter ConvertPanScreen:
		caseOf values[0]:
			case 0: result = [|LockScreen()|]
			case 1: result = [|UnlockScreen()|]
			case 2:
				if values[4] == 0:
					result = [|PanScreen(TFacing.$(ReferenceExpression(Enum.GetName(TDirections, values[1]))), \
													$(values[2]), $(values[3]))|]
				else:
					result = [|await(PanScreenAndWait(TFacing.$(ReferenceExpression(Enum.GetName(TDirections, values[1]))), \
													$(values[2]), $(values[3])))|]
			case 3:
				if values[4] == 0:
					result = [|ReturnScreen($(values[3]))|]
				else result = [|await(ReturnScreenAndWait($(values[3])))|]
	
	simpleConverter ConvertObjectID:
		if values[0] == 0:
			result = [|GetObjectID($(values[1]), $(values[2]))|]
		else: result = [|GetObjectID(Ints[$(values[1])], Ints[$(values[2])])|]
		result = [|Ints[$(values[3])] = $result|]
	
	simpleConverter ConvertTerrainID:
		if values[0] == 0:
			result = [|GetTerrainID($(values[1]), $(values[2]))|]
		else: result = [|GetTerrainID(Ints[$(values[1])], Ints[$(values[2])])|]
		result = [|Ints[$(values[3])] = $result|]
	
	simpleConverter ConvertTakeDamage:
		subject as Expression
		caseOf values[0]:
			case 0: subject = [|Party|]
			case 1: subject = [|Heroes[$(values[1])]|]
			case 1: subject = [|Heroes[Ints[$(values[1])]]|]
		result = [|$subject.TakeDamage($(values[2]), $(values[3]), $(values[4]), $(values[5]))|]
		if values[6] != 0:
			result = [|Ints[$(values[7])] = $result|]
	
	simpleConverter ConvertLevel:
		param1 as Expression
		caseOf values[0]:
			case 0: param1 = [|-1|]
			case 1: param1 = [|$(values[1])|]
			case 2: param1 = [|Ints[$(values[1])]|]
		param2 = GetIntScript(values[3], values[4])
		if values[2] == 0:
			result = [|AddLevels($param1, $param2, $(values[5] != 0))|]
		else: result = [|RemoveLevels($param1, $param2)|]

	simpleConverter ConvertExperience:
		param1 as Expression
		caseOf values[0]:
			case 0: param1 = [|-1|]
			case 1: param1 = [|$(values[1])|]
			case 2: param1 = [|Ints[$(values[1])]|]
		param2 = GetIntScript(values[3], values[4])
		if values[2] == 0:
			result = [|AddExp($param1, $param2, $(values[5] != 0))|]
		else: result = [|RemoveExp($param1, $param2)|]

	simpleConverter ConvertMoney:
		caseOf values[0]:
			case 0: result = [|Money += $(GetIntScript(values[1], values[2]))|]
			case 1: result = [|Money -= $(GetIntScript(values[1], values[2]))|]
			case 2: result = [|Money  = $(GetIntScript(values[1], values[2]))|]
	
	simpleConverter ConvertTimer:
		if (values.Count > 5) and (values[5] == 1):
			timer = [|Timer2|]
		else: timer = [|Timer|]
		caseOf values[0]:
			case 0: result = [|$timer.Time = $(GetIntScript(values[1], values[2]))|]
			case 1: result = [|$timer.Start($(values[3] != 0), $(values[4] != 0))|]
			case 2: result = [|$timer.Pause()|]
	
	private static def ConvertShowMessage(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		sm = [|
			ShowMessage:
				$(Expression.Lift(ec.Name))
		|]
		parent.Add(sm)
		return sm.Body
	
	private static def ConvertComment(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		c = [|
			comment:
				$(Expression.Lift(ec.Name))
		|]
		parent.Add(c)
		return c.Body
	
	private static def Cleanup(converter as TScriptConverter, ec as EventCommand, parent as Block) as Block:
		assert converter.BlockStack.Count == 0
		assert converter.IfStack.Count == 0
		return null
		
	simpleConverter ConvertPortrait:
		if string.IsNullOrEmpty(name):
			result = [|ClearPortrait()|]
		else: result = [|SetPortrait($name, $(values[0]), $(values[1] != 0), $(values[2] != 0))|]
	
	private def LogUnknownOpcode(opcode as int):
		count as int
		count = 0 unless _tally.TryGetValue(opcode, count)
		_tally[opcode] = count + 1
	
	public UnknownOpcodeList as List[of string]:
		get:
			result = List[of string]()
			for pair in _tally.OrderBy({kv | kv.Value}):
				result.Add("Opcode $(pair.Key) used $(pair.Value) times.")
			return result
	
	public def ConvertOpcode(opcode as EventCommand, parent as Block) as Node:
		converter as TConvertRoutine
		unless _opcodeDictionary.TryGetValue(opcode.Opcode, converter):
			LogUnknownOpcode(opcode.Opcode)
			return null
		return converter(self, opcode, parent)

	private static def GetIntScript(decider as int, value as int) as Expression:
		return (Expression.Lift(value) if decider == 0 else [|Ints[$value]|])
