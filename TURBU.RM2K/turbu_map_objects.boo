namespace TURBU.MapObjects

import System.Linq.Enumerable
import Newtonsoft.Json.Linq

import turbu.containers
import turbu.operators
import SG.defs
import Pythia.Runtime
import System
import turbu.defs
import turbu.classes
import turbu.pathing
import TURBU.MapInterface

enum TMoveType:
	Still
	RandomMove
	CycleUD
	CycleLR
	ChaseHero
	FleeHero
	ByRoute

enum TStartCondition:
	Key
	Touch
	Collision
	Automatic
	Parallel
	Call

enum TAnimType:
	Sentry
	Jogger
	FixedDir
	FixedJog
	Statue
	SpinRight

[EnumSet]
enum TPageConditions:
	None = 0
	Switch1 = 1
	Switch2 = 2
	Var1 = 4
	Item = 8
	Hero = 0x10
	Timer1 = 0x20
	Timer2 = 0x40
	Var2 = 0x80

[EnumSet]
enum TBattlePageConditions:
	None = 0
	Turns = 1
	MonsterTime = 2
	HeroTime = 4
	Exhaustion = 8
	MonsterHP = 0x10
	HeroHP = 0x20
	CommandUsed = 0x40

class TRpgEventConditions(TObject):

	[Property(OnEval)]
	private static FOnEval as Func[of TRpgEventConditions, bool]

	[Property(Conditions)]
	protected FConditions as TPageConditions

	[Property(Switch1Set)]
	protected FSwitch1 as int

	[Property(Switch2Set)]
	protected FSwitch2 as int

	[Property(Variable1Set)]
	protected FVariable1 as int

	[Property(Variable2Set)]
	protected FVariable2 as int

	[Property(Variable1Op)]
	protected FVar1Op as TComparisonOp

	[Property(Variable2Op)]
	protected FVar2Op as TComparisonOp

	[Property(Variable1Value)]
	protected FVarValue1 as int

	[Property(Variable2Value)]
	protected FVarValue2 as int

	[Property(ItemNeeded)]
	protected FItem as int

	[Property(HeroNeeded)]
	protected FHero as int

	[Property(TimeRemaining)]
	protected FClock1 as int

	[Property(TimeRemaining2)]
	protected FClock2 as int

	[Property(Timer1Op)]
	protected FClock1Op as TComparisonOp

	[Property(Timer2Op)]
	protected FClock2Op as TComparisonOp

	[Property(Script)]
	protected FScript as string

	public Valid as bool:
		get: return FOnEval(self)

class TBattleEventConditions(TRpgEventConditions):

	[Getter(BattleConditions)]
	protected FBattleConditions as TBattlePageConditions

	[Getter(MonsterHP)]
	protected FMonsterHP as int

	[Getter(TurnsMultiple)]
	protected FTurnsMultiple as int

	[Getter(MonsterHPMax)]
	protected FMonsterHPMax as int

	[Getter(HeroCommandWhich)]
	protected FHeroCommandWhich as int

	[Getter(HeroHP)]
	protected FHeroHP as int

	[Getter(HeroHPMax)]
	protected FHeroHPMax as int

	[Getter(ExhaustionMax)]
	protected FExhaustionMax as int

	[Getter(MonsterTurnsMultiple)]
	protected FMonsterTurnsMultiple as int

	[Getter(HeroTurnsMultiple)]
	protected FHeroTurnsMultiple as int

	[Getter(MonsterHPMin)]
	protected FMonsterHPMin as int

	[Getter(HeroHPMin)]
	protected FHeroHPMin as int

	[Getter(ExhaustionMin)]
	protected FExhaustionMin as int

	[Getter(TurnsConst)]
	protected FTurnsConst as int

	[Getter(MonsterTurnsConst)]
	protected FMonsterTurnsConst as int

	[Getter(HeroTurnsConst)]
	protected FHeroTurnsConst as int

	[Getter(MonsterTurn)]
	protected FMonsterTurn as int

	[Getter(HeroCommandWho)]
	protected FHeroCommandWho as int

	[Getter(HeroTurn)]
	protected FHeroTurn as int

class TRpgEventPage(TRpgDatafile):

	protected FSpriteIndex as int

	[Property(Frame)]
	protected FFrame as int

	[Getter(BaseTransparent)]
	protected FTransparent as bool

	[Property(Direction)]
	protected FDirection as TDirections

	[Property(MoveType)]
	protected FMoveType as TMoveType

	[Property(MoveFrequency)]
	protected FMoveFrequency as byte

	[Property(Trigger)]
	protected FStartCondition as TStartCondition

	[Property(ZOrder)]
	protected FEventHeight as byte

	[Property(IsBarrier)]
	protected FNoOverlap as bool

	[Property(AnimType)]
	protected FAnimType as TAnimType

	[Property(MoveSpeed)]
	protected FMoveSpeed as byte

	[Property(Path)]
	protected FPath = Path()

	[Property(MoveIgnore)]
	protected FMoveIgnore as bool

	[Getter(ActionMatrix)]
	protected FMatrix as ushort

	protected FOverrideFile as string

	protected FOverrideTransparency as bool

	protected FOverrideIndex as int

	[Property(DoOverrideSprite)]
	protected FOverrideSprite as bool

	private def IsValid() as bool:
		return (FConditions() if assigned(FConditions) else true)

	private def HasScriptFunction() as bool:
		return FScript is not null

	private def GetTileGroup() as int:
		return -1 unless PageName.StartsWith('*')
		n = self.PageName
		return int.Parse(n[1:])

	private def GetTransparent() as bool:
		return (FOverrideTransparency if FOverrideSprite else FTransparent)

	private def GetBaseFilename() as string:
		return super.Name

	[Property(Conditions)]
	protected FConditions as Func[of bool]

	[Getter(Parent)]
	protected FParent as TRpgMapObject

	[Property(Script)]
	protected FScript as Action

	public def constructor(id as int):
		FId = id
		FMoveSpeed = 1

	public def constructor(value as JObject):
		super(value)
		value.CheckRead('SpriteIndex', FSpriteIndex)
		value.CheckRead('Frame', FFrame)
		value.CheckReadEnum('Direction', FDirection)
		value.CheckRead('Transparent', FTransparent)
		value.CheckReadEnum('MoveType', FMoveType)
		value.CheckRead('MoveFrequency', FMoveFrequency)
		value.CheckReadEnum('AnimType', FAnimType)
		value.CheckRead('MoveSpeed', FMoveSpeed)
		value.CheckRead('ZOrder', FEventHeight)
		value.CheckRead('IsBarrier', FNoOverlap)
		value.CheckReadEnum('Trigger', FStartCondition)
		value.Remove('Conditions') //worry about this later
		FConditions = {return false}
		value.CheckEmpty()

	public def constructor(value as JObject, id as int, globals as TURBU.DataReader.IGlobalScriptProvider):
		super()
		switch as int
		value.CheckRead('Switch', switch)
		FConditions = globals.GetConditions(switch)
		value.CheckReadEnum('Trigger', FStartCondition)
		FScript = globals.Value[id]
		value.CheckEmpty()

	internal def SetParent(value as TRpgMapObject):
		FParent = value

	public IsTile as bool:
		get: return self.Tilegroup != -1

	public def OverrideSprite(filename as string, transparent as bool, index as int):
		FOverrideSprite = true
		FOverrideFile = filename
		FOverrideTransparency = transparent
		FOverrideIndex = index

	public SpriteIndex as int:
		get: return (FOverrideIndex if FOverrideSprite else FSpriteIndex)
		set:
			if FOverrideSprite:
				FOverrideIndex = value
			else: FSpriteIndex = value

	public PageName as string:
		get: return (FOverrideFile if FOverrideSprite else super.Name)
		set:
			FOverrideSprite = false
			FName = value

	public BaseFilename as string:
		get: return GetBaseFilename()

	public Transparent as bool:
		get: return GetTransparent()
		set: FTransparent = value

	public HasScript as bool:
		get: return HasScriptFunction()

	public Valid as bool:
		get: return IsValid()

	public Tilegroup as int:
		get: return GetTileGroup()

class TRpgMapObject(TRpgDatafile, IRpgMapObject):

	[Property(Location)]
	private FLocation as TSgPoint

	[Property(Pages)]
	private FPages = TRpgObjectList[of TRpgEventPage]()

	private FCurrentlyPlaying as int

	[Getter(CurrentPage)]
	private FCurrentPage as TRpgEventPage

	[Getter(Updated)]
	private FPageChanged as bool

	[Property(Locked)]
	private FLocked as bool

	FPageUpdater as Func of int

	public event OnTurn as Action
	
	public event OnDoneTurn as Action of TDirections

	public def constructor():
		super()

	public def constructor(id as short):
		super()
		FId = id
		AddPage(TRpgEventPage(0))
		FCurrentPage = FPages[0]

	public def constructor(value as JObject, validPage as Func[of int, Func[of int]]):
		super(value)
		value.CheckRead('Location', FLocation)
		var pages = value['Pages'] cast JArray
		value.Remove('Pages')
		for p in pages.Cast[of JObject]():
			AddPage(TRpgEventPage(p))
		FCurrentPage = FPages[0]
		FPageUpdater = validPage(FId)
		value.CheckEmpty()

	public def constructor(value as JObject, globals as TURBU.DataReader.IGlobalScriptProvider):
		super(value)
		AddPage(TRpgEventPage(value, FId, globals))
		FCurrentPage = FPages[0]
		value.CheckEmpty()

	public def FaceHero():
		OnTurn()

	public def ResumeFacing():
		if self.FCurrentPage is not null:
			OnDoneTurn(FCurrentPage.Direction)

	internal def Initialize():
		for page in FPages:
			page.SetParent(self)
		UpdateCurrentPage()

	public def AddPage(value as TRpgEventPage):
		FPages.Add(value)

	public IsTile as bool:
		get: return (FCurrentPage.IsTile if assigned(FCurrentPage) else false)

	public def UpdateCurrentPage():
		current as TRpgEventPage
		if assigned(FPageUpdater):
			var pageID = FPageUpdater()
			current = (FPages[pageID - 1] if pageID > 0 else null)
		else:
			current = null
		FPageChanged = FCurrentPage != current
		if FPageChanged and assigned(current):
			current.DoOverrideSprite = false
		FCurrentPage = current

	public self[x as int] as TRpgEventPage:
		get: return FPages[x]

	public Playing as bool:
		get: return FCurrentlyPlaying > 0
		set:
			if value:
				++FCurrentlyPlaying
			else:
				FCurrentlyPlaying = Math.Max(FCurrentlyPlaying - 1, 0)
	
	public PageCount as int:
		get: return FPages.Count
