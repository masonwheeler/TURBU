namespace timing

import System
import TURBU.Timing

class Timestamp:

	private _goal as long

	private _pauseTicks as int

	private _paused as bool

	private def SetupTicks(ticks as int):
		_goal = GameClock.Ticks + Math.Max(ticks, 0)

	public def constructor(lengthInMs as int):
		super()
		SetupTicks(MsToTicks(lengthInMs))

	private def constructor(ticks as int, dummy as bool):
		super()
		SetupTicks(ticks)

	public static def MsToTicks(ms as int) as int:
		return Math.Max(Math.Round(ms * GameClock.TICK_RATE / 1000.0), 0)

	public static def FromTicks(ticks as int) as Timestamp:
		return Timestamp(ticks, true)

	public RemainingTicks as int:
		get:
			return (_pauseTicks if _paused else Math.Max(_goal - GameClock.Ticks, 0))

	public IsDone as bool:
		get: return RemainingTicks == 0

	public TimeRemaining as int:
		get:
			return Math.Round(RemainingTicks * GameClock.TICK_MS)

	public def Pause():
		if not _paused:
			_pauseTicks = self.RemainingTicks
			_paused = true

	public def Resume():
		if _paused:
			self.SetupTicks(_pauseTicks)
			_paused = false

	public static def NewFrame():
		pass

	public static FrameLength as int:
		get: return 17

	public override def ToString():
		return RemainingTicks.ToString() + ' ticks'

def MoveTowards(remainingTicks as int, ref current as double, goal as double):
	diff as double = (current - goal) / (Math.Max(remainingTicks, 0) + 1)
	current = current - diff
	return diff

def MoveTowards(remainingTicks as int, ref current as single, goal as single):
	diff as single = (current - goal) / (Math.Max(remainingTicks, 0) + 1)
	current = current - diff
	return diff

def MoveTowards(remainingTicks as int, ref current as byte, goal as byte):
	diff as short = commons.round((((current - goal) cast double) / (Math.Max(remainingTicks, 0) + 1)))
	assert Math.Abs(diff) < 256
	current = current - diff
	return diff

def MoveTowards(remainingTicks as int, ref current as int, goal as int):
	diff as short = commons.round((((current - goal) cast double) / (Math.Max(remainingTicks, 0) + 1)))
	current = current - diff
	return diff
