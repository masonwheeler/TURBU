namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro Terrains(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgTerrain]]*:
			pass
	|]
	arr = ArrayLiteralExpression()
	arr.Items.AddRange(body.Select({e | e.Expression}))
	result.Body.Statements.Add([|return $(arr)|])
	result.Accept(EnumFiller( {'Concealment': [|TConcealmentFactor|]} ))
	yield result
	yield ExpressionStatement([|Data()|])
	yield [|import turbu.terrain|]

macro Terrains.Terrain(index as IntegerLiteralExpression, body as ExpressionStatement*):
	macro Vehicles(value as BoolLiteralExpression*):
		return MakeArrayValue('VehiclePass', value)
	
	return Lambdify('TRpgTerrain', index, body)