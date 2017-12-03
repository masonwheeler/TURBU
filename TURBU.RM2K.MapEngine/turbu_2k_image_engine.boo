namespace turbu.RM2K.image.engine

import Pythia.Runtime
import sdl.sprite
import sdl.canvas
import SDL.ImageManager

[Disposable(Destroy, true)]
class TImageEngine(SpriteEngine):

	[Property(ParentEngine)]
	private FParentEngine as SpriteEngine

	public def constructor(parent as SpriteEngine, canvas as TSdlCanvas, images as TSdlImages):
		super(null, canvas)
		FParentEngine = parent
		self.Images = images

	public override def Draw():
		WorldX = FParentEngine.WorldX
		WorldY = FParentEngine.WorldY
		super.Draw()
		self.Dead()

	private new def Destroy():
		if assigned(FSpriteList):
			for image in FSpriteList.ToArray():
				image.Dead()
			self.Dead()