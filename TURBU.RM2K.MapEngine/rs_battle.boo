namespace TURBU.RM2K.RPGScript

import turbu.defs
import turbu.script.engine
import TURBU.RM2K
import turbu.monsters
import turbu.battles
import turbu.map.metadata
import SG.defs
import TURBU.Meta
import TURBU.BattleEngine
import TURBU.RM2K.MapEngine
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import TURBU.RM2K.RPGScript

def battle(which as int, background as string, firstStrike as bool, results as TBattleResult) as TBattleResult:
	formation as TBattleFormation
	if firstStrike:
		formation = TBattleFormation.FirstStrike
	else:
		formation = TBattleFormation.Normal
	return battleEx(which, background, formation, results, 0, 0)

def battleEx(which as int, background as string, formation as TBattleFormation, bgMode as int, terrain as int, results as TBattleResult) as TBattleResult:
	mParty as TRpgMonsterParty
	engine as IBattleEngine
	conditions as TBattleConditions
	battleResult as TBattleResultData
	if background == '':
		caseOf bgMode:
			case 0, 1:
				background = GetCurrentBackground()
			case 2:
				background = GDatabase.value.Terrains[terrain].BattleBG
	mParty = GDatabase.value.MonsterParties[which]
	engine = GGameEngine.value.DefaultBattleEngine
	using conditions = TBattleConditions(background, formation, results):
		FadeOutMusic(0)
		PlaySystemMusic(TBgmTypes.Battle, false)
		EraseScreenDefault(TTransitionTypes.BattleStartErase)
		GScriptEngine.value.ThreadWait()
		battleResult = engine.StartBattle(GEnvironment.value.Party, mParty, conditions)
		ShowScreenDefault(TTransitionTypes.BattleEndShow)
		GScriptEngine.value.ThreadWait()
		FadeOutMusic(0)
		FadeInLastMusic(0)
		assert battleResult.data == null
		result = battleResult.result
	return result

private def GetTerrainBackground() as string:
	loc as TSgPoint
	terrain as int
	loc = GEnvironment.value.Party.Sprite.Location
	terrain = GSpriteEngine.value.GetTile(loc.x, loc.y, 0).Terrain
	return GDatabase.value.Terrains[terrain].BattleBG

private def GetMapBackground(metadata as TMapMetadata) as string:
	return (GetTerrainBackground() if string.IsNullOrEmpty(metadata.BattleBgName) else metadata.BattleBgName)

private def GetCurrentBackground() as string:
	metadata as TMapMetadata
	metadata = GDatabase.value.MapTree[GSpriteEngine.value.MapID]
	while (metadata.BattleBgState != TInheritedDecision.Parent) and (metadata.Parent == 0):
		caseOf metadata.BattleBgState:
			case TInheritedDecision.Parent:
				metadata = GDatabase.value.MapTree[metadata.Parent]
			case TInheritedDecision.No:
				return GetTerrainBackground()
			case TInheritedDecision.Yes:
				return GetMapBackground(metadata)
