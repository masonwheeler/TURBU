namespace LCF_Parser

import System
import System.Collections.Generic
import System.IO
import System.Linq
import Boo.Adt
import Boo.Lang.Compiler.Ast
import commons
import Pythia.Runtime
import SDL2.SDL
import SDL2.SDL_image
import TURBU.Design.Optimizations
import TURBU.Meta
import TURBU.RM2K.Import
import TURBU.RM2K.Import.LCF

[Disposable(Destroy)]
class RMProjectConverter(TThread):
	private _outputPath as string
	private _projectFolder as string
	private _rtpLocation as string
	private _2k3 as bool
	private _ldb as LDB
	private _lmt as LMT
	private _report as IConversionReport
	private _scripts as string
	private _database as string
	private _everything = Block()

	public def constructor(rmProject as string, outputPath as string, progress as IConversionReport):
		_projectFolder = rmProject
		_outputPath = outputPath
		_report = progress
		super()
		SDL_Init(SDL_INIT_NOPARACHUTE)
		IMG_Init(IMG_InitFlags.IMG_INIT_PNG)
	
	private def Destroy():
		IMG_Quit()
		SDL_Quit()
	
	converter:
		task "Loading Project Files":
			using fs = FileStream(Path.Combine(_projectFolder, 'RPG_RT.LDB'), FileMode.Open):
				_2k3 = DatabaseVersion(fs) == 2003
				LCFWord.Is2k3 = _2k3
				_ldb = LDB(fs)
			using fs = FileStream(Path.Combine(_projectFolder, 'RPG_RT.LMT'), FileMode.Open):
				_lmt = LMT(fs)
			_scripts = Path.Combine(_outputPath, 'Scripts')
			Directory.CreateDirectory(_scripts)
			_database = Path.Combine(_outputPath, 'Database')
			Directory.CreateDirectory(_database)
			if _2k3:
				_rtpLocation = GetRegistryValue('Software\\Enterbrain\\RPG2003', 'RuntimePackagePath')
			else: _rtpLocation = GetRegistryValue('Software\\ASCII\\RPG2000', 'RuntimePackagePath')
			if string.IsNullOrEmpty(_rtpLocation):
				raise "Unable to locate the RTP for this project"
		
		task "Converting Map Tree":
			_mapTree = TMapTreeConverter.ConvertMapTree(_lmt)
			_everything.Add(MapTreeResources(_mapTree))
			File.WriteAllText(Path.Combine(_database, 'MapTree.tdb'), _mapTree.ToCodeString())
		
		task "Converting Maps", files = Directory.EnumerateFiles(_projectFolder, '*.lmu').ToArray(), files.Length:
			maps = Path.Combine(_outputPath, 'Maps')
			Directory.CreateDirectory(maps)
			let invalidChars = Path.GetInvalidFileNameChars()
			for filename in Directory.EnumerateFiles(_projectFolder, '*.lmu'):
				break if self.Terminated
				_report.NewStep(Path.GetFileName(filename))
				using fs = FileStream(filename, FileMode.Open):
					lmu = LMU(fs)
					TMapConverter.ConvertMap(lmu, _lmt, IDFromFilename(filename), _report, ScanScriptForResources) do(mapName as string, map as Node, script as Node):
						mapName = string(mapName.Where({x | not invalidChars.Contains(x)}).ToArray())
						File.WriteAllText(Path.Combine(maps, "$mapName.tmf"), map.ToCodeString())
						File.WriteAllText(Path.Combine(_scripts, "$mapName.boo"), script.ToScriptString())
						_everything.Add(MapResources(map cast MacroStatement))
		
		task "Converting Database", TDatabaseConverter.STEPS:
			TDatabaseConverter.Convert(_ldb, _database, _scripts, _everything, _report, _2k3, {return self.Terminated},
												self.ScanScriptForResources)
		
		task "Copying Resources":
			grouping = _everything.Statements.Cast[of MacroStatement]().Distinct(MacroComparer())\
				.ToLookup({m | m.Name}, {m | (m.Arguments[0] cast StringLiteralExpression).Value})
			for group in grouping: //sanity check
				raise "Unknown resource type: $(group.Key)" unless group.Key in RES_TYPES
			SaveEngines(grouping.Where({g | g.Key.EndsWith('Engine')}))
			SaveResources(grouping['Music'], 'Music', 'Music', SOUND_TYPES)
			SaveResources(grouping['Sound'], 'Sound', 'Sound', SOUND_TYPES)
			SaveResources(grouping['Movie'], 'Movie', 'Movies', MOVIE_TYPES)
			SaveImageResources(grouping['Sprite'], 'CharSet', 'Sprites')
			SaveImageResources(grouping['Portrait'], 'FaceSet', 'Portraits')
			SaveImageResources(grouping['Background'], 'Panorama', 'Backgrounds')
			SaveImageResources(grouping['BattleBG'], 'Backdrop', 'BattleBGs')
			SaveImageResources(grouping['Picture'], 'Picture', 'Pictures')
			SaveImageResources(grouping['Frame'], 'Frame', 'Frames')
			SaveImageResources(grouping['Monster'], 'Monster', 'Monsters')
			SaveImageResources(grouping['SysTile'], 'System', 'SysTiles')
			SaveImageResources(grouping['Anim'], 'Battle', 'Animations')
			SaveImageResources(grouping['BattleSprite'], 'BattleCharSet', 'BattleSprites')
			SaveImageResources(grouping['BattleWeapon'], 'BattleWeapon', 'BattleWeapons')
			SaveImageResources((_ldb.SysData.TitleScreen,), 'Title', 'Special Images')
			SaveImageResources((_ldb.SysData.GameOverScreen,), 'GameOver', 'Special Images')
			SaveImageResources((_ldb.SysData.BattleSysGraphic,), 'System2', 'System2') if _2k3
			tileGroups = SaveTilesets(grouping['Tileset'])
			File.WriteAllText(Path.Combine(self._database, 'TileGroups.tdb'), tileGroups.ToCodeString())
			exePath = Path.GetDirectoryName(System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName)
			glyphPath = Path.Combine(_outputPath, 'Images', 'SysTiles', 'Glyphs')
			Directory.CreateDirectory(glyphPath)
			File.Copy(Path.Combine(exePath, 'resources', 'glyphs.png'), Path.Combine(glyphPath, 'glyphs.png'))
		
		task "Building TURBU package":
			exePath = Path.GetDirectoryName(System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName)
			RunBake(_outputPath, exePath, _lmt.Maps[0].Name)
	
	private static final RES_TYPES = HashSet[of string](('Music', 'Sound', 'Movie', 'Sprite', 'Portrait',
		'Background', 'BattleBG', 'Picture', 'Frame', 'Monster', 'SysTile', 'Tileset', 'Anim', 'BattleSprite',
		'MapEngine', 'BattleEngine', 'BattleWeapon'))
	
	private static final IMG_TYPES = HashSet[of string](('.png', '.bmp', '.xyz'))
	private static final SOUND_TYPES = HashSet[of string](('.mid', '.wav', '.ogg', '.mp3', '.it', '.xm', '.s3m', '.mod'))
	private static final MOVIE_TYPES = HashSet[of string](('.avi', '.mpg'))
	
	private def SaveImageResources(values as string*, fromPath as string, toPath as string):
		for value in values:
			continue if string.IsNullOrEmpty(value)
			loc = LocateFileGeneral(value, fromPath, IMG_TYPES)
			if loc is null:
				_report.MakeError("Unable to locate file $(fromPath)\\$value.", 2)
			else:
				outPath = Path.Combine(_outputPath, 'Images', toPath)
				Directory.CreateDirectory(outPath)
				dest = Path.ChangeExtension(Path.Combine(outPath, Path.GetFileName(loc)), '.png')
				caseOf Path.GetExtension(loc).ToLowerInvariant():
					case '.png': File.Copy(loc, dest)
					case '.bmp': CopyBMP(loc, dest)
					case '.xyz': CopyXYZ(loc, dest)
	
	private def SaveResources(values as string*, fromPath as string, toPath as string, extensions as HashSet[of string]):
		for value in values:
			continue if string.IsNullOrEmpty(value) or (value == '(OFF)' and fromPath in ('Music', 'Sound'))
			loc = LocateFileGeneral(value, fromPath, extensions)
			if loc is null:
				_report.MakeError("Unable to locate file $(fromPath)\\$value.", 2)
			else: 
				outPath = Path.Combine(_outputPath, toPath)
				Directory.CreateDirectory(outPath)
				File.Copy(loc, Path.Combine(outPath, Path.GetFileName(loc)))
	
	private def SaveTilesets(values as string*) as MacroStatement:
		outPath = Path.Combine(_outputPath, 'Images', 'Tilesets')
		Directory.CreateDirectory(outPath)
		result = MacroStatement('TileGroups')
		for value in values:
			loc = LocateFileGeneral(value, 'ChipSet', IMG_TYPES)
			if loc is null:
				_report.MakeError("Unable to locate file ChipSet\\$value.", 2)
			else: result.Body.Statements.AddRange(ConvertTileset(loc, outPath))
		return result
	
	private def LocateFileGeneral(filename as string, fromPath as string, extensions as HashSet[of string]) as string:
		result = LocateFileSpecific(Path.Combine(_projectFolder, fromPath), filename, extensions)
		return result unless result is null
		result = LocateFileSpecific(Path.Combine(_rtpLocation, fromPath), filename, extensions)
		_report.MakeNotice("Used RTP resource $fromPath\\$(Path.GetFileName(filename)), which may not be legal", 2) unless result is null
		return result
	
	private def LocateFileSpecific(dir as string, filename as string, extensions as HashSet[of string]) as string:
		return null unless Directory.Exists(dir)
		return Directory.EnumerateFiles(dir, filename + '.*').FirstOrDefault({f | Path.GetExtension(f) in extensions})
	
	private def CopyBMP(filename as string, destination as string):
		System.Drawing.Bitmap.FromFile(filename).Save(destination, System.Drawing.Imaging.ImageFormat.Png)
	
	private def CopyXYZ(filename as string, destination as string):
		XYZImage(filename).Save(destination, System.Drawing.Imaging.ImageFormat.Png)
	
	private def SaveEngines(engines as IGrouping[of string, string]*):
		values = Block()
		for engine in engines:
			grp = MacroStatement(engine.Key)
			values.Add(grp)
			for value in engine:
				grp.Body.Add(Expression.Lift(value)) unless string.IsNullOrEmpty(value)
		grp = MacroStatement('DataReader')
		grp.Body.Add([|'Compiled Data Reader'|])
		values.Add(grp)
		File.WriteAllText(Path.Combine(_outputPath, "boot.boo"), values.ToCodeString())
	
	private static final OPCODES = HashSet[of int]((10130, 10630, 10640, 10650, 10660, 10670, 10680, 10710, 11110,
																	11510, 11550, 11560, 11720))
	
	private def ScanScriptForResources(script as EventCommand*):
		for opcode in script.Where({o | OPCODES.Contains(o.Opcode)}):
			ConvertOpcode(opcode)
	
	private def ConvertOpcode(opcode as EventCommand):
		caseOf opcode.Opcode:
			case 10130, 10640: _everything.Add([|Portrait $(opcode.Name)|])
			case 10630, 10650: _everything.Add([|Sprite $(opcode.Name)|])
			case 10660, 11510: 
				_everything.Add([|Music $(opcode.Name)|])
			case 10670, 11550: _everything.Add([|Sound $(opcode.Name)|])
			case 10680: _everything.Add([|SysTile $(opcode.Name)|])
			case 10710: _everything.Add([|BattleBG $(opcode.Name)|])
			case 11110: _everything.Add([|Picture $(opcode.Name)|])
			case 11560: _everything.Add([|Movie $(opcode.Name)|])
			case 11720: _everything.Add([|Background $(opcode.Name)|])
			default: assert false
	
	private static def MapResources(map as MacroStatement) as Block:
		mre = MapResourceExtractor()
		map.Accept(mre)
		return mre.Result
	
	private static def MapTreeResources(tree as MacroStatement) as Block:
		mtre = MapTreeResourceExtractor()
		tree.Accept(mtre)
		return mtre.Result
	
	private static def IDFromFilename(filename as string) as int:
		filename = Path.GetFileNameWithoutExtension(filename)
		num = filename[-4:]
		return int.Parse(num)
	
macro converter:
	macro task(name as string, init as Expression*):
		tasks = converter['tasks'] as List[of Method]
		if tasks is null:
			tasks = List[of Method]()
			converter['tasks'] = tasks
		taskName = "Task$((tasks.Count + 1).ToString('D2'))"
		result = Method(taskName)
		inits = init.ToArray()
		if inits.Length == 0:
			sct = [|_report.SetCurrentTask($name)|]
		else:
			lenExpr = inits[-1]
			sct = [|_report.SetCurrentTask($name, $lenExpr)|]
			for expr in inits[:-1]:
				result.Body.Add(expr)
		result.Body.Add(sct)
		result.Body.Add(task.Body)
		tasks.Add(result)
	
	tasks = converter['tasks'] as List[of Method]
	result = [|
		override protected def Execute():
			_report.Initialize(self, $(tasks.Count))
	|]
	tryBlock = [|
		try:
			pass
		except e as Exception:
			_report.Fatal(e)
	|]
	for task in tasks:
		yield task
		tryBlock.ProtectedBlock.Add([|$task()|])
		tryBlock.ProtectedBlock.Add([|return if self.Terminated|])
	result.Body.Add(tryBlock)
	result.Body.Add([|_report.MakeReport('Conversion Log.txt')|])
	yield result

internal class MacroComparer(IEqualityComparer[of MacroStatement]):
	def Equals(x as MacroStatement, y as MacroStatement) as bool:
		return x.Name.Equals(y.Name) and \
			(x.Arguments[0] cast StringLiteralExpression).Value.ToUpperInvariant().Equals(
			(y.Arguments[0] cast StringLiteralExpression).Value.ToUpperInvariant())
		
	def GetHashCode(obj as MacroStatement):
		arg = (obj.Arguments[0] cast StringLiteralExpression).Value
		return obj.Name.GetHashCode() ^ (arg.ToUpperInvariant().GetHashCode() if arg is not null else 0)
