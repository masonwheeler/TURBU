namespace timing

import System
import System.Linq.Enumerable
import Pythia.Runtime

class TRpgTimestamp(TObject):

	private static FLastFrame as DateTime

	private static FCounter as int

	private static FFrameLength = array(int, 10)

	private static def constructor():
		for i in range(FFrameLength.Length):
			FFrameLength[i] = 16

	private FHour as ushort

	private FMin as ushort

	private FSec as ushort

	private FMsec as ushort

	private FPauseTime as int

	private FPaused as bool

	private def Setup(length as int):
		try:
			n = DateTime.Now
			FHour = n.Hour
			FMin = n.Minute
			FSec = n.Second
			FMsec = n.Millisecond
			FMsec += length % 1000
			if FMsec >= 1000:
				++FSec
				FMsec -= 1000
			length /= 1000
			return if length == 0
			FSec += length % 60
			while FSec >= 60:
				++FMin
				FSec -= 60
			length /= 60
			return if length == 0
			FMin += length % 60
			while FMin >= 60:
				++FHour
				FMin -= 60
			length /= 60
			assert length == 0
		ensure:
			if FHour == 0:
				FHour = 24

	public def constructor(length as int):
		super()
		Setup(length)

	public TimeRemaining as int:
		get:
			return FPauseTime if FPaused
			n = DateTime.Now
			theHour as int = n.Hour
			min as int = n.Minute
			sec as int = n.Second
			msec as int = n.Millisecond
			hour = (24 if theHour == 0 else theHour)
			hour = FHour - hour
			min = FMin - min
			sec = FSec - sec
			msec = FMsec - msec
			while msec < 0:
				--sec
				msec += 1000
			while sec < 0:
				--min
				sec += 60
			while min < 0:
				--hour
				min += 60
			return ((min * 60000) + (sec * 1000) + msec if hour == 0 else 0)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def Pause():
		if not FPaused:
			FPauseTime = self.TimeRemaining
			FPaused = true

	public def Resume():
		if FPaused:
			self.Setup(FPauseTime)
			FPaused = false

	public static def NewFrame():
		if FLastFrame == 0:
			FLastFrame = DateTime.Now
		else:
			unchecked:
				delta as int = Math.Max(DateTime.Now.Subtract(FLastFrame).TotalMilliseconds, 0)
			FLastFrame = DateTime.Now
			if FCounter == 0:
				if delta > 0:
					for i in range(FFrameLength.Length):
						FFrameLength[i] = delta
					++FCounter
			else:
				++FCounter
				FCounter = 0 if FCounter >= FFrameLength.Length
				FFrameLength[FCounter] = delta

	public static FrameLength as int:
		get: return Math.Round(FFrameLength.Average())

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
