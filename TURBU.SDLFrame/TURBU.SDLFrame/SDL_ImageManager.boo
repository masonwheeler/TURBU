namespace SDL.ImageManager

import System
import System.Collections.Generic
import System.IO
import System.Math
import Boo.Adt
import SDL2
import SDL2.SDL2_GPU
import SDL2.SDL_image
import SG.defs
import sdl.canvas
import Pythia.Runtime

enum TDrawMode:
	dmFull
	dmSprite

class ESdlImageException(Exception):
	def constructor(msg as string):
		super(msg)

callable TArchiveLoader(filename as string) as string

[Metaclass(TSdlImage)]
class TSdlImageClass(TClass):
	virtual def Create(filename as string, imagename as string, container as TSdlImages):
		return TSdlImage(filename, imagename, container)

	virtual def CreateSprite(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return TSdlImage(filename, imagename, container)

[Disposable(Destroy, true)]
class TSdlImage(TObject):
	private static nullInt = 0
	private static nullUInt as uint = 0
	
	static def constructor():
		_metaclass = TSdlImageClass.Instance of TSdlImageClass()
		flags = IMG_InitFlags.IMG_INIT_PNG
		assert IMG_Init(flags) == flags

	classDestructor:
		IMG_Quit()
	
	private static FRw as IntPtr

	[Getter(Surface)]
	protected FSurface as GPU_Image_PTR

	[Property(Name)]
	protected FName as string

	protected FTextureSize as TSgPoint

	[Getter(TexPerRow)]
	protected FTexturesPerRow as int

	[Getter(TexRows)]
	protected FTextureRows as int

	[Getter(Colorkey)]
	protected FColorKey as SDL.SDL_Color
	
	[Getter(ImageSize)]
	private FImageSize as TSgPoint
	
	[Property(Alpha)]
	private FAlpha as byte

	override def ToString():
		return "$(GetType().Name)('$(Name)', Image: ($(ImageSize.x), $(ImageSize.y)), Texture: ($(TextureSize.x), $(TextureSize.y)))"

	private def GetSurface(surface as IntPtr) as SDL.SDL_Surface:
		sur as SDL.SDL_Surface = Marshal.PtrToStructure(surface, SDL.SDL_Surface);
		return sur

	protected virtual def Setup(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint, lSurface as IntPtr):
		intFilename as string
		FName = imagename
		if (lSurface == IntPtr.Zero) and (FSurface.Pointer == IntPtr.Zero):
			if filename != '':
				if FRw == IntPtr.Zero:
					intFilename = filename
					lSurface = IMG_Load(intFilename)
				else: lSurface = IMG_LoadTyped_RW(FRw, 0, filename)
			else: lSurface = SDL.SDL_CreateRGBSurface(0, spriteSize.x, spriteSize.y, 32, 0, 0, 0, 0)
		if lSurface == IntPtr.Zero:
			raise ESdlImageException(SDL.SDL_GetError())
		sur = GetSurface(lSurface)
		format = sur.Format
		if format.palette != IntPtr.Zero:
			FColorKey = format.Palette.Color(0)
			SDL.SDL_SetColorKey(lSurface, 1, SDL.SDL_MapRGB(sur.format, FColorKey.r, FColorKey.g, FColorKey.b))
		ProcessImage(lSurface)
		if FSurface.Pointer == IntPtr.Zero:
			FSurface = GPU_CopyImageFromSurface(lSurface)
		img = FSurface.Value
		FImageSize = TSgPoint(img.w, img.h)
		if (spriteSize.x == EMPTY.x) and (spriteSize.y == EMPTY.y):
			self.TextureSize = sgPoint(sur.w, sur.h)
		else: self.TextureSize = spriteSize
		SDL.SDL_FreeSurface(lSurface)
		container.Add(self) if assigned(container)

	protected virtual def ProcessImage(image as IntPtr):
		pass

	public def constructor(filename as string, imagename as string, container as TSdlImages):
		super()
		Setup(filename, imagename, container, EMPTY, IntPtr.Zero)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages):
		super()
		FSurface = GPU_CopyImageFromSurface(surface)
		Setup('', imagename, container, EMPTY, surface)

	public def constructor(surface as GPU_Image_PTR, imagename as string, container as TSdlImages):
		super()
		FSurface = surface
		FName = imagename
		container.Add(self) if assigned(container)

	public def constructor(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super()
		Setup(filename, imagename, container, spriteSize, IntPtr.Zero)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super()
		Setup('', imagename, container, spriteSize, surface)

	public def constructor(imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super()
		spriteSize.y = spriteSize.y * count
		Setup('', imagename, container, spriteSize, IntPtr.Zero)
		spriteSize.y = spriteSize.y / count
		self.TextureSize = spriteSize

	private def Destroy():
		GPU_FreeImage(FSurface)

	public virtual def Draw():
		self.Draw(EMPTY, SDL.SDL_RendererFlip.SDL_FLIP_NONE)

	public def Draw(dest as TSgPoint, flip as SDL.SDL_RendererFlip):
		currentRenderTarget().Parent.Draw(self, dest, flip)

	public def DrawRect(dest as TSgPoint, source as GPU_Rect, flip as SDL.SDL_RendererFlip):
		currentRenderTarget().Parent.DrawRect(self, dest, source, flip)

	public def DrawSprite(dest as TSgPoint, index as int, flip as SDL.SDL_RendererFlip):
		if index < Count:
			currentRenderTarget().Parent.DrawRect(self, dest, self.SpriteRect[index], flip)

	public def DrawTo(dest as GPU_Rect):
		currentRenderTarget().Parent.DrawTo(self, dest)

	public def DrawRectTo(dest as GPU_Rect, source as GPU_Rect):
		currentRenderTarget().Parent.DrawRectTo(self, dest, source)

	public def DrawSpriteTo(dest as GPU_Rect, index as int):
		return if index >= Count:
		currentRenderTarget().Parent.DrawRectTo(self, dest, self.SpriteRect[index])

	public TextureSize as TSgPoint:
		get: return FTextureSize
		set: 
			var lSize = FImageSize
			if (lSize.x % value.x > 0) or (lSize.y % value.y > 0):
				raise ESdlImageException('Texture size is not evenly divisible into base image size.')
			FTextureSize = value
			FTexturesPerRow = lSize.x / value.x
			FTextureRows = lSize.y / value.y


	public Count as int:
		get: return FTexturesPerRow * FTextureRows

	public SpriteRect[index as int] as GPU_Rect:
		get:
			x as int = index % FTexturesPerRow
			y as int = index / FTexturesPerRow
			result = GPU_MakeRect(x * FTextureSize.x, y * FTextureSize.y, FTextureSize.x, FTextureSize.y)
			return result

	static def CreateSprite(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return TSdlImage(filename, imagename, container, spriteSize)

	static def CreateSprite(surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return TSdlImage(surface, imagename, container, spriteSize)

	static def CreateBlankSprite(imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		return TSdlImage(imagename, container, spriteSize, count)

class TSdlOpaqueImageClass(TSdlImageClass):
	override def Create(filename as string, imagename as string, container as TSdlImages):
		return TSdlOpaqueImage(filename, imagename, container)

	override def CreateSprite(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		return TSdlOpaqueImage(filename, imagename, container)

class TSdlOpaqueImage(TSdlImage):
	static def constructor():
		_metaclass = TSdlImageClass.Instance of TSdlOpaqueImageClass()
	
	public def constructor(filename as string, imagename as string, container as TSdlImages):
		super(filename, imagename, container)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages):
		super(surface, imagename, container)

	public def constructor(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(filename, imagename, container, spriteSize)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(surface, imagename, container, spriteSize)

	public def constructor(imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super(imagename, container, spriteSize, count)
		
	protected override def ProcessImage(image as IntPtr):
		SDL.SDL_SetColorKey(image, 0, 0)
		SDL.SDL_SetSurfaceBlendMode(image, SDL.SDL_BlendMode.SDL_BLENDMODE_NONE)

[Disposable(Destroy)]
class TSdlImages(object):

	private FData as (TSdlImage) = (,)

	[Property(FreeOnClear)]
	private FFreeOnClear as bool

	[Property(ArchiveLoader)]
	private FArchiveLoader as TArchiveLoader

	private FUpdateMutex as IntPtr

	private FHash as Dictionary[of string, int]

	[Property(SpriteClass)]
	private FSpriteClass as TSdlImageClass

	private def GetItem(Num as int) as TSdlImage:
		if (Num >= 0) and (Num < FData.Length):
			return FData[Num]
		else: return null

	private def GetImage(name as string) as TSdlImage:
		index as int
		if FHash.TryGetValue(name, index):
			return FData[index]
		else: return null

	private def FindEmptySlot() as int:
		for i in range(FData.Length):
			if FData[i] == null:
				return i
		return -1

	private def Insert(element as TSdlImage) as int:
		Slot as int
		Slot = FindEmptySlot()
		if Slot == -1:
			Slot = FData.Length
			Array.Resize[of TSdlImage](FData, Max(Slot * 2, 16))
		FData[Slot] = element
		result = Slot
		FHash.Add(element.Name, result)
		return result

	public def constructor(FreeOnClear as bool, loader as TArchiveLoader):
		super()
		FFreeOnClear = FreeOnClear
		FArchiveLoader = loader
		FUpdateMutex = SDL.SDL_CreateMutex()
		FHash = Dictionary[of string, int]()
		FSpriteClass = classOf(TSdlImage)

	private def Destroy():
		self.Clear()
		SDL.SDL_DestroyMutex(FUpdateMutex)

	[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
	public def Contains(name as string) as bool:
		result = (self.IndexOf(name) != -1)
		return result

	public def IndexOf(element as TSdlImage) as int:
		result = IndexOf(element.Name)
		return result

	public def IndexOf(name as string) as int:
		result as int
		result = -1 unless FHash.TryGetValue(name, result)
		return result

	public def Add(element as TSdlImage) as int:
		SDL.SDL_LockMutex(FUpdateMutex)
		try:
			if FHash.ContainsKey(element.Name):
				result = IndexOf(element)
			else:
				result = Insert(element)
		ensure:
			SDL.SDL_UnlockMutex(FUpdateMutex)
		return result

	public def AddFromFile(filename as string, imagename as string) as int:
		result = AddFromFile(filename, filename, classOf(TSdlImage))
		return result

	public def AddFromFile(filename as string, imagename as string, imgClass as TSdlImageClass) as int:
		result = self.Add(imgClass.Create(filename, filename, null))
		return result

	public def AddFromArchive(filename as string, imagename as string, loader as TArchiveLoader) as int:
		if assigned(loader):
			filename = loader(filename)
		elif assigned(FArchiveLoader):
			filename = FArchiveLoader(filename)
		else:
			raise ESdlImageException('No archive loader available!')
		if string.IsNullOrEmpty(filename):
			raise ESdlImageException("Archive loader failed to extract $filename from the archive.")
		result = self.Add(TSdlImage(filename, imagename, null))
		return result

	public def AddSpriteFromArchive(filename as string, imagename as string, spriteSize as TSgPoint, imgClass as TSdlImageClass, loader as TArchiveLoader) as int:
		if assigned(loader):
			filename = loader(filename)
		elif assigned(FArchiveLoader):
			filename = FArchiveLoader(filename)
		else:
			raise ESdlImageException('No archive loader available!')
		if string.IsNullOrEmpty(filename):
			raise ESdlImageException("Archive loader failed to extract $filename from the archive.")
		result = self.Add(imgClass.CreateSprite(filename, imagename, null, spriteSize))
		return result

	public def AddSpriteFromArchive(filename as string, imagename as string, spritesize as TSgPoint, loader as TArchiveLoader) as int:
		result = AddSpriteFromArchive(filename, imagename, spritesize, FSpriteClass, loader)
		return result

	public def EnsureImage(filename as string, imagename as string) as TSdlImage:
		result = EnsureImage(filename, imagename, EMPTY)
		return result

	public def EnsureImage(filename as string, imagename as string, spritesize as TSgPoint) as TSdlImage:
		index as int
		if self.Contains(imagename):
			result = GetImage(imagename)
		else:
			if File.Exists(filename):
				index = AddFromFile(filename, imagename)
			else:
				index = AddSpriteFromArchive(filename, imagename, spritesize, null)
			result = self[index]
		return result

	public def EnsureBGImage(filename as string, imagename as string) as TSdlImage:
		index as int
		if self.Contains(imagename):
			result = GetImage(imagename)
		else:
			if File.Exists(filename):
				index = AddFromFile(filename, imagename, classOf(TSdlBackgroundImage))
			else:
				index = AddSpriteFromArchive(filename, imagename, EMPTY, classOf(TSdlBackgroundImage), null)
			result = self[index]
		return result

	public def Remove(Num as int):
		SDL.SDL_LockMutex(FUpdateMutex)
		try:
			if (Num < 0) or (Num >= FData.Length):
				return
			FHash.Remove(FData[Num].Name)
			FData[Num].Dispose()
			FData[Num] = null
		ensure:
			SDL.SDL_UnlockMutex(FUpdateMutex)

	public def Extract(num as int) as TSdlImage:
		SDL.SDL_LockMutex(FUpdateMutex)
		try:
			result as TSdlImage = null
			if (num < 0) or (num >= FData.Length):
				return result
			result = FData[num]
			FData[num] = null
			FHash.Remove(result.Name)
		ensure:
			SDL.SDL_UnlockMutex(FUpdateMutex)
		return result

	public def Clear():
		SDL.SDL_LockMutex(FUpdateMutex)
		try:
			FHash.Clear()
			if FFreeOnClear:
				for data in FData:
					data.Dispose() unless data is null
			Array.Resize of TSdlImage(FData, 0)
		ensure:
			SDL.SDL_LockMutex(FUpdateMutex)

	public def Pack():
		Lo = -1
		Hi = FData.Length - 1
		while Lo < Hi:
			++Lo
			if FData[Lo] == null:
				--Hi while (FData[Hi] == null) and (Hi > Lo)
				if Hi > Lo:
					FData[Lo] = FData[Hi]
					--Hi
		
		--Hi if FData[Hi] == null
		Array.Resize of TSdlImage(FData, (Hi * 2))
		FHash.Clear()
		for i in range(0, (Hi + 1)):
			FHash.Add(FData[i].Name, i)

	public Count as int:
		get: return FData.Length

	public self[Num as int] as TSdlImage:
		get: return GetItem(Num)

	public Image[Name as string] as TSdlImage:
		get: return GetImage(Name)

class TSdlBackgroundImageClass(TSdlImageClass):
	override def CreateSprite(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
			return TSdlBackgroundImage(filename, imagename, container, spriteSize)
	
	override def Create(filename as string, imagename as string, container as TSdlImages):
		return TSdlBackgroundImage(filename, imagename, container)

class TSdlBackgroundImage(TSdlImage):

	static def constructor():
		_metaclass = TSdlImageClass.Instance of TSdlOpaqueImageClass()
	
	public def constructor(filename as string, imagename as string, container as TSdlImages):
		super(filename, imagename, container)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages):
		super(surface, imagename, container)

	public def constructor(filename as string, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(filename, imagename, container, spriteSize)

	public def constructor(surface as IntPtr, imagename as string, container as TSdlImages, spriteSize as TSgPoint):
		super(surface, imagename, container, spriteSize)

	public def constructor(imagename as string, container as TSdlImages, spriteSize as TSgPoint, count as int):
		super(imagename, container, spriteSize, count)
		
	protected override def ProcessImage(image as IntPtr):
		SDL.SDL_SetColorKey(image, 1, 0)
		FColorKey.r = 0
		FColorKey.g = 0
		FColorKey.b = 0
		FColorKey.a = 0

let EMPTY = TSgPoint(x: 0, y: 0)
