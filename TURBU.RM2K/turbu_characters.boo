namespace turbu.characters

import System
import System.Drawing
import System.Linq.Enumerable

import Newtonsoft.Json.Linq
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
	SkillGroup
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

	internal def constructor(value as JObject):
		super()
		value.CheckRead('ID', FIndex)
		value.ReadArray('Block', FBlock)
		value.CheckEmpty()

	public def Compare(other as IStatBlock) as bool:
		unless (other isa TStatBlock) and (self.Size == other.Size):
			return false
		var lOther = other cast TStatBlock
		var i = 0
		while (i < Size) and (FBlock[i] == lOther.FBlock[i]):
			++i
		return i == Size

	public Size as ushort:
		get: return FBlock.Length
		set: Array.Resize[of int](FBlock, value)

[TableName('Classes')]
class TClassTemplate(TRpgDatafile):

	[Getter(MapSprite)]
	private FMapSprite as string = ''

	[Getter(SpriteIndex)]
	private FSpriteIndex as int

	[Getter(Translucent)]
	private FTranslucent as bool

	[Getter(ActionMatrix)]
	private FActionMatrix as int

	[Getter(BattleSprite)]
	private FBattleSprite as int

	private FBattleMatrix as int

	[Getter(Portrait)]
	private FPortrait as string = ''

	[Getter(PortraitIndex)]
	private FPortraitIndex as int

	[Getter(Commands)]
	private FCommands = array(int, 0)

	[Getter(StatBlocks)]
	private FStatBlocks as (IStatBlock)

	[Getter(ExpMethod)]
	private FExpFunc as string = ""

	[Getter(ExpVars)]
	private FExpVars = array(int, 0)

	[Getter(Skillset)]
	private FSkillset = array(TSkillGainInfo, 0)

	[Getter(Resist)]
	private FResists = array(SgPoint, 0)

	[Getter(Condition)]
	private FConditions = array(SgPoint, 0)

	[Getter(Equipment)]
	private FEquip = array(int, 5)

	[Getter(DualWield)]
	private FDualWield as TWeaponStyle

	[Getter(StaticEq)]
	private FStaticEq as bool

	[Getter(StrongDef)]
	private FStrongDef as bool

	[Getter(UnarmedAnim)]
	private FUnarmedAnim as int

	[Getter(Guest)]
	private FGuest as bool

	[Getter(BattlePos)]
	private FBattlePos as SgPoint

	[Property(OnJoin)]
	private FOnJoin as Action of TRpgObject

	public def constructor():
		super()
		for i in range(TSlot.Relic):
			self.Eq[i] = -1

	public def constructor(value as JObject):
		self(value, false)

	public def constructor(value as JObject, inherited as bool):
		super(value)
		value.CheckRead('MapSprite', FMapSprite)
		value.CheckRead('SpriteIndex', FSpriteIndex)
		value.CheckRead('Translucent', FTranslucent)
		value.CheckRead('ActionMatrix', FActionMatrix)
		value.CheckRead('BattleSprite', FBattleSprite)
		value.CheckRead('Portrait', FPortrait)
		value.CheckRead('PortraitIndex', FPortraitIndex)
		value.ReadArray('Commands', FCommands)
		blocks as JArray = value['StatBlocks']
		value.Remove('StatBlocks')
		Array.Resize[of IStatBlock](FStatBlocks, blocks.Count)
		for block in blocks.Cast[of JObject]().OrderBy({o | o['ID'] cast int}):
			assert assigned(block['Block'])
			FStatBlocks[block['ID'] cast int - 1] = TStatBlock(block)
		value.CheckRead('ExpMethod', FExpFunc)
		value.ReadArray('ExpVars', FExpVars)
		skillset as JArray = value['Skillset']
		if assigned(skillset):
			value.Remove('Skillset')
			Array.Resize[of TSkillGainInfo](FSkillset, skillset.Count)
			for i in range(skillset.Count):
				FSkillset[i] = TSkillGainInfo(skillset[i] cast JObject)
		value.ReadArray('Resist', FResists)
		value.ReadArray('Condition', FConditions)
		value.ReadArray('Equipment', FEquip)
		value.CheckReadEnum('DualWield', FDualWield)
		value.CheckRead('StaticEq', FStaticEq)
		value.CheckRead('StrongDef', FStrongDef)
		value.CheckRead('UnarmedAnim', FUnarmedAnim)
		value.CheckRead('Guest', FGuest)
		value.CheckRead('BattlePos', FBattlePos)
		value.CheckEmpty() unless inherited

	public def AddResist(value as Point):
		Array.Resize[of SgPoint](FResists, FResists.Length + 1)
		FResists[FResists.Length - 1] = value

	public def AddCondition(value as Point):
		Array.Resize[of SgPoint](FConditions, FConditions.Length + 1)
		FConditions[FConditions.Length - 1] = value

	public def GetCondition(value as int) as int:
		return FConditions.FirstOrDefault({p | p.x == value}).y
	
	public Command[x as byte] as short:
		get: return FCommands[x]
		set: FCommands[x] = value

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
	private FMinLevel as int

	[Property(MaxLevel)]
	private FMaxLevel as int

	[Property(CanCrit)]
	private FCanCrit as bool

	[Property(CritRate)]
	private FCritRate as int

	public def constructor():
		super()

	public def constructor(value as JObject):
		super(value, true)
		value.CheckRead('Title', FTitle)
		value.CheckRead('CharClass', FClass)
		value.CheckReadEnum('PortraitShift', FPortraitShift)
		value.CheckReadEnum('SpriteShift', FSpriteShift)
		value.CheckReadEnum('BattleSpriteShift', FBattleSpriteShift)
		value.CheckRead('MinLevel', FMinLevel)
		value.CheckRead('MaxLevel', FMaxLevel)
		value.CheckRead('CanCrit', FCanCrit)
		value.CheckRead('CritRate', FCritRate)
		value.CheckEmpty()

enum TMovementStyle:
	Surface
	Hover
	Fly

[TableName('Vehicles')]
class TVehicleTemplate(TRpgDatafile):

	[Property(MapSprite)]
	protected FMapSprite as string

	[Property(SpriteIndex)]
	protected FSpriteIndex as int

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