namespace turbu.script.engine

import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Threading
import System.Threading.Tasks
import Boo.Lang.Useful.Attributes
import Pythia.Runtime
import timing
import TURBU.MapInterface
import TURBU.MapObjects
import turbu.containers
import TURBU.Meta

[Singleton]
class TScriptEngine(TObject):

	private FCurrentProgram as Boo.Lang.Compiler.CompilerContext

	private FScripts = List[of TRpgEventPage]()

	private FThreadLock as object

	private _inputId as int

	private _waiting = List[of KeyValuePair[of Func of bool, TaskCompletionSource of bool]]()

	private _altWaiting = List[of KeyValuePair[of Func of bool, TaskCompletionSource of bool]]()

	[Property(OnEnterCutscene)]
	private FEnterCutscene as Action

	[Property(OnLeaveCutscene)]
	private FLeaveCutscene as Action

	[Getter(Teleporting)]
	private _teleporting as bool

	// This is important, a way to give teleport scripts that continue after the teleport command
	// a chance to proceed, and potentially alter game state, before the new map's events fire based
	// on that game state.  Necessary for RM2K compatibility.  See Love and War, Legislature Cutscene
	// (map 83) for an example
	[Getter(Teleported)]
	private _teleported as bool

	[Property(OnRenderUnpause)]
	private FRenderUnpause as Action

	private FAllGlobalScripts as IDictionary[of int, TRpgEventPage]

	public def constructor():
		GScriptEngine.value = self
		FThreadLock = object()

	public def BeginTeleport():
		_teleporting = true

	public def EndTeleport():
		_teleporting = false
		_teleported = true

	internal def ResetTeleport():
		_teleported = false

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
			page.Parent.Locked = true
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
		get: return CurrentPage?.Parent

	public IsTeleportScript as bool:
		get: return System.Runtime.Remoting.Messaging.CallContext.LogicalGetData('IsTeleportScript') cast bool
		set: System.Runtime.Remoting.Messaging.CallContext.LogicalSetData('IsTeleportScript', value)

	[async]
	public def KillAll(cleanup as Action) as Task:
		for pair in _waiting:
			pair.Value.SetCanceled()
		_waiting.Clear()
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
			time = Math.Max(time, Timestamp.FrameLength)
			var ts = Timestamp(time)
			waitFor {ts.TimeRemaining == 0}
		ensure:
			FLeaveCutscene() if block

	[async]
	public def FramePause() as Task:
		FRenderUnpause()
		await Sleep(1, false)

	public def WaitTask(tcs as TaskCompletionSource of bool, cond as Func of bool) as Task:
		_waiting.Add(KeyValuePair[of Func of bool, TaskCompletionSource of bool](cond, tcs))
		return tcs.Task

	private _ticking as bool //teleporting can cause reentrancy here
	
	internal def Tick(killSet as HashSet[of TRpgMapObject]):
		return if _ticking
		
		assert _altWaiting.Count == 0
		_ticking = true
		var temp = _waiting
		_waiting = _altWaiting
		_altWaiting = temp
		if killSet.Count > 0:
			for pair in _altWaiting.ToArray():
				if killSet.Contains(pair.Value.Task.AsyncState cast TRpgMapObject):
					pair.Value.SetCanceled()
					_altWaiting.Remove(pair)
		for pair in _altWaiting:
			try:
				if pair.Key():
					pair.Value.SetResult(true)
				else: _waiting.Add(pair)
			except e as Exception:
				pair.Value.SetException(e)
		_altWaiting.Clear()
		_ticking = false


class TMapObjectManager(TObject):

	private FMapObjects = List[of TRpgMapObject]()

	private FGlobalScripts = List[of TRpgEventPage]()

	[Getter(ScriptEngine)]
	private FScriptEngine as TScriptEngine

	private FPlaylist = List[of TRpgEventPage]()

	private FKillSet = HashSet[of TRpgMapObject]()

	[Property(OnUpdate)]
	private FOnUpdate as Action

	[Property(InCutscene)]
	private FInCutscene as bool

	private _doneTeleportScript as Action

	public def constructor([Required] onTeleportDone as Action):
		FScriptEngine = TScriptEngine.Instance
		GMapObjectManager.value = self
		_doneTeleportScript = onTeleportDone

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
		FKillSet.Clear()
		for obj in FMapObjects:
			var isParallel = (obj.Playing and obj.CurrentPage.Trigger == TStartCondition.Parallel)
			if (not obj.Locked) and (isParallel or not obj.Playing):
				obj.UpdateCurrentPage()
				if assigned(obj.CurrentPage) and (obj.CurrentPage.HasScript) \
						and (obj.CurrentPage.Trigger in (TStartCondition.Automatic, TStartCondition.Parallel)):
					FPlaylist.Add(obj.CurrentPage) unless (isParallel and not obj.UpdatedFromParallel)
				if obj.Playing and obj.UpdatedFromParallel:
					FKillSet.Add(obj)
		for gPage in FGlobalScripts:
			gObj = gPage.Parent
			if (not (gObj.Locked or gObj.Playing)) and gPage.Valid:
				FPlaylist.Add(gPage)
		if assigned(FOnUpdate):
			FOnUpdate()
		FScriptEngine.Tick(FKillSet)
		if FScriptEngine.Teleported:
			FScriptEngine.ResetTeleport()
		else:
			unless FScriptEngine.Teleporting:
				for page in FPlaylist:
					RunPageScript(page)

	[async]
	public def RunPageScript(page as TRpgEventPage) as Task:
		return if page.Parent.Playing
		page.Parent.Playing = true
		FScriptEngine.IsTeleportScript = false
		await FScriptEngine.RunPageScript(page)
		if FScriptEngine.IsTeleportScript:
			self._doneTeleportScript()

static class GScriptEngine:
	public value as TScriptEngine

static class GMapObjectManager:
	public value as TMapObjectManager