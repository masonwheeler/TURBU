﻿namespace TURBU.Player

import System
import System.IO
import System.Linq.Enumerable
import System.Reflection
import System.Windows.Forms
import archiveInterface
import TURBU.EngineBasis
import TURBU.Engines
import TURBU.MapEngine
import TURBU.BattleEngine
import TURBU.DataReader
import TURBU.PluginInterface

partial class frmTURBUPlayer:
	private FDatabaseName as string
	
	private FMapEngine as IMapEngine
	
	[Property(Args)]
	private _args as (string)
	
	private _projectFolder as string
	
	private _destroyed as bool
	
	public def constructor():
		// The InitializeComponent() call is required for Windows Forms designer support.
		InitializeComponent()

	[Async]
	private def Destroy() as System.Threading.Tasks.Task:
		await TTurbuEngines.CleanupEngines()
		_destroyed = true

		//FMapEngine.Dispose() if FMapEngine is not null
		//_pluginManager.Dispose()
	
	private def FrmTURBUPlayerLoad(sender as object, e as System.EventArgs):
		self.ClientSize = System.Drawing.Size(960, 720)
		self.imgGame.OnAvailable = self.GameAvailable
	
	[Async]
	private def FrmTURBUPlayerClosing(sender as object, e as System.Windows.Forms.FormClosingEventArgs) as void:
		if not _destroyed:
			self.Hide()
			e.Cancel = true;
			await self.Destroy()
			self.Close()
	
	private def GameAvailable(sender as object, e as System.EventArgs):
		self.BeginInvoke(self.Available)
		
	private def Available():
		try:
			Boot()
			project.folder.GProjectFolder.value = _projectFolder
			FMapEngine.Initialize(imgGame.SdlWindow, FDatabaseName)
		except e as Exception:
			MessageBox.Show(e.ToString())
			raise
		FMapEngine.Start()
	
	private def Boot():
		_projectFolder = GetProject()
		FDatabaseName = Path.Combine(_projectFolder, 'Database')
		OpenArchive(MAP_DB, MAP_ARCHIVE, true)
		OpenArchive(IMAGE_DB, IMAGE_ARCHIVE, true)
		OpenArchive(SCRIPT_DB, SCRIPT_ARCHIVE, true)
		OpenArchive(MUSIC_DB, MUSIC_ARCHIVE, false)
		OpenArchive(SFX_DB, SFX_ARCHIVE, true)
		OpenArchive(VIDEO_DB, VIDEO_ARCHIVE, false)

		LoadEngines()
		FMapEngine = BootModule.Boot(_projectFolder)
		raise "Project boot file does not contain a map engine" if FMapEngine is null
	
	private def OpenArchive(folderName as string, index as int, required as bool):
		pathName = Path.Combine(_projectFolder, folderName)
		unless Directory.Exists(pathName):
			if required:
				raise FileNotFoundException("Required folder '$folderName' does not exist")
			else: Directory.CreateDirectory(pathName)
		GArchives.Add(DiscArchive.OpenFolder(pathName))
		assert GArchives.Count - 1 == index
	
	private def CurrentFolder() as string:
		return Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location)
		
	private def GetProject() as string:
		if self._args.Length == 0:
			return CurrentFolder()
		else: return _args[0]
	
	private def LoadEngines():
		var beforeList = AppDomain.CurrentDomain.GetAssemblies()
		for filename in Directory.EnumerateFiles(_projectFolder, '*.dll')\
				.Union(Directory.EnumerateFiles(CurrentFolder(), '*.dll'))\
				.Where({f | IsDotNetAssembly(f)})\
				.Where({f | not AppDomain.CurrentDomain.GetAssemblies().Select({a | a.Location}).Contains(f)}):
			try:
				Assembly.LoadFrom(filename)
			except as BadImageFormatException: //if this is not a valid assembly, ignore it
				pass
		for module in AppDomain.CurrentDomain.GetAssemblies().Except(beforeList).SelectMany({a | a.Modules}):
			System.Runtime.CompilerServices.RuntimeHelpers.RunModuleConstructor(module.ModuleHandle)
		for engine in Jv.PluginManager.GPluginManager:
			LoadEngine(engine)
	
	private def LoadEngine(data as TEngineData):
		base = data.Engine.Create()
		if data.Style == TEngineStyle.Map:
			mapEngine = base cast IMapEngine
			TTurbuEngines.AddEngine(data.Style, mapEngine.Data, mapEngine)
		elif data.Style == TEngineStyle.Battle:
			battleEngine = base cast IBattleEngine
			TTurbuEngines.AddEngine(data.Style, battleEngine.Data, battleEngine)
		elif data.Style == TEngineStyle.Data:
			dataEngine = base cast IDataReader
			TTurbuEngines.AddEngine(data.Style, dataEngine.Data, dataEngine)
		else: raise "Engine style '$(Enum.GetName(TEngineStyle, data.Style))' is not supported yet."

[STAThread]
public def Main(argv as (string)) as void:
	Application.EnableVisualStyles()
	Application.SetCompatibleTextRenderingDefault(false)
	player = frmTURBUPlayer(Args: argv)
	try:
		var env = Environments.CachingEnvironment(Environments.ClosedEnvironment())
		Environments.ActiveEnvironment.With(env, {Application.Run(player)} )
	except e as Exception:
		MessageBox.Show(e.Message)
	ensure:
		player.Dispose()
