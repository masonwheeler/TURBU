namespace TURBU.RM2K.TextDataReader.Readers

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast

macro Vocab(body as ExpressionStatement*):
	result = [|
		def Data() as System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgVocabDictionary]]*:
			result = TRpgVocabDictionary()
	|]
	for bin in body.Select({es | es.Expression}).Cast[of BinaryExpression]():
		assert bin.Operator = BinaryOperatorType.Assign
		result.Body.Add([|result.Vocab.Add($(bin.Left), $(bin.Right))|])
	result.Body.Add([|return (System.Collections.Generic.KeyValuePair[of int, System.Func[of TRpgVocabDictionary]](0, {return result}),)|])
	yield result
	yield ExpressionStatement([|Data()|])
