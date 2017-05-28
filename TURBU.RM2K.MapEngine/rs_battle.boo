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
	lock engine:
		var conditions = TBattleConditions(background, formation, results)
		FadeOutMusic(0)
		PlaySystemMusic(TBgmTypes.Battle)
		await EraseScreenDefault(TTransitionTypes.BattleStartErase)
		battleResult as TBattleResultData = engine.StartBattle(GEnvironment.value.Party, mParty, conditions)
		await ShowScreenDefault(TTransitionTypes.BattleEndShow)
		FadeOutMusic(0)
		FadeInLastMusic(0)
	assert battleResult.data == null
	return battleResult.result

def SetEncounterRate(low as int, high as int):
	raise "Not implemented yet"

def EndBattle():
	raise "Not implemented yet"

def SetBattleBG(filename as string):
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
internal class T2kMonster(turbu.Heroes.TRpgBattleCharacter, turbu.RM2K.animations.IAnimTarget):
	def constructor(base as turbu.classes.TRpgDatafile):
		super(base)

	def Show():
		raise "Not implemented yet"

	def SafeLoseHP(value as int):
		raise "Not implemented yet"

	MaxHP as int:
		get: raise "Not implemented yet"

	Condition[i as int] as bool:
		get: raise "Not implemented yet"
		set: raise "Not implemented yet"

	def Flee(force as bool, ignoreIfSurrounded as bool):
		raise "Not implemented yet"

	def Position(sign as int) as TSgPoint:
		raise "Not implemented yet"

	def Flash(r as int, g as int, b as int, power as int, time as int):
		raise "Not implemented yet"

	public override def Retarget() as turbu.Heroes.TRpgBattleCharacter:
		raise "Not implemented yet"

	protected override def SetHP(value as int):
		raise "Not implemented yet"

	protected override def SetMP(value as int):
		raise "Not implemented yet"


static class BattleState:
	def TurnsMatch(multiple as int, offset as int) as bool:
		raise "Not implemented yet"

	def MonstersPresent(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def HeroHPBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def MonsterHPBetween(id as int, minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def MonsterMPBetween(id as int, minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def PartyLevelBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"

	def PartyExhaustionBetween(minimum as int, maximum as int) as bool:
		raise "Not implemented yet"
	
	def GetMonster(i as int) as T2kMonster:
		raise "Not implemented yet"
