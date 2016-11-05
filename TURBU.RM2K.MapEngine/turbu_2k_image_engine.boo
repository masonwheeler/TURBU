namespace turbu.RM2K.image.engine

import Pythia.Runtime
import sdl.sprite
import sdl.canvas
import SDL.ImageManager

[Disposable(Destroy, true)]
class TImageEngine(TSpriteEngine):

	[Property(ParentEngine)]
	private FParentEngine as TSpriteEngine

	public def constructor(parent as TSpriteEngine, canvas as TSdlCanvas, images as TSdlImages):
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
				image.Dispose()