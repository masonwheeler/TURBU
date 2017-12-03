namespace turbu.RM2K.CharSprites

import turbu.defs
import turbu.pathing
import sdl.sprite
import SG.defs
import timing
import TURBU.RM2K
import turbu.characters
import turbu.terrain
import Boo.Adt
import Pythia.Runtime
import System
import tiles
import turbu.RM2K.map.tiles
import turbu.map.sprites
import turbu.mapchars
import turbu.Heroes
import turbu.RM2K.sprite.engine
import turbu.RM2K.environment
import TURBU.Meta

enum TVehicleState:
	Empty
	Launching
	Active
	Landing
	Emptying

class TVehicleTile(TEventTile):

	internal FOwner as TVehicleSprite

	[Getter(Offset)]
	protected FOffset as TSgPoint

	protected FOnCleanup as Action

	protected def OffsetTowards(offset as TSgPoint, State as TVehicleState):
		displacement as int
		if FOffset.x != offset.x:
			displacement = (offset.x - FOffset.x)
			displacement = (displacement / Math.Abs(displacement))
			FOffset.x += displacement
			self.X = (self.X + displacement)
		if FOffset.y != offset.y:
			displacement = (offset.y - FOffset.y)
			displacement = (displacement / Math.Abs(displacement))
			FOffset.y += displacement
			self.Y = (self.Y + displacement)
		FOwner.ReportState(State) if (FOffset.x == offset.x) and (FOffset.y == offset.y)

	public def constructor(base as TEventTile, parent as SpriteEngine, onCleanup as Action):
		super(base.Event, parent cast T2kSpriteEngine)
		self.Z = 3
		self.Assign(base)
		FOnCleanup = onCleanup

	def destructor():
		FOnCleanup() if assigned(FOnCleanup)

	public override def Draw():
		caseOf FOwner.State:
			case TVehicleState.Empty, TVehicleState.Emptying, TVehicleState.Active:
				pass
			case TVehicleState.Launching:
				OffsetTowards(sgPoint(0, -FOwner.Altitude), TVehicleState.Active)
			case TVehicleState.Landing:
				OffsetTowards(commons.ORIGIN, TVehicleState.Emptying)
			default :
				assert false
		super.Draw()

enum TUnloadMethod:
	Here
	Front

[Disposable(Destroy)]
class TVehicleSprite(TCharSprite):

	[Getter(Template)]
	private FTemplate as TRpgVehicle

	[Property(Carrying)]
	private FCarrying as THeroSprite

	private FStateCounter as int

	[Getter(Altitude)]
	private FAltitude as int

	private FShadow as TSprite

	private FOnCleanup as Action

	private def SetState(Value as TVehicleState):
		FState = Value
		if FState == TVehicleState.Emptying:
			self.Unload()

	private UnloadLocation as TSgPoint:
		get:
			caseOf FUnloadMethod:
				case TUnloadMethod.Here:
					result = FLocation
				case TUnloadMethod.Front:
					result = self.InFront
			return result

	protected FState as TVehicleState

	protected FAnimated as bool

	protected FAnimDir as bool

	protected FAnimCounter as byte

	protected FUnloadMethod as TUnloadMethod

	protected override def CanMoveForward() as bool:
		engine as T2kSpriteEngine
		sprite as TMapSprite
		terrain as TRpgTerrain
		engine = (FEngine cast T2kSpriteEngine)
		result = engine.EdgeCheck(FLocation.x, FLocation.y, self.Facing)
		if result:
			terrain = GDatabase.value.Terrains[engine.Tiles[0, InFront.x, InFront.y].Terrain]
			result = terrain.VehiclePass[FTemplate.VehicleIndex]
		if result and (FAltitude == 0):
			for sprite in (InFrontTile cast TMapTile).Event:
				if (sprite isa TEventSprite) and ((sprite cast TEventSprite).BaseTile.Z == 4):
					result = false
				elif (sprite isa TCharSprite) and (not (sprite isa TVehicleSprite)):
					result = false
		return result

	internal def ReportState(which as TVehicleState):
		++FStateCounter
		if FStateCounter == 2:
			self.State = which
			FStateCounter = 0

	protected def Unload() as bool:
		ground as TTile
		result = false
		ground = (FEngine cast T2kSpriteEngine).Tiles[0, UnloadLocation.x, UnloadLocation.y]
		if ground.Open(self):
			result = true
			self.State = TVehicleState.Empty
			FTemplate.Carrying = null
			FCarrying.Location = self.UnloadLocation
			FCarrying.Visible = true
			(FEngine cast T2kSpriteEngine).CurrentParty = FCarrying
			FShadow.Visible = false
			FTiles[0].Z = 3
			FTiles[1].Z = 3
		else:
			self.State = TVehicleState.Launching
		return result

	protected def DoAction(Button as TButtonCode):
		ground as TMapTile
		if FAltitude == 0:
			ground = (FEngine cast T2kSpriteEngine).Tiles[0, UnloadLocation.x, UnloadLocation.y]
			if (Button == TButtonCode.Enter) and not ground.Open(null):
				self.ActivateEvents(ground)
				return
		caseOf Button:
			case TButtonCode.Enter:
				self.State = TVehicleState.Landing
			case TButtonCode.Cancel:
				pass
			case TButtonCode.Up, TButtonCode.Down, TButtonCode.Left, TButtonCode.Right:
				pass
			default :
				assert false

	protected override def Bump(bumper as TMapSprite):
		hero = bumper as THeroSprite
		if assigned(hero):
			hero.BoardVehicle()

	protected override def SetTarget(value as TSgPoint):
		if FState == TVehicleState.Active:
			FTarget = value + (FTiles[0] cast TVehicleTile).Offset
		else:
			super.SetTarget(value)

	public def constructor(parent as SpriteEngine, whichVehicle as TRpgVehicle, cleanup as Action):
		newTile as TVehicleTile
		super(null, parent)
		self.OnChangeSprite = whichVehicle.ChangeSprite
		whichVehicle.Gamesprite = self
		self.FTemplate = whichVehicle
		newTile = TVehicleTile((FTiles[1] cast TEventTile), parent, { FTiles[1] = null })
		newTile.FOwner = self
		FTiles[1] = newTile
		newTile = TVehicleTile((FTiles[0] cast TEventTile), parent, { FTiles[0] = null })
		newTile.FOwner = self
		FTiles[0] = newTile
		Visible = (whichVehicle.Map == (FEngine cast T2kSpriteEngine).MapObj.ID)
		FAnimated = false
		FAltitude = whichVehicle.Template.Altitude
		if FAltitude == 0:
			FUnloadMethod = TUnloadMethod.Front
		else:
			FUnloadMethod = TUnloadMethod.Here
		FShadow = TSprite(FTiles[0])
		FShadow.Alpha = 160
		FShadow.Z = 1
		FShadow.Visible = false
		FOnCleanup = cleanup
		FMoveFreq = 8

	private new def Destroy():
		if assigned(FOnCleanup):
			FOnCleanup()

	public def Launch():
		self.State = TVehicleState.Launching
		FTiles[0].Z = 13
		FTiles[1].Z = 13
		FAnimated = true
		if FTemplate.Template.MovementStyle != TMovementStyle.Surface:
			if self.Facing == TDirections.Up:
				self.Facing = TDirections.Right
			elif self.Facing == TDirections.Down:
				self.Facing = TDirections.Left
			FShadow.Visible = true
			FShadow.X = FTiles[0].X + 4
			FShadow.Y = FTiles[0].Y
			FShadow.Z = 13

	public override def Place() as void:
		kept as int
		kept = FMoveFrame
		super.Place()
		FMoveFrame = kept
		++FAnimCounter
		if FAnimCounter == VEHICLE_ANIM_RATE:
			FAnimCounter = 0
			if FAnimated:
				turbu.sprites.nextPosition(FActionMatrix, FAction, FMoveFrame)
		if ((GEnvironment.value.Party.Base == self) and FMoved) and (not GSpriteEngine.value.ScreenLocked):
			(FEngine cast T2kSpriteEngine).MoveTo(Math.Truncate((FTiles[0].X + GSpriteEngine.value.DisplacementX)), Math.Truncate((FTiles[0].Y + GSpriteEngine.value.DisplacementY)))
		if FMoved and (FTemplate.Template.MovementStyle != TMovementStyle.Surface):
			caseOf self.Facing:
				case TDirections.Up: FShadow.Y = FShadow.Y - 4
				case TDirections.Right: FShadow.X = FShadow.X + 4
				case TDirections.Down: FShadow.Y = FShadow.Y + 4
				case TDirections.Left: FShadow.X = FShadow.X - 4

	public override def Action(Button as TButtonCode):
		DoAction(Button) if FState == TVehicleState.Active

	public override def SetLocation(data as TSgPoint):
		super.SetLocation(data)
		Place()
		if assigned(FShadow):
			FShadow.X = FTiles[0].X + 4
			FShadow.Y = FTiles[0].Y
		FTiles[0].X = FTiles[0].X + (FTiles[0] as TVehicleTile).Offset.x
		FTiles[0].Y = FTiles[0].Y + (FTiles[0] as TVehicleTile).Offset.y
		FTiles[1].X = FTiles[1].X + (FTiles[1] as TVehicleTile).Offset.x
		FTiles[1].Y = FTiles[1].Y + (FTiles[1] as TVehicleTile).Offset.y

	public State as TVehicleState:
		get: return FState
		set: SetState(value)

class THeroSprite(TCharSprite):

	[Getter(Template)]
	private FTemplate as TRpgHero

	private FParty as TRpgParty

	private FNextMove as TDirections

	private FMoveQueued as bool

	private FMoveTick as bool

	private def RideVehicle(theVehicle as TVehicleSprite):
		(FEngine cast T2kSpriteEngine).CurrentParty = theVehicle
		theVehicle.Template.Carrying = FParty
		theVehicle.Carrying = self
		self.LeaveTile()
		FLocation = sgPoint(-1, -1)
		self.Visible = false
		theVehicle.Launch()

	private def QueueMove(direction as TDirections):
		unless self.HasMoveChange():
			FNextMove = direction
			FMoveQueued = true

	private def SetMovement(direction as TDirections):
		MoveQueue = MakeSingleStepPath(direction)

	protected override def DoMove(which as Path) as bool:
		FMoveTick = true
		result = super.DoMove(which)
		FMoveTick = false
		return result

	protected override def GetCanSkip() as bool:
		return true

	public def constructor(parent as SpriteEngine, whichHero as TRpgHero, party as TRpgParty):
		super(null, parent)
		FTiles[1].Z = 5
		FTiles[0].Z = 4
		party.SetSprite(self)
		self.OnChangeSprite = party.ChangeSprite
		FTemplate = whichHero
		if assigned(FTemplate) and (FTemplate.Sprite != ''):
			Update(FTemplate.Sprite, FTemplate.Transparent, FTemplate.SpriteIndex)
		SetLocation(sgPoint(1, 1))
		FParty = party
		FMoveFreq = 8
		FCanSkip = true
		self.Facing = TDirections.Down

	def destructor():
		if FParty.Sprite == self:
			FParty.SetSprite(null)

	public override def Action(button as TButtonCode):
		if button == TButtonCode.Enter:
			ActivateEvents(((FEngine cast T2kSpriteEngine).Tiles[0, FLocation.x, FLocation.y]) cast TMapTile)
			var currentTile = self.InFrontTile
			if assigned(currentTile):
				ActivateEvents(currentTile)
				var location = FLocation
				while currentTile.Countertop:
					currentTile = GSpriteEngine.value.TileInFrontOf(location, self.Facing)
					if assigned(currentTile):
						ActivateEvents(currentTile)
					else:
						break

	public override def Place():
		super.Place()
		if FMoveQueued:
			FMoveQueued = false
			if MoveAssign == null:
				self.Move(FNextMove)

	public def BoardVehicle():
		eventList as (TMapSprite) = ((FEngine cast T2kSpriteEngine).Tiles[0, FLocation.x, FLocation.y] cast TMapTile).Event
		for theSprite in eventList:
			if (theSprite isa TVehicleSprite) and ((theSprite as TVehicleSprite).State == TVehicleState.Empty):
				RideVehicle(theSprite as TVehicleSprite)
				return
		caseOf self.Facing:
			case TDirections.Up:
				if FLocation.y == 0:
					return
			case TDirections.Right:
				if FLocation.x == (FEngine cast T2kSpriteEngine).Width:
					return
			case TDirections.Down:
				if FLocation.y == (FEngine cast T2kSpriteEngine).Height:
					return
			case TDirections.Left:
				if FLocation.x == 0:
					return
		eventList = ((FEngine cast T2kSpriteEngine).Tiles[0, InFront.x, InFront.y] cast TMapTile).Event
		for theSprite in eventList:
			vs = theSprite as TVehicleSprite
			if assigned(vs) and vs.State == TVehicleState.Empty:
				RideVehicle(vs)

	public override def Move(whichDir as TDirections) as bool:
		if self.HasMoveChange():
			return false
		if assigned(FMoveTime):
			if (MoveFreq == 8) and (FMoveTime.TimeRemaining <= TRpgTimestamp.FrameLength):
				QueueMove(whichDir)
			return false
		if assigned(FPause):
			if FPause.TimeRemaining <= TRpgTimestamp.FrameLength:
				QueueMove(whichDir)
			return false
		if FMoveTick:
			return super.Move(whichDir)
		else:
			SetMovement(whichDir)
			return false

	public def PackUp():
		FEngine.Remove(FTiles[0])
		FEngine.Remove(FTiles[1])
		(FEngine cast T2kSpriteEngine).LeaveLocation(FLocation, self)

	public def settleDown(engine as SpriteEngine):
		FEngine = engine

let AIRSHIP_OFFSET = TSgPoint(x: 0, y: -16)
let VEHICLE_ANIM_RATE = 10
