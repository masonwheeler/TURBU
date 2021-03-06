namespace TURBU.TextUtils

import Boo.Adt
import Pythia.Runtime
import System
import System.Collections.Generic
import SG.defs
import sdl.canvas
import SDL.ImageManager
import dm.shaders
import SDL2
import SDL2.SDL2_GPU

[Disposable()]
class TRpgFont(TObject):

	[Getter(Font)]
	private FFont as SDL2.NFont //PFtglFont

	private FSize as uint

	public def constructor(name as string, size as uint):
		var lName = System.IO.Path.Combine(TFontEngine.FontPath, name)
		FFont = NFont(lName, size)
		if FFont == IntPtr.Zero:
			raise EFontError("Unable to load font \"$name\".")
		FSize = size

[Disposable(Destroy, true)]
class TFontEngine(TObject):

	private FCurrent as TRpgFont

	private FCharBlit as int

	private FPass1 as int

	private FPass2 as int

	private FShaderEngine as TdmShaders

	private FTarget as SdlRenderTarget

	[Property(Glyphs)]
	private FGlyphs as TSdlImage

	private FFonts = List[of TRpgFont]()

	[Property(OnGetColor)]
	private FOnGetColor as Func[of GPU_Image_PTR]

	[Property(OnGetDrawRect)]
	private FOnGetDrawRect as Func[of int, GPU_Rect]

	private FTextBlock = GPU_LoadMultitextureBlock(2, ('texAlpha', 'texRGB'), ('RPG_TexCoord', 'RPG_TexCoord2'))

	[Getter(FontPath)]
	private static _fontPath as string

	def constructor():
		_fontPath = Environment.GetFolderPath(Environment.SpecialFolder.Fonts)
	
	private def Destroy():
		for font in FFonts:
			font.Dispose()
	
	def Initialize(shader as TdmShaders):
		assert FShaderEngine is null
		FCharBlit = shader.ShaderProgram('textV', 'textBlit')
		FPass1 = shader.ShaderProgram('textV', 'textShadow')
		FPass2 = shader.ShaderProgram('textV', 'textF')
		FShaderEngine = shader
		FTarget = SdlRenderTarget(SgPoint(16, 16))
		FFonts = List[of TRpgFont]()

	private def RenderChar(text as char):
		FTarget.Parent.PushRenderTarget()
		FTarget.SetRenderer()
		GPU_Clear(FTarget.RenderTarget)
		var targetText = (text.ToString() if text != char('%') else '%%')
		FCurrent.Font.draw(FTarget.RenderTarget, 0, 0, targetText)
		FTarget.Parent.PopRenderTarget()

	private def DrawTargetPass1(target as GPU_Target_PTR, x as single, y as single):
		FShaderEngine.UseShaderProgram(FPass1)
		FShaderEngine.SetUniformValue(FPass1, 'strength', 0.7f)
		GPU_Blit(FTarget.Image, IntPtr.Zero, target, x + FTarget.Width / 2.0, y + FTarget.Height / 2.0)

	private def DrawTargetPass2(target as GPU_Target_PTR, x as single, y as single, index as int):
		rect as GPU_Rect = FOnGetDrawRect(index)
		GPU_SetMultitextureBlock(FTextBlock)
		FShaderEngine.UseShaderProgram(FPass2)
		GPU_MultitextureBlit(
			(FTarget.Image, FOnGetColor()),
			(GPU_MakeRect(0, 0, FTarget.Width, FTarget.Height), rect),
			target, x + FTarget.Width / 2.0, y + FTarget.Height / 2.0)

	private def RenderGlyph(index as int):
		let GLYPH_SIZE = 12
		FTarget.Parent.PushRenderTarget()
		FTarget.SetRenderer()
		GPU_Clear(FTarget.RenderTarget)
		//GPU_ClearRGBA(FTarget.RenderTarget, 0, 0, 0, 255)
		
		srcRect = GPU_MakeRect((index % 13) * GLYPH_SIZE, (index / 13) * GLYPH_SIZE, GLYPH_SIZE, GLYPH_SIZE)
		FTarget.Parent.DrawRect(FGlyphs, ORIGIN, srcRect, 0)
		FTarget.Parent.PopRenderTarget()

	public def DrawText(target as GPU_Target_PTR, text as string, x as single, y as single, colorIndex as int) as SgFloatPoint:
		var result = sgPointF(x, y)
		for aChar in text:
			result = DrawChar(target, aChar, result.x, result.y, colorIndex)
		return result

	public def DrawChar(target as GPU_Target_PTR, text as char, x as single, y as single, colorIndex as int) as SgFloatPoint:
		glCheckError()
		RenderChar(text)
		GPU_FlushBlitBuffer()
		DrawTargetPass1(target, x + 1, y + 1)
		DrawTargetPass2(target, x, y, colorIndex)
		GPU_DeactivateShaderProgram()
		return sgPointF(x + TEXT_WIDTH, y)

	public def DrawGlyph(target as GPU_Target_PTR, index as int, x as single, y as single, colorIndex as int) as SgFloatPoint:
		RenderGlyph(index)
		GPU_FlushBlitBuffer()
		DrawTargetPass1(target, x + 1, y + 1)
		DrawTargetPass2(target, x, y, colorIndex)
		GPU_DeactivateShaderProgram()
		return sgPointF(x + (TEXT_WIDTH * 2), y)

	public def DrawTextRightAligned(target as GPU_Target_PTR, text as string, x as single, y as single, colorIndex as int) as SgFloatPoint:
		result = sgPointF(x - (text.Length * TEXT_WIDTH), y)
		DrawText(target, text, result.x, result.y, colorIndex)
		return result

	public def DrawTextCentered(target as GPU_Target_PTR, text as string, x as single, y as single, width as int, colorIndex as int):
		textWidth as int
		midpoint as single
		textWidth = text.Length * TEXT_WIDTH
		midpoint = x + (width cast double / 2.0)
		DrawText(target, text, midpoint - (textWidth / 2), y, colorIndex)

	public Current as TRpgFont:
		get: return FCurrent
		set:
			FCurrent = value
			FFonts.Add(value) unless FFonts.Contains(value)

class EFontError(Exception):
	def constructor(Message as string):
		super(Message)

let TEXT_WIDTH = 6
let GFontEngine = TFontEngine()