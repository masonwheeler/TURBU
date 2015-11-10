namespace turbu.classes

import turbu.containers
import commons
import Pythia.Runtime
import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Reflection
import System.Threading
import turbu.defs
import turbu.constants
import TURBU.DataReader
import TURBU.EngineBasis
import TURBU.RM2K
import System.IO
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import Boo.Lang.Compiler

abstract class TRpgObject(TObject):

	[Getter(Template)]
	private FTemplate as TRpgDatafile

	[Property(OnCreate)]
	private FOnCreate as Action of TRpgObject

	[Property(OnDestroy)]
	private FOnDestroy as Action of TRpgObject

	def constructor(base as TRpgDatafile):
		FTemplate = base

abstract class TRpgDatafile(TObject, IRpgObject):
	private static currentloader = ThreadLocal[of BinaryReader]()

	[Property(Name)]
	protected FName as string = ''

	[Property(ID)]
	protected FId as int

	[Property(OnCreate)]
	protected FOnCreate as Action of TRpgObject

	[Property(OnDestroy)]
	protected FOnDestroy as Action of TRpgObject

	protected def GetID() as int:
		return self.ID

	protected def GetName() as string:
		return self.Name

	public def constructor():
		super()
	
	override def ToString():
		return "$(self.ClassName) $ID: $Name"

	public def CopyToClipboard():
		System.Windows.Forms.Clipboard.SetData('CF_' + self.ClassName, self)

struct TColorShift:

	private FColorset as (single)

	[Property(hue)]
	private FHue as byte

	private def getColor(x as TColorSet) as single:
		return FColorset[x]

	private def setColor(x as TColorSet, value as single):
		clamp(value, 0, 2)
		FColorset[x] = value

	private def isClear() as bool:
		return (FColorset[TColorSet.cs_red] == 0) and (FColorset[TColorSet.cs_green] == 0) and (FColorset[TColorSet.cs_blue] == 0) and (FColorset[TColorSet.cs_sat] == 0) and (FHue == 0)

	public red as single:
		get:
			return getColor(TColorSet.cs_red)
		set:
			setColor(TColorSet.cs_red, value)

	public green as single:
		get:
			return getColor(TColorSet.cs_green)
		set:
			setColor(TColorSet.cs_green, value)

	public blue as single:
		get:
			return getColor(TColorSet.cs_blue)
		set:
			setColor(TColorSet.cs_blue, value)

	public sat as single:
		get:
			return getColor(TColorSet.cs_sat)
		set:
			setColor(TColorSet.cs_sat, value)

	public clear as bool:
		get:
			return isClear()

class TRpgDataList[of T(TRpgDatafile, constructor)](TRpgObjectList[of T]):

	public def constructor():
		super()
		self.Add(Activator.CreateInstance[of T]())
	
	public def constructor(values as T*):
		self()
		self.AddRange(values)

	public new def Clear():
		super.Clear()
		self.Add(Activator.CreateInstance(T, null))

class TRpgDataDict[of T(TRpgDatafile, constructor)](Dictionary[of int, TRpgDatafile]):

	protected FDataset as IDataTypeReader[of T]

	protected FCountLoaded as bool

	protected FDatasetCount as int

	protected def Add(value as T):
		self.Add(value.ID, value)

	public def constructor(dataset as IDataReader):
		super()
		FDataset = dataset.GetReader[of T](false)
		//FSerializer = serializer
		self.Add(Activator.CreateInstance[of T]())

	public def Upload():
		assert false
/*		iterator as TRpgDatafile
		for iterator in self.Values:
			if iterator.ID == 0:
				Continue
			else:
				iterator.upload(FSerializer, FDataset)
		if self.Count > 1:
			FDataset.postSafe
			*/

	public def Download():
		for value in self.FDataset.GetAll().Where({v | not self.ContainsKey(v.ID)}):
			self.Add(value)

	public Count as int:
		new get: return FDataset.Count

/*	private callable TGetNewObject(sender as TRpgDataDict[of T]) as T
	
	[Property(OnGetNewObject)]
	private FOnGetNewObject as TGetNewObject
*/
	protected def GetNewItem() as TRpgDatafile:
/*		if assigned(FOnGetNewObject):
			return FOnGetNewObject(self)
		else:*/
			return Activator.CreateInstance(T, null)
	
	public def FirstWhere(filter as Func[of T, bool]) as T:
		assert false
/*		ds as DataTable
		self.Load()
		try:
			ds = TClientDataset.Create(null)
			ds.CloneCursor(FDataset, true)
			ds.Filtered = true
			ds.Filter = TExpression(TLambda.GetExpression(filter)).ToSql
			ds.IndexFieldNames = 'id'
			ds.First
			if ds.RecordCount == 0:
				return null
			return self[ds.FieldByName('id').AsInteger]
		ensure:
			ds.Free()
	*/

	public self[Key as int] as T:
		new get:
			result as TRpgDatafile
			if TryGetValue(Key, result):
				return result cast T
			result = FDataset.GetData(Key)
			self.Add(result)
			return result

class TRpgDecl(IEnumerable[of TNameType]):

	[Property(name)]
	private FName as string

	[Property(designName)]
	private FDesignName as string

	[Property(retval)]
	private FRetval as int

	[Property(params)]
	private FParams as List[of TNameType]

	def System.Collections.IEnumerable.GetEnumerator():
		return FParams.GetEnumerator()
	
	def GetEnumerator() as IEnumerator[of TNameType]:
		return FParams.GetEnumerator()

	public def constructor(aName as string, aDesignName as string):
		FName = aName
		FDesignName = aDesignName
		FParams = List[of TNameType]()

	public def equals(other as TRpgDecl) as bool:
		i as int
		result = ((FParams.Count == other.params.Count) and (self.retval == other.retval))
		if result:
			for i in range(0, FParams.Count):
				result = ((result and (FParams[i].typeVar == other.params[i].typeVar)) and (FParams[i].flags == other.params[i].flags))
		return result

	public def fourInts() as bool:
		i as int
		result = (FParams.Count >= 5)
		if result:
			for I in range(1, 5):
				result = (result and (FParams[i].typeVar == vt_integer))
		return result

	public def Clone() as TRpgDecl:
		param as TNameType
		result = TRpgDecl(FName, FDesignName)
		result.FParams = List[of TNameType]()
		for param in self.FParams:
			result.FParams.Add(param)
		return result

class TDeclList(TRpgObjectList[of TRpgDecl]):

	private def getLookup(value as string) as TRpgDecl:
		return self[IndexOf(value)]

	private FComparer = Comparer[of TRpgDecl].Create(declComp)

	public def IndexOf(value as string) as int:
		result as int
		using dummy = TRpgDecl(value, ''):
			result = self.BinarySearch(dummy, FComparer)
			if result < 0:
				result = -1
		return result

	public new def Sort():
		super.Sort(FComparer)
		i as int = 1
		while i < self.Count:
			if self[i].name == self[(i - 1)].name:
				self.RemoveAt(i)
			else: ++i

	public decl[value as string] as TRpgDecl:
		get: return getLookup(value)

class EventTypeAttribute(System.Attribute):

	[Getter(name)]
	private FName as string

	public def constructor(name as string):
		FName = name

class ERpgLoadError(Exception):
	def constructor(msg as string):
		super(msg)

[Extension]
public def CheckWrite(writer as JsonWriter, name as string, value as string, base as string):
	if value != base:
		writer.WritePropertyName(name)
		writer.WriteValue(value)

[Extension]
public def CheckWrite(writer as JsonWriter, name as string, value as int, base as int):
	if value != base:
		writer.WritePropertyName(name)
		writer.WriteValue(value)

[Extension]
public def CheckWrite(writer as JsonWriter, name as string, value as single, base as single):
	if value != base:
		writer.WritePropertyName(name)
		writer.WriteValue(value)

[Extension]
public def CheckWrite(writer as JsonWriter, name as string, value as bool, base as bool):
	if value != base:
		writer.WritePropertyName(name)
		writer.WriteValue(value)

[Extension]
public def WriteArray(writer as JsonWriter, name as string, value as (int)):
	i as int
	writer.WritePropertyName(name)
	writeJsonArray writer:
		for i in value:
			writer.WriteValue(i)

[Extension]
public def WriteArray(writer as JsonWriter, name as string, value as (bool)):
	b as bool
	writer.WritePropertyName(name)
	writeJsonArray writer:
		for b in value:
			writer.WriteValue(b)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as string):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast string
		item.Remove()

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as int):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast int
		item.Remove()

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as uint):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast uint
		item.Remove()

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as byte):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast byte
		item.Remove()

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as single):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast single
		item.Remove()

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as bool):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast bool
		item.Remove()

[Extension]
public def ReadArray(obj as JObject, name as string, ref value as (bool)):
	arr as JArray
	i as int
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		arr = item cast JArray
		Array.Resize[of bool](value, arr.Count)
		for i in range(0, arr.Count):
			value[i] = arr[i] cast bool
		arr.Remove()

[Extension]
public def CheckEmpty(obj as JObject):
	if obj.Count > 0:
		logs.logText('Unknown savefile data: ' + obj.ToString())

internal def declComp(Left as TRpgDecl, Right as TRpgDecl) as int:
	return string.Compare(Left.name, Right.name)
