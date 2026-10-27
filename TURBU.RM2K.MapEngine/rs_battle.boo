namespace TURBU.RM2K.RPGScript

import System.Threading.Tasks
import turbu.defs
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
import turbu.script.engine
import TURBU.RM2K.RPGScript

[async]
def Battle(which as int, background as string, firstStrike as bool, results as TBattleResult) as Task of TBattleResult:
	var formation = (TBattleFormation.FirstStrike if firstStrike else TBattleFormation.Normal)
	return await(BattleEx(which, background, formation, results, 0, 0))

[async]
def BattleEx(which as int, background as string, formation as TBattleFormation, bgMode as int, terrain as int, results as TBattleResult) as Task of TBattleResult:
	if background == '':
		caseOf bgMode:
			case 0, 1:
				background = GetCurrentBackground()
			case 2:
				background = GDatabase.value.Terrains[terrain].BattleBG
	mParty as TRpgMonsterParty = GDatabase.value.MonsterParties[which]
	engine as IBattleEngine = GGameEngine.value.DefaultBattleEngine
	battleResult as TBattleResultData
	lock engine:
		var conditions = TBattleConditions(background, formation, results)
		MemorizePlayingMusic()
		PlaySystemMusic(TBgmTypes.Battle)
		await EraseScreenDefault(TTransitionTypes.BattleStartErase)
		GMapObjectManager.value.Paused = true
		try:
			battleResult = await(engine.StartBattle(GEnvironment.value.Party, mParty, conditions))
		ensure:
			GMapObjectManager.value.Paused = false
		var outcome = 2
		outcome = 0 if battleResult.result == TBattleResult.Victory
		outcome = 1 if battleResult.result == TBattleResult.Escaped
		GEnvironment.value.CountBattle(outcome)
		await ShowScreenDefault(TTransitionTypes.BattleEndShow)
		FadeInLastMusic(0)
	assert battleResult.data == null
	return battleResult.result

def SetEncounterRate(low as int, high as int):
	GGameEngine.value.Encounters.StepsOverride = high

[async]
def RunEncounter(which as int, firstStrike as bool, canEscape as bool) as Task:
	var results = TBattleResult.Victory
	results |= TBattleResult.Escaped if canEscape
	var formation = (TBattleFormation.FirstStrike if firstStrike else TBattleFormation.Normal)
	try:
		await(BattleEx(which, '', formation, 0, 0, results))
	except ex as System.Exception:
		System.Diagnostics.Debug.WriteLine("Random encounter failed: $ex")
	ensure:
		GGameEngine.value.EncounterFinished()

def EndBattle():
	BattleState.Terminate()

def SetBattleBG(filename as string):
	BattleState.SetBackdrop(filename)

private def GetTerrainBackground() as string:
	loc as SgPoint = GEnvironment.value.Party.Sprite.Location
	terrain as int = GSpriteEngine.value.GetTile(loc.x, loc.y, 0).Terrain
	return GDatabase.value.Terrains[terrain].BattleBG

private def GetMapBackground(metadata as TMapMetadata) as string:
	return (GetTerrainBackground() if string.IsNullOrEmpty(metadata.BattleBgName) else metadata.BattleBgName)

private def GetCurrentBackground() as string:
	metadata as TMapMetadata = GDatabase.value.MapTree[GSpriteEngine.value.MapID]
	while metadata.BattleBgState == TInheritedDecision.Parent and metadata.Parent != 0:
		metadata = GDatabase.value.MapTree[metadata.Parent]
	return GetMapBackground(metadata) if metadata.BattleBgState == TInheritedDecision.Yes
	return GetTerrainBackground()
