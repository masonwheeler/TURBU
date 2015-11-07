namespace turbu.sounds

import System
import turbu.classes
import turbu.defs
import Newtonsoft.Json
import Newtonsoft.Json.Linq

abstract class TSoundTemplate(TRpgDatafile):

	[Property(FadeIn)]
	private FFadeIn as int

	[Property(Tempo)]
	private FTempo as int

	[Property(Volume)]
	private FVolume as int

	[Property(Balance)]
	private FBalance as int

	protected abstract def SetFilename(value as string):
		pass

	public def constructor():
		super()

	public def constructor(source as TSoundTemplate):
		super()
		FName = source.FName
		FFadeIn = source.FFadeIn
		FTempo = source.FTempo
		FBalance = source.FBalance
		FVolume = source.FVolume
	
	public def constructor(filename as string, fadeIn as int, volume as int, tempo as int, balance as int):
		super()
		FName = filename
		FFadeIn = fadeIn
		FVolume = volume
		FTempo = tempo
		FBalance = balance

	public def Serialize(writer as JsonWriter):
		writeJsonObject writer:
			writer.CheckWrite('Name', FName, '')
			writer.CheckWrite('FadeIn', FFadeIn, 0)
			writer.CheckWrite('Tempo', FTempo, 0)
			writer.CheckWrite('Balance', FBalance, 0)
			writer.CheckWrite('Volume', FVolume, 0)

	public def Deserialize(obj as JObject):
		obj.CheckRead('Name', FName)
		obj.CheckRead('FadeIn', FFadeIn)
		obj.CheckRead('Tempo', FTempo)
		obj.CheckRead('Balance', FBalance)
		obj.CheckRead('Volume', FVolume)
		obj.CheckEmpty()

	public Filename as string:
		get: return FName
		set: SetFilename(value)

[TableName('SysSounds')]
class TRpgSound(TSoundTemplate):
	
	def constructor():
		super()

	def constructor(source as TSoundTemplate):
		super(source)
	
	public def constructor(filename as string, fadeIn as int, volume as int, tempo as int, balance as int):
		super(filename, fadeIn, volume, tempo, balance)
	
	protected override def SetFilename(value as string):
		FName = value

[TableName('SysMusic')]
class TRpgMusic(TSoundTemplate):
	
	def constructor():
		super()
	
	def constructor(source as TSoundTemplate):
		super(source)
	
	public def constructor(filename as string, fadeIn as int, volume as int, tempo as int, balance as int):
		super(filename, fadeIn, volume, tempo, balance)
	
	protected override def SetFilename(value as string):
		FName = value
