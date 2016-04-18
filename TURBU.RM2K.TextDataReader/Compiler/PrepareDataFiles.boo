namespace TURBU.RM2K.TextDataReader.Compiler

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

class PrepareDataFiles(AbstractTransformerCompilerStep):
	_pbp as string
	
	override def Run():
		var defs = Context.Parameters.Defines
		raise "ProjectBasePath not defined" unless defs.TryGetValue('ProjectBasePath', _pbp)
		_pbp += '\\'
		super.Run()
	
	override def OnModule(node as Module):
		var filename = node.LexicalInfo.FileName
		return unless filename.StartsWith(_pbp)
		var relativeFN = filename[_pbp.Length:]
		var pathSegments = relativeFN.Split(*(System.IO.Path.DirectorySeparatorChar,))
		return unless pathSegments.Length == 2
		return unless string.Intern(pathSegments[0]) in ('Maps', 'Scripts', 'Database')
		if pathSegments[1].EndsWith('.boo') or pathSegments[1].EndsWith('.tmf'):
			AddImports(node, ("TURBU.RM2K.TextDataReader.Readers", "Pythia.Runtime", "turbu.defs", "turbu.maps", "SG.defs", "TURBU.BattleEngine", "TURBU.MapObjects", "TURBU.Meta", "TURBU.RM2K.RPGScript"))
		elif pathSegments[1].EndsWith('.tdb'):
			AddImports(node, ("TURBU.RM2K.TextDataReader.Readers", "Pythia.Runtime", "turbu.defs", "SG.defs"))
	
	private def AddImports(mod as Module, imports as string*) as void:
		mod.Imports.AddRange(imports.Select( {i | Import(i, IsSynthetic: true)} ))

