namespace turbu.map.sprites

import commons
import charset.data
import timing
import TURBU.Timing
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

	private class MoveChangeData:

		[Getter(Path)]
		private final _path as Path

		[Getter(Frequency)]
		private final _frequency as int

		[Getter(Skip)]
		private final _skip as bool

		public def constructor(path as Path, frequency as int, skip as bool):
			_path = path
			_frequency = frequency
			_skip = skip

	private FMoveQueue as Path

	private FMoveStep as Func[of TObject, bool]

	[Getter(MoveAssign, Protected: true)]
	private FMoveAssignment as Path

	private FMoveChange as MoveChangeData

	private FDirLocked as bool

	private FMoveReversed as bool

	private FMoveOpen as bool

	private FFacing as TDirections

	private FJumping as bool

	protected FJumpAnimateOverride as bool

	private FLastJumpOp as int

	private FJumpTarget as SgPoint

	private _moveStart as long

	private _moveTicks as int

	private _moveFromX as single

	private _moveFromY as single

	private _interpDX as single

	private _interpDY as single

	private FTransparencyFactor as byte

	private FInitialized as bool

	private FFlashColor as TSgColor

	private FFlashTimer as Timestamp

	private FFlashLength as int

	protected FForceTurn as bool

	protected static def PointInRect(thePoint as SgPoint, theRect as SDL2.SDL.SDL_Rect) as bool:
		return IsBetween(thePoint.x, theRect.x, theRect.x + theRect.w) and \
				IsBetween(thePoint.y, theRect.y, theRect.y + theRect.h)

	private def TryMove(where as TDirections) as bool:
		FMoveOpen = self.Move(where)
		return FMoveOpen or CanSkip

	private def TryMoveDiagonal(one as TDirections, two as TDirections) as bool:
		return self.MoveDiag(one, two) or CanSkip

	protected def DirTowardsHero() as TDirections:
		var heroLoc = (GSpriteEngine.value.CurrentParty.Location if GSpriteEngine.value.CurrentParty is not null else SgPoint(0, 1000))
		return towards(self.Location, heroLoc)

	private def CanJump(target as SgPoint) as bool:
		if PointInRect(target, SDL.SDL_Rect(0, 0, FEngine.Width, FEngine.Height)) \
				and (FSlipThrough or (FEngine cast T2kSpriteEngine).Passable(target.x, target.y)):
			result = true
			FJumpTarget = target
		else: result = false
		return result

	private def StartMoveTo(target as SgPoint):
		var start = FLocation
		FLocation = target
		lTarget as SgPoint = target
		GSpriteEngine.value.NormalizePoint(lTarget.x, lTarget.y)
		// A step across the edge of a wraparound map: the sprite starts from the equivalent point
		// one map width away, so that it walks one tile like any other step instead of crossing
		// the whole map.
		var dx = lTarget.x - start.x
		var dy = lTarget.y - start.y
		dx = -Math.Sign(dx) if Math.Abs(dx) > 1
		dy = -Math.Sign(dy) if Math.Abs(dy) > 1
		if (lTarget.x - start.x != dx) or (lTarget.y - start.y != dy):
			SetLocation(SgPoint(lTarget.x - dx, lTarget.y - dy))
			FLocation = lTarget
		SetTarget(lTarget * TILE_SIZE)
		FTarget.x -= WIDTH_BIAS
		assert _moveTime is null
		BeginMoveTimer(WALK_TICKS[FMoveRate])
		EnterTile()

	private def SetMoveOrder(value as Path):
		FMoveAssignment = value
		FMoveStep = null

	private def BeginJump(target as SgPoint):
		self.LeaveTile()
		FJumpTarget = target
		FJumping = true
		FJumpAnimateOverride = true
		SetTarget(FJumpTarget * TILE_SIZE)
		FTarget.x -= WIDTH_BIAS
		if (not self.DirLocked) and (FLocation != FJumpTarget):
			self.Facing = towards(FLocation, FJumpTarget)
		FLocation = FJumpTarget
		assert _moveTime is null
		GSpriteEngine.value.AddLocation(self.Location, self)
		BeginMoveTimer(JUMP_TICKS[FMoveRate])

	private def BeginMoveTimer(ticks as int):
		_moveTicks = Math.Max(ticks, 1)
		_moveStart = GameClock.Ticks
		_moveFromX = FTiles[0].X
		_moveFromY = FTiles[0].Y
		_moveTime = Timestamp.FromTicks(_moveTicks)

	private def CancelMove():
		_moveTime = null
		FJumping = false
		SnapToTarget()

	private def SnapToTarget():
		for tile in FTiles:
			if tile is not null:
				tile.X = FTarget.x
		FTiles[0].Y = FTarget.y
		FTiles[1].Y = FTarget.y - TILE_SIZE.y if FTiles[1] is not null
		FTiles[0].UpdateGridLoc()
		FTiles[1].UpdateGridLoc() if FTiles[1] is not null

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
		return FFlashTimer is not null and FFlashTimer.TimeRemaining > 0

	private def GetFlashColor() as (single):
		result = array(single, 4)
		result[0] = FFlashColor.Rgba[1] / 255.0
		result[1] = FFlashColor.Rgba[2] / 255.0
		result[2] = FFlashColor.Rgba[3] / 255.0
		result[3] = (FFlashColor.Rgba[4] / 255.0) * ((FFlashTimer.TimeRemaining cast double) / (FFlashLength cast double))
		return result

	private def SetMovePause():
		if FMoveFreq not in range(1, 9):
			raise Exception("Invalid move frequency: $FMoveFreq")
		if FMoveFreq < 8:
			FPause = Timestamp.FromTicks(1 << (9 - FMoveFreq))
		else: FPause = null

	private def OpChangeFacing(dir as TDirections):
		preserving FForceTurn:
			FForceTurn = true
			self.Facing = dir
		FPause = Timestamp(MOVE_DELAY[FMoveRate - 1] / 3)

	protected def TurnChangeFacing(dir as TDirections):
		self.Facing = dir

	private DirLocked as bool:
		get: return (self.HasPage and (FMapObj.CurrentPage.AnimType in range(TAnimType.FixedDir, TAnimType.SpinRight + 1))) or FDirLocked
		set: FDirLocked = value

	[Property(OnChangeSprite)]
	protected FChangeSprite as Action[of string, bool, int]

	protected FLocation as SgPoint

	protected FTarget as SgPoint

	protected FMoveDir as TDirections

	protected FTiles = array(EventTile, 2)

	[DisposeParent]
	protected FEngine as SpriteEngine

	[Property(MoveRate)]
	protected FMoveRate as byte

	[Property(MoveFreq)]
	protected FMoveFreq as byte

	[Getter(SlipThrough)]
	protected FSlipThrough as bool

	protected FAnimFix as bool

	[Getter(Event)]
	protected FMapObj as TRpgMapObject

	protected FVisible as bool

	protected FPause as Timestamp

	protected _moveTime as Timestamp

	private _wrapped as SgPoint?

	protected FCanSkip as bool

	protected FUnderConstruction as bool

	protected def EnterTile():
		lock GEventLock:
			GSpriteEngine.value.AddLocation(self.Location, self)

	protected virtual def SetFacing(Data as TDirections):
		if FUnderConstruction or FForceTurn or \
				not (self.HasPage and (FMapObj.CurrentPage.AnimType in range(TAnimType.FixedDir, TAnimType.Statue + 1))):
			FFacing = Data
		FMoveDir = Data

	protected def SetVisible(value as bool):
		FVisible = value
		FTiles[1].Visible = value if FTiles[1] != null
		FTiles[0].Visible = value if FTiles[0] != null

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetBaseTile() as TSprite:
		return FTiles[0]

	protected virtual def SetLocation(value as SgPoint):
		FLocation = value
		SetTarget(value * TILE_SIZE)
		FTarget.x -= WIDTH_BIAS

	protected virtual def CanMoveForward() as bool:
		return (FEngine cast T2kSpriteEngine).CanExit(FLocation.x, FLocation.y, FMoveDir, self)

	protected def CanMoveDiagonal(one as TDirections, two as TDirections, ref destination as SgPoint) as bool:
		assert ord(one) % 2 == 0 and ord(two) % 2 == 1
		var temp = FFacing
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
		FPause = Timestamp(300)
		return true

	public def Jump(x as int, y as int) as bool:
		var target = self.Location + SgPoint(x, y)
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
		if FMoveStep is null:
			FMoveStep = which.NextCommand()
		FMoveOpen = true
		result = (FMoveStep(self) if FMoveStep is not null else false)
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
			FPause = Timestamp(MOVE_DELAY[FMoveRate] / 3)
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

	protected def SetFlashEvents(tile as EventTile):
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
			yield {m as TObject | return step()}

	protected def MakeLoopingPath(step as Func[of TObject, bool]):
		return Path(false) do(p as Path) as Func[of TObject, bool]*:
			while true:
				yield step
				p.Looped = true

	private def MakeRandomPath():
		return MakeLoopingPath({m as TObject| return (m cast TMapSprite).RandomStep()})

	private def MakeChasePath():
		return MakeLoopingPath({m as TObject| return (m cast TMapSprite).TowardsHero()})

	private def MakeFleePath():
		return MakeLoopingPath({m as TObject| return (m cast TMapSprite).AwayFromHero()})

	protected def UpdateMove(data as TRpgEventPage):
		FMoveRate = data.MoveSpeed
		FMoveFreq = data.MoveFrequency
		FCanSkip = true
		caseOf data.MoveType:
			case TMoveType.Still, TMoveType.CycleUD, TMoveType.CycleLR: MoveQueue = null
			case TMoveType.RandomMove: MoveQueue = MakeRandomPath()
			case TMoveType.ChaseHero: MoveQueue = MakeChasePath()
			case TMoveType.FleeHero: MoveQueue = MakeFleePath()
			case TMoveType.ByRoute:
				assert data.Path is not null
				MoveQueue = Path(data.Path)
				FCanSkip = data.Path.Skip
			default : assert false
		CancelMove() if _moveTime is not null and data.AnimType in (TAnimType.Sentry, TAnimType.FixedDir)

	protected abstract def DoUpdatePage(Data as TRpgEventPage):
		pass

	protected virtual def Bump(bumper as TMapSprite):
		pass

	protected virtual def SetTarget(value as SgPoint):
		FTarget = value

	protected AnimFix as bool:
		get: return FAnimFix or (self.HasPage and (FMapObj.CurrentPage.AnimType == TAnimType.Statue))
		set: FAnimFix = value

	protected MoveQueue as Path:
		get: return FMoveQueue
		set: FMoveQueue = value

	[NoImport]
	public def constructor(base as TRpgMapObject, parent as SpriteEngine):
		FMapObj = base
		FEngine = parent cast T2kSpriteEngine
		FMoveRate = 4
		UpdateMove(FMapObj.CurrentPage) if self.HasPage

	private def Destroy():
		FTiles[0].Dead() unless FTiles[0] is null
		FTiles[1].Dead() unless FTiles[1] is null
		(FEngine cast T2kSpriteEngine).LeaveLocation(FLocation, self)

	override def ToString():
		var result = self.ClassName
		if FMapObj is not null:
			return "$result $(FMapObj.ID): $(FMapObj.Name)"
		return result

	public virtual def Move(whichDir as TDirections) as bool:
		target as SgPoint
		result = false
		return result if _moveTime is not null or FPause is not null
		if self.DirLocked:
			FMoveDir = whichDir
		else: Facing = whichDir
		if FSlipThrough or self.CanMoveForward():
			self.LeaveTile()
			target = SgPoint(FLocation.x, FLocation.y)
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
		destination as SgPoint
		var result = false
		return result if _moveTime is not null or FPause is not null
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

	private def ResetWrappedPosition():
		self.FLocation = _wrapped
		_wrapped = null

	protected virtual def StepFinished():
		pass

	public virtual def Place():
		if (FInitialized and _moveTime is null) or \
			(FInitialized and FMoveQueue is null and FMoveAssignment is null and \
				FMapObj is not null and FMapObj.CurrentPage.MoveType == TMoveType.Still):
			return
		if _moveTime is not null:
			if _moveTime.IsDone:
				_moveTime = null
				FJumping = false
				SnapToTarget()
				SetMovePause()
				FJumpAnimateOverride = false
				CurrentTile().Bump(self) unless FSlipThrough
				if _wrapped is not null:
					ResetWrappedPosition()
				StepFinished()
		unless FInitialized:
			EnterTile()
			FInitialized = true

	public def UpdatePage(Data as TRpgEventPage):
		DoUpdatePage(Data)

	public virtual def Interpolate(renderTime as double):
		return if _moveTime is null or FTiles[0] is null
		var p = Math.Min(Math.Max((renderTime - _moveStart) / _moveTicks, 0.0), 1.0)
		_interpDX = ((_moveFromX + ((FTarget.x - _moveFromX) * p)) cast single) - FTiles[0].X
		_interpDY = ((_moveFromY + ((FTarget.y - _moveFromY) * p)) cast single) - FTiles[0].Y
		_interpDY -= JumpHeight(p) if FJumping
		ApplyInterpolation(_interpDX, _interpDY)

	public virtual def EndInterpolation():
		return if _interpDX == 0 and _interpDY == 0
		ApplyInterpolation(-_interpDX, -_interpDY)
		_interpDX = 0
		_interpDY = 0

	private def ApplyInterpolation(dx as single, dy as single):
		for tile in FTiles:
			continue if tile is null
			tile.X += dx
			tile.Y += dy
			tile.UpdateGridLoc()

	public InFront as SgPoint:
		get:
			var direction = (FMoveDir if self.DirLocked else FFacing)
			caseOf direction:
				case TDirections.Up: result = SgPoint(FLocation.x, FLocation.y - 1)
				case TDirections.Right: result = SgPoint(FLocation.x + 1, FLocation.y)
				case TDirections.Down: result = SgPoint(FLocation.x, FLocation.y + 1)
				case TDirections.Left: result = SgPoint(FLocation.x - 1, FLocation.y)
			return result

	public InFrontTile as TMapTile:
		get:
			inFront as SgPoint = self.InFront
			return (FEngine cast T2kSpriteEngine).GetTile(inFront.x, inFront.y, 0)

	public HasPage as bool:
		get: return FMapObj?.CurrentPage is not null

	public def Flash(r as byte, g as byte, b as byte, power as byte, time as uint):
		if time == 0:
			FFlashTimer = null
			return
		FFlashColor.Rgba[1] = r
		FFlashColor.Rgba[2] = g
		FFlashColor.Rgba[3] = b
		FFlashColor.Rgba[4] = power
		time = time * 100
		FFlashTimer = Timestamp(time)
		FFlashLength = time

	public virtual def MoveTick(moveBlocked as bool):
		return if _moveTime is not null
		if FPause is not null:
			return if FPause.RemainingTicks > 0
			FPause = null
		canMove as bool = not (moveBlocked or FMapObj?.Playing)
		if FMoveAssignment is not null:
			var tries = 0
			while FMoveAssignment is not null and FPause is null and _moveTime is null and tries < 4:
				FMoveAssignment = null unless DoMove(FMoveAssignment)
				++tries
		elif FMoveQueue is not null and canMove:
			var queueTries = 0
			var maxTries = (4 if self.HasPage and FMapObj.CurrentPage.MoveType == TMoveType.ByRoute else 1)
			while FMoveQueue is not null and FPause is null and _moveTime is null and queueTries < maxTries:
				FMoveQueue = null unless DoMove(FMoveQueue)
				self.UpdateMove(FMapObj.CurrentPage) if FMoveQueue is null and FMoveStep is null and maxTries > 1
				++queueTries
		elif canMove and self.HasPage:
			caseOf FMapObj.CurrentPage.MoveType:
				case TMoveType.CycleUD:
					FMoveOpen = (self.Move(TDirections.Up) if FMoveReversed else self.Move(TDirections.Down))
				case TMoveType.CycleLR:
					FMoveOpen = (self.Move(TDirections.Right) if FMoveReversed else self.Move(TDirections.Left))
				case TMoveType.ByRoute:
					self.UpdateMove(FMapObj.CurrentPage)
					MoveTick(moveBlocked)
					return
				default:
					pass
		if self.HasPage and (FMapObj.CurrentPage.MoveType in (TMoveType.CycleUD, TMoveType.CycleLR)) and not FMoveOpen:
			FMoveReversed = not FMoveReversed
			(self.InFrontTile).Bump(self) if self.InFrontTile is not null

	public abstract def Update(filename as string, transparent as bool, spriteIndex as int):
		pass

	public def Stop():
		if FMoveAssignment != null:
			if _moveTime != null:
				CancelMove()
				if _wrapped is not null:
					ResetWrappedPosition()
			elif FPause != null:
				FPause = null
			FMoveAssignment = null

	public def CopyDrawState(base as TMapSprite):
		if base.FFlashTimer != null:
			FFlashTimer = Timestamp(base.FFlashTimer.TimeRemaining)
			FFlashColor = base.FFlashColor
			FFlashLength = base.FFlashLength
		FMoveQueue = base.FMoveQueue.Clone() unless base.FMoveQueue is null
		if base.FMoveAssignment != null:
			FMoveAssignment = base.FMoveAssignment.Clone()
			FMoveFreq = base.FMoveFreq
		if base.FMoveChange != null:
			FMoveChange = base.FMoveChange
		FMoveReversed = base.FMoveReversed
		FMoveOpen = base.FMoveOpen
		FMoveDir = base.FMoveDir
		FTransparencyFactor = base.FTransparencyFactor
		FSlipThrough = base.FSlipThrough
		self.Facing = base.Facing if base isa TCharSprite
		self.Location = base.Location

	protected def HasMoveChange() as bool:
		return FMoveChange != null

	public def MoveChange(path as Path, frequency as int, skip as bool):
		lock self:
			FMoveChange = MoveChangeData(path, frequency, skip)

	public def CheckMoveChange():
		lock self:
			if FMoveChange != null:
				SetMoveOrder(FMoveChange.Path)
				self.CanSkip = FMoveChange.Skip
				self.MoveFreq = FMoveChange.Frequency
				FMoveChange = null

	public Location as SgPoint:
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

	protected override def SetLocation(value as SgPoint):
		super.SetLocation(value)
		FTiles[0].X = Location.x * TILE_SIZE.x
		FTiles[0].Y = Location.y * TILE_SIZE.y

	protected override def DoUpdatePage(data as TRpgEventPage):
		FTiles[0].Update(data)
		UpdateMove(data)

	public def constructor(base as TRpgMapObject, parent as SpriteEngine):
		super(base, parent)
		FTiles[0] = EventTile(Event, parent)
		FTiles[1] = null
		self.Translucency = (3 if FMapObj.CurrentPage != null and FMapObj.CurrentPage.Transparent else 0)
		SetLocation(SgPoint(base.Location.x, base.Location.y))
		self.SetFlashEvents(FTiles[0])

	public override def Update(filename as string, transparent as bool, spriteIndex as int):
		self.Translucency = (3 if transparent else 0)
		assert false

[Disposable(Destroy, true)]
class TCharSprite(TMapSprite):

	private static final _spriteWidthOffset as int

	static def constructor():
		var l = GDatabase.value.Layout
		_spriteWidthOffset = (l.SpriteSize.x - l.TileSize.x) / 2

	# Ticks since the walking pattern last advanced
	private FAnimCount as int

	private def LoadCharset(filename as string):
		FEngine.Images.EnsureImage(("Sprites\\$filename.png"), filename, SPRITE_SIZE)

	private def UpdateFrame():
		var animType = (FMapObj.CurrentPage.AnimType if HasPage else TAnimType.Sentry)
		var rate = Math.Min(Math.Max(FMoveRate, 1), 6)
		standing as bool = _moveTime is null
		jumping as bool = FJumpAnimateOverride
		caseOf animType:
			case TAnimType.Sentry, TAnimType.FixedDir:
				unless jumping:
					unless standing and (FMoveFrame % 2 == 1) and ANIM_STEP_STANDING[rate] - 1 <= FAnimCount:
						++FAnimCount
			case TAnimType.Jogger, TAnimType.FixedJog:
				++FAnimCount unless jumping
			case TAnimType.SpinRight:
				++FAnimCount
			default:
				pass
		if animType <= TAnimType.FixedJog:
			if (not standing and ANIM_STEP_MOVING[rate] <= FAnimCount) or (standing and ANIM_STEP_STANDING[rate] <= FAnimCount):
				FMoveFrame = (FMoveFrame + 1) % FActionMatrix[FAction].Length
				FAnimCount = 0
			if jumping or self.AnimFix:
				FMoveFrame = 1
				FAnimCount = 0
		elif animType == TAnimType.SpinRight and ANIM_STEP_SPIN[rate] <= FAnimCount:
			self.Facing = (ord(self.Facing) + 1) % 4
			FAnimCount = 0

	protected FMoved as bool

	protected FActionMatrix as ((int))

	protected FAction as int

	protected FMoveFrame as int

	[Property(SpriteIndes)]
	private FSpriteIndex as int

	protected override def SetFacing(data as TDirections):
		super.SetFacing(data)
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

	protected override def SetLocation(data as SgPoint):
		super.SetLocation(data)
		FTiles[0].X = (Location.x * TILE_SIZE.x) - _spriteWidthOffset
		FTiles[0].Y = Location.y * TILE_SIZE.y
		FTiles[1].X = (Location.x * TILE_SIZE.x) - _spriteWidthOffset
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
				ClearPortrait() //This seems to be the rule RM2K follows
				GMapObjectManager.value.RunPageScript(mapObj.CurrentPage)

	protected override def DoUpdatePage(data as TRpgEventPage):
		FTiles[0].Update(data)
		FTiles[1].Update(data)
		if data != null:
			FUnderConstruction = true
			self.Facing = data.Direction
			FMoveFrame = data.Frame
			UpdateMove(data)
			FUnderConstruction = false
			Update(data.PageName, Translucency >= 3, data.SpriteIndex)
			FTiles[1].Z = FTiles[0].Z + 1
		self.Visible = data != null

	public def constructor(base as TRpgMapObject, parent as SpriteEngine):
		super(base, parent)
		FUnderConstruction = true
		FTiles[0] = EventTile(base, parent)
		FTiles[1] = EventTile(base, parent)
		if base?.CurrentPage != null:
			Translucency = 3 if base.CurrentPage.Transparent
			FActionMatrix = GDatabase.value.MoveMatrix[FMapObj.CurrentPage.ActionMatrix]
			FSpriteIndex = base.CurrentPage.SpriteIndex
			self.Facing = base.CurrentPage.Direction
			UpdatePage(base.CurrentPage)
			FTiles[1].Z = FTiles[0].Z + 1
		else: FActionMatrix = GDatabase.value.MoveMatrix[0]
		if base != null:
			SetLocation(SgPoint(base.Location.x, base.Location.y))
			base.OnTurn += self.ActivateFaceHero
			base.OnDoneTurn += self.TurnChangeFacing
		FUnderConstruction = false
		self.SetFlashEvents(FTiles[0])
		self.SetFlashEvents(FTiles[1])

	private new def Destroy():
		if FMapObj != null:
			FMapObj.OnTurn -= self.ActivateFaceHero
			FMapObj.OnDoneTurn -= self.TurnChangeFacing

	private def ActivateFaceHero():
		self.TurnChangeFacing(DirTowardsHero())

	public def Reload(imageName as string, index as byte):
		FTiles[0].Name = imageName + index.ToString()
		FTiles[1].Name = imageName + index.ToString()
		self.Facing = TFacing.Down
		FMoveFrame = 0

	public def Assign(Data as TCharSprite):
		self.Facing = Data.Facing
		FLocation = Data.Location

	public override def Place():
		FMoved = _moveTime is not null
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

	public virtual def Action(button as TButtonCode):
		raise ESpriteError("Non-player sprites can't receive an Action.")

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
let WALK_TICKS = (0, 64, 32, 16, 8, 4, 2)
let JUMP_TICKS = (0, 32, 22, 16, 11, 8, 4)

def JumpHeight(p as double) as single:
	var d = Math.Abs(128 - (256 * (1 - p)))
	return (16 - ((d * d) / 1024.0)) cast single
let WIDTH_BIAS = 4
let ANIM_STEP_MOVING = (0, 12, 10, 8, 6, 5, 4)
let ANIM_STEP_STANDING = (0, 16, 12, 10, 8, 7, 6)
let ANIM_STEP_SPIN = (0, 24, 16, 12, 8, 6, 4)
let MAX_TRANSPARENCY = 7
let TRANSPARENCY_STEP = 255.0 / (MAX_TRANSPARENCY + 1)
