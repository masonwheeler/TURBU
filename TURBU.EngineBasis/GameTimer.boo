namespace TURBU.EngineBasis

import System

//Translated and adapted from a C# example in a defunct blog post archived at
//http://web.archive.org/web/20110910100053/http://www.indigo79.net/archives/27

public class TGameTimer:
	
	private _interval as int
	
	private _elapsedTimerHandler as ElapsedTimerDelegate
	
	private _enabled as bool
	
	private _stopwatch = System.Diagnostics.Stopwatch()
	
	private _lastElapsedTime as timespan
	
	private _spillover as int
	
	private _syncObject as System.Windows.Forms.Control
	
	public event OnProcess as System.Action
	
	public Enabled as bool:
		get: return _enabled
		set:
			if value:
				Start()
			else: Stop()
	
	public def constructor(intervalMS as int, callback as ElapsedTimerDelegate, syncObject as System.Windows.Forms.Control):
		self._interval = intervalMS
		
		self._elapsedTimerHandler = callback
		
		self._syncObject = syncObject
	
	public callable ElapsedTimerDelegate() as void
	
	private def TimerHandler(id as int, msg as int, user as IntPtr, dw1 as int, dw2 as int):
		
		_syncObject.Invoke(self._elapsedTimerHandler)
	
	public def Start():
		timeBeginPeriod(1)
		mHandler = TimerHandler
		mTimerId = timeSetEvent(self._interval, 0, mHandler, IntPtr.Zero, EVENT_TYPE)
		mTestStart = DateTime.Now
		mTestTick = 0
		_enabled = true
		_stopwatch.Start()
	
	public def Stop():
		_enabled = false
		err as int = timeKillEvent(mTimerId)
		assert err == 0, "timeKillEvent returned $err"
		timeEndPeriod(1)
		mTimerId = 0
		_stopwatch.Reset()
	
	public def Process():
		e = _stopwatch.Elapsed
		elapsedTime = e.Subtract(_lastElapsedTime).TotalMilliseconds + _spillover
		while elapsedTime > _interval:
			elapsedTime -= _interval
			OnProcess()
		_spillover = elapsedTime
		_lastElapsedTime = e
	
	private mTimerId as int
	
	private mHandler as TimerEventHandler
	
	private mTestTick as int
	
	private mTestStart as DateTime
	
	// P/Invoke declarations
	private callable TimerEventHandler(id as int, msg as int, user as IntPtr, dw1 as int, dw2 as int) as void
	
	private static final TIME_PERIODIC = 1
	
	private static final EVENT_TYPE as int = TIME_PERIODIC // + 0x100;  // TIME_KILL_SYNCHRONOUS causes a hang ?!
	
	[DllImport('winmm.dll')]
	private static def timeSetEvent(delay as int, resolution as int, handler as TimerEventHandler, user as IntPtr, eventType as int) as int:
		pass

	[DllImport('winmm.dll')]
	private static def timeKillEvent(id as int) as int:
		pass

	[DllImport('winmm.dll')]
	private static def timeBeginPeriod(msec as int) as int:
		pass

	[DllImport('winmm.dll')]
	private static def timeEndPeriod(msec as int) as int:
		pass
