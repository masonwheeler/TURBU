namespace turbu.RM2K.distortions

import sdl.canvas
import commons
import SDL.ImageManager
import SDL2.SDL2_GPU
import System
import turbu.RM2K.images
import turbu.RM2K.sprite.engine

def drawWave(image as TSdlRenderTarget, source as GPU_Rect, amp as int, period as int, phase as int):
	i as int
	shift as int
	width as ushort
	height as ushort
	viewRect as GPU_Rect
	width = image.Width
	height = image.Height
	for i in range(height):
		shift = round(amp * Math.Sin(((phase + i) cast double) / (period cast double)))
		viewRect = GPU_MakeRect(source.x, i, width, 1)
		GSpriteEngine.value.Canvas.DrawRectTo(image, GPU_MakeRect(source.x + shift, source.y + i, width, 1), viewRect)

def drawWave(image as TRpgImage, amp as int, period as int, phase as int, DrawFx as int):
	i as int
	shift as int
	width as ushort
	height as ushort
	viewRect as GPU_Rect
	base as TSdlImage
	x as single
	y as single
	base = image.Base.Image
	width = base.TextureSize.x
	height = base.TextureSize.y
	x = image.Base.X - ((width cast double) / 2.0)
	y = image.Base.Y - ((height cast double) / 2.0)
	for i in range(height):
		shift = round(amp * Math.Sin(((phase + i) cast double) / (period cast double)))
		viewRect = GPU_MakeRect(commons.round(x), i, width, 1)
		GSpriteEngine.value.Canvas.DrawRectTo(base, GPU_MakeRect(x + shift, i + y, width, height), viewRect)

