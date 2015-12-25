namespace turbu.script.engine

import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Threading
import Boo.Adt
import Boo.Lang.Interpreter
import Boo.Lang.Useful.Attributes
import Pythia.Runtime
import timing
import TURBU.MapInterface
import TURBU.MapObjects
import turbu.containers
import TURBU.Meta
//import SDL2.SDL

[Disposable(Destroy, true)]
class TScriptThread(TThread):

	private FPages as Stack[of TRpgEventPage]

	internal FPage as TRpgEventPage

	private FParent as TScriptEngine

	internal FDelay as TRpgTimestamp

	internal FWaiting as Func of bool

	internal FSignal = System.Threading.EventWaitHandle(false, EventResetMode.ManualReset)

	internal FOnCleanup as Action

	internal def ScriptOnLine(Sender as InteractiveInterpreter):
		if (not self.Terminated) and assigned(FWaiting):
			repeat :
				Thread.Sleep(TRpgTimestamp.FrameLength)
				until self.Terminated or (FWaiting() == true)
			FWaiting = null
		elif assigned(FDelay):
			if FDelay.TimeRemaining > 0:
				ThreadSleep(Sender)
			else: FDelay = null
		if Terminated:
			Abort

	internal def InternalThreadSleep():
		let DELAY_SLICE = 50
		repeat :
			timeleft as uint = FDelay.TimeRemaining
			var sleeptime = Math.Min(DELAY_SLICE, timeleft cast int)
			System.Threading.Thread.Sleep(sleeptime)
			until timeleft == sleeptime or self.Terminated
		if Terminated:
			Abort

	private def ThreadSleep(Sender as InteractiveInterpreter):
		InternalThreadSleep()
		self.ScriptOnLine(Sender)

	internal def PushPage(value as TRpgEventPage):
		FPages = Stack[of TRpgEventPage]() if FPages == null
		FPages.Push(FPage)
		FPage = value

	internal def PopPage():
		FPage = FPages.Pop()

	protected override def Execute():
		try:
			while not Terminated:
				if FPage.Trigger != TStartCondition.Parallel:
					TScriptEngine.Instance.OnEnterCutscene()
				try:
					if FPage.Script is not null:
						FParent.RunScript(FPage.Script)
				ensure:
					Thread.Sleep(TRpgTimestamp.FrameLength)
					FPage.Parent.Playing = false
					if FPage.Trigger != TStartCondition.Parallel:
						TScriptEngine.Instance.OnLeaveCutscene()
					FSignal.Reset()
					if self == FParent.TeleportThread:
						self.Terminate()
					else: 
						FParent.SaveToPool(self)
						FSignal.WaitOne()
		ensure:
			self.Dispose()

	public def constructor(page as TRpgEventPage, parent as TScriptEngine):
		super(true)
		FPage = page
		FParent = parent
		parent.AddScriptThread(self)

	private def Destroy():
		FParent.ClearScriptThread(self)
		FSignal.Dispose()
		FOnCleanup.Invoke() if assigned(FOnCleanup)

	public CurrentObject as TRpgMapObject:
		get: return FPage.Parent

[Singleton]
class TScriptEngine(TObject):

//	private FCompiler as TrsCompiler

	private FExec as InteractiveInterpreter

	private FCurrentProgram as Boo.Lang.Compiler.CompilerContext

	private FThreads as List[of TScriptThread]

	private FThreadLock as object
	
	private _inputId as int

//	private FImports as (KeyValuePair[of string, TrsExecImportProc])

//	private FEnvProc as TRegisterEnvironmentProc

	[Property(OnEnterCutscene)]
	private FEnterCutscene as Action

	[Property(OnLeaveCutscene)]
	private FLeaveCutscene as Action

	private FThreadPool as Queue[of TScriptThread]

	[Property(TeleportThread)]
	private FTeleportThread as TScriptThread

	[Property(OnRenderUnpause)]
	private FRenderUnpause as Action

	internal def AddScriptThread(thread as TScriptThread):
		lock FThreadLock:
			FThreads.Add(thread)

	internal def ClearScriptThread(thread as TScriptThread):
		lock FThreadLock:
			FThreads.Remove(thread)
			if FTeleportThread == thread:
				FTeleportThread = null

	private def CreateExec():
		FExec = InteractiveInterpreter(RememberLastValue: true)
		/*
		FExec.OnDivideByZero = self.OnDivideByZero
		*/

/*
	private def OnRunLine(Sender as AbstractInterpreter, line as TrsDebugLineInfo):
		st as TScriptThread
		st = (TThread.CurrentThread cast TScriptThread)
		st.scriptOnLine(sender)
*/
	internal def GetThread(page as TRpgEventPage) as TScriptThread:
		lock FThreadLock:
			if FThreadPool.Count > 0:
				result = FThreadPool.Dequeue()
				result.FPage = page
				result.FSignal.Set()
			else:
				result = TScriptThread(page, self)
				result.Start()
		return result

	internal def SaveToPool(thread as TScriptThread):
		lock FThreadLock:
			FThreadPool.Enqueue(thread)

/*	private def RegisterImports():
		FCompiler.RegisterStandardUnit('media', RegisterMediaC)

	private def OnDivideByZero(Sender as InteractiveInterpreter, l as int, ref handled as bool) as int:
		result = l
		handled = true
		return result
*/
	public def constructor():
		GScriptEngine.value = self
		FThreads = List[of TScriptThread]()
		FThreadLock = object()
		FThreadPool = Queue[of TScriptThread]()

	public def RunScript(script as Action):
		script()

	public def RunScript(name as string, args as (object)):
		ctx = FExec.Eval(name)
		if ctx.Errors.Count > 0:
			raise ctx.Errors.ToString(false)
		(FExec.LastValue as callable).Call(args)

	public def RunObjectScript(obj as TRpgMapObject, page as int):
		var context = TThread.CurrentThread cast TScriptThread
		lPage as TRpgEventPage = obj.Pages[(page - 1)]
		assert assigned(context.FPage)
		context.PushPage(lPage)
		try:
			RunScript(lPage.Script)
		ensure:
			context.PopPage()

	public def KillAll(Cleanup as Action):
		return unless TThread.HasCurrentThread
		curr as TScriptThread
		
		def WakeAllThreads():
			thread as TScriptThread
			lock FThreadLock:
				FThreadPool.Clear()
				for thread in FThreads:
					if thread != curr:
						thread.Terminate()
						(thread cast TScriptThread).FSignal.Set()
						
		done as bool
		oldCleanup as Action
		lCleanup as Action
		curr = TThread.CurrentThread as TScriptThread
		if assigned(Cleanup):
			assert assigned(curr)
			if assigned(curr.FOnCleanup):
				oldCleanup = curr.FOnCleanup
				lCleanup = Cleanup
				Cleanup = def ():
					oldCleanup()
					lCleanup()
			curr.FOnCleanup = Cleanup
		WakeAllThreads()
		repeat :
			Thread.Sleep(10)
			WakeAllThreads()
			lock FThreadLock:
				done = ((curr == null) and (FThreads.Count == 0)) or ((FThreads.Count == 1) and (FThreads[0] == curr))
			if TThread.CurrentThread.IsMainThread:
				System.Windows.Forms.Application.DoEvents()
			until done

	public def AbortThread():
		curr as TThread = TThread.CurrentThread
		if curr isa TScriptThread:
			curr.Terminate()
			Abort

	public def ThreadSleep(time as int, block as bool):
		FRenderUnpause()
		st as TScriptThread = TThread.CurrentThread cast TScriptThread
		st.FDelay = TRpgTimestamp(time)
		FEnterCutscene() if block
		try:
			st.InternalThreadSleep()
		ensure:
			FLeaveCutscene() if block

	public def SetWaiting(value as Func of bool):
		FRenderUnpause()
		st = (TThread.CurrentThread cast TScriptThread)
		st.FWaiting = value

	public def ThreadWait():
		FRenderUnpause()
		st = TThread.CurrentThread cast TScriptThread
		try:
			st.ScriptOnLine(null)
		except as Pythia.Runtime.EAbort:
			pass

	public def Reset():
		FExec = null
		CreateExec()
		//RegisterImports

class TMapObjectManager(TObject):

	private FMapObjects = List[of TRpgMapObject]()

	private FGlobalScripts = List[of TRpgEventPage]()

	[Getter(ScriptEngine)]
	private FScriptEngine as TScriptEngine

	private FPlaylist = List[of TRpgEventPage]()

	[Property(OnUpdate)]
	private FOnUpdate as Action

	[Property(InCutscene)]
	private FInCutscene as bool

	public def constructor():
		FScriptEngine = TScriptEngine.Instance
		GMapObjectManager.value = self

	public def LoadGlobalScripts(list as TRpgObjectList[of TRpgMapObject]):
		assert FGlobalScripts.Count == 0
		for i in range(0, list.Count):
			page as TRpgEventPage = list[i].Pages[0]
			if page.Trigger != TStartCondition.Call:
				FGlobalScripts.Add(page)

	public def LoadMap(map as IRpgMap, context as TThread):
		FMapObjects.Clear()
		FMapObjects.AddRange(map.GetMapObjects().Cast[of TRpgMapObject]())

	public def Tick():
		FPlaylist.Clear()
		for obj in FMapObjects:
			obj.UpdateCurrentPage()
			if assigned(obj.CurrentPage) and (obj.CurrentPage.HasScript) and (not obj.Locked or obj.Playing) \
					and (obj.CurrentPage.Trigger in (TStartCondition.Automatic, TStartCondition.Parallel)):
				FPlaylist.Add(obj.CurrentPage)
		for page in FGlobalScripts:
			obj = page.Parent
			FPlaylist.Add(page) if (not (obj.Locked or obj.Playing)) and page.Valid
		if assigned(FOnUpdate):
			FOnUpdate()
		if FScriptEngine.TeleportThread == null:
			for page in FPlaylist:
				RunPageScript(page)

	public def RunPageScript(page as TRpgEventPage):
		return if page.Parent.Playing
		page.Parent.Playing = true
		thread as TScriptThread = FScriptEngine.GetThread(page)

static class GScriptEngine:
	public value as TScriptEngine

static class GMapObjectManager:
	public value as TMapObjectManager