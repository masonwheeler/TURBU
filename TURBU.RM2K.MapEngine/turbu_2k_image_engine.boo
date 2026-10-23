namespace turbu.RM2K.image.engine

import Pythia.Runtime
import sdl.sprite
import sdl.canvas
import SDL.ImageManager
import turbu.RM2K.images

[Disposable(Destroy, true)]
class TImageEngine(SpriteEngine):

	[Property(ParentEngine)]
	[DisposeParent]
	private FParentEngine as SpriteEngine

	public def constructor(parent as SpriteEngine, canvas as SdlCanvas, images as SdlImages):
		super(null, canvas)
		FParentEngine = parent
		self.Images = images

	public def Tick():
		for image in FSpriteList.OfType[of TRpgImageSprite]():
			image.Tick()

	public override def Draw():
		Viewport.WorldX = FParentEngine.Viewport.WorldX
		Viewport.WorldY = FParentEngine.Viewport.WorldY
		self.Dead()
		super.Draw()

	private new def Destroy():
		if assigned(FSpriteList):
			for image in FSpriteList.ToArray():
				image.Dead()
			self.Dead()