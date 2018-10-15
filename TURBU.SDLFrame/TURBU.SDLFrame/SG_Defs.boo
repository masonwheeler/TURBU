namespace SG.defs

import System
import System.Math
import Boo.Adt
import SDL2.SDL
import System.Drawing

struct SgPoint:

	x as int

	y as int

	def constructor(aX as int, aY as int):
		self.x = aX
		self.y = aY

	override def ToString():
		return "SgPoint: x: $x, y: $y"

	static def op_Equality(a as SgPoint, b as SgPoint) as bool:
		return (a.x == b.x) and (a.y == b.y)

	static def op_Inequality(a as SgPoint, b as SgPoint) as bool:
		return not (a == b)

	static def op_Multiply(a as SgPoint, b as int) as SgPoint:
		return SgPoint(a.x * b, a.y * b)

	static def op_Multiply(a as SgPoint, b as SgPoint) as SgPoint:
		return SgPoint(a.x * b.x, a.y * b.y)

	static def op_Multiply(a as SgPoint, b as double) as SgPoint:
		return SgPoint(Round(a.x * b), Round(a.y * b))

	static def op_Division(a as SgPoint, b as int) as SgPoint:
		return SgPoint(a.x / b, a.y / b)

	static def op_Division(a as SgPoint, b as SgPoint) as SgPoint:
		return SgPoint(a.x / b.x, a.y / b.y)

	static def op_Division(a as SgPoint, b as double) as SgPoint:
		return SgPoint(Round((a.x cast double) / (b cast double)), Round((a.y cast double) / (b cast double)))

	static def op_Modulus(a as SgPoint, b as SgPoint) as SgPoint:
		return SgPoint(a.x % b.x, a.y % b.y)

	static def op_Addition(a as SgPoint, b as SgPoint) as SgPoint:
		return SgPoint(a.x + b.x, a.y + b.y)

	static def op_Subtraction(a as SgPoint, b as SgPoint) as SgPoint:
		return SgPoint(a.x - b.x, a.y - b.y)

	static def op_Implicit(a as Point) as SgPoint:
		return SgPoint(a.X, a.Y)

	static def op_Implicit(a as SgPoint) as Point:
		result as Point
		result.X = a.x
		result.Y = a.y
		return result

struct SgFloatPoint:

	x as single

	y as single

	override def ToString():
		return "SgFloatPoint: x: $x, y: $y"

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Equality(a as SgFloatPoint, b as SgFloatPoint) as bool:
		result = ((a.x == b.x) and (a.y == b.y))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Inequality(a as SgFloatPoint, b as SgFloatPoint) as bool:
		result = (not (a == b))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Multiply(a as SgFloatPoint, b as double) as SgFloatPoint:
		result as SgFloatPoint
		result.x = (a.x * b)
		result.y = (a.y * b)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Division(a as SgFloatPoint, b as double) as SgFloatPoint:
		result as SgFloatPoint
		result.x = (a.x / (b cast double))
		result.y = (a.y / (b cast double))
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Addition(a as SgFloatPoint, b as SgFloatPoint) as SgFloatPoint:
		result as SgFloatPoint
		result.x = (a.x + b.x)
		result.y = (a.y + b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Subtraction(a as SgFloatPoint, b as SgFloatPoint) as SgFloatPoint:
		result as SgFloatPoint
		result.x = (a.x - b.x)
		result.y = (a.y - b.y)
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as Point) as SgFloatPoint:
		result as SgFloatPoint
		result.x = a.X
		result.y = a.Y
		return result

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	static def op_Implicit(a as SgPoint) as SgFloatPoint:
		result as SgFloatPoint
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

def sgPoint(x as int, y as int) as SgPoint:
	result as SgPoint
	result.x = x
	result.y = y
	return result

def sgPointF(x as single, y as single) as SgFloatPoint:
	result as SgFloatPoint
	result.x = x
	result.y = y
	return result

let ORIGIN = SgPoint(x: 0, y: 0)
let fxOneColor = 2147483638
let SDL_BLACK = SDL_Color(a: 255)
let SDL_WHITE = SDL_Color(r: 255, g: 255, b: 255, a: 255)
let SDL_GREEN = SDL_Color(r: 0, g: 144, b: 53, a: 255)
