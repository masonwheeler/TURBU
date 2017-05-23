namespace turbu.script.engine

import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Threading
import System.Threading.Tasks
import Boo.Adt
import Boo.Lang.Useful.Attributes
import Pythia.Runtime
import timing
import TURBU.MapInterface
import TURBU.MapObjects
import turbu.containers
import TURBU.Meta
//import SDL2.SDL

[Singleton]
class TScriptEngine(TObject):

//	private FCompiler as TrsCompiler

	private FCurrentProgram as Boo.Lang.Compiler.CompilerContext

	private FScripts = List[of TRpgEventPage]()

	private FThreadLock as object

	private _inputId as int

	private _waiting = List[of KeyValuePair[of Func of bool, TaskCompletionSource of bool]]()

	private _altWaiting = List[of KeyValuePair[of Func of bool, TaskCompletionSource of bool]]()

	private _cancelTokenSource = CancellationTokenSource()

	[Property(OnEnterCutscene)]
	private FEnterCutscene as Action

	[Property(OnLeaveCutscene)]
	private FLeaveCutscene as Action

	[Property(Teleporting)]
	private FTeleporting as bool

	[Property(OnRenderUnpause)]
	private FRenderUnpause as Action

	private FAllGlobalScripts as IDictionary[of int, TRpgEventPage]

	public def constructor():
		GScriptEngine.value = self
		FThreadLock = object()

	[async]
	public def RunScript(script as Func of Task) as Task:
		var scriptTask = script()
		scriptTask.ConfigureAwait(true)
		await scriptTask

	[async]
	public def RunObjectScript(obj as TRpgMapObject, page as int) as Task:
		var context = CurrentPage
		lPage as TRpgEventPage = obj.Pages[page - 1]
		assert assigned(context)
		try:
			CurrentPage = lPage
			await RunScript(lPage.Script)
		ensure:
			CurrentPage = context

	[async]
	internal def RunPageScript(page as TRpgEventPage) as Task:
		FScripts.Add(page)
		CurrentPage = page
		page.Parent.FaceHero()
		if page.Trigger != TStartCondition.Parallel:
			self.OnEnterCutscene()
		try:
			await RunScript(page.Script)
		except as EAbort:
			pass
		ensure:
			FScripts.Remove(page)
			page.Parent.Playing = false
			page.Parent.ResumeFacing()
			if page.Trigger != TStartCondition.Parallel:
				self.OnLeaveCutscene()

	internal def LoadGlobals(list as TRpgMapObject*):
		FAllGlobalScripts = list.ToDictionary({o | o.ID}, {o | o.Pages[0]})

	public def CallGlobalScript(id as int):
		page as TRpgEventPage
		if FAllGlobalScripts.TryGetValue(id, page):
			CurrentPage = page
			RunScript(page.Script)

	private CurrentPage as TRpgEventPage:
		get: return System.Runtime.Remoting.Messaging.CallContext.LogicalGetData('CurrentPage') cast TRpgEventPage
		set: System.Runtime.Remoting.Messaging.CallContext.LogicalSetData('CurrentPage', value)

	public CurrentObject as TRpgMapObject:
		get: return CurrentPage.Parent

	[async]
	public def KillAll(cleanup as Action) as Task:
		self._cancelTokenSource.Cancel(true)
		CancelWaiting()
		_cancelTokenSource = CancellationTokenSource()
		var done = false
		repeat :
			await Task.Delay(10)
			lock FThreadLock:
				done = ((CurrentPage == null) and (FScripts.Count == 0)) or ((FScripts.Count == 1) and (FScripts[0] == CurrentPage))
			until done
		cleanup() if cleanup != null

	[async]
	public def Sleep(time as int, block as bool) as Task:
		FRenderUnpause()
		FEnterCutscene() if block
		try:
			await(Task.Delay(Math.Max(time, TRpgTimestamp.FrameLength), _cancelTokenSource.Token))
		ensure:
			FLeaveCutscene() if block

	[async]
	public def FramePause() as Task:
		FRenderUnpause()
		await Sleep(1, false)

	public def WaitTask(tcs as TaskCompletionSource of bool, cond as Func of bool) as Task:
		_waiting.Add(KeyValuePair[of Func of bool, TaskCompletionSource of bool](cond, tcs))
		return tcs.Task

	internal def Tick():
		assert _altWaiting.Count == 0
		var temp = _waiting
		_waiting = _altWaiting
		_altWaiting = temp
		for pair in _altWaiting:
			try:
				if pair.Key():
					pair.Value.SetResult(true)
				else: _waiting.Add(pair)
			except e as Exception:
				pair.Value.SetException(e)
		_altWaiting.Clear()

	private def CancelWaiting():
		for pair in _waiting:
			pair.Value.SetCanceled()
		_waiting.Clear()

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
		for obj in list:
			obj.Initialize()
		FGlobalScripts.AddRange(list.Select({o | o.Pages[0]}).Where({p | p.Trigger != TStartCondition.Call}))
		FScriptEngine.LoadGlobals(list)

	public def LoadMap(map as IRpgMap):
		FMapObjects.Clear()
		FMapObjects.AddRange(map.GetMapObjects().Cast[of TRpgMapObject]())

	public def Tick():
		FPlaylist.Clear()
		for obj in FMapObjects:
			unless obj.Locked or obj.Playing:
				obj.UpdateCurrentPage()
				if assigned(obj.CurrentPage) and (obj.CurrentPage.HasScript) \
						and (obj.CurrentPage.Trigger in (TStartCondition.Automatic, TStartCondition.Parallel)):
					FPlaylist.Add(obj.CurrentPage)
		for gPage in FGlobalScripts:
			gObj = gPage.Parent
			if (not (gObj.Locked or gObj.Playing)) and gPage.Valid:
				FPlaylist.Add(gPage)
		if assigned(FOnUpdate):
			FOnUpdate()
		FScriptEngine.Tick()
		unless FScriptEngine.Teleporting:
			for page in FPlaylist:
				RunPageScript(page)

	[async]
	public def RunPageScript(page as TRpgEventPage) as Task:
		return if page.Parent.Playing
		page.Parent.Playing = true
		FScriptEngine.RunPageScript(page)

static class GScriptEngine:
	public value as TScriptEngine

static class GMapObjectManager:
	public value as TMapObjectManager