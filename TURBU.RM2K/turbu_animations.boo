namespace turbu.animations

import System
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
	private FFrame as ushort

	[Property(Sound)]
	private FSound as TRpgSound

	[Property(Flash)]
	private FFlashWhere as TFlashTarget

	[Property(Color)]
	private FColor = TSgColor(31, 31, 31, 31)

	[Property(ShakeWhere)]
	private FShakeWhere as TFlashTarget

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def GetColor(index as int) as byte:
		return FColor.Rgba[index]

	public def constructor():
		super()
		FSound = TRpgSound()

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
	private FPosition as TSgPoint

	[Property(Zoom)]
	private FZoom as int = 100

	[Property(Color)]
	private FColor = TSgColor(100, 100, 100, 100)

	[Property(ImageIndex)]
	private FImageIndex as int

	[Property(Transparency)]
	private FTransparency as int

[TableName('Animations')]
class TAnimTemplate(TRpgDatafile):

	[Property(Filename)]
	private FFilename as string

	[Property(Effects)]
	private FTimingSec = TRpgObjectList[of TAnimEffects]()

	[Property(Frames)]
	private FFrameSec = TRpgObjectList[of TAnimCell]()

	[Property(HitsAll)]
	private FHitsAll as bool

	[Property(YTarget)]
	private FYTarget as TAnimYTarget

	[Property(CellSize)]
	private FCellSize as TSgPoint

	public def constructor():
		super()

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
