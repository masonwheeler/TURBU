namespace TURBU.PluginInterface

import Pythia.Runtime
import System
import turbu.versioning

enum TEngineStyle:
	Map
	Battle
	Data
	Menu
	Minigame

class TRpgPlugBase(TObject):

	public def constructor():
		super()

	public virtual def IsDesign() as bool:
		return false
	
	public virtual def AfterConstruction():
		pass

class TRpgMetadata(TObject):

	[Getter(Name)]
	private FName as string

	[Getter(Version)]
	private FVersion as TVersion

	public def constructor(name as string, version as TVersion):
		super()
		FName = name
		FVersion = version

class TEngineData(TObject):

	[Getter(Style)]
	private FStyle as TEngineStyle

	[Getter(Engine)]
	private FEngine as TPlugClass

	public def constructor(style as TEngineStyle, engine as TPlugClass):
		super()
		FStyle = style
		FEngine = engine

interface ITurbuPlugin:

	def ListPlugins() as TEngineData*

class ERpgPlugin(Exception):
	def constructor(Message as string):
		super(Message)
