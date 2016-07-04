namespace TURBU.RM2K.Import.LCF

import System.Collections.Generic
import System.IO
import System.Linq.Enumerable

struct StartPoint:
	Map as int
	X as int
	Y as int

class LMT:
	[Getter(Maps)]
	private final _maps = Dictionary[of int, MapTreeData]()
	
	[Getter(Nodes)]
	private final _nodes = List[of int]()
	
	[Getter(CurrentMap)]
	private final _currentMap as int
	
	[Getter(StartPoints)]
	private final _startPoints = List[of StartPoint]()

	//layout is too irregular to parse as a standard LCFObject
	def constructor(input as Stream):
		assert ReadLCFString(input) == 'LcfMapTree', "File header 'LcfMapTree' not found"
		for i in range(BERInt(input)):
			data = MapTreeData(input)
			_maps.Add(data.ID, data)
		for i in range(BERInt(input)):
			_nodes.Add(BERInt(input))
		assert _nodes[0] == 0
		assert _nodes.Count == _maps.Count
		_currentMap = BERInt(input)
		current = BERInt(input)
		base = 0
		for i in range(4):
			sp = StartPoint(Map: -1, X: 0, Y: 0)
			if current == base + 1:
				sp.Map = LCFInt(input)
				current = BERInt(input)
			elif current > 0 and current < base + 1:
				raise LCFUnexpectedSection(current, 1, LMT)
			if current == base + 2:
				sp.X = LCFInt(input)
				current = BERInt(input)
			elif current > 0 and current < base + 2:
				raise LCFUnexpectedSection(current, 2, LMT)
			if current == base + 3:
				sp.Y = LCFInt(input)
				current = BERInt(input)
			elif current > 0 and current < base + 3:
				raise LCFUnexpectedSection(current, 3, LMT)
			StartPoints.Add(sp)
			base += 10
		assert current == 0, "Ending 0 not found at offset $(input.Position.ToString('X'))"
	
	public def Save(output as Stream):
		WriteValue(output, 'LcfMapTree')
		WriteBERInt(output, _maps.Count)
		for data in _maps.Values.OrderBy({m | m.ID}):
			data.Save(output)
		WriteBERInt(output, _nodes.Count)
		for node in _nodes:
			WriteBERInt(output, node)
		WriteBERInt(output, _currentMap)
		current = 1
		for sp in StartPoints:
			unless sp.Map == -1:
				WriteBERInt(output, current)
				WriteValue(output, sp.Map)
			unless sp.X == 0:
				WriteBERInt(output, current + 1)
				WriteValue(output, sp.X)
			unless sp.Y == 0:
				WriteBERInt(output, current + 2)
				WriteValue(output, sp.Y)
			current += 10
		output.WriteByte(0)
	
	def Ancestry(id as int) as string*:
		var currentMap = id
		var result = List[of string]()
		while currentMap > 0:
			var value = self.Maps[currentMap]
			result.Add(value.Name)
			currentMap = value.Parent
		return result.AsEnumerable().Reverse().ToArray()

LCFObject MapTreeData:
	hasID
	1    = Name as string
	2    = Parent(0) as int
	3    = Generation(0) as int
	4    = NodeType as int
	5    = HScroll(0) as int
	6    = VScroll(0) as int
	7    = TreeOpen(false) as bool
	0x0B = BgmState as int
	0x0C = BgmData as RMMusic
	0x15 = BattleBGState as int
	0x16 = BattleBGName('') as string
	0x1F = CanPort as int
	0x20 = CanEscape as int
	0x21 = CanSave as int
	0x29 = Battles as (EncounterData)
	0x2C = EncounterRate(25) as int
	0x33 = AreaData as intArray

LCFObject EncounterData:
	hasID
	1 = MonsterParty as int