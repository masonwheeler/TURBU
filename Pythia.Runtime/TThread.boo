namespace Pythia.Runtime

import System
import System.Threading

class TThread:
	
	protected _thread as Thread
	
	[Getter(Terminated)]
	private _terminated as bool
	
	private static final _mainThreadID = Thread.CurrentThread.ManagedThreadId
	
	public def constructor():
		self(false)
	
	public def constructor(createSuspended as bool):
		_thread = Thread() do():
			_currentThread.Value = self
			self.Execute()
		_thread.Start() unless createSuspended
	
	internal def constructor([Required] wrapped as Thread):
		_currentThread.Value = self
		_thread = wrapped
	
	public static def CreateAnonymousThread([Required] closure as Action) as TThread:
		return TAnonymousThread(closure)
	
	protected abstract def Execute():
		pass
	
	internal static _currentThread = ThreadLocal[of TThread]()
	
	public static def Synchronize([Required] closure as Action):
		System.Windows.Forms.Application.OpenForms[0].Invoke(closure)
	
	public static def Queue([Required] closure as Action):
		System.Windows.Forms.Application.OpenForms[0].BeginInvoke(closure)
	
	public static HasCurrentThread:
		get: return _currentThread.IsValueCreated
	
	public static CurrentThread as TThread:
		get:
			unless _currentThread.IsValueCreated:
				TWrapperThread(Thread.CurrentThread)
			return _currentThread.Value
	
	public Priority as ThreadPriority:
		get: return _thread.Priority
		set: _thread.Priority = value
	
	public IsMainThread as bool:
		get: return _thread.ManagedThreadId == _mainThreadID
	
	public def Start():
		_thread.Start()
	
	public def Terminate():
		_terminated = true

private final class TAnonymousThread(TThread):
	_proc as Action
	
	def constructor([Required] proc as Action):
		_proc = proc
		super(true)
	
	protected override def Execute():
		_proc()

internal final class TWrapperThread(TThread):
	def constructor([Required] wrapped as Thread):
		super(wrapped)
	
	override def Execute():
		assert false
