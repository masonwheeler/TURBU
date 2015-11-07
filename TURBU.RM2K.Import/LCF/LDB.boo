namespace TURBU.RM2K.Import.LCF

import System
import System.Linq.Enumerable

LCFObject LDB:
	header 'LcfDataBase'
	0x0B = Heroes as (RMHero)
	0x0C = Skills as (RMSkill)
	0x0D = Items as (RMItem)
	0x0E = Monsters as (RMMonster)
	0x0F = MParties as (RMMonsterParty)
	0x10 = Terrains as (RMTerrain)
	0x11 = Attributes as (RMAttribute)
	0x12 = Conditions as (RMCondition)
	0x13 = Animations as (RMAnimation)
	0x14 = Tilesets as (RMTileset)
	0x15 = Vocab as RMVocabDict
	0x16 = SysData as RMSystemRecord
	0x17 = Switches as (RMVariable)
	0x18 = Variables as (RMVariable)
	0x19 = GlobalEvents as (GlobalEvent)
	skipSec range(0x1A, 0x1C)
	0x1D = BattleLayout as RMBattleLayout
	0x1E = Classes as (RMCharClass)
	skipSec 0x1F
	0x20 = BattleAnims as (RM2K3AttackAnimation)
	noZeroEnd

class RMVocabDict(ILCFObject):
	[Getter(Items)]
	private _dict = System.Collections.Generic.Dictionary[of int, string]()
	
	def constructor(input as System.IO.Stream):
		last = -1
		current = BERInt(input)
		while current > 0:
			assert current > last
			last = current
			_dict.Add(current, LCFString(input))
			current = BERInt(input)
	
	def Save(output as System.IO.Stream):
		for pair in _dict.OrderBy({kv | kv.Key}):
			WriteBERInt(output, pair.Key)
			WriteValue(output, pair.Value)
		output.WriteByte(0)
	
	self[index as int] as string:
		get: return Items[index]

LCFObject RMVariable:
	hasID
	1 = Name('') as string