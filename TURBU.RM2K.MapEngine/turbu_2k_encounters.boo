namespace TURBU.RM2K.MapEngine

import System
import System.Collections.Generic
import Pythia.Runtime
import SG.defs
import turbu.map.metadata
import turbu.monsters
import turbu.RM2K.environment
import turbu.RM2K.sprite.engine
import TURBU.RM2K

class TEncounterTracker:

	private static final BANDS = (20, 40, 60, 100, 140, 160, 180)

	private static final FACTORS = (1.0 / 16, 1.0 / 8, 1.0 / 4, 1.0 / 2, 2.0, 4.0, 8.0, 16.0)

	private _counter as int

	private _pending as bool

	private _stepsOverride = -1

	private _random = Random()

	public Pending as bool:
		get: return _pending

	public StepsOverride as int:
		get: return _stepsOverride
		set: _stepsOverride = value

	public def Reset():
		_counter = 0
		_pending = false
		_stepsOverride = -1

	private def Metadata() as TMapMetadata:
		return GDatabase.value.MapTree[GSpriteEngine.value.MapID] cast TMapMetadata

	private def Steps(metadata as TMapMetadata) as int:
		return _stepsOverride if _stepsOverride >= 0
		var args = metadata.EncounterParams
		return (args[1] if assigned(args) and args.Length > 1 else 0)

	private def PartyLocation() as SgPoint:
		return GEnvironment.value.Party.Sprite.Location

	private def PartyTerrain() as int:
		var loc = PartyLocation()
		return GSpriteEngine.value.GetTile(loc.x, loc.y, 0).Terrain

	private def TerrainRate(terrain as int) as int:
		return (GDatabase.value.Terrains[terrain].EncounterMultiplier if terrain > 0 else 100)

	public def Step():
		var steps = Steps(Metadata())
		return if steps == 0
		var rate = TerrainRate(PartyTerrain())
		_counter += rate
		var band = 0
		while band < BANDS.Length and _counter >= steps * BANDS[band]:
			++band
		var chance = (rate * (FACTORS[band] / steps)) / 100.0
		if chance > _random.NextDouble():
			_counter = 0
			_pending = true

	private def InHabitat(party as TRpgMonsterParty, terrain as int) as bool:
		var habitats = party.Habitats
		return true if terrain < 1 or habitats is null or terrain > habitats.Length
		return habitats[terrain - 1] != 0

	private def AddParties(candidates as List[of int], parties as (int), terrain as int):
		return if parties is null
		for id in parties:
			candidates.Add(id) if InHabitat(GDatabase.value.MonsterParties[id], terrain)

	public def TakePending() as int:
		_pending = false
		var metadata = Metadata()
		var terrain = PartyTerrain()
		var loc = PartyLocation()
		var candidates = List[of int]()
		AddParties(candidates, metadata.Battles, terrain)
		for region in metadata.Regions:
			var b = region.Bounds
			if loc.x >= b.x and loc.x < b.w and loc.y >= b.y and loc.y < b.h:
				AddParties(candidates, region.Battles, terrain)
		return (0 if candidates.Count == 0 else candidates[_random.Next(candidates.Count)])

	public def RollFirstStrike() as bool:
		return _random.Next(32) == 0

	public def CanEscape() as bool:
		var metadata = Metadata()
		while metadata.CanEscape == TInheritedDecision.Parent and metadata.Parent != 0:
			metadata = GDatabase.value.MapTree[metadata.Parent] cast TMapMetadata
		return metadata.CanEscape != TInheritedDecision.No
