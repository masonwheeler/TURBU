namespace AsphyreTimer

import Boo.Adt
import Pythia.Runtime
import TURBU.Meta
import System
import System.Windows.Forms

[Disposable(Destroy, true)]
class TAsphyreTimer(TObject):
	let FixedHigh = 0x100000
	let DeltaLimit = 3 * FixedHigh

	private FMaxFPS as int

	private FSpeed as double

	[Property(Enabled)]
	private FEnabled as bool

	event OnTimer as Action

	[Getter(FrameRate)]
	private FFrameRate as int

	private PrevTime as uint

	private PrevTime64 as long

	event OnProcess as Action

	private Processed as bool

	private LatencyFP as long

	private DeltaFP as int

	private HighFreq as long

	private MinLatency as int

	private SpeedLatcy as int

	private FixedDelta as int

	private SampleLatency as long

	private SampleIndex as int
	
	[DllImport("KERNEL32")]
	private static def QueryPerformanceCounter(ref lpPerformanceCount as long) as bool:
		pass
	
	[DllImport("KERNEL32")]
	private static def QueryPerformanceFrequency(ref lpPerformanceFreq as long) as bool:
		pass
	
	[DllImport("kernel32.dll")]
	static def SleepEx(dwMilliseconds as uint, bAlertable as bool) as uint:
		pass
	
	public def constructor(fps as int, onTimer as Action):
		super()
		Speed = 60.0
		MaxFPS = fps
		if QueryPerformanceFrequency(HighFreq):
			QueryPerformanceCounter(PrevTime64)
		else: raise 'High performance frequency not available'
		Application.Idle += AppIdle
		FixedDelta = 0
		FFrameRate = 0
		SampleLatency = 0
		SampleIndex = 0
		Processed = false
		self.OnTimer += onTimer

	private def Destroy():
		Application.Idle -= AppIdle
		FEnabled = false

	private def RetrieveLatency() as long:
		CurTime64 as long
		QueryPerformanceCounter(CurTime64)
		result = (CurTime64 - PrevTime64) * FixedHigh * 1000 / HighFreq
		PrevTime64 = CurTime64
		return result

	private def AppIdle(Sender as object, args as EventArgs):
		WaitAmount as int
		SampleMax as int
		msg as NativeMethods.Message
		LatencyFP = RetrieveLatency()
		unless FEnabled:
			SleepEx(5, true)
			return
		repeat:
			if LatencyFP < MinLatency:
				WaitAmount = (MinLatency - LatencyFP) / FixedHigh
				SleepEx(Math.Max(WaitAmount, 0), true)
			else:
				WaitAmount = 0
			DeltaFP  = Math.Min((LatencyFP cast Int64) * FixedHigh / SpeedLatcy, DeltaLimit)
			SampleLatency += LatencyFP + (WaitAmount * FixedHigh)
			SampleMax = (4 if LatencyFP <= 0 else (FixedHigh cast Int64) * 1000 / LatencyFP)
			++SampleIndex
			if SampleIndex >= SampleMax:
				FFrameRate = (SampleIndex cast Int64) * FixedHigh * 1000 / SampleLatency
				SampleLatency = 0
				SampleIndex = 0
			if Processed:
				FixedDelta += DeltaFP
				Processed = false
			OnTimer()
			until NativeMethods.PeekMessage(msg, IntPtr.Zero, 0, 0, 0) or (FEnabled == false)

	public Delta as double:
		get: return (DeltaFP cast double) / (FixedHigh cast double)

	public Latency as double:
		get: return (LatencyFP cast double) / (FixedHigh cast double)

	public def Process():
		Processed = true
		Amount as int = FixedDelta / FixedHigh
		return if Amount < 1
		for i in range(Amount):
			OnProcess()
		FixedDelta &= FixedHigh - 1

	public def Reset():
		FixedDelta = 0
		DeltaFP = 0
		RetrieveLatency()

	public Speed as double:
		get: return FSpeed
		set:
			FSpeed = Math.Max(value, 1.0)
			SpeedLatcy = Math.Round(FixedHigh * 1000.0 / FSpeed)

	public MaxFPS as int:
		get: return FMaxFPS
		set:
			FMaxFPS = Math.Max(value, 1)
			MinLatency = Math.Round(FixedHigh * 1000.0 / FMaxFPS)

	private static class NativeMethods:
		[StructLayout(LayoutKind.Sequential)]
		public struct Message
			public hWnd as IntPtr
			public Msg as uint
			public wParam as IntPtr
			public lParam as IntPtr
			public Time as uint
			public Point as System.Drawing.Point
		
		[DllImport("User32.dll")]
		public def PeekMessage(ref message as Message, hWnd as IntPtr, filterMin as uint, filterMax as uint, flags as uint) [MarshalAs(UnmanagedType.Bool)] as bool:
			pass