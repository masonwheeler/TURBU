﻿namespace TURBU.RM2K

import System
import System.Collections.Generic
import System.Linq.Enumerable
import Pythia.Runtime
import turbu.animations
import turbu.characters
import turbu.classes
import turbu.containers
import turbu.defs
import turbu.items
import turbu.map.metadata
import turbu.resists
import turbu.skills
import turbu.sounds
import turbu.terrain
import turbu.tilesets
import TURBU.BattleEngine
import TURBU.DatabaseInterface
import TURBU.RM2K.GameData
import TURBU.MapInterface
import TURBU.MapObjects
import turbu.monsters

[TableName('Vocab')]
class TRpgVocabDictionary(TRpgDatafile):
	[Getter(Vocab)]
	FVocab = Dictionary[of string, string]()

[Transient]
class TRpgDatabase(TRpgDatafile, IRpgDatabase):
	
	[Getter(Anim)]
	private FAnims as TRpgDataDict[of TAnimTemplate]
	
	[Getter(BattleStyle)]
	private FBattleStyle = TRpgObjectList[of TBattleEngineData]()
	
	[Getter(Bgm)]
	private FBgm = array(TRpgMusic, Enum.GetValues(TBgmTypes).Length)
	
	[Getter(Classes)]
	FClasses as TRpgDataDict[of TClassTemplate]
	
	[Getter(Command)]
	FCommands as TBattleCommandList
	
	[Getter(Conditions)]
	private FConditions as TRpgDataDict[of TConditionTemplate]
	
	[Getter(GlobalEvents)]
	private FGlobalEvents = TRpgObjectList[of TRpgMapObject]()
	
	[Getter(Hero)]
	private FHeroes as TRpgDataDict[of THeroTemplate]
	
	[Getter(Layout)]
	private FLayout as TGameLayout
	
	private FMapTree as TMapTree
	
	[Getter(MonsterParties)]
	private FMonsterParties as TRpgDataDict[of TRpgMonsterParty]
	
	[Getter(MoveMatrix)]
	private FMoveMatrix as List[of ((int))]
	
	[Getter(Sfx)]
	private FSfx = array(TRpgSound, Enum.GetValues(TSfxTypes).Length)
	
	[Getter(Skill)]
	private FSkills as TRpgDataDict[of TSkillTemplate]
	
	[Getter(Terrains)]
	private FTerrains as TRpgDataDict[of TRpgTerrain]
	
	[Getter(Tileset)]
	private FTilesets as TRpgDataDict[of TTileSet]
	
	[Getter(TileGroups)]
	private FTileGroups = Dictionary[of string, TTileGroup]()
	
	[Getter(Vehicles)]
	private FVehicles as TRpgDataDict[of TVehicleTemplate]
	
	[Getter(Switch)]
	private FSwitches = List[of string]()
	
	[Getter(Variable)]
	private FVariables = List[of string]()
	
	[Getter(Items)]
	private FItems as TRpgDataDict[of TItemTemplate]
	
	private FSysVocab as TRpgVocabDictionary
	
	def constructor(dm as TdmDatabase):
		reader = dm.Reader
		FItems = TRpgDataDict[of TItemTemplate](reader)
		FAnims = TRpgDataDict[of TAnimTemplate](reader)
		FConditions = TRpgDataDict[of TConditionTemplate](reader)
		FClasses = TRpgDataDict[of TClassTemplate](reader)
		FHeroes = TRpgDataDict[of THeroTemplate](reader)
		FMonsterParties = TRpgDataDict[of TRpgMonsterParty](reader)
		FSkills = TRpgDataDict[of TSkillTemplate](reader)
		FTerrains = TRpgDataDict[of TRpgTerrain](reader)
		FTilesets = TRpgDataDict[of TTileSet](reader)
		for grp in reader.GetReader[of TTileGroup](true).GetAll():
			FTileGroups.Add(grp.Filename, grp)
		TTileGroupRecord.LookupGroup = {name | return FTileGroups[name]}
		FVehicles = TRpgDataDict[of TVehicleTemplate](reader)
		FCommands = TBattleCommandList(reader)
		FLayout = reader.GetReader[of TGameLayout](true).GetData(0)
		LoadSounds(reader)
		FSysVocab = reader.GetReader[of TRpgVocabDictionary](true).GetData(0)
		FMapTree = reader.GetReader[of TMapTree](true).GetData(0)
		FMoveMatrix = FLayout.MoveMatrix
	
	private def LoadSounds(reader as TURBU.DataReader.IDataReader):
		soundReader = reader.GetReader[of TRpgSound](true)
		musicReader = reader.GetReader[of TRpgMusic](true)
		i = -1
		for sfx in soundReader.GetAll():
			++i
			FSfx[i] = sfx
		i = -1
		for song in musicReader.GetAll():
			++i
			FBgm[i] = song
	
	def VocabNum(name as string, num as int) as string:
		assert false

	public Vocab[key as string] as string:
		get: return FSysVocab.Vocab[key]
	
	public MapTree as IMapTree:
		get: return FMapTree
	
	def InterpolateVocab(key as string, value as string) as string:
		assert false
	
	def InterpolateVocab(key as string, value as string, count as int) as string:
		assert false
	
static class GDatabase:
	public value as TRpgDatabase

class TBattleCommandList(TRpgDataDict[of TBattleCommand]):
	
	public def constructor(dataset as TURBU.DataReader.IDataReader):
		super(dataset)
	
	def IndexOf(name as string) as int:
		cmd = self.Values.FirstOrDefault({c | c.Name == name})
		return (cmd.ID if assigned(cmd) else -1)