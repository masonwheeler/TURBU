namespace turbu.RM2K.image.engine

import sdl.sprite
import sdl.canvas
import SDL.ImageManager

class TImageEngine(TSpriteEngine):

	[Property(ParentEngine)]
	private FParentEngine as TSpriteEngine

	public def constructor(AParent as TSpriteEngine, ACanvas as TSdlCanvas, images as TSdlImages):
		super(null, ACanvas)
		FParentEngine = AParent
		self.Images = images

	public override def Draw():
		WorldX = FParentEngine.WorldX
		WorldY = FParentEngine.WorldY
		super.Draw()
		self.Dead()