namespace SG.defs

import Boo.Adt
import Pythia.Runtime
import System
import SDL2.SDL
import System.Drawing

struct TSgPoint:

	x as int

	y as int

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Equality(a as TSgPoint, b as TSgPoint) as bool:
		return ((a.x == b.x) and (a.y == b.y))

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Inequality(a as TSgPoint, b as TSgPoint) as bool:
		return (not (a == b))

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as TSgPoint, b as int) as TSgPoint:
		result.x = (a.x * b)
		result.y = (a.y * b)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as TSgPoint, b as TSgPoint) as TSgPoint:
		result.x = (a.x * b.x)
		result.y = (a.y * b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as TSgPoint, b as double) as TSgPoint:
		result.x = round((a.x * b))
		result.y = round((a.y * b))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as TSgPoint, b as int) as TSgPoint:
		result.x = (a.x / b)
		result.y = (a.y / b)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as TSgPoint, b as TSgPoint) as TSgPoint:
		result.x = (a.x / b.x)
		result.y = (a.y / b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as TSgPoint, b as double) as TSgPoint:
		result.x = round(((a.x cast double) / (b cast double)))
		result.y = round(((a.y cast double) / (b cast double)))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Modulus(a as TSgPoint, b as TSgPoint) as TSgPoint:
		result.x = (a.x % b.x)
		result.y = (a.y % b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Addition(a as TSgPoint, b as TSgPoint) as TSgPoint:
		result.x = (a.x + b.x)
		result.y = (a.y + b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Subtraction(a as TSgPoint, b as TSgPoint) as TSgPoint:
		result.x = (a.x - b.x)
		result.y = (a.y - b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as Point) as TSgPoint:
		system.Move(a, result, sizeof(TPoint))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as TSgPoint) as Point:
		system.Move(a, result, sizeof(TPoint))
		return result

struct TSgFloatPoint:

	x as single

	y as single

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Equality(a as TSgFloatPoint, b as TSgFloatPoint) as bool:
		return ((a.x == b.x) and (a.y == b.y))

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Inequality(a as TSgFloatPoint, b as TSgFloatPoint) as bool:
		return (not (a == b))

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as TSgFloatPoint, b as double) as TSgFloatPoint:
		result.x = (a.x * b)
		result.y = (a.y * b)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as TSgFloatPoint, b as double) as TSgFloatPoint:
		result.x = ((a.x cast double) / (b cast double))
		result.y = ((a.y cast double) / (b cast double))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Addition(a as TSgFloatPoint, b as TSgFloatPoint) as TSgFloatPoint:
		result.x = (a.x + b.x)
		result.y = (a.y + b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Subtraction(a as TSgFloatPoint, b as TSgFloatPoint) as TSgFloatPoint:
		result.x = (a.x - b.x)
		result.y = (a.y - b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as Point) as TSgFloatPoint:
		result.x = a.X
		result.y = a.Y
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as TSgPoint) as TSgFloatPoint:
		result.x = a.X
		result.y = a.Y
		return result

struct TSgColor:

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as uint) as TSgColor:
		result.color = a
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as TSgColor) as uint:
		return a.color

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as TSgColor) as SDL_Color:
		result.r = a.rgba[1]
		result.g = a.rgba[2]
		result.b = a.rgba[3]
		result.unused = a.rgba[4]
		return result

	[Pythia.Attributes.VariantRecord(false)]
	color as uint

	[Pythia.Attributes.VariantRecord(true)]
	rgba as (byte)

def sgPoint(x as int, y as int) as TSgPoint:
	result.x = x
	result.y = y
	return result

def sgPointF(x as single, y as single) as TSgFloatPoint:
	result.x = x
	result.y = y
	return result

let (ORIGIN as TSgPoint) = TSgPoint(x: 0, y: 0)
let (fxOneColor) = 2147483638
let (SDL_BLACK as SDL_Color) = sdl_13.TSDL_Color(unused: 255)
let (SDL_WHITE as SDL_Color) = sdl_13.TSDL_Color(r: 255, g: 255, b: 255, unused: 255)
let (SDL_GREEN as SDL_Color) = sdl_13.TSDL_Color(r: 0, g: 144, b: 53, unused: 255)
