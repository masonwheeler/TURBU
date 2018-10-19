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
	private final _name as string

	[Getter(Version)]
	private final _version as TVersion

	public def constructor(name as string, version as TVersion):
		super()
		_name = name
		_version = version

class TEngineData(TObject):

	[Getter(Style)]
	private final _style as TEngineStyle

	[Getter(Engine)]
	private final _engine as TPlugClass

	public def constructor(style as TEngineStyle, engine as TPlugClass):
		super()
		_style = style
		_engine = engine

interface ITurbuPlugin:

	def ListPlugins() as TEngineData*

class RpgPluginException(Exception):
	def constructor(Message as string):
		super(Message)
