namespace commons

import System
import Microsoft.Win32
import Boo.Adt
import SG.defs

class EFatalError(Exception):
	def constructor(msg as string):
		super(msg)

def GetRegistryValue(KeyName as string, valueName as string) as string:
	using rootKey = Registry.CurrentUser.OpenSubKey(KeyName, false):
		return ('' if rootKey is null else rootKey.GetValue(valueName).ToString())

def SetRegistryValue(KeyName as string, valueName as string, value as string):
	using rootKey = Registry.CurrentUser.OpenSubKey(KeyName, true):
		return if rootKey is null
		rootKey.SetValue(valueName, value)

def IsBetween(number as int, low as int, high as int) as bool:
	return ((number >= low) and (number <= high))

def round(value as double) as int:
	if value >= 0:
		result = Math.Truncate(value + 0.5)
	else:
		result = Math.Truncate(value - 0.5)
	return result

def clamp(ref value as single, low as single, high as single):
	value = Math.Min(high, Math.Max(low, value))

def clamp(number as int, low as int, high as int) as int:
	return Math.Min(Math.Max(number, low), high)

static class GCurrentFolder:
	public value as string

let ORIGIN = sgPoint(0, 0)
let NULLRECT = SDL2.SDL2_GPU.GPU_MakeRect(0, 0, 0, 0)
let MULTIPLIER_31 = 8.22580645161
