namespace sg.utils

import System
import SG.defs
import System.Drawing
import SDL2.SDL
import SDL2.SDL2_GPU
import commons

def constrictRect(value as Rectangle, amount as int) as Rectangle:
	return expandRect(value, -amount)

def expandRect(value as Rectangle, amount as int) as Rectangle:
	result = Rectangle(value.Left - amount, value.Top - amount, value.Right + amount, value.Bottom + amount)
	return result

def constrictSdlRect(value as SDL_Rect, amount as int) as SDL_Rect:
	return expandSdlRect(value, -amount)

def expandSdlRect(value as SDL_Rect, amount as int) as SDL_Rect:
	result as SDL_Rect
	result.x = (value.x - amount)
	result.y = (value.y - amount)
	result.w = (value.w + (amount * 2))
	result.h = (value.h + (amount * 2))
	return result

def multiplyRect(value as Rectangle, amount as int) as Rectangle:
	result = Rectangle(value.Left * amount, value.Top * amount, value.Right * amount, value.Bottom * amount)
	return result

def multiplyRect(value as Rectangle, amount as SgPoint) as Rectangle:
	result = Rectangle(value.Left * amount.x, value.Top * amount.y, value.Right * amount.x, value.Bottom * amount.y)
	return result

def multiplyRect(value as Rectangle, amount as single) as Rectangle:
	result = Rectangle(round(value.Left * amount), round(value.Top * amount), round(value.Right * amount),
		round(value.Bottom * amount))
	return result

def divideRect(value as Rectangle, amount as SgPoint) as Rectangle:
	result = Rectangle(
		round((value.Left cast double) / (amount.x cast double)),
		round((value.Top cast double) / (amount.y cast double)),
		round((value.Right cast double) / (amount.x cast double)),
		round((value.Bottom cast double) / (amount.y cast double)))
	return result

def pointToGridLoc(point as SgPoint, cellSize as SgPoint, hScroll as int, vScroll as int, scale as double) as SgPoint:
	return ((point / scale ) + SgPoint(hScroll, vScroll)) / cellSize

def gridLocToPoint(point as SgPoint, cellSize as SgPoint, hScroll as int, vScroll as int, scale as double) as SgPoint:
	result as SgPoint
	result.x = round(point.x * scale * cellSize.x) - hScroll
	result.y = round(point.y * scale * cellSize.y) - vScroll
	return result

def TRectToSdlRect(value as Rectangle) as SDL_Rect:
	return SDL_Rect(x: value.Left, y: value.Top, w: value.Width, h: value.Height)

def SdlRectToTRect(value as GPU_Rect) as Rectangle:
	return Rectangle(value.x, value.y, value.w, value.h)
