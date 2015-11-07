namespace turbu.RM2K.images

import Pythia.Runtime
import sdl.sprite
import Newtonsoft.Json.Linq

[Metaclass(TRpgImageSprite)]
class TRpgImageSpriteClass(TSpriteClass):
	pass

[Metaclass(TRpgImage)]
class TRpgImageClass(TClass):

	virtual def Create(engine as TSpriteEngine, Name as string, x as int, y as int, baseWX as single, baseWY as single, zoom as int, pinned as bool, masked as bool) as turbu.RM2K.images.TRpgImage:
		return turbu.RM2K.images.TRpgImage(engine, Name, x, y, baseWX, baseWY, zoom, pinned, masked)

	virtual def Deserialize(engine as TSpriteEngine, obj as JObject) as turbu.RM2K.images.TRpgImage:
		return turbu.RM2K.images.TRpgImage(engine, obj)

