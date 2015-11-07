namespace TURBU.RM2K

import System
//import Boo.Lang.Compiler.Ast

class Lookup(System.Attribute):
"""Denotes that an int param is an index into a DB table"""
	
	private _target as string
	
	public def constructor(target as string):
		_target = target

