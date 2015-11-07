namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import turbu.map.metadata
import TURBU.Meta
import TURBU.RM2K.Import.LCF

static class TMapTreeConverter:
	
	public def ConvertMapTree(mapTree as LMT) as MacroStatement:
		result = [|
			MapTree:
				MapEngines:
					'TURBU basic map engine'
		|]
		assert mapTree.Maps.Count == mapTree.Nodes.Count
		mapping = System.Collections.Generic.Dictionary[of int, MacroStatement]()
		for node in mapTree.Nodes:
			current as MapTreeData = mapTree.Maps[node]
			caseOf current.NodeType:
				case 0:
					metadata = ConvertRoot(current, node)
					result.Body.Add(metadata)
					mapping.Add(node, metadata)
				case 1:
					metadata = ConvertMetadata(current, node)
					result.Body.Add(metadata)
					mapping.Add(node, metadata)
				case 2:
					AddRegion(mapping[current.Parent], current, node)
				default: raise "Unknown LMT node type $(current.NodeType) on node #$node"
		currentMapObj = mapTree.Maps[mapTree.CurrentMap]
		currentMap = (mapTree.CurrentMap if currentMapObj.NodeType < 2 else currentMapObj.Parent)
		result.Body.Add([|CurrentMap $currentMap|])
		for pt in mapTree.StartPoints:
			result.Body.Add([|StartPoint $(pt.Map), $(pt.X), $(pt.Y)|])
		return result
	
	private def AddRegion(map as MacroStatement, area as MapTreeData, id as int):
		areaData as (int) = area.AreaData
		result = [|
			Area $id:
				name $(area.Name)
				bounds $(areaData[0]), $(areaData[1]), $(areaData[2]), $(areaData[3])
		|]
		if assigned(area.Battles) and area.Battles.Count > 0:
			battles = MacroStatement('Battles')
			for party in area.Battles:
				battles.Arguments.Add(Expression.Lift(party.MonsterParty))
			result.Body.Add(battles)
		map.Body.Add(result)
	
	private def ConvertRoot(current as MapTreeData, id as int) as MacroStatement:
		assert id == 0
		return [|
			root:
				Name $(current.Name)
				TreeOpen $(current.TreeOpen)
		|]
	
	private def ConvertMetadata(current as MapTreeData, id as int) as MacroStatement:
		result = [|
			map $id:
				Name $(current.Name)
				Parent $(current.Parent)
				MapEngine 'TURBU basic map engine'
				ScrollPosition $(current.HScroll), $(current.VScroll)
				TreeOpen $(current.TreeOpen)
				BgmState $(ReferenceExpression(Enum.GetName(TInheritedDecision, current.BgmState)))
				BattleBgState $(ReferenceExpression(Enum.GetName(TInheritedDecision, current.BattleBGState)))
				CanPort $(ReferenceExpression(Enum.GetName(TInheritedDecision, current.CanPort)))
				CanEscape $(ReferenceExpression(Enum.GetName(TInheritedDecision, current.CanEscape)))
				CanSave $(ReferenceExpression(Enum.GetName(TInheritedDecision, current.CanSave)))
				EncounterScript RandomEncounterSteps(0, $(current.EncounterRate))
		|]
		if current.BgmState == TInheritedDecision.Yes:
			result.Body.Add(TMusicConverter.Convert(current.BgmData, 'Song'))
		if current.BattleBGState == TInheritedDecision.Yes:
			result.Body.Add([|BattleBgName $(current.BattleBGName)|])
		if assigned(current.Battles) and current.Battles.Count > 0:
			battles = MacroStatement('battles')
			for party in current.Battles:
				battles.Arguments.Add(Expression.Lift(party.MonsterParty))
			result.Body.Add(battles)
		return result
