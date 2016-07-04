namespace TURBU.RM2K.TextDataReader.BSONReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import Newtonsoft.Json.Linq
import turbu.defs

macro Sound(name as string, fadeIn as int, volume as int, tempo as int, balance as int):
	return JsonStatement(JProperty('Sound', JArray(name, fadeIn, volume, tempo, balance)))

macro Song(name as string, fadeIn as int, volume as int, tempo as int, balance as int):
	return JsonStatement(JProperty('Song', JArray(name, fadeIn, volume, tempo, balance)))

internal def BuildPlaylist(resName as string, body as ExpressionStatement*, enumType as Type):
	for value in body.Select({e | e.Expression}).Cast[of MethodInvocationExpression]():
		var target = value.Target.ToString()
		var args = value.Arguments
		var result = JObject()
		result['ID'] = Enum.Parse(enumType, target) cast int
		result['Name'] = ExpressionValue(args[0])
		result['FadeIn'] = ExpressionValue(args[1])
		result['Tempo'] = ExpressionValue(args[2])
		result['Balance'] = ExpressionValue(args[3])
		result['Volume'] = ExpressionValue(args[4])
		AddResource(resName, result)

macro SystemSounds(body as ExpressionStatement*):
	BuildPlaylist('SysSounds', body, TSfxTypes)

macro SystemMusic(body as ExpressionStatement*):
	BuildPlaylist('SysMusic', body, TBgmTypes)
