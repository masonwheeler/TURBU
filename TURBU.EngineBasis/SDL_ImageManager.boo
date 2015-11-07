namespace SDL.ImageManager

import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import SG.defs
import SDL2.SDL
import System.Math
import SDL.rwStream
import sdl.canvas
import SDL2.SDL_image
import System.Drawing
import System.IO

enum TDrawMode:

	dmFull

	dmSprite

class ESdlImageException(Exception):
	pass

callable TArchiveLoader(filename as string) as IntPtr
callable TArchiveCallback(ref rw as IntPtr)
class TSdlImage(TObject):

	private static FRw as IntPtr

	[Getter(surface)]
	protected FSurface as IntPtr

	[Property(name)]
	protected FName as string

	protected FTextureSize as TSgPoint

	[Getter(texPerRow)]
	protected FTexturesPerRow as int

	[Getter(texRows)]
	protected FTextureRows as int

	[Getter(Colorkey)]
	protected FColorkey as SDL_Color

	protected def getSpriteRect(index as int) as Rectangle:
		x as int
		y as int
		x = (index % FTexturesPerRow)
		y = (index / FTexturesPerRow)
		return rect(point((x * FTextureSize.X), (y * FTextureSize.y)), FTextureSize)

	protected virtual def setup(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint, lSurface as IntPtr):
		loader as TImgLoadMethod
		loadStream as Stream
		intFilename as string
		FName = imagename
		if (lSurface == null) and (FSurface.ptr == null):
			if filename != '':
				if not loaders.TryGetValue(ExtractFileExt(filename), loader):
					loader = null
				if FRw == null:
					intFilename = PAnsiChar(UTF8String(filename))
					if not assigned(loader):
						LSurface = PSdlSurface(IMG_Load(intFilename))
					else:
						using loadStream = TFileStream.Create(filename, fmOpenRead):
							LSurface = loader(loadStream)
				elif not assigned(loader):
					LSurface = PSdlSurface(IMG_LoadTyped_RW(FRw, 0, PAnsiChar(ansiString(filename))))
				else:
					using loadStream = TRWStream.Create(FRw, false):
						LSurface = loader(loadStream)
			else:
				LSurface = TSdlSurface.Create(spritesize.x, spritesize.y, 32, 0, 0, 0, 0)
		if LSurface == null:
			raise ESdlImageException.Create(string(IMG_GetError))
		if assigned(LSurface.format.palette):
			FColorkey = (*LSurface.format.palette.colors[0])
			LSurface.colorkey = SDL_MapRGB(LSurface.format, FColorkey.r, FColorkey.g, FColorkey.b)
		processImage(LSurface)
		if FSurface.ptr == null:
			FSurface = TSdlTexture.Create(renderer, 0, LSurface)
		if (spriteSize.X == EMPTY.X) and (spriteSize.Y == EMPTY.Y):
			self.textureSize = point(LSurface.width, LSurface.height)
		else:
			self.textureSize = spriteSize
		LSurface.Free()
		if assigned(container):
			container.add(self)

	protected def SetTextureSize(size as TSgPoint):
		lSize as TSgPoint
		lSize = FSurface.size
		if ((lSize.X % size.X) > 0) or ((lSize.Y % size.Y) > 0):
			raise ESdlImageException.Create('Texture size is not evenly divisible into base image size.')
		FTextureSize = size
		FTexturesPerRow = (lSize.X / size.X)
		FTextureRows = (lSize.Y / size.Y)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	protected def GetCount() as int:
		return (FTexturesPerRow * FTextureRows)

	protected virtual def processImage(image as IntPtr):
		pass

	public def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages):
		super()
		setup(renderer, filename, imagename, container, EMPTY, null)

	public def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages):
		super()
		FSurface = TSdlTexture.Create(renderer, 0, surface)
		setup(renderer, '', imagename, container, EMPTY, surface)

	public def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages):
		SDL_LockMutex(rwMutex)
		try:
			FRw = rw
			setup(renderer, ExtractFileExt(extension), imagename, container, EMPTY, null)
			FRw = null
		ensure:
			SDL_UnlockMutex(rwMutex)

	public def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super()
		setup(renderer, filename, imagename, container, spriteSize, null)

	public def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super()
		SDL_LockMutex(rwMutex)
		FRw = rw
		setup(renderer, extension, imagename, container, spriteSize, null)
		FRw = null
		SDL_UnlockMutex(rwMutex)

	public def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super()
		setup(renderer, '', imagename, container, spriteSize, surface)

	public def constructor(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super()
		spriteSize.Y = (spriteSize.Y * count)
		setup(renderer, '', imagename, container, spriteSize, null)
		spriteSize.Y = (spriteSize.Y / count)
		self.textureSize = spriteSize

	def destructor():
		FSurface.Free()

	public virtual def Draw():
		self.Draw(EMPTY, [])

	public def Draw(dest as TSgPoint, flip as SDL_RendererFlip):
		currentRenderTarget.parent.draw(self, dest, flip)

	public def DrawRect(dest as TSgPoint, source as Rectangle, flip as SDL_RendererFlip):
		currentRenderTarget.parent.drawRect(self, dest, source, flip)

	public def DrawSprite(dest as TSgPoint, index as int, flip as SDL_RendererFlip):
		if index >= count:
			return
		currentRenderTarget.parent.drawRect(self, dest, self.spriteRect[index], flip)

	public def DrawTo(dest as Rectangle):
		currentRenderTarget.parent.drawTo(self, dest)

	public def DrawRectTo(dest as Rectangle, source as Rectangle):
		currentRenderTarget.parent.drawRectTo(self, dest, source)

	public def DrawSpriteTo(dest as Rectangle, index as int):
		if index >= count:
			return
		currentRenderTarget.parent.drawRectTo(self, dest, self.spriteRect[index])

	public textureSize as TSgPoint:
		get:
			return FTextureSize
		set:
			SetTextureSize(value)

	public count as int:
		get:
			return GetCount()

	public spriteRect[index as int] as Rectangle:
		get:
			return getSpriteRect(index)

class TSdlOpaqueImage(TSdlImage):

	protected override def processImage(image as IntPtr):
		SDL_SetColorKey(image, false, 0)
		image.BlendMode = []

	def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

class TSdlImages(TObject):

	private FRenderer as IntPtr

	private FData as (TSdlImage)

	[Property(FreeOnClear)]
	private FFreeOnClear as bool

	[Property(ArchiveLoader)]
	private FArchiveLoader as TArchiveLoader

	[Property(ArchiveCallback)]
	private FArchiveCallback as TArchiveCallback

	private FUpdateMutex as IntPtr

	private FHash as Dictionary[of string, int]

	[Property(SpriteClass)]
	private FSpriteClass as TSdlImageClass

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	private def GetCount() as int:
		return Length(FData)

	private def GetItem(Num as int) as TSdlImage:
		if (Num >= 0) and (Num < Length(FData)):
			Result = FData[Num]
		else:
			Result = null
		return result

	private def GetImage(Name as string) as TSdlImage:
		index as int
		if FHash.TryGetValue(name, index):
			result = FData[index]
		else:
			result = null
		return result

	private def FindEmptySlot() as int:
		i as int
		Result = -1
		for i in range(0, Length(FData)):
			if FData[i] == null:
				Result = i
				Break
		return result

	private def Insert(Element as TSdlImage) as int:
		Slot as int
		Slot = FindEmptySlot
		if Slot == -1:
			Slot = Length(FData)
			SetLength(FData, max((Slot * 2), 16))
		FData[Slot] = Element
		Result = Slot
		FHash.Add(element.name, result)
		return result

	public def constructor(renderer as IntPtr, FreeOnClear as bool, loader as TArchiveLoader, callback as TArchiveCallback):
		super()
		FRenderer = renderer
		FFreeOnClear = FreeOnClear
		FArchiveLoader = loader
		FArchiveCallback = callback
		FUpdateMutex = SDL_CreateMutex
		FHash = TDictionary[of string, int].Create
		FSpriteClass = TSdlImage

	def destructor():
		self.Clear
		FHash.Free()
		SDL_DestroyMutex(FUpdateMutex)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def Contains(name as string) as bool:
		return (self.IndexOf(name) != -1)

	public def IndexOf(Element as TSdlImage) as int:
		return IndexOf(element.name)

	public def IndexOf(Name as string) as int:
		if not FHash.TryGetValue(name, result):
			result = -1
		return result

	public def Add(Element as TSdlImage) as int:
		SDL_LockMutex(FUpdateMutex)
		try:
			if FHash.ContainsKey(element.name):
				Result = IndexOf(Element)
			else:
				Result = Insert(Element)
		ensure:
			SDL_UnlockMutex(FUpdateMutex)
		return result

	public def AddFromFile(filename as string, imagename as string) as int:
		return AddFromFile(filename, filename, TSdlImage)

	public def AddFromFile(filename as string, imagename as string, imgClass as TSdlImageClass) as int:
		return self.Add(imgClass.Create(FRenderer, filename, filename, null))

	public def AddFromArchive(filename as string, imagename as string, loader as TArchiveLoader) as int:
		dummy as IntPtr
		if assigned(loader):
			dummy = loader(filename)
		elif assigned(FArchiveLoader):
			dummy = FArchiveLoader(filename)
		else:
			raise ESdlImageException.Create('No archive loader available!')
		if dummy == null:
			raise ESdlImageException.CreateFmt('Archive loader failed to extract "%s" from the archive.', [filename])
		result = self.Add(TSdlImage.Create(FRenderer, dummy, ExtractFileExt(filename), imagename, null))
		if assigned(FArchiveCallback):
			FArchiveCallback(dummy)
		else:
			SDL_FreeRW(dummy)
		return result

	public def AddSpriteFromArchive(filename as string, imagename as string, spritesize as TSgPoint, imgClass as TSdlImageClass, loader as TArchiveLoader) as int:
		dummy as IntPtr
		if assigned(loader):
			dummy = loader(filename)
		elif assigned(FArchiveLoader):
			dummy = FArchiveLoader(filename)
		else:
			raise ESdlImageException.Create('No archive loader available!')
		if dummy == null:
			raise ESdlImageException.CreateFmt('Archive loader failed to extract "%s" from the archive.', [filename])
		result = self.Add(imgClass.CreateSprite(FRenderer, dummy, ExtractFileExt(filename), imagename, null, spriteSize))
		if assigned(FArchiveCallback):
			FArchiveCallback(dummy)
		else:
			SDL_FreeRW(dummy)
		return result

	public def AddSpriteFromArchive(filename as string, imagename as string, spritesize as TSgPoint, loader as TArchiveLoader) as int:
		return AddSpriteFromArchive(filename, imagename, spritesize, FSpriteClass, loader)

	public def EnsureImage(filename as string, imagename as string) as TSdlImage:
		return EnsureImage(filename, imagename, EMPTY)

	public def EnsureImage(filename as string, imagename as string, spritesize as TSgPoint) as TSdlImage:
		index as int
		if self.Contains(imagename):
			result = GetImage(imagename)
		else:
			if FileExists(filename):
				index = AddFromFile(filename, imagename)
			else:
				index = AddSpriteFromArchive(filename, imagename, spritesize)
			result = Self[index]
		return result

	public def EnsureBGImage(filename as string, imagename as string) as TSdlImage:
		index as int
		if self.Contains(imagename):
			result = GetImage(imagename)
		else:
			if FileExists(filename):
				index = AddFromFile(filename, imagename, TSdlBackgroundImage)
			else:
				index = AddSpriteFromArchive(filename, imagename, EMPTY, TSdlBackgroundImage)
			result = Self[index]
		return result

	public def Remove(Num as int):
		SDL_LockMutex(FUpdateMutex)
		try:
			if (Num < 0) or (Num >= Length(FData)):
				return
			FHash.Remove(FData[Num].name)
			freeAndNil(FData[Num])
		ensure:
			SDL_UnlockMutex(FUpdateMutex)

	public def Extract(Num as int) as TSdlImage:
		SDL_LockMutex(FUpdateMutex)
		try:
			result = null
			if (Num < 0) or (Num >= Length(FData)):
				return result
			result = FData[num]
			FData[num] = null
			FHash.Remove(result.name)
		ensure:
			SDL_UnlockMutex(FUpdateMutex)
		return result

	public def Clear():
		i as int
		SDL_LockMutex(FUpdateMutex)
		try:
			FHash.Clear
			if FFreeOnClear:
				for i in range(0, Length(FData)):
					FData[i].Free()
			SetLength(FData, 0)
		ensure:
			SDL_LockMutex(FUpdateMutex)

	public def Pack():
		Lo as int
		Hi as int
		I as int
		Lo = -1
		Hi = high(FData)
		while Lo < Hi:
			inc(Lo)
			if FData[Lo] == null:
				while (FData[Hi] == null) and (Hi > Lo):
					dec(Hi)
					if Hi > Lo:
						FData[Lo] = FData[Hi]
						dec(Hi)
			if FData[Hi] == null:
				dec(Hi)
			setLength(FData, (Hi * 2))
			FHash.Clear
			for I in range(0, (Hi + 1)):
				FHash.Add(FData[i].name, i)

	public def SetRenderer(renderer as IntPtr):
		if FRenderer.ptr != null:
			raise Exception.Create('Cannot call TSdlImages.SetRenderer twice!')
		FRenderer = renderer

	public Count as int:
		get:
			return GetCount()

	[Pythia.Attributes.DelphiDefaultProperty]
	public Items[Num as int] as TSdlImage:
		get:
			return GetItem(Num)

	public Image[Name as string] as TSdlImage:
		get:
			return GetImage(Name)

class TSdlBackgroundImage(TSdlImage):

	protected override def processImage(image as IntPtr):
		SDL_SetColorKey(image, false, 0)
		integer(FColorKey) = 0

	def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, rw as IntPtr, extension as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

	def constructor(renderer as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super(param.Name, param.Name, param.Name, param.Name, param.Name)

callable TImgLoadMethod(inFile as Stream) as IntPtr
def registerImageLoader(extension as string, loader as TImgLoadMethod):
	if extension[1] != '.':
		extension = ('.' + extension)
	loaders.Add(extension, loader)

let (EMPTY as TSgPoint) = TSgPoint(X: 0, Y: 0)
class_of TSdlImage, TSdlImageClass
initialization :
	loaders = TDictionary[of string, TImgLoadMethod].Create
	rwMutex = SDL_CreateMutex
	assert IMG_Init([imgPng, imgXyz]) == [imgPng, imgXyz]
finalization :
	IMG_Quit
	loaders.Free()
	SDL_DestroyMutex(rwMutex)
