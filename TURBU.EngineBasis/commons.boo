namespace commons

import System
import System.Windows.Forms
import System.IO
import Microsoft.Win32
import Boo.Adt
import Boo.Lang.Compiler
import Pythia.Runtime
import SG.defs

class EParseMessage(Exception):
	def constructor(msg as string):
		super(msg)

class EFatalError(Exception):
	def constructor(msg as string):
		super(msg)

class EMessageAbort(Exception):

	public def constructor():
		super('')

def powerWrap(base as int, exponent as int) as int:
	exp as double
	dummy as double
	exp = exponent
	dummy = Math.Pow(base, exp)
	return Math.Truncate(dummy)

def MsgBox(text as string, caption as string, Flags as ushort) as DialogResult:
	result as DialogResult
	closure = {result = System.Windows.Forms.MessageBox.Show(text, caption)}
	ct = TThread.CurrentThread
	if not ct.IsMainThread:
		TThread.Synchronize(closure)
	else:
		closure()
	return result

def GetRegistryValue(KeyName as string, valueName as string) as string:
	using rootKey = Registry.CurrentUser.OpenSubKey(KeyName, false):
		return ('' if rootKey is null else rootKey.GetValue(valueName).ToString())

def SetRegistryValue(KeyName as string, valueName as string, value as string):
	using rootKey = Registry.CurrentUser.OpenSubKey(KeyName, true):
		return if rootKey is null
		rootKey.SetValue(valueName, value)

def getPersonalFolder() as string:
	return Environment.GetFolderPath(Environment.SpecialFolder.Personal)

def IncludeTrailingPathDelimiter(path as string) as string:
	let BACKSLASH = Path.DirectorySeparatorChar
	return path.TrimEnd(BACKSLASH) + BACKSLASH

def getProjectFolder() as string:
	return IncludeTrailingPathDelimiter(GetRegistryValue('\\Software\\TURBU', 'TURBU Projects Folder'))

def getTempFolder() as string:
	return Path.GetTempPath()

def createProjectFolder():
	SetRegistryValue('\\Software\\TURBU', 'TURBU Projects Folder', (IncludeTrailingPathDelimiter(getPersonalFolder()) + 'TURBU Projects'))
	Directory.CreateDirectory(getProjectFolder())

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def IsBetween(number as int, low as int, high as int) as bool:
	return ((number >= low) and (number <= high))

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def round(value as double) as int:
	if value >= 0:
		result = Math.Truncate(value + 0.5)
	else:
		result = Math.Truncate(value - 0.5)
	return result

def PointInRect(thePoint as TSgPoint, theRect as SDL2.SDL.SDL_Rect) as bool:
	return IsBetween(thePoint.x, theRect.x, theRect.x + theRect.w) and \
			IsBetween(thePoint.y, theRect.y, theRect.y + theRect.h)

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def clamp(ref value as single, low as single, high as single):
	value = Math.Min(high, Math.Max(low, value))

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def clamp(number as int, low as int, high as int) as int:
	return Math.Min(Math.Max(number, low), high)

def EnableControls(controls as (Control), enabled as bool):
	control as Control
	for control in controls:
		control.Enabled = enabled

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def swap(ref x as int, ref y as int):
	dummy as int = x
	x = y
	y = dummy

def OutputFormattedString(value as string, args as (object)):
	System.Diagnostics.Debug.Print(value, *args)

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def safeMod(big as int, small as int) as int:
	return ((big % small) + small) % small

def runThreadsafe(synchronous as bool, closure as Action):
	ct as TThread = TThread.CurrentThread
	if not ct.IsMainThread:
		if synchronous:
			TThread.Synchronize(closure)
		else:
			TThread.Queue(closure)
	else:
		closure()

static class GCurrentFolder:
	public value as string

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
[Extension]
public def syncRun(tt as TThread, AMethod as Action):
	TThread.Synchronize(AMethod)

let LFCR = '\r\n'
let ORIGIN = sgPoint(0, 0)
let NULLRECT = SDL2.SDL2_GPU.GPU_MakeRect(0, 0, 0, 0)
let MULTIPLIER_31 = 8.22580645161
