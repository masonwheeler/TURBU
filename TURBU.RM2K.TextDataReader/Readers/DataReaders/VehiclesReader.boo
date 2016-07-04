namespace TURBU.RM2K.TextDataReader.Readers.DataReaders

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching
import TURBU.RM2K.TextDataReader.Readers

macro Vehicles(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TVehicleTemplate]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller( {'MovementStyle': [|TMovementStyle|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.characters|]
	yield [|import turbu.sounds|]

macro Vehicles.Vehicle(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Sprite(name as string, id as int):
		Vehicle.Body.Add([|MapSprite($name)|])
		Vehicle.Body.Add([|SpriteIndex($id)|])
	
	macro Music(name as string, v1 as int, v2 as int, v3 as int, v4 as int):
		return ExpressionStatement([|Music(TRpgMusic($name, $v1, $v2, $v3, $v4))|])
		
	return Lambdify('TVehicleTemplate', index, body)