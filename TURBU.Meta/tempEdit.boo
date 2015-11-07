namespace TURBU.Meta

import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro tempEdit(assignment as BinaryExpression, body as Statement*):
	raise "tempEdit macro requires an assignment expression" unless assignment.Operator == BinaryOperatorType.Assign
	yield ExpressionStatement(assignment)
	yieldAll body
	yield ExpressionStatement([|$(assignment.Right.CleanClone()) = $(assignment.Left.CleanClone())|])
