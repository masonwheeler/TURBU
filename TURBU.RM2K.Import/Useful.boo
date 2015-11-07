namespace TURBU.RM2K.Import

import Boo.Lang.Compiler.Ast

def ListOf(values as (byte)) as ListLiteralExpression:
	result = ListLiteralExpression()
	result.Items.AddRange(Expression.Lift(value) for value in values)
	return result
