namespace turbu.RM2K.items

import turbu.defs
import turbu.items
import commons
import TURBU.RM2K
import turbu.classes
import Boo.Adt
import Pythia.Runtime
import System.Collections.Generic
import System
import turbu.RM2K.Item.types
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import TURBU.Meta

class TRpgItem(TObject):

	[Getter(Template)]
	private FTemplate as TItemTemplate

	[Property(Quantity)]
	private FQuantity as int

	[Property(Level)]
	private FLevel as int

	protected virtual def GetUses() as int:
		return FQuantity

	protected virtual def SetUses(Value as int):
		pass

	protected abstract def GetOnField() as bool:
		pass

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def UseOnce():
		--FQuantity

	[NoImport]
	public def constructor(Item as int, Quantity as int):
		super()
		FTemplate = GDatabase.value.Items[Item]
		FQuantity = Quantity

	[NoImport]
	public static def NewItem(Item as int, Quantity as int) as TRpgItem:
		subtype as TRpgItemClass
		caseOf GDatabase.value.Items[Item].ItemType:
			case TItemType.Junk:
				subtype = classOf(TJunkItem)
			case TItemType.Weapon, TItemType.Armor:
				subtype = classOf(TEquipment)
			case TItemType.Medicine:
				subtype = classOf(TRecoveryItem)
			case TItemType.Book:
				subtype = classOf(TBookItem)
			case TItemType.Upgrade:
				subtype = classOf(TStatItem)
			case TItemType.Skill:
				subtype = classOf(TSkillItem)
			case TItemType.Variable:
				subtype = classOf(TSwitchItem)
			default :
				raise Exception('Invalid Item type')
		return subtype.Create(Item, Quantity)

	public abstract def UsableBy(hero as int) as bool:
		pass

	public virtual def UsableByHypothetical(hero as int) as bool:
		return UsableBy(hero)

	public UsesLeft as int:
		get: return GetUses()
		set: SetUses(value)

	public ID as int:
		get: return Template.ID

	public Desc as string:
		get: return Template.Desc

	public Name as string:
		get: return Template.Name

	public Cost as int:
		get: return Template.Cost

	public UsableOnField as bool:
		get: return GetOnField()

class TRpgInventory(TObject):

	private FSorted as bool

	private FList = List[of TRpgItem]()

	private def GetItem(id as int) as TRpgItem:
		Sort()
		return FList[id]

	public def constructor():
		super()

	[NoImport]
	public def Serialize(writer as JsonWriter):
		Item as TRpgItem
		Sort()
		writeJsonArray writer:
			for Item in FList:
				writeJsonObject writer:
					writeJsonProperty writer, 'ID', Item.ID
					writeJsonProperty writer, 'Quantity', Item.Quantity
					writer.CheckWrite('Uses', Item.UsesLeft, Item.Quantity)

	[NoImport]
	public def Deserialize(arr as JArray):
		i as int
		id as int
		Quantity as int
		obj as JObject
		FList.Clear()
		for i in range(0, arr.Count):
			obj = arr[i] cast JObject
			obj.CheckRead('ID', id)
			obj.CheckRead('Quantity', Quantity)
			id = self.Add(id, Quantity)
			Quantity = -1
			obj.CheckRead('Uses', Quantity)
			if Quantity != -1:
				FList[id].UsesLeft = Quantity
			obj.CheckEmpty()

	public def Add(id as int, number as int) as int:
		i as int
		Item as TRpgItem
		template as TItemTemplate
		result = -1
		if not IsBetween(id, 1, GDatabase.value.Items.Count):
			return result
		Item = null
		template = GDatabase.value.Items[id]
		for i in range(0, Count):
			if FList[i].Template == template:
				Item = FList[i]
				result = i
				break
		if Item == null:
			result = FList.Count
			FList.Add(TRpgItem.NewItem(id, number))
			FSorted = false
		else:
			Item.Quantity = Math.Min(MAXITEMS, Item.Quantity + number)
		return result

	public def AddItem(value as TRpgItem):
		i as int = 0
		Item as TRpgItem = null
		total as int
		while (Item == null) and (i < Count):
			if FList[i].Template == value.Template:
				Item = FList[i]
			++i
			if Item == null:
				FList.Add(value)
				FSorted = false
			else:
				total = value.Quantity + Item.Quantity
				if total > MAXITEMS:
					value.Quantity -= total - MAXITEMS
				Item.Quantity += value.Quantity

	public def IndexOf(id as int) as int:
		return -1 unless IsBetween(id, 1, GDatabase.value.Items.Count)
		for i in range(self.Count):
			return i if FList[i].Template.ID == id
		return -1

	public def QuantityOf(id as int) as int:
		idx as int = IndexOf(id)
		result = (0 if idx == -1 else FList[idx].Quantity)
		return result

	public def Contains(id as int) as bool:
		return IndexOf(id) != -1

	public def Remove(id as int, number as int):
		i as int = 0
		Item as TRpgItem = null
		if (id < 1) or (id > GDatabase.value.Items.Count):
			return
		while (Item == null) and (i < Count):
			if FList[i].Template == GDatabase.value.Items[id]:
				Item = FList[i]
			++i
			if Item != null:
				if Item.Quantity <= number:
					FList.Remove(Item)
				else:
					Item.Quantity -= number

	public def Sort():
		unless FSorted:
			FList.Sort(Comparer[of TRpgItem].Create(ItemSortCompare))
			FSorted = true

	public Count as int:
		get: return FList.Count

	public self[id as int] as TRpgItem:
		get:
			return GetItem(id)

	private static def ItemSortCompare(item1 as TRpgItem, item2 as TRpgItem) as int:
		return item1.Template.ID - item2.Template.ID

let MAXITEMS = 99
