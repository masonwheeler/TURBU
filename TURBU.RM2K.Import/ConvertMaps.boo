﻿namespace TURBU.RM2K.Import

import Boo.Adt
import Boo.Lang.Compiler.Ast
import System
import System.Collections.Generic
import turbu.maps
import turbu.tilesets
import TURBU.MapObjects
import TURBU.RM2K.Import.LCF

static class TMapConverter:
	
	public def ConvertMap(map as LMU, mapTree as LMT, id as int, progress as IConversionReport,\
			ScanScript as Action[of EventCommand*], saveData as Action[of string, Node, Node]):
		let WRAPAROUNDS = ([|None|], [|Vertical|], [|Horizontal|], [|Both|])
		let PANNING = ([|None|], [|Scroll|], [|Autoscroll|])
		treeMap as MapTreeData
		unless mapTree.Maps.TryGetValue(id, treeMap):
			progress.MakeError("No entry for map $id exists in the map tree.", 1)
			return
		mapName = treeMap.Name
		hPan = ((2 if map.HPanAutoscroll else 1) if map.HPan else 0)
		vPan = ((2 if map.VPanAutoscroll else 1) if map.VPan else 0)
		ms as MacroStatement = [|
			MapData $id:
				Size $(map.Width), $(map.Height)
				Wraparound $(WRAPAROUNDS[map.Wraparound])
				Background $(map.UsesPano), $(map.PanoName)
				Panning $(PANNING[hPan]), $(map.HPanSpeed), $(PANNING[vPan]), $(map.VPanSpeed)
				Tiles:
					$(TileDataArray(map))
		|]
		events = EventData(map.Events)
		ms.Body.Add(events) unless events is null
		//legacy data is related to RM2k3 random generation. Ignore.
		ConvertMapScripts(id, map.Events, ScanScript) do(script as Node):
			saveData("$(mapName)_$id", ms, script)
	
	private def EventData(events as List[of MapEvent]) as MacroStatement:
		return null if events is null or events.Count == 0
		result = MacroStatement('MapObjects')
		for ev in events:
			sub as MacroStatement = [|
				MapObject $(ev.ID):
					Name $(ev.Name)
					Position $(ev.X), $(ev.Y)
			|]
			pages = EventPages(ev.Name, ev.Pages)
			sub.Body.Add(pages) unless pages is null
			result.Body.Add(sub)
		return result
	
	private def EventPages(eventName as string, pages as List[of EventPage]) as MacroStatement:
		let EventPageFacing = ('Up', 'Right', 'Down', 'Left')
		return null if pages is null or pages.Count == 0
		result = MacroStatement('Pages')
		for page in pages:
			if string.IsNullOrEmpty(page.GraphicFile):
				tileValue = (ConvertHighTileValue(page.Graphic + 10000) if page.Graphic != 0 else ConvertHighTileValue(10001) - 1)
				tr = turbu.tilesets.TTileRef(tileValue)
				graphicName = "*$(tr.Group)"
				graphicIndex as int = tr.Tile
			else:
				graphicName = page.GraphicFile
				graphicIndex = page.Graphic
			
			sub as MacroStatement = [|
				Page $(page.ID):
					Conditions:
						$(PageConditions(page.Conditions))
					Sprite $graphicName, $graphicIndex, $(ReferenceExpression(EventPageFacing[page.Direction])), $(page.Frame),\
						$(page.Transparent)
					Move $(ReferenceExpression(Enum.GetName(TMoveType, page.MoveType))), $(page.MoveFrequency), \
								$(ReferenceExpression(Enum.GetName(TAnimType, page.AnimType))), $(page.MoveSpeed)
					Trigger $(ReferenceExpression(Enum.GetName(TStartCondition, page.StartCondition)))
					Height $(page.EventHeight), $(page.NoOverlap)
			|]
			if page.MoveType == TMoveType.ByRoute:
				sub.Body.Add(ConvertMoveBlock(page.MoveScript))
			result.Body.Add(sub)
		return result
	
	private def ConvertMoveBlock(script as EventMoveBlock) as MacroStatement:
		result = [|MoveScript $(script.Loop), $(script.Ignore)|]
		result.Body.Add(MacroStatement('Option Loop')) if script.Loop
		result.Body.Add(MacroStatement('Option IgnoreObstacles')) if script.Ignore
		ConvertMoveOrders(script.MoveOrder, result.Body)
		return result
	
	private def PageConditions(value as EventConditions) as Block:
		let COMPARISON_OPERATORS = (BinaryOperatorType.Equality, BinaryOperatorType.GreaterThanOrEqual, \
			BinaryOperatorType.LessThanOrEqual, BinaryOperatorType.GreaterThan, BinaryOperatorType.LessThan, \
			BinaryOperatorType.Inequality)
		result = Block()
		cond as TPageConditions = value.Conditions
		if cond == TPageConditions.None:
			result.Add([|true|])
			return result
		if TPageConditions.Switch1 in cond:
			result.Add([|Switch $(value.Switch1)|])
		if TPageConditions.Switch2 in cond:
			result.Add([|Switch $(value.Switch2)|])
		if TPageConditions.Var1 in cond:
			be = BinaryExpression(COMPARISON_OPERATORS[value.VarOperator], Expression.Lift(value.Variable), \
				Expression.Lift(value.VarValue))
			result.Add([|Variable $be|])
		if TPageConditions.Item in cond:
			result.Add([|Item $(value.Item)|])
		if TPageConditions.Hero in cond:
			result.Add([|Hero $(value.Hero)|])
		if TPageConditions.Timer1 in cond:
			result.Add([|Timer1 $(value.Clock)|])
		if TPageConditions.Timer2 in cond:
			result.Add([|Timer2 $(value.Clock2)|])
		return result
	
	private def ConvertHighTileValue(tile as int) as int:
		assert tile >= 10000
		return -1 if tile == 10000
		tile -= 10000
		group = tile / 48
		assert group <= 2
		group += 18
		return (group << 8) + (tile % 48)
	
	private def ConvertLowTileValue(tile as int) as int:
		assert tile < 10000
		if tile >= 5000:
			tile -= 5000
			group = tile / 48
			assert group <= 2
			group += 15
			return (group << 8) + (tile % 48)
		elif tile >= 4000:
			tile -= 4000
			group = tile / 50
			baseGroup = group % 4
			if baseGroup == 1:
				++group
			elif baseGroup == 2:
				--group
			group += 4
			return group << 8
		elif tile >= 3000:
			tile -= 3000
			group = 3
			return (group << 8) + (tile / 50)
		else:
			refined = tile / 50
			if refined < 20:
				group = 0
			elif refined < 40:
				group = 2
			else: group = 1
			return group << 8
	
	private def TileDataArray(map as LMU) as Block:
		lowTiles as (int) = map.LowChip
		highTiles as (int) = map.HighChip
		assert lowTiles.Length == highTiles.Length
		assert lowTiles.Length == map.Width * map.Height
		lowRefs = matrix(TTileRef, map.Width, map.Height)
		idx = 0
		result = Block()
		lowLayer = MacroStatement('Layer')
		highLayer = MacroStatement('Layer')
		result.Statements.AddRange((lowLayer, highLayer))
		for y in range(map.Height):
			x = 0
			highRow = ArrayLiteralExpression()
			for lTile in lowTiles[idx:idx + map.Width]:
				lowRefs[x, y] = TTileRef(ConvertLowTileValue(lTile))
				++x
			for hTile in highTiles[idx:idx + map.Width]:
				highRow.Items.Add(Expression.Lift(ConvertHighTileValue(hTile)))
			assert highRow.Items.Count == map.Width
			idx += map.Width
			highLayer.Body.Add(highRow)
		assert idx == lowTiles.Length
		BuildLowLayer(lowLayer, lowRefs)
		return result
	
	private def BuildLowLayer(layer as MacroStatement, refs as (TTileRef, 2)):
		for y in range(refs.GetLength(1)):
			row = ArrayLiteralExpression()
			for x in range(refs.GetLength(0)):
				var tref = refs[x, y]
				if tref.Group < 16 and tref.Group != 3:
					tref.Tile = BorderScan(refs, x, y)
				row.Items.Add(Expression.Lift(tref.Value))
			layer.Body.Add(row)

	private def BorderScan(refs as (TTileRef, 2), x as int, y as int) as TDirs8:
		var result = TDirs8.None
		var group = refs[x, y].Group
		
		def CheckNeighbor(x as int, y as int, value as TDirs8):
			return if x < 0 or y < 0
			return if x >= refs.GetLength(0) or y >= refs.GetLength(1)
			isSame as bool
			if group in (0, 1, 2):
				isSame = refs[x, y].Group in (0, 1, 2)
			else: isSame = refs[x, y].Group == group
			result |= value unless isSame
		
		CheckNeighbor(x - 1, y - 1, TDirs8.nw)
		CheckNeighbor(x,     y - 1, TDirs8.n)
		CheckNeighbor(x + 1, y - 1, TDirs8.ne)
		CheckNeighbor(x - 1, y,     TDirs8.w)
		CheckNeighbor(x + 1, y,     TDirs8.e)
		CheckNeighbor(x - 1, y + 1, TDirs8.sw)
		CheckNeighbor(x,     y + 1, TDirs8.s)
		CheckNeighbor(x + 1, y + 1, TDirs8.se)
		return result

public def ConvertMoveOrders(orders as List[of MoveOpcode], body as Block):
	i = 0
	while i < orders.Count:
		opcode = orders[i]
		if opcode.Data is not null:
			mie = MethodInvocationExpression(ReferenceExpression(turbu.pathing.MOVE_CODES[opcode.Code]))
			mie.Arguments.Add(Expression.Lift(opcode.Name)) if opcode.Name is not null
			for value in opcode.Data:
				mie.Arguments.Add(Expression.Lift(value))
			body.Add(mie)
		else:
			runCount = 0
			while i + 1 < orders.Count and orders[i + 1].Code == opcode.Code:
				++i
				++runCount
			if runCount == 0:
				body.Add(ReferenceExpression(turbu.pathing.MOVE_CODES[opcode.Code]))
			else: body.Add([| $(ReferenceExpression(turbu.pathing.MOVE_CODES[opcode.Code])) * $runCount |])
		++i
