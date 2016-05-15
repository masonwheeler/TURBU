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

def Battle(which as int, background as string, firstStrike as bool, results as TBattleResult) as TBattleResult:
	var formation = (TBattleFormation.FirstStrike if firstStrike else TBattleFormation.Normal)
	return BattleEx(which, background, formation, results, 0, 0)

def BattleEx(which as int, background as string, formation as TBattleFormation, bgMode as int, terrain as int, results as TBattleResult) as TBattleResult:
	if background == '':
		caseOf bgMode:
			case 0, 1:
				background = GetCurrentBackground()
			case 2:
				background = GDatabase.value.Terrains[terrain].BattleBG
	mParty as TRpgMonsterParty = GDatabase.value.MonsterParties[which]
	engine as IBattleEngine = GGameEngine.value.DefaultBattleEngine
	var conditions = TBattleConditions(background, formation, results)
	FadeOutMusic(0)
	PlaySystemMusic(TBgmTypes.Battle, false)
	EraseScreenDefault(TTransitionTypes.BattleStartErase)
	GScriptEngine.value.ThreadWait()
	battleResult as TBattleResultData = engine.StartBattle(GEnvironment.value.Party, mParty, conditions)
	ShowScreenDefault(TTransitionTypes.BattleEndShow)
	GScriptEngine.value.ThreadWait()
	FadeOutMusic(0)
	FadeInLastMusic(0)
	assert battleResult.data == null
	return battleResult.result

def SetEncounterRate(low as int, high as int):
	raise "Not implemented yet"

def EndBattle():
	raise "Not implemented yet"

private def GetTerrainBackground() as string:
	loc as TSgPoint = GEnvironment.value.Party.Sprite.Location
	terrain as int = GSpriteEngine.value.GetTile(loc.x, loc.y, 0).Terrain
	return GDatabase.value.Terrains[terrain].BattleBG

private def GetMapBackground(metadata as TMapMetadata) as string:
	return (GetTerrainBackground() if string.IsNullOrEmpty(metadata.BattleBgName) else metadata.BattleBgName)

private def GetCurrentBackground() as string:
	metadata as TMapMetadata = GDatabase.value.MapTree[GSpriteEngine.value.MapID]
	while (metadata.BattleBgState != TInheritedDecision.Parent) and (metadata.Parent == 0):
		caseOf metadata.BattleBgState:
			case TInheritedDecision.Parent:
				metadata = GDatabase.value.MapTree[metadata.Parent]
			case TInheritedDecision.No:
				return GetTerrainBackground()
			case TInheritedDecision.Yes:
				return GetMapBackground(metadata)

//Hack, just to get this to compile at this stage.  Will probably revamp later.
static class BattleState:
	def TurnsMatch(multiple as int, offset as int) as bool:
		raise "Not implemented yet"

	def MonstersPresent(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def MonsterHPBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def MonsterMPBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def PartyLevelBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def PartyExhaustionBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"
	
	def GetMonster(i as int) as TRpgMonster:
		raise "Not implemented yet"
