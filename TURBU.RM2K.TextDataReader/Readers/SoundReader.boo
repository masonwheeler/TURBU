namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast

macro Sound(name as StringLiteralExpression, fadeIn as IntegerLiteralExpression, volume as IntegerLiteralExpression, tempo as IntegerLiteralExpression, balance as IntegerLiteralExpression):
	return ExpressionStatement([|Sound(turbu.sounds.TRpgSound($name, $fadeIn, $volume, $tempo, $balance))|])

macro Song(name as StringLiteralExpression, fadeIn as IntegerLiteralExpression, volume as IntegerLiteralExpression, tempo as IntegerLiteralExpression, balance as IntegerLiteralExpression):
	return ExpressionStatement([|Song(turbu.sounds.TRpgMusic($name, $fadeIn, $volume, $tempo, $balance))|])

macro SystemSounds(body as ExpressionStatement*):
	data = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgSound]]*:
			pass
	|]

	for value in body.Select({e | e.Expression}).Cast[of MethodInvocationExpression]():
		target = value.Target
		args = value.Arguments
		lambda = [|{return turbu.sounds.TRpgSound($(args[0]), $(args[1]), $(args[2]), $(args[3]), $(args[4]), ID: TSfxTypes.$target)}|]
		pair = [|System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgSound]](TSfxTypes.$target, $lambda)|]
		data.Body.Add([|yield $pair|])
	yield data
	yield ExpressionStatement([|Data()|])

macro SystemMusic(body as ExpressionStatement*):
	data = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgMusic]]*:
			pass
	|]

	for value in body.Select({e | e.Expression}).Cast[of MethodInvocationExpression]():
		target = value.Target
		args = value.Arguments
		lambda = [|{return turbu.sounds.TRpgMusic($(args[0]), $(args[1]), $(args[2]), $(args[3]), $(args[4]), ID: TBgmTypes.$target)}|]
		pair = [|System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgMusic]](TBgmTypes.$target, $lambda)|]
		data.Body.Add([|yield $pair|])
	yield data
	yield ExpressionStatement([|Data()|])
