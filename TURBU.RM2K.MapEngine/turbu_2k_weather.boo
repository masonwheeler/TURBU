namespace turbu.RM2K.weather

import turbu.defs
import SDL.ImageManager
import sdl.sprite
import sdl.canvas
import SG.defs
import Boo.Adt
import Pythia.Runtime
import SDL2
import SDL2.SDL2_GPU
import System
import commons
import TURBU.Meta
import System.Runtime.InteropServices

class TWeatherSprite(TParticleSprite):

	public def constructor(AParent as TParentSprite):
		super(AParent)

	[Property(Erratic)]
	private FErratic as bool
	
	private static random = System.Random()

	protected override def DoDraw():
		flip as SDL.SDL_RendererFlip
		if FEngine.Images[FImageIndex].Name != FImageName:
			SetImageName(FImageName)
		return if FImage == null
		
		var topleft = SgPoint(Math.Round(FX), Math.Round(FY))
		color as SDL.SDL_Color = GPU_GetColor(FImage.Surface)
		GPU_SetColor(FImage.Surface, SDL.SDL_Color(r: color.r, g: color.g, b: color.b, a: self.Alpha))
		FImage.Draw(topleft, flip)
		GPU_SetColor(FImage.Surface, color)

	public override def Move(moveCount as single):
		super.Move(moveCount)
		self.Alpha = Math.Min(Math.Max(round(255 * LifeTime), 0), 255)
		if FErratic:
			self.X += random.NextDouble() + random.NextDouble() - 1
		if self.Alpha == 0 or not self.InVisibleRect():
			self.Dead()

class TWeatherSystem(SpriteEngine):

	private FSize as int

	private FType as TWeatherEffects

	private FIntensity as byte

	private FFogSprite as TParentSprite

	private FFilling as bool

	private random = System.Random()

	private def AddSprite():
		sprite as TWeatherSprite = TWeatherSprite(self)
		sprite.Z = 2
		sprite.UpdateSpeed = 1
		sprite.X = random.Next(Canvas.Width)
		sprite.Y = random.Next(Canvas.Height / 3)
		sprite.Pinned = true
		sprite.Moves = true
		caseOf FType:
			case TWeatherEffects.None:
				assert false
			case TWeatherEffects.Rain:
				sprite.VelocityX = RAINFALLX
				sprite.VelocityY = RAINFALLY
				sprite.Decay = RAIN_DECAYRATE
				sprite.Alpha = (random.Next(256) if FFilling else 255)
				sprite.LifeTime = sprite.Alpha / 100.0
				sprite.ImageName = 'rain'
			case TWeatherEffects.Snow:
				sprite.VelocityX = (random.NextDouble() + random.NextDouble() / 2.0) - 1
				sprite.VelocityY = SNOWFALL
				sprite.Decay = SNOW_DECAYRATE
				sprite.ImageName = 'snow'
				sprite.Erratic = true
			case TWeatherEffects.Sand:
				sprite.VelocityX = (random.NextDouble() - 0.5) * RAINFALLY * 2.0
				sprite.VelocityY = RAINFALLY
				sprite.Decay = SANDRAIN_DECAYRATE
				sprite.Alpha = (random.Next(256) if FFilling else 255)
				sprite.LifeTime = sprite.Alpha / 73.143 // at 256, this comes out to 3.5
				sprite.ImageName = 'sandrain' + random.Next(4).ToString()
				sprite.X = (Canvas.Width / 2) + (sprite.VelocityX * 50)
				sprite.Y = 0
			default : pass

	private def CreateFog(r as byte, g as byte, b as byte) as IntPtr:
		result = SDL.SDL_CreateRGBSurface(0, FOGSIZE.x, FOGSIZE.y, 32, 0xFF0000, 0xFF00, 0xFF, 0xFF000000)
		try:
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_LockSurface(result)
			sur = Marshal.PtrToStructure[of SDL.SDL_Surface](result)
			generator = def():
				for y in range(0, 64):
					for x in range(0, 64):
						yield PixelData(x, y, SDL.SDL_MapRGBA(sur.format, r, g, b, random.Next(9) + 40))
			PutPixels(result, generator())
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_UnlockSurface(result)
		failure:
			SDL.SDL_FreeSurface(result)
		return result

	private def CreateRain(r as byte, g as byte, b as byte) as IntPtr:
		result = SDL.SDL_CreateRGBSurface(0, 8, 20, 32, 0xFF0000, 0xFF00, 0xFF, 0xFF000000)
		try:
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_LockSurface(result)
			sur = Marshal.PtrToStructure[of SDL.SDL_Surface](result)
			SDL.SDL_FillRect(result, IntPtr.Zero, SDL.SDL_MapRGBA(sur.format, 0, 0, 0, 0))
			var pixel = SDL.SDL_MapRGBA(sur.format, r, g, b, 128)
			generator = def():
				for y in range(1, 19):
					yield PixelData(7 - (y / 3), y, pixel)
			PutPixels(result, generator())
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_UnlockSurface(result)
		failure:
			SDL.SDL_FreeSurface(result)
		return result

	private def CreateSnow(r as byte, g as byte, b as byte) as IntPtr:
		result = SDL.SDL_CreateRGBSurface(0, 2, 2, 32, 0, 0, 0, 0)
		try:
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_LockSurface(result)
			sur = Marshal.PtrToStructure[of SDL.SDL_Surface](result)
			var pixel = SDL.SDL_MapRGBA(sur.format, r, g, b, 255)
			PutPixels(result, (PixelData(0, 0, pixel), PixelData(0, 1, pixel), PixelData(1, 0, pixel), PixelData(1, 1, pixel)))
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_UnlockSurface(result)
		failure:
			SDL.SDL_FreeSurface(result)
		return result

	private def CreateSand(r as byte, g as byte, b as byte) as IntPtr:
		var result = SDL.SDL_CreateRGBSurface(0, 1, 2, 32, 0, 0, 0, 0)
		try:
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_LockSurface(result)
			var sur = Marshal.PtrToStructure[of SDL.SDL_Surface](result)
			pixel as int = SDL.SDL_MapRGBA(sur.format, r, g, b, 185)
			PutPixels(result, (PixelData(0, 0, pixel), PixelData(0, 1, pixel)))
			if SDL.SDL_MUSTLOCK(result):
				SDL.SDL_UnlockSurface(result)
		failure:
			SDL.SDL_FreeSurface(result)
		return result

	private def LoadFog():
		EnsureFogSprite()
		fogW as int = self.Canvas.Width / FOGSIZE.x
		fogH as int = self.Canvas.Height / FOGSIZE.y
		++fogW if (self.Canvas.Width % FOGSIZE.x) != 0
		++fogH if (self.Canvas.Height % FOGSIZE.y) != 0
		if FFogSprite.Count != (fogW + 2) * (fogH + 2) * FIntensity:
			FFogSprite.Clear()
			weatherName as string = ('fog' if FType == TWeatherEffects.Fog else 'sand')
			for i in range(FIntensity):
				vx as single = random.NextDouble() - 0.5
				vy as single = random.NextDouble() - 0.5
				for y in range(-1, fogH):
					for x in range(-1, fogW):
						newFog = TWeatherSprite(FFogSprite)
						newFog.VelocityX = vx
						newFog.VelocityY = vy
						newFog.Z = 1
						newFog.X = x * FOGSIZE.x
						newFog.Y = y * FOGSIZE.y
						newFog.ImageName = weatherName + (random.Next(6) + 1).ToString()
						newFog.Moves = true
						newFog.UpdateSpeed = 1
		else: WrapFog()

	private def WrapFog():
		cw as int = self.Canvas.Width
		ch as int = self.Canvas.Height
		for fog in FFogSprite.SpriteList:
			if fog.X + fog.Width <= 0:
				fog.X += cw + fog.Width
			elif fog.X >= cw:
				fog.X -= cw + fog.Width
			if fog.Y + fog.Height <= 0:
				fog.Y += ch + fog.Height
			elif fog.Y >= ch:
				fog.Y -= ch + fog.Height

	private def EnsureFogSprite():
		if FFogSprite == null:
			FFogSprite = TParentSprite(self)
			FFogSprite.Z = 1

	private def CreateWeatherImage(surface as IntPtr, Name as string, addblend as bool):
		SDL.SDL_SetSurfaceBlendMode(surface, SDL.SDL_BlendMode.SDL_BLENDMODE_BLEND)
		img = TSdlImage(surface, Name, self.Images)
		if addblend:
			GPU_SetBlendMode(img.Surface, GPU_BlendPresetEnum.GPU_BLEND_NORMAL_ADD_ALPHA)
		else:
			GPU_SetBlendMode(img.Surface, GPU_BlendPresetEnum.GPU_BLEND_NORMAL)

	public def constructor(parent as SpriteEngine, images as SdlImages, canvas as SdlCanvas):
		super(parent, canvas)
		self.Z = 21
		self.Images = images
		for i in range(1, 7):
			CreateWeatherImage(CreateFog(242, 255, 242), "fog$i", true)
		for i in range(1, 7):
			CreateWeatherImage(CreateFog(255, 240, 183), "sand$i", true)
		CreateWeatherImage(CreateRain(255, 255, 255), 'rain', true)
		CreateWeatherImage(CreateSand(180, 170, 92), 'sandrain0', false)
		CreateWeatherImage(CreateSand(155, 4, 0), 'sandrain1', false)
		CreateWeatherImage(CreateSand(255, 114, 0), 'sandrain2', false)
		CreateWeatherImage(CreateSand(255, 255, 255), 'sandrain3', false)
		CreateWeatherImage(CreateSnow(255, 255, 255), 'snow', true)

	public override def Draw():
		return if FType == TWeatherEffects.None
		
		self.Dead()
		count as int = (0 if FSpriteList == null else FSpriteList.Count)
		goal as int = Math.Min(FSize - 1, count + (SPAWN_RATE[FType] * FIntensity)) + 1
		if count < goal:
			for i in range(count, goal):
				self.AddSprite()
		else: FFilling = false
		if FType in (TWeatherEffects.Fog, TWeatherEffects.Sand):
			LoadFog()
		if assigned(FSpriteList):
			for sprite in FSpriteList:
				sprite.Move(0)
		super.Draw()

	public WeatherType as TWeatherEffects:
		get: return FType
		set:
			return if value == FType
			FType = value
			if assigned(FSpriteList):
				for i in range(0, FSpriteList.Count):
					FSpriteList[i].Dead()
			FSize = FIntensity * WEATHER_POWER[FType]
			if value == TWeatherEffects.None:
				self.Dead()
			FFogSprite = null
			FFilling = true

	public Intensity as byte:
		get: return FIntensity
		set: 
			FIntensity = value
			FSize = FIntensity * WEATHER_POWER[FType]


	private static def PutPixels(surface as IntPtr, pixels as PixelData*):
		sur = Marshal.PtrToStructure[of SDL.SDL_Surface](surface)
	
		bpp as int = sur.Format.BytesPerPixel
		assert bpp == 4
		count = sur.h * sur.pitch / bpp
		pixelData = array(int, count)
		Marshal.Copy(sur.pixels, pixelData, 0, count)
		for pixel in pixels:
			idx = (pixel.Y * sur.pitch / bpp) + pixel.X
			pixelData[idx] = pixel.Pixel cast int
		Marshal.Copy(pixelData, 0, sur.pixels, count)

struct PixelData:
	X as int
	Y as int
	Pixel as uint
	
	def constructor(x as int, y as int, pixel as uint):
		X = x
		Y = y
		Pixel = pixel

let WEATHER_POWER = (0, 30, 45, 0, 20)
let RAINFALLX = -0.9
let RAINFALLY = 3.6
let SNOWFALL = 1.1
let RAIN_DECAYRATE = 0.05;
let SNOW_DECAYRATE = 0.002
let SANDRAIN_DECAYRATE = 0.06
let FOGSIZE = SgPoint(x: 64, y: 64)
let SPAWN_RATE = (0, 1, 2, 0, 1)
