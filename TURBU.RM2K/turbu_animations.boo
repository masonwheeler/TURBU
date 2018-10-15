namespace turbu.animations

import System
import System.Linq.Enumerable
import Newtonsoft.Json.Linq
import turbu.classes
import turbu.containers
import turbu.defs
import turbu.sounds
import SG.defs

enum TAnimYTarget:
	Top
	Center
	Bottom

enum TFlashTarget:
	None
	Target
	Screen

class TAnimEffects(TRpgDatafile):

	[Property(Frame)]
	private FFrame as int

	[Property(Sound)]
	private FSound as TRpgSound

	[Property(Flash)]
	private FFlashWhere as TFlashTarget

	[Property(Color)]
	private FColor = TSgColor(31, 31, 31, 31)

	[Property(ShakeWhere)]
	private FShakeWhere as TFlashTarget

	private def GetColor(index as int) as byte:
		return FColor.Rgba[index]

	public def constructor():
		super()
		FSound = TRpgSound()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Frame', FFrame)
		var soundVal = value['Sound'] cast JArray
		if soundVal is not null:
			value.Remove('Sound')
			FSound = TRpgSound(soundVal)
		value.CheckReadEnum('Flash', FFlashWhere)
		colorValue as (int)
		if value.ReadArray('Color', colorValue):
			assert colorValue.Length == 4
			FColor = TSgColor(colorValue[0], colorValue[1], colorValue[2], colorValue[3])
		value.CheckReadEnum('ShakeWhere', FShakeWhere)
		value.CheckEmpty()

	public r as byte:
		get:
			return GetColor(1)

	public g as byte:
		get:
			return GetColor(2)

	public b as byte:
		get:
			return GetColor(3)

	public a as byte:
		get:
			return GetColor(4)

class TAnimCell(TRpgDatafile):

	[Property(Frame)]
	private FFrame as int

	[Property(Position)]
	private FPosition as SgPoint

	[Property(Zoom)]
	private FZoom as int = 100

	[Property(Color)]
	private FColor = TSgColor(100, 100, 100, 100)

	[Property(ImageIndex)]
	private FImageIndex as int

	[Property(Transparency)]
	private FTransparency as int

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Frame', FFrame)
		value.CheckRead('Position', FPosition)
		value.CheckRead('Zoom', FZoom)
		colorValue as (int)
		if value.ReadArray('Color', colorValue):
			assert colorValue.Length == 4
			FColor = TSgColor(colorValue[0], colorValue[1], colorValue[2], colorValue[3])
		value.CheckRead('ImageIndex', FImageIndex)
		value.CheckRead('Transparency', FTransparency)
		value.CheckEmpty()


[TableName('Animations')]
class TAnimTemplate(TRpgDatafile):

	[Getter(Filename)]
	private FFilename as string

	[Getter(Effects)]
	private FTimingSec = TRpgObjectList[of TAnimEffects]()

	[Getter(Frames)]
	private FFrameSec = TRpgObjectList[of TAnimCell]()

	[Getter(HitsAll)]
	private FHitsAll as bool

	[Getter(YTarget)]
	private FYTarget as TAnimYTarget

	[Getter(CellSize)]
	private FCellSize as SgPoint

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('Filename', FFilename)
		value.CheckRead('HitsAll', FHitsAll)
		value.CheckReadEnum('YTarget', FYTarget)
		value.CheckRead('CellSize', FCellSize)
		var frames = value['Frames'] cast JArray
		value.Remove('Frames')
		for frame in frames.Cast[of JObject]():
			FFrameSec.Add(TAnimCell(frame))
		var effects = value['Effects'] cast JArray
		value.Remove('Effects')
		for effect in effects.Cast[of JObject]():
			FTimingSec.Add(TAnimEffects(effect))
		value.CheckEmpty()

class TBattleCharData(TRpgDatafile):

	[Getter(Filename)]
	protected FFilename as string

	[Getter(Frame)]
	protected FFrame as int

	protected FUnk04 as int

	protected FUnk05 as int

	public def constructor():
		super()

class TBattleCharAnim(TRpgDatafile):

	protected FSpeed as int

	protected FPoses = TRpgObjectList[of TBattleCharData]()

	protected FWeapons = TRpgObjectList[of TBattleCharData]()

	public def constructor():
		super()
