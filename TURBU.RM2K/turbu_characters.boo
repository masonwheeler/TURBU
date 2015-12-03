namespace turbu.characters

import System
import System.Drawing
import System.Linq.Enumerable
import Pythia.Runtime
import SG.defs
import turbu.defs
import turbu.classes
import turbu.skills
import turbu.sounds

enum TCommandStyle:
	Weapon
	Skill
	Defend
	Item
	Flee
	Skillgroup
	Special
	Script

[TableName('Commands')]
class TBattleCommand(TRpgDatafile):

	public def constructor():
		super()

	[Property(Style)]
	private FStyle as TCommandStyle

	[Property(Value)]
	private FVal as short

interface IStatBlock:

	def Compare(other as IStatBlock) as bool

	Size as ushort:
		get
		set

	Block as (int):
		get
		set

	Index as int:
		get

class TStatBlock(TObject, IStatBlock):
	[Property(Block)]
	private FBlock as (int)
	
	[Property(Index)]
	private FIndex as int

	public def Compare(other as IStatBlock) as bool:
		i as int
		lOther as TStatBlock
		if not ((other isa TStatBlock) and (self.Size != other.Size)):
			return false
		lOther = other cast TStatBlock
		i = 0
		while (i < Size) and (FBlock[i] == lOther.FBlock[i]):
			++i
			result = (i == Size)
		return result

	public Size as ushort:
		get: return FBlock.Length
		set: Array.Resize[of int](FBlock, value)

[TableName('Classes')]
class TClassTemplate(TRpgDatafile):

	[Property(MapSprite)]
	private FMapSprite as string = ''

	[Property(SpriteIndex)]
	private FSpriteIndex as int

	[Property(Translucent)]
	private FTranslucent as bool

	[Property(ActionMatrix)]
	private FActionMatrix as int

	[Property(BattleSprite)]
	private FBattleSprite as int

	private FBattleMatrix as int

	[Property(Portrait)]
	private FPortrait as string = ''

	[Property(PortraitIndex)]
	private FPortraitIndex as int

	[Property(Commands)]
	private FCommand = array(int, 0)

	[Property(StatBlocks)]
	private FStatBlocks as (IStatBlock)

	[Property(ExpMethod)]
	private FExpFunc as string = ""

	[Property(ExpVars)]
	private FExpVars = array(int, 0)

	[Property(Skillset)]
	private FSkillset = array(TSkillGainInfo, 0)

	[Property(Resist)]
	private FResists = array(TSgPoint, 0)

	[Property(Condition)]
	private FConditions = array(TSgPoint, 0)

	[Property(Equipment)]
	private FEquip = array(int, 5)

	[Property(DualWield)]
	private FDualWield as TWeaponStyle

	[Property(StaticEq)]
	private FStaticEq as bool

	[Property(StrongDef)]
	private FStrongDef as bool

	[Property(UnarmedAnim)]
	private FUnarmedAnim as int

	[Property(Guest)]
	private FGuest as bool

	[Property(BattlePos)]
	private FBattlePos as TSgPoint

	[Property(OnJoin)]
	private FOnJoin as Action of TRpgObject

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def getCommand(x as byte) as short:
		return FCommand[x]

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def setCommand(x as byte, value as short):
		FCommand[x] = value

	public def constructor():
		super()
		for i in range(TSlot.Relic):
			self.Eq[i] = -1

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def addResist(value as Point):
		Array.Resize[of TSgPoint](FResists, FResists.Length + 1)
		FResists[FResists.Length - 1] = value

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def addCondition(value as Point):
		Array.Resize[of TSgPoint](FConditions, FConditions.Length + 1)
		FConditions[FConditions.Length - 1] = value

	public def GetCondition(value as int) as int:
		return FConditions.FirstOrDefault({p | p.x == value}).y
	
	public Command[x as byte] as short:
		get:
			return getCommand(x)
		set:
			setCommand(x, value)

	public Eq[x as TSlot] as short:
		get: return FEquip[x]
		set: FEquip[x] = value

	public ClsName as string:
		get: return FName
		set: FName = value

[TableName('Heroes')]
class THeroTemplate(TClassTemplate):

	[Property(Title)]
	private FTitle as string

	[Property(CharClass)]
	private FClass as int

	[Property(PortraitShift)]
	private FPortraitShift as TColorShift

	[Property(SpriteShift)]
	private FSpriteShift as TColorShift

	[Property(BattleSpriteShift)]
	private FBattleSpriteShift as TColorShift

	[Property(MinLevel)]
	private FMinLevel as ushort

	[Property(MaxLevel)]
	private FMaxLevel as ushort

	[Property(CanCrit)]
	private FCanCrit as bool

	[Property(CritRate)]
	private FCritRate as int

enum TMovementStyle:
	Surface
	Hover
	Fly

[TableName('Vehicles')]
class TVehicleTemplate(TRpgDatafile):

	[Property(MapSprite)]
	protected FMapSprite as string

	[Property(Translucent)]
	protected FTranslucent as bool

	[Property(ShallowWater)]
	protected FShallowWater as bool

	[Property(DeepWater)]
	protected FDeepWater as bool

	[Property(LowLand)]
	protected FLowLand as bool

	[Property(MovementStyle)]
	protected FMovementStyle as TMovementStyle

	[Property(Altitude)]
	protected FAltitude as byte

	[Property(Music)]
	protected FMusic = TRpgMusic()