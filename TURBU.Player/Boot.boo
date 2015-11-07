namespace TURBU.Player

import System
import System.IO
import System.Linq.Enumerable
import TURBU.Engines
import TURBU.MapEngine
import TURBU.PluginInterface
import Boo.Lang.Compiler.Ast
import Boo.Lang.Parser

public def Boot(projectLocation as string) as IMapEngine:
	styleMap = {
		'MapEngine': TEngineStyle.Map,
		'BattleEngine': TEngineStyle.Battle,
		'MenuEngine': TEngineStyle.Menu,
		'Minigame': TEngineStyle.Minigame,
		'DataReader': TEngineStyle.Data
	}

	result as IMapEngine = null
	try:
		cu = BooParser.ParseFile(Path.Combine(projectLocation, 'boot.boo'))
		module = cu.Modules.First
		for ms in module.Globals.Statements.Cast[of MacroStatement]():
			style as TEngineStyle = styleMap[ms.Name]
			for line in ms.Body.Statements.Cast[of StringLiteralExpression]().Select({s | s.Value}):
				engine = TTurbuEngines.RetrieveEngine(style, line, turbu.versioning.TVersion(0, 0, 0))
				result = engine as IMapEngine if result is null
				result.RegisterDataReader(engine) if style == TEngineStyle.Data and result is not null
				result.RegisterBattleEngine(engine) if style == TEngineStyle.Battle and result is not null
	except e as Exception:
		raise "$projectLocation does not contain a valid TURBU boot file for this project: $(e.Message)"
	return result
	