namespace turbu.decl.utils

import Boo.Adt
import System
import turbu.classes
import System.Collections.Generic

enum TScriptSignature:
	ssNone
	ssScriptEvent
	ssDamageCalcEvent
	ssToHitEvent
	ssCondOnTurnEvent
	ssExpCalc
	ssSkillCheck

def signatureMatch(func as TRpgDecl) as string:
	iterator as KeyValuePair[of string, TRpgDecl]
	for iterator in sigDict:
		if func.equals(iterator.Value):
			return iterator.Key
	return ''

def GetSignature(Event as string) as TRpgDecl:
	result as TRpgDecl
	if not sigDict.TryGetValue(Event, result):
		result = null
	return result

let sigDict = Dictionary[of string, TRpgDecl]()