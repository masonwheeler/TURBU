namespace sdl.sprite

import System
import SDL2.SDL2_GPU

interface IViewport:
	WorldX as single:
		get

	WorldY as single:
		get

	VisibleWidth as int:
		get

	VisibleHeight as int:
		get

	OffsetX as int:
		get

	OffsetY as int:
		get

	def SpriteInViewport(sprite as TSprite) as bool

class Viewport(IViewport):
	private _worldX as single

	public WorldX as single:
		get:
			return _worldX
		virtual set:
			_worldX = value

	private _worldY as single

	public WorldY as single:
		get:
			return _worldY
		virtual set:
			_worldY = value

	property VisibleWidth as int

	property VisibleHeight as int

	property OffsetX = 0

	property OffsetY = 0

	def constructor(width as int, height as int):
		self.VisibleWidth = width
		self.VisibleHeight = height

	virtual def SpriteInViewport(sprite as TSprite) as bool:
		return (
				sprite.X + sprite.Width > WorldX and
				sprite.Y + sprite.Height > WorldY and
				sprite.X < WorldX + VisibleWidth and
				sprite.Y < WorldY + VisibleHeight )

	virtual def SetView(rect as GPU_Rect):
		WorldX = rect.x
		WorldY = rect.y
		VisibleWidth = commons.round(rect.w)
		VisibleHeight = commons.round(rect.h)

	protected def Offset(x as int, y as int):
		OffsetX = x
		OffsetY = y

class CompositeViewport(Viewport):
	[Getter(SubViews)]
	private _subViews = array(Viewport, 0)

	private _maxWidth as int

	private _maxHeight as int

	def constructor(width as int, height as int, maxWidth as int, maxHeight as int):
		super(width, height)
		_maxWidth = maxWidth
		_maxHeight = maxHeight

	override def SpriteInViewport(sprite as TSprite) as bool:
		for view in SubViews:
			if view.SpriteInViewport(sprite):
				sprite.SetViewport(view)
				return true
		sprite.SetViewport(self)
		return super.SpriteInViewport(sprite)

	private def SetSubViewCount(value as int):
		var count = _subViews.Length
		if count < value:
			Array.Resize[of Viewport](_subViews, value)
			for i in range(count, value):
				_subViews[i] = Viewport(0, 0)
		elif count > value:
			for i in range(value, count):
				var vp = _subViews[i]
				vp.VisibleWidth = 0
				vp.VisibleHeight = 0

	private def SetupLRView(rect as GPU_Rect):
		_subViews[0].Offset(0, 0)
		if rect.x < 0:
			_subViews[0].SetView(GPU_MakeRect(_maxWidth + rect.x, rect.y, -rect.x,         rect.h))
			_subViews[1].SetView(GPU_MakeRect(0,                  rect.y, rect.w + rect.x, rect.h))
			_subViews[1].Offset(-rect.x, 0)
		else:
			_subViews[0].SetView(GPU_MakeRect(rect.x, rect.y, _maxWidth - rect.x,            rect.h))
			_subViews[1].SetView(GPU_MakeRect(0,      rect.y, rect.w - (_maxWidth - rect.x), rect.h))
			_subViews[1].Offset(_maxWidth - rect.x, 0)

	private def SetupUDView(rect as GPU_Rect):
		_subViews[0].Offset(0, 0)
		if rect.y < 0:
			_subViews[0].SetView(GPU_MakeRect(rect.x, _maxHeight + rect.y, rect.w, -rect.y))
			_subViews[1].SetView(GPU_MakeRect(rect.x, 0,                   rect.w, rect.h + rect.y))
			_subViews[1].Offset(0, -rect.y)
		else:
			_subViews[0].SetView(GPU_MakeRect(rect.x, rect.y, rect.w, _maxHeight - rect.y))
			_subViews[1].SetView(GPU_MakeRect(rect.x, 0,      rect.w, rect.h - (_maxHeight - rect.y)))
			_subViews[1].Offset(0, _maxHeight - rect.y)

	private def SetupQuadView(rect as GPU_Rect):
		_subViews[0].SetView(GPU_MakeRect(_maxWidth + rect.x, _maxHeight + rect.y, -rect.x,         -rect.y))
		_subViews[0].Offset(0, 0)
		_subViews[1].SetView(GPU_MakeRect(0,                  _maxHeight + rect.y, rect.w + rect.x, -rect.y))
		_subViews[1].Offset(-rect.x, 0)
		_subViews[2].SetView(GPU_MakeRect(_maxWidth + rect.x, 0,                   -rect.x,         rect.h + rect.y))
		_subViews[2].Offset(0, -rect.y)
		_subViews[3].SetView(GPU_MakeRect(0,                  0,                   rect.w + rect.x, rect.h + rect.y))
		_subViews[3].Offset(-rect.x, -rect.y)

	override def SetView(rect as GPU_Rect):
		super(rect)
		var sides = 0
		++sides if rect.x < 0 or rect.x + rect.w > self._maxWidth
		++sides if rect.y < 0 or rect.y + rect.h > self._maxHeight
		SetSubViewCount(sides * 2)
		__switch__(sides, s0, s1, s2)
		assert false
		:s0
		return
		:s1
		if rect.x < 0 or rect.x + rect.w > self._maxWidth:
			SetupLRView(rect)
		else: SetupUDView(rect)
		return
		:s2
		SetupQuadView(rect)

	public WorldX as single:
		override set:
			var oldX = self.WorldX
			super(value)
			for view in SubViews:
				if view.VisibleWidth > 0:
					view.WorldX += value - oldX

	public WorldY as single:
		override set:
			var oldY = self.WorldY
			super(value)
			for view in SubViews:
				if view.VisibleWidth > 0:
					view.WorldY += value - oldY
