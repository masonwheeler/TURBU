namespace turbu.classes

import turbu.containers
import commons
import Pythia.Runtime
import System
import System.Collections.Generic
import System.Linq.Enumerable
import turbu.defs
import TURBU.DataReader
import TURBU.EngineBasis
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

	override def ToString():
		return "$(self.ClassName) $(FTemplate.ID): $(FTemplate.Name)"

abstract class TRpgDatafile(TObject, IRpgObject):
	[Property(Name)]
	protected FName as string = ''

	[Property(ID)]
	protected FId as int

	public def constructor():
		super()
	
	public def constructor(value as JObject):
		super()
		value.CheckRead('ID', FId)
		value.CheckRead('Name', FName)

	override def ToString():
		return "$(self.ClassName) $ID: $Name"

	public def CopyToClipboard():
		System.Windows.Forms.Clipboard.SetData('CF_' + self.ClassName, self)

struct TColorShift:

	private FColorSet as (single)

	[Property(Hue)]
	private FHue as byte

	private def SetColor(x as TColorSet, value as single):
		clamp(value, 0, 2)
		FColorSet[x] = value

	public Red as single:
		get: return FColorSet[TColorSet.Red]
		set: SetColor(TColorSet.Red, value)

	public Green as single:
		get: return FColorSet[TColorSet.Green]
		set: SetColor(TColorSet.Green, value)

	public Blue as single:
		get: return FColorSet[TColorSet.Blue]
		set: SetColor(TColorSet.Blue, value)

	public Sat as single:
		get: return FColorSet[TColorSet.Sat]
		set: SetColor(TColorSet.Sat, value)

	public Clear as bool:
		get: return (FColorSet[TColorSet.Red]  == 0) and (FColorSet[TColorSet.Green] == 0) and \
					(FColorSet[TColorSet.Blue] == 0) and (FColorSet[TColorSet.Sat]   == 0) and (FHue == 0)

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
		FDataset = dataset.GetReader[of T]()
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
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as int):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast int
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as uint):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast uint
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as byte):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast byte
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as single):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast single
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as bool):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		value = item cast bool
		obj.Remove(name)

[Extension]
public def CheckRead(obj as JObject, name as string, ref value as SG.defs.SgPoint):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var arr = item cast JArray
		assert arr.Count == 2
		value = SG.defs.SgPoint(arr[0] cast int, arr[1] cast int)
		obj.Remove(name)

[Extension]
public def ReadArray(obj as JObject, name as string, ref value as (string)) as bool:
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var arr = item cast JArray
		Array.Resize[of string](value, arr.Count)
		for i in range(arr.Count):
			value[i] = arr[i] cast string
		obj.Remove(name)
		return true
	else: return false

[Extension]
public def ReadArray(obj as JObject, name as string, ref value as (int)) as bool:
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var arr = item cast JArray
		Array.Resize[of int](value, arr.Count)
		for i in range(arr.Count):
			value[i] = arr[i] cast int
		obj.Remove(name)
		return true
	else: return false

[Extension]
public def ReadArray(obj as JObject, name as string, ref value as (bool)) as bool:
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var arr = item cast JArray
		Array.Resize[of bool](value, arr.Count)
		for i in range(arr.Count):
			value[i] = arr[i] cast bool
		obj.Remove(name)
		return true
	else: return false

[Extension]
public def ReadArray(obj as JObject, name as string, ref value as (SG.defs.SgPoint)) as bool:
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var arr = item cast JArray
		Array.Resize[of SG.defs.SgPoint](value, arr.Count)
		for i in range(arr.Count):
			var pt = arr[i] cast JArray
			assert pt.Count == 2
			value[i] = SG.defs.SgPoint(pt[0] cast int, pt[1] cast int)
		obj.Remove(name)
		return true
	else: return false

[Extension]
public def CheckReadEnum[of T(struct)](obj as JObject, name as string, ref value as T):
	item as JToken
	obj.TryGetValue(name, item)
	if assigned(item):
		var jValue = item cast string
		value = System.Enum.Parse(T, jValue) cast T
		obj.Remove(name)

[Extension]
public def CheckEmpty(obj as JObject):
	assert obj.Count == 0, "Unknown JSON data: $obj"
	#if obj.Count > 0:
	#	logs.logText('Unknown savefile data: ' + obj.ToString())
