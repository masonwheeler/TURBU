namespace timing

import System
from System.Diagnostics import Stopwatch

class TRpgTimestamp:

	private static _timer = Stopwatch()

	private static _lastFrame as long

	private static _counter as int

	private static _frameLength = array(int, 10)

	private static def constructor():
		for i in range(_frameLength.Length):
			_frameLength[i] = 16
		_timer.Start()

	private _goal as long

	private _pauseTime as int

	private _paused as bool

	private def Setup(length as int):
		var n = _timer.ElapsedMilliseconds
		_goal = n + length

	public def constructor(length as int):
		super()
		Setup(length)

	public TimeRemaining as int:
		get:
			return Math.Max(_goal - _timer.ElapsedMilliseconds, 0)

	public def Pause():
		if not _paused:
			_pauseTime = self.TimeRemaining
			_paused = true

	public def Resume():
		if _paused:
			self.Setup(_pauseTime)
			_paused = false

	public static def NewFrame():
		if _lastFrame == 0:
			_lastFrame = _timer.ElapsedMilliseconds
		else:
			unchecked:
				delta as int = Math.Max(_timer.ElapsedMilliseconds - _lastFrame, 0)
			_lastFrame = _timer.ElapsedMilliseconds
			return if delta > 1000
			if _counter == 0:
				if delta > 0:
					for i in range(_frameLength.Length):
						_frameLength[i] = delta
					++_counter
			else:
				++_counter
				_counter = 0 if _counter >= _frameLength.Length
				_frameLength[_counter] = delta

	public static FrameLength as int:
		get:
			var total = 0
			for value in _frameLength:
				total += value
			return total / _frameLength.Length

	public override def ToString():
		return TimeRemaining.ToString() + 'ms'

def MoveTowards(timer as int, ref current as double, goal as double):
	timefactor as int = Math.Max(timer / TRpgTimestamp.FrameLength, 1)
	diff as double = (current - goal) / timefactor
	current = current - diff
	return diff

def MoveTowards(timer as int, ref current as single, goal as single):
	timefactor as int = Math.Max(timer / TRpgTimestamp.FrameLength, 1)
	diff as single = (current - goal) / timefactor
	current = current - diff
	return diff

def MoveTowards(timer as int, ref current as byte, goal as byte):
	timefactor as int = Math.Max(timer / TRpgTimestamp.FrameLength, 1)
	diff as short = commons.round((((current - goal) cast double) / timefactor))
	assert Math.Abs(diff) < 256
	current = current - diff
	return diff

def MoveTowards(timer as int, ref current as int, goal as int):
	timefactor as int = Math.Max(timer / TRpgTimestamp.FrameLength, 1)
	diff as short = commons.round((((current - goal) cast double) / timefactor))
	current = current - diff
	return diff
