namespace SG.defs

import System
import System.Math
import Boo.Adt
import SDL2.SDL
import System.Drawing

struct TSgPoint:

	x as int

	y as int

	def constructor(aX as int, aY as int):
		self.x = aX
		self.y = aY

	override def ToString():
		return "TSgPoint: x: $x, y: $y"

	static def op_Equality(a as TSgPoint, b as TSgPoint) as bool:
		return (a.x == b.x) and (a.y == b.y)

	static def op_Inequality(a as TSgPoint, b as TSgPoint) as bool:
		return not (a == b)

	static def op_Multiply(a as TSgPoint, b as int) as TSgPoint:
		return TSgPoint(a.x * b, a.y * b)

	static def op_Multiply(a as TSgPoint, b as TSgPoint) as TSgPoint:
		return TSgPoint(a.x * b.x, a.y * b.y)

	static def op_Multiply(a as TSgPoint, b as double) as TSgPoint:
		return TSgPoint(Round(a.x * b), Round(a.y * b))

	static def op_Division(a as TSgPoint, b as int) as TSgPoint:
		return TSgPoint(a.x / b, a.y / b)

	static def op_Division(a as TSgPoint, b as TSgPoint) as TSgPoint:
		return TSgPoint(a.x / b.x, a.y / b.y)

	static def op_Division(a as TSgPoint, b as double) as TSgPoint:
		return TSgPoint(Round((a.x cast double) / (b cast double)), Round((a.y cast double) / (b cast double)))

	static def op_Modulus(a as TSgPoint, b as TSgPoint) as TSgPoint:
		return TSgPoint(a.x % b.x, a.y % b.y)

	static def op_Addition(a as TSgPoint, b as TSgPoint) as TSgPoint:
		return TSgPoint(a.x + b.x, a.y + b.y)

	static def op_Subtraction(a as TSgPoint, b as TSgPoint) as TSgPoint:
		return TSgPoint(a.x - b.x, a.y - b.y)

	static def op_Implicit(a as Point) as TSgPoint:
		return TSgPoint(a.X, a.Y)

	static def op_Implicit(a as TSgPoint) as Point:
		result as Point
		result.X = a.x
		result.Y = a.y
		return result

struct TSgFloatPoint:

	x as single

	y as single

	override def ToString():
		return "TSgFloatPoint: x: $x, y: $y"

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Equality(a as TSgFloatPoint, b as TSgFloatPoint) as bool:
		result = ((a.x == b.x) and (a.y == b.y))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Inequality(a as TSgFloatPoint, b as TSgFloatPoint) as bool:
		result = (not (a == b))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as TSgFloatPoint, b as double) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = (a.x * b)
		result.y = (a.y * b)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as TSgFloatPoint, b as double) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = (a.x / (b cast double))
		result.y = (a.y / (b cast double))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Addition(a as TSgFloatPoint, b as TSgFloatPoint) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = (a.x + b.x)
		result.y = (a.y + b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Subtraction(a as TSgFloatPoint, b as TSgFloatPoint) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = (a.x - b.x)
		result.y = (a.y - b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as Point) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = a.X
		result.y = a.Y
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as TSgPoint) as TSgFloatPoint:
		result as TSgFloatPoint
		result.x = a.x
		result.y = a.x
		return result

[StructLayout(LayoutKind.Explicit)]
struct TSgColor:

	def constructor(r as byte, g as byte, b as byte, a as byte):
		_R = r
		_G = g
		_B = b
		_A = a
	
	def constructor(color as uint):
		Color = color

	static def op_Implicit(a as TSgColor) as SDL_Color:
		result = SDL_Color(r: a.R, g: a.G, b: a.B, a: a.A)
		return result

	[FieldOffset(0)]
	public Color as uint

	[FieldOffset(0)]
	[Property(R)]
	private _R as byte
	
	[FieldOffset(1)]
	[Property(G)]
	private _G as byte

	[FieldOffset(2)]
	[Property(B)]
	private _B as byte

	[FieldOffset(3)]
	[Property(A)]
	private _A as byte

	Rgba[index as byte] as byte:
		get:
			__switch__(index - 1, label1, label2, label3, label4)
			raise "Invalid rgba index: $index"
			:label1
			return R
			:label2
			return G
			:label3
			return B
			:label4
			return A
		set:
			__switch__(index - 1, label1, label2, label3, label4)
			raise "Invalid rgba index: $index"
			:label1
			_R = value
			:label2
			_G = value
			:label3
			_B = value
			:label4
			_A = value

def sgPoint(x as int, y as int) as TSgPoint:
	result as TSgPoint
	result.x = x
	result.y = y
	return result

def sgPointF(x as single, y as single) as TSgFloatPoint:
	result as TSgFloatPoint
	result.x = x
	result.y = y
	return result

let ORIGIN = TSgPoint(x: 0, y: 0)
let fxOneColor = 2147483638
let SDL_BLACK = SDL_Color(a: 255)
let SDL_WHITE = SDL_Color(r: 255, g: 255, b: 255, a: 255)
let SDL_GREEN = SDL_Color(r: 0, g: 144, b: 53, a: 255)
