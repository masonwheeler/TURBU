namespace turbu.map.sprites

import commons
import charset.data
import timing
import turbu.pathing
import TURBU.MapObjects
import turbu.defs
import SG.defs
import sdl.sprite
import turbu.constants
import TURBU.RM2K
import turbu.script.engine
import Boo.Adt
import Boo.Lang.Compiler
import Pythia.Runtime
import tiles
import System
import turbu.RM2K.map.tiles
import turbu.RM2K.sprite.engine
import turbu.RM2K.map.locks
import turbu.RM2K.environment
import TURBU.Meta
import SDL2
import TURBU.RM2K.RPGScript

[Disposable(Destroy, true)]
class TMapSprite(TObject):
	
	private _random = Random()

	public class TMoveChange(TObject):

		[Getter(Path)]
		private FPath as Path

		[Getter(Frequency)]
		private FFrequency as int

		[Getter(Skip)]
		private FSkip as bool

		public def constructor(path as Path, frequency as int, skip as bool):
			FPath = path
			FFrequency = frequency
			FSkip = skip

	private FMoveQueue as Path

	private FMoveStep as Func[of TObject, bool]

	[Getter(MoveAssign, Protected: true)]
	private FMoveAssignment as Path

	private FMoveChange as TMoveChange

	private FDirLocked as bool

	private FMoveReversed as bool

	private FMoveOpen as bool

	private FFacing as TDirections

	private FJumping as bool

	protected FJumpAnimateOverride as bool

	private FLastJumpOp as int

	private FJumpTarget as TSgPoint

	private FJumpTime as int

	private FTransparencyFactor as byte

	private FInitialized as bool

	private FFlashColor as TSgColor

	private FFlashTimer as TRpgTimestamp

	private FFlashLength as int

	private def TryMove(where as TDirections) as bool:
		FMoveOpen = self.Move(where)
		return FMoveOpen or CanSkip

	private def TryMoveDiagonal(one as TDirections, two as TDirections) as bool:
		return self.MoveDiag(one, two) or CanSkip

	private def DirTowardsHero() as TDirections:
		var heroLoc = (GSpriteEngine.value.CurrentParty.Location if assigned(GSpriteEngine.value.CurrentParty) else sgPoint(0, 1000)))
		return towards(self.Location, heroLoc)

	private def CanJump(target as TSgPoint) as bool:
		FJumpTime = commons.round(MOVE_DELAY[FMoveRate] / 1.5)
		if PointInRect(target, SDL.SDL_Rect(0, 0, FEngine.Width, FEngine.Height)) \
				and (FSlipThrough or (FEngine cast T2kSpriteEngine).Passable(target.x, target.y)):
			result = true
			FJumpTarget = target
		else: result = false
		return result

	private def StartMoveTo(target as TSgPoint):
		FLocation = target
		lTarget as TSgPoint = target
		GSpriteEngine.value.NormalizePoint(lTarget.x, lTarget.y)
		SetTarget(lTarget * TILE_SIZE)
		if lTarget != target:
			caseOf FMoveDir:
				case TDirections.Up: --lTarget.y
				case TDirections.Right: --lTarget.x
				case TDirections.Down: ++lTarget.y
				case TDirections.Left: ++lTarget.x
			SetLocation(lTarget)
		FTarget.x -= WIDTH_BIAS
		assert not assigned(FMoveTime)
		FMoveTime = TRpgTimestamp(MOVE_DELAY[FMoveRate - 1])
		EnterTile()

	private def SetMoveOrder(value as Path):
		FMoveAssignment = value

	private def BeginJump(target as TSgPoint):
		self.LeaveTile()
		FJumpTarget = target
		FJumping = true
		FJumpAnimateOverride = true
		midpoint as TSgPoint = ((FJumpTarget - FLocation) * TILE_SIZE) / 2.0
		midpoint.y -= TILE_SIZE.y / 2
		SetTarget((FLocation * TILE_SIZE) + midpoint)
		FTarget.x -= WIDTH_BIAS
		if (not self.DirLocked) and (FLocation != FJumpTarget):
			self.Facing = towards(FLocation, FJumpTarget)
		FLocation = FJumpTarget
		assert not assigned(FMoveTime)
		GSpriteEngine.value.AddLocation(self.Location, self)
		FMoveTime = TRpgTimestamp(FJumpTime)

	private def EndJump():
		SetTarget(FLocation * TILE_SIZE)
		FTarget.x -= WIDTH_BIAS
		FJumping = false
		assert not assigned(FMoveTime)
		FMoveTime = TRpgTimestamp(FJumpTime)

	private def Get90Dir() as TDirections:
		if _random.Next(2) == 1:
			return (ord(self.Facing cast TDirections) + 1) % 4
		else:
			return (ord(self.Facing cast TDirections) + 3) % 4

	private def TryMovePreferredDirection(facing as TDirections) as bool:
		ninetyDegrees as TDirections
		return true if Move(facing)
		ninetyDegrees = Get90Dir()
		if Move(ninetyDegrees):
			result = true
		elif Move(opposite_facing(ninetyDegrees)):
			result = true
		elif Move(opposite_facing(facing)):
			result = true
		else: result = false
		FMoveOpen = result or CanSkip
		return result

	private def TryMoveTowardsHero() as bool:
		return TryMovePreferredDirection(DirTowardsHero())

	private def TryMoveAwayFromHero() as bool:
		return TryMovePreferredDirection(opposite_facing(DirTowardsHero()))

	private def MustFlash() as bool:
		return assigned(FFlashTimer) and (FFlashTimer.TimeRemaining > 0)

	private def GetFlashColor() as (single):
		result = array(single, 4)
		result[0] = FFlashColor.Rgba[1] / 255.0
		result[1] = FFlashColor.Rgba[2] / 255.0
		result[2] = FFlashColor.Rgba[3] / 255.0
		result[3] = (FFlashColor.Rgba[4] / 255.0) * ((FFlashTimer.TimeRemaining cast double) / (FFlashLength cast double))
		return result

	private def SetMovePause():
		frequency as int
		if FMoveFreq not in range(1, 9):
			raise Exception("Invalid move frequency: $FMoveFreq")
		if FMoveFreq < 8:
			frequency = 8 - FMoveFreq
			frequency = 2 ** frequency
			FPause = TRpgTimestamp(frequency * (BASE_MOVE_DELAY - 15) / 4)
		else: FPause = null

	private def OpChangeFacing(dir as TDirections):
		self.Facing = dir
		FMoveTime = TRpgTimestamp(100)
		FPause = TRpgTimestamp(MOVE_DELAY[FMoveRate - 1] / 3)

	private DirLocked as bool:
		get: return (self.HasPage and (FMapObj.CurrentPage.AnimType in range(TAnimType.FixedDir, TAnimType.SpinRight + 1))) or FDirLocked
		set: FDirLocked = value

	[Property(OnChangeSprite)]
	protected FChangeSprite as Action[of string, bool, int]

	protected FLocation as TSgPoint

	protected FTarget as TSgPoint

	protected FMoveDir as TDirections

	protected FTiles = array(TEventTile, 2)

	[DisposeParent]
	protected FEngine as TSpriteEngine

	[Property(MoveRate)]
	protected FMoveRate as byte

	[Property(MoveFreq)]
	protected FMoveFreq as byte

	protected FSlipThrough as bool

	protected FAnimFix as bool

	[Getter(Event)]
	protected FMapObj as TRpgMapObject

	protected FVisible as bool

	protected FPause as TRpgTimestamp

	protected FMoveTime as TRpgTimestamp

	protected FCanSkip as bool

	protected FUnderConstruction as bool

	protected def EnterTile():
		lock GEventLock:
			GSpriteEngine.value.AddLocation(self.Location, self)

	protected virtual def SetFacing(Data as TDirections):
		if FUnderConstruction or not (self.HasPage and (FMapObj.CurrentPage.AnimType in range(TAnimType.FixedDir, TAnimType.Statue + 1))):
			FFacing = Data
		FMoveDir = Data

	protected def SetVisible(value as bool):
		FVisible = value
		FTiles[1].Visible = value if FTiles[1] != null
		FTiles[0].Visible = value if FTiles[0] != null

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetBaseTile() as TSprite:
		return FTiles[0]

	protected virtual def SetLocation(value as TSgPoint):
		FLocation = value
		SetTarget(value * TILE_SIZE)
		FTarget.x -= WIDTH_BIAS

	protected virtual def CanMoveForward() as bool:
		return (FEngine cast T2kSpriteEngine).CanExit(FLocation.x, FLocation.y, FMoveDir, self)

	protected def CanMoveDiagonal(one as TDirections, two as TDirections, ref destination as TSgPoint) as bool:
		temp as TDirections
		assert ord(one) % 2 == 0 and ord(two) % 2 == 1
		temp = FFacing
		FFacing = one
		result = FSlipThrough or (FEngine cast T2kSpriteEngine).CanExit(FLocation.x, FLocation.y, one, self)
		unless result:
			FFacing = two
			result = (FEngine cast T2kSpriteEngine).CanExit(FLocation.x, FLocation.y, two, self)
		FFacing = temp
		return false unless result
		destination = FLocation
		if one == TDirections.Up:
			--destination.y
		else: ++destination.y
		if two == TDirections.Left:
			--destination.x
		else: ++destination.x
		return PointInRect(destination, SDL.SDL_Rect(0, 0, FEngine.Width, FEngine.Height)) and CurrentTile().Open(self)

	public def Up():
		return TryMove(TDirections.Up)

	public def Right():
		return TryMove(TDirections.Right)

	public def Down():
		return TryMove(TDirections.Down)

	public def Left():
		return TryMove(TDirections.Left)

	public def UpRight():
		return TryMoveDiagonal(TDirections.Up, TDirections.Right)

	public def DownRight():
		return TryMoveDiagonal(TDirections.Down, TDirections.Right)

	public def DownLeft():
		return TryMoveDiagonal(TDirections.Down, TDirections.Left)

	public def UpLeft():
		return TryMoveDiagonal(TDirections.Up, TDirections.Left)

	public def RandomStep():
		return TryMove(_random.Next(4) cast TDirections)

	public def TowardsHero():
		return (self == GSpriteEngine.value.CurrentParty) or TryMoveTowardsHero()

	public def AwayFromHero():
		return (self == GSpriteEngine.value.CurrentParty) or TryMoveAwayFromHero()

	public def MoveForward():
		return TryMove(FFacing)

	public def FaceUp():
		OpChangeFacing(TDirections.Up)
		return true

	public def FaceRight():
		OpChangeFacing(TDirections.Right)
		return true

	public def FaceDown():
		OpChangeFacing(TDirections.Down)
		return true

	public def FaceLeft():
		OpChangeFacing(TDirections.Left)
		return true

	public def FaceHero():
		OpChangeFacing(DirTowardsHero())
		return true

	public def FaceAwayFromHero():
		OpChangeFacing(opposite_facing(DirTowardsHero()))
		return true

	public def TurnRight():
		OpChangeFacing((ord(self.Facing) + 1) % 4)
		return true

	public def TurnLeft():
		OpChangeFacing((ord(self.Facing) + 3) % 4)
		return true

	public def Turn90():
		OpChangeFacing(Get90Dir())
		return true

	public def Turn180():
		OpChangeFacing(opposite_facing(self.Facing))
		return true

	public def Pause():
		assert FPause is null
		FPause = TRpgTimestamp(300)
		return true

	public def Jump(x as int, y as int) as bool:
		var target = self.Location + sgPoint(x, y)
		if CanJump(target):
			BeginJump(target)
			return true
		else: return false

	public def Jump(x as int, y as int, random as int, chase as int, forward as int) as bool:
		raise "Not implemented yet"

	public def SpeedUp():
		FMoveRate = Math.Min(6, FMoveRate + 1)
		return true

	public def SpeedDown():
		FMoveRate = Math.Max(1, FMoveRate - 1)
		return true

	public def ClipOff():
		FSlipThrough = true
		return true

	public def ClipOn():
		FSlipThrough = false
		return true

	public def FacingFixed():
		FDirLocked = true
		return true

	public def FacingFree():
		FDirLocked = false
		return true

	public def ChangeSprite(name as string, spriteIndex as int):
		FChangeSprite(name, false, spriteIndex)
		return true

	public def AnimStop():
		self.AnimFix = true
		return true

	public def AnimResume():
		self.AnimFix = false
		return true

	public def PlaySfx(name as string, volume as int, tempo as int, balance as int):
		PlaySound(name, volume, tempo, balance)
		return true

	public def SwitchOn(value as int):
		GEnvironment.value.Switch[value] = true
		return true

	public def SwitchOff(value as int):
		GEnvironment.value.Switch[value] = false
		return true

	public def TransparencyUp():
		self.Translucency = Math.Min(FTransparencyFactor + 1, MAX_TRANSPARENCY)
		return true

	public def TransparencyDown():
		self.Translucency = Math.Max(FTransparencyFactor - 1, 0)
		return true

	public def FreqUp():
		FMoveFreq = Math.Min(8, FMoveFreq + 1)
		return true

	public def FreqDown():
		FMoveFreq = Math.Max(0, FMoveFreq - 1)
		return true

	protected virtual def DoMove(which as Path) as bool:
		unless assigned(FMoveStep):
			FMoveStep = which.NextCommand()
		FMoveOpen = true
		result = (FMoveStep(self) if assigned(FMoveStep) else false)
		if result:
			FMoveStep = null
/*
		result = true
		unchanged as bool = false
		if FOrder.Opcode == OP_CLEAR:
			FOrder = which.NextCommand()
		caseOf FOrder.Opcode:
			case 26: self.DirLocked = true
			case 27: self.DirLocked = false
			case 41: DecTransparencyFactor()
			case 48: result = false
			default : assert false
		if FOrder.Opcode in range(12, 23):
			FPause = TRpgTimestamp(MOVE_DELAY[FMoveRate] / 3)
		FOrder.Opcode = OP_CLEAR unless unchanged
		if (not FMoveOpen) and (FOrder.Opcode != 23) and (self.InFrontTile != null):
			(self.InFrontTile).Bump(self)
*/
		return result

	protected virtual def GetCanSkip() as bool:
		return FCanSkip

	protected virtual def SetTranslucency(value as byte):
		FTransparencyFactor = clamp(value, 0, MAX_TRANSPARENCY)
		FTiles[0].Alpha = (((MAX_TRANSPARENCY + 1) - FTransparencyFactor) * TRANSPARENCY_STEP) cast int

	protected def SetFlashEvents(tile as TEventTile):
		tile.OnMustFlash = self.MustFlash
		tile.OnFlashColor = self.GetFlashColor

	protected def MakeSingleStepPath(dir as TDirections) as Path:
		step as Func of bool
		caseOf dir:
			case TDirections.Up: step = self.Up
			case TDirections.Down: step = self.Down
			case TDirections.Left: step = self.Left
			case TDirections.Right: step = self.Right
			default: raise "Unknown path direction: $dir"
		return Path(true) do(p as Path) as Func[of TObject, bool]*:
			yield {m | return step()}

	protected def MakeLoopingPath(step as Func of bool):
		def steps(p as Path):
			while true:
				yield step
				p.Looped = true
		
		return Path(false, steps)

	private def MakeRandomPath():
		return MakeLoopingPath({return self.RandomStep()})

	private def MakeChasePath():
		return MakeLoopingPath({return self.TowardsHero()})

	private def MakeFleePath():
		return MakeLoopingPath({return self.AwayFromHero()})

	protected def UpdateMove(Data as TRpgEventPage):
		FMoveRate = Data.MoveSpeed
		FMoveFreq = Data.MoveFrequency
		FCanSkip = true
		caseOf Data.MoveType:
			case TMoveType.Still, TMoveType.CycleUD, TMoveType.CycleLR: MoveQueue = null
			case TMoveType.RandomMove: MoveQueue = MakeRandomPath()
			case TMoveType.ChaseHero: MoveQueue = MakeChasePath()
			case TMoveType.FleeHero: MoveQueue = MakeFleePath()
			case TMoveType.ByRoute:
				assert assigned(Data.Path)
				MoveQueue = Path(Data.Path)
				FCanSkip = Data.MoveIgnore
			default : assert false
		FMoveTime = null if Data.AnimType in (TAnimType.Sentry, TAnimType.FixedDir)

	protected abstract def DoUpdatePage(Data as TRpgEventPage):
		pass

	protected virtual def Bump(bumper as TMapSprite):
		pass

	protected virtual def SetTarget(value as TSgPoint):
		FTarget = value

	protected AnimFix as bool:
		get: return FAnimFix or (self.HasPage and (FMapObj.CurrentPage.AnimType == TAnimType.Statue))
		set: FAnimFix = value

	protected MoveQueue as Path:
		get: return FMoveQueue
		set: FMoveQueue = value

	[NoImport]
	public def constructor(base as TRpgMapObject, parent as TSpriteEngine):
		FMapObj = base
		FEngine = parent cast T2kSpriteEngine
		FMoveRate = 4
		UpdateMove(FMapObj.CurrentPage) if self.HasPage

	private def Destroy():
		FTiles[0].Dead() if assigned(FTiles[0])
		FTiles[1].Dead() if assigned(FTiles[1])
		(FEngine cast T2kSpriteEngine).LeaveLocation(FLocation, self)

	override def ToString():
		var result = self.ClassName
		if assigned(FMapObj):
			return "$result $(FMapObj.ID): $(FMapObj.Name)"
		return result

	public virtual def Move(whichDir as TDirections) as bool:
		target as TSgPoint
		result = false
		return result if assigned(FMoveTime) or assigned(FPause)
		if self.DirLocked:
			FMoveDir = whichDir
		else: Facing = whichDir
		if FSlipThrough or self.CanMoveForward():
			self.LeaveTile()
			target = sgPoint(FLocation.x, FLocation.y)
			caseOf FMoveDir:
				case TDirections.Up: --target.y
				case TDirections.Right: ++target.x
				case TDirections.Down: ++target.y
				case TDirections.Left: --target.x
			if FSlipThrough:
				return false unless GSpriteEngine.value.NormalizePoint(target.x, target.y)
			StartMoveTo(target)
			result = true
		unless result:
			if self.InFrontTile is not null:
				(self.InFrontTile).Bump(self)
		return result

	public def MoveDiag(one as TDirections, two as TDirections) as bool:
		destination as TSgPoint
		var result = false
		return result if assigned(FMoveTime) and assigned(FPause)
		if (not self.DirLocked) and Facing not in (one, two):
			Facing = two
		if self.CanMoveDiagonal(one, two, destination):
			self.LeaveTile()
			self.StartMoveTo(destination)
			result = true
		return result

	public def LeaveTile():
		lock GEventLock:
			GSpriteEngine.value.LeaveLocation(self.Location, self)

	public virtual def Place():
		if (FInitialized and not assigned(FMoveTime)) or \
			(FInitialized and not (assigned(FMoveQueue) or assigned(FMoveAssignment)) and \
				assigned(FMapObj) and (FMapObj.CurrentPage.MoveType == TMoveType.Still)):
			return
		if assigned(FMoveTime):
			timeRemaining as int = FMoveTime.TimeRemaining
			lX as single = FTiles[0].X
			MoveTowards(timeRemaining, lX, FTarget.x)
			FTiles[0].X = lX
			lY = FTiles[0].Y
			MoveTowards(timeRemaining, lY, FTarget.y)
			FTiles[0].Y = lY
			FTiles[0].UpdateGridLoc()
			if timeRemaining <= TRpgTimestamp.FrameLength:
				FMoveTime = null
				if FJumping:
					EndJump()
				else:
					SetMovePause()
					FJumpAnimateOverride = false
				CurrentTile().Bump(self)
		unless FInitialized:
			EnterTile()
			FInitialized = true

	public def UpdatePage(Data as TRpgEventPage):
		DoUpdatePage(Data)

	public InFront as TSgPoint:
		get:
			caseOf FFacing:
				case TDirections.Up: result = sgPoint(FLocation.x, FLocation.y - 1)
				case TDirections.Right: result = sgPoint(FLocation.x + 1, FLocation.y)
				case TDirections.Down: result = sgPoint(FLocation.x, FLocation.y + 1)
				case TDirections.Left: result = sgPoint(FLocation.x - 1, FLocation.y)
			return result

	public InFrontTile as TMapTile:
		get:
			inFront as TSgPoint = self.InFront
			return (FEngine cast T2kSpriteEngine).GetTile(inFront.x, inFront.y, 0)

	public HasPage as bool:
		get: return assigned(FMapObj) and assigned(FMapObj.CurrentPage)

	public def Flash(r as byte, g as byte, b as byte, power as byte, time as uint):
		if time == 0:
			FFlashTimer = null
			return
		FFlashColor.Rgba[1] = r
		FFlashColor.Rgba[2] = g
		FFlashColor.Rgba[3] = b
		FFlashColor.Rgba[4] = power
		time = time * 100
		FFlashTimer = TRpgTimestamp(time)
		FFlashLength = time

	public virtual def MoveTick(moveBlocked as bool):
		return if assigned(FMoveTime)
		if assigned(FPause):
			return if FPause.TimeRemaining > 0
			FPause = null
		canMove as bool = not (moveBlocked or FMapObj?.Playing)
		if assigned(FMoveAssignment):
			FMoveAssignment = null unless DoMove(FMoveAssignment)
		elif assigned(FMoveQueue) and canMove:
			FMoveQueue = null unless DoMove(FMoveQueue)
		elif canMove and self.HasPage:
			caseOf FMapObj.CurrentPage.MoveType:
				case TMoveType.CycleUD:
					FMoveOpen = (self.Move(TDirections.Up) if FMoveReversed else self.Move(TDirections.Down))
				case TMoveType.CycleLR:
					FMoveOpen = (self.Move(TDirections.Right) if FMoveReversed else self.Move(TDirections.Left))
				default:
					pass
		if self.HasPage and (FMapObj.CurrentPage.MoveType in (TMoveType.CycleUD, TMoveType.CycleLR)) and not FMoveOpen:
			FMoveReversed = not FMoveReversed
			(self.InFrontTile).Bump(self) if self.InFrontTile is not null

	public abstract def Update(filename as string, transparent as bool, spriteIndex as int):
		pass

	public def Stop():
		if assigned(FMoveAssignment):
			if assigned(FMoveTime):
				FMoveTime = null
			elif assigned(FPause):
				FPause = null
			FMoveAssignment = null

	public def CopyDrawState(base as TMapSprite):
		if assigned(base.FFlashTimer):
			FFlashTimer = TRpgTimestamp(base.FFlashTimer.TimeRemaining)
			FFlashColor = base.FFlashColor
			FFlashLength = base.FFlashLength
		FMoveQueue = base.FMoveQueue.Clone() if assigned(base.FMoveQueue)
		if assigned(base.FMoveAssignment):
			FMoveAssignment = base.FMoveAssignment.Clone()
			FMoveFreq = base.FMoveFreq
		FMoveReversed = base.FMoveReversed
		FMoveOpen = base.FMoveOpen
		FMoveDir = base.FMoveDir
		FTransparencyFactor = base.FTransparencyFactor
		self.Facing = base.Facing if base isa TCharSprite
		self.Location = base.Location

	public def MoveChange(path as Path, frequency as int, skip as bool):
		lock self:
			FMoveChange = TMoveChange(path, frequency, skip)

	public def CheckMoveChange():
		lock self:
			if assigned(FMoveChange):
				SetMoveOrder(FMoveChange.Path)
				self.CanSkip = FMoveChange.Skip
				self.MoveFreq = FMoveChange.Frequency
				FMoveChange = null

	public Location as TSgPoint:
		get: return FLocation
		set: SetLocation(value)

	public BaseTile as TSprite:
		get: return GetBaseTile()

	public Visible as bool:
		get: return FVisible
		set: SetVisible(value)

	public Facing as TDirections:
		get: return FFacing
		set: SetFacing(value)

	public MoveOrder as Path:
		get: return FMoveAssignment
		set: SetMoveOrder(value)

	public CanSkip as bool:
		get: return GetCanSkip()
		set: FCanSkip = value

	public Translucency as byte:
		get: return FTransparencyFactor
		set: SetTranslucency(value)

	public Tiles[x as byte] as TTile:
		get: return FTiles[x]

class TEventSprite(TMapSprite):

	protected override def SetLocation(value as TSgPoint):
		super.SetLocation(value)
		FTiles[0].X = Location.x * TILE_SIZE.x
		FTiles[0].Y = Location.y * TILE_SIZE.y

	protected override def DoUpdatePage(Data as TRpgEventPage):
		FTiles[0].Update(Data)
		UpdateMove(Data)

	public def constructor(base as TRpgMapObject, parent as TSpriteEngine):
		super(base, parent)
		FTiles[0] = TEventTile(Event, parent)
		FTiles[1] = null
		self.Translucency = (3 if assigned(FMapObj.CurrentPage) and FMapObj.CurrentPage.Transparent else 0)
		SetLocation(sgPoint(base.Location.x, base.Location.y))
		self.SetFlashEvents(FTiles[0])

	public override def Update(filename as string, transparent as bool, spriteIndex as int):
		self.Translucency = (3 if transparent else 0)
		assert false

class TCharSprite(TMapSprite):

	[Getter(Frame)]
	private FWhichFrame as short

	private FAnimTimer as TRpgTimestamp

	private def LoadCharset(filename as string):
		commons.runThreadsafe(true, { FEngine.Images.EnsureImage(("Sprites\\$filename.png"), filename, SPRITE_SIZE) })

	private def UpdateFrame():
		ANIM_DELAY = (208, 125, 104, 78, 57, 42)
		TIME_FACTOR = 7
		newFrame as int
		moveDelay as int
		return if FJumpAnimateOverride or self.AnimFix or FAnimTimer.TimeRemaining > 0
		++FWhichFrame
		if FWhichFrame >= FOOTSTEP_CONSTANT[FMoveRate - 1]:
			FWhichFrame = 0
			newFrame = (FMoveFrame + 1) % FActionMatrix[FAction].Length
		else: newFrame = FMoveFrame
		moveDelay = ANIM_DELAY[FMoveRate - 1]
		if HasPage:
			caseOf FMapObj.CurrentPage.AnimType:
				case TAnimType.Sentry, TAnimType.FixedDir: FMoveFrame = (newFrame if assigned(FMoveTime) else 1)
				case TAnimType.Jogger, TAnimType.FixedJog: FMoveFrame = newFrame
				case TAnimType.SpinRight:
					self.Facing = (ord(self.Facing) + 1) % 4
					moveDelay = moveDelay * 10
				case TAnimType.Statue:
					pass
		elif not assigned(FMoveTime) and not assigned(MoveQueue) \
     			and not (assigned(MoveAssign) and (FTarget != FLocation * TILE_SIZE)):
			FMoveFrame = 1
		else: FMoveFrame = newFrame
		FAnimTimer = TRpgTimestamp(moveDelay / TIME_FACTOR)

	protected FMoved as bool

	protected FActionMatrix as ((int))

	protected FAction as int

	protected FMoveFrame as int

	[Property(SpriteIndes)]
	private FSpriteIndex as int

	protected override def SetFacing(Data as TDirections):
		super.SetFacing(Data)
		FAction = ord(Facing)
		UpdateTiles()

	protected def UpdateTiles():
		var l = GDatabase.value.Layout
		var start = (l.SpriteSheetFrames.x * (FSpriteIndex % l.SpriteSheet.x)) + (l.SpriteSheetRow * (FSpriteIndex / l.SpriteSheet.x))
		frame as int = FActionMatrix[FAction][FMoveFrame]
		frame = (l.SpriteRow * 2 * (frame / l.SpriteSheetFrames.x)) + (frame % l.SpriteSheetFrames.x)
		frame += start
		FTiles[0].ImageIndex = frame + l.SpriteRow
		FTiles[1].ImageIndex = frame

	protected override def SetLocation(Data as TSgPoint):
		super.SetLocation(Data)
		FTiles[0].X = (Location.x * TILE_SIZE.x) - 4
		FTiles[0].Y = Location.y * TILE_SIZE.y
		FTiles[1].X = (Location.x * TILE_SIZE.x) - 4
		FTiles[1].Y = (Location.y - 1) * TILE_SIZE.y

	protected override def SetTranslucency(value as byte):
		super.SetTranslucency(value)
		FTiles[1].Alpha = FTiles[0].Alpha

	protected def ActivateEvents(where as TMapTile):
		eventList as TMapSprite* = where.Event
		for sprite in eventList:
			continue if sprite == self
			mapObj as TRpgMapObject = sprite.Event
			if mapObj == null:
				sprite.Bump(self)
			elif (mapObj.CurrentPage?.HasScript) and (mapObj.CurrentPage.Trigger == TStartCondition.Key):
				GMapObjectManager.value.RunPageScript(mapObj.CurrentPage)

	protected override def DoUpdatePage(Data as TRpgEventPage):
		FTiles[0].Update(Data)
		FTiles[1].Update(Data)
		if assigned(Data):
			FUnderConstruction = true
			self.Facing = Data.Direction
			FMoveFrame = Data.Frame
			UpdateMove(Data)
			FUnderConstruction = false
			Update(Data.PageName, Translucency >= 3, Data.SpriteIndex)
			FTiles[1].Z = FTiles[0].Z + 1
		self.Visible = assigned(Data)

	public def constructor(base as TRpgMapObject, parent as TSpriteEngine):
		super(base, parent)
		FUnderConstruction = true
		FWhichFrame = -1
		FTiles[0] = TEventTile(base, parent)
		FTiles[1] = TEventTile(base, parent)
		if assigned(base?.CurrentPage):
			Translucency = 3 if base.CurrentPage.Transparent
			FActionMatrix = GDatabase.value.MoveMatrix[FMapObj.CurrentPage.ActionMatrix]
			FSpriteIndex = base.CurrentPage.SpriteIndex
			self.Facing = base.CurrentPage.Direction
			UpdatePage(base.CurrentPage)
			FTiles[1].Z = FTiles[0].Z + 1
		else: FActionMatrix = GDatabase.value.MoveMatrix[0]
		if assigned(base):
			SetLocation(sgPoint(base.Location.x, base.Location.y))
		FUnderConstruction = false
		self.SetFlashEvents(FTiles[0])
		self.SetFlashEvents(FTiles[1])
		FAnimTimer = TRpgTimestamp(0)

	public def Reload(imageName as string, index as byte):
		FTiles[0].Name = imageName + index.ToString()
		FTiles[1].Name = imageName + index.ToString()
		self.Facing = TFacing.Down
		FMoveFrame = 0

	public def Assign(Data as TCharSprite):
		self.Facing = Data.Facing
		FLocation = Data.Location

	public override def Place():
		FMoved = (FMoveFrame > 0) and (FWhichFrame == (FMoveRate - 1))
		super.Place()
		UpdateFrame()
		FTiles[1].Y = FTiles[0].Y - TILE_SIZE.y
		FTiles[1].X = FTiles[0].X
		FTiles[1].UpdateGridLoc()

	public override def Update(filename as string, transparent as bool, spriteIndex as int):
		LoadCharset(filename) if filename != ''
		FTiles[1].ImageName = filename
		FTiles[0].ImageName = filename
		self.Translucency = (3 if transparent else 0)
		FSpriteIndex = spriteIndex
		UpdateTiles()

	public virtual def Action(Button as TButtonCode):
		raise ESpriteError('Non-player sprites can\'t receive an Action.')

	public override def MoveTick(moveBlocked as bool):
		super.MoveTick(moveBlocked)
		UpdateTiles()

[Extension]
public def CurrentTile(tms as TMapSprite) as TMapTile:
	engine = tms.BaseTile.Engine cast T2kSpriteEngine
	location = tms.Location
	return engine.Tiles[0, location.x, location.y]

let BASE_MOVE_DELAY = 133
let MOVE_DELAY = (1064, 532, 266, 133, 67, 33)
let WIDTH_BIAS = 4
let FOOTSTEP_CONSTANT = (11, 10, 8, 6, 5, 5) //yay for fudge factors!
let MAX_TRANSPARENCY = 7
let TRANSPARENCY_STEP = 255.0 / (MAX_TRANSPARENCY + 1)
