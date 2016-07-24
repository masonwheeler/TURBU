namespace TURBU.RM2K.Import

import System
import System.Collections.Generic
import Boo.Adt
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import SDL2.SDL
import SDL2.SDL_image
import SDL2.SDL_Pnglite
import TURBU.Meta
import TURBU.RM2K.Import.LCF

static class TTilesetConverter:
	def Convert(base as RMTileset, tilesets as HashSet[of string]) as MacroStatement:
		result = [|
			Tileset $(base.ID):
				Name $(base.Name)
				HighSpeed $(base.HighSpeed)
		|]
		unless string.IsNullOrEmpty(base.Filename):
			tilesets.Add(base.Filename)
			result.Body.Add(ConvertTileGroups(base))
		return result
	
	let DATA_INDEX = (0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 66, 114, 162)
	
	private def ConvertTileGroups(base as RMTileset) as MacroStatement:
		result = MacroStatement('TileGroups')
		blockData = (base.BlockData cast (byte) if assigned(base.BlockData) else null)
		uBlockData = (base.UBlockData cast (byte) if assigned(base.UBlockData) else null)
		terrain = (base.Terrain cast (int) if assigned(base.Terrain) else null)
		for i in range(TILESET_MAP.Length):
			groupname = "$(base.Filename)-$(TILESET_NAME[i])"
			newRecord = [|
				TileGroupRecord $(i + 1):
					GroupName $groupname
					Layers $((0 if i <= 18 else 1))
					AnimDir $([|PingPong|] if base.Animation else [|Forward|])
			|]
			attributes = MacroStatement('Attributes')
			if i <= 18:
				terrainM = MacroStatement('Terrain')
				for j in range(DATA_INDEX[i], DATA_INDEX[i + 1]):
					attributes.Body.Add(ConvertAttributes((blockData[j] if assigned(blockData) else 15)))
					terrainM.Arguments.Add((IntegerLiteralExpression(terrain[j]) if assigned(terrain) else [|1|]))
				newRecord.Body.Add(terrainM)
			else:
				for j in range((i - 19) * 48, (i - 18) * 48):
					defaultFlags = (31 if j == 0 else 15)
					attributes.Body.Add((ConvertAttributes((uBlockData[j] if assigned(uBlockData) else defaultFlags))))
			newRecord.Body.Add(attributes)
			result.Body.Add(newRecord)
		SwapTileGroupData(result, 1, 2)
		SwapTileGroupData(result, 5, 6)
		SwapTileGroupData(result, 9, 10)
		SwapTileGroupData(result, 13, 14)
		return result
	
	private def SwapTileGroupData(value as MacroStatement, l as int, r as int):
		group1 = value.Body.Statements[l] as MacroStatement
		group2 = value.Body.Statements[r] as MacroStatement
		tempL as MacroStatement
		tempR as MacroStatement
		tempL = group1.SubMacro('Attributes')
		tempR = group2.SubMacro('Attributes')
		group1.Body.Statements.Remove(tempL)
		group2.Body.Statements.Remove(tempR)
		group1.Body.Add(tempR)
		group2.Body.Add(tempL)
		
		tempL = group1.SubMacro('Terrain')
		return if tempL is null
		tempR = group2.SubMacro('Terrain')
		group1.Body.Statements.Remove(tempL)
		group2.Body.Statements.Remove(tempR)
		group1.Body.Add(tempR)
		group2.Body.Add(tempL)
	
	private def ConvertAttributes(value as int) as ListLiteralExpression:
		result = ListLiteralExpression()
		result.Items.Add([|Down|]) if value & 1
		result.Items.Add([|Left|]) if value & 2
		result.Items.Add([|Right|]) if value & 4
		result.Items.Add([|Up|]) if value & 8
		result.Items.Add([|Ceiling|]) if value & 16
		result.Items.Add([|Overhang|]) if value & 32
		result.Items.Add([|Countertop|]) if value & 64
		return result

let TILESET_NAME = ('water1', 'water3', 'water2', 'anims', 'border1', 'border2', 'border3', 'border4', 'border5',
	'border6', 'border7', 'border8', 'border9', 'border10', 'border11', 'border12', 'lowtile1', 'lowtile2',
	'lowtile3', 'hitile1', 'hitile2', 'hitile3')

let TILESET_MAP = (
	SDL_Rect(0, 0, 48, 64),
	SDL_Rect(0, 64, 48, 64),
	SDL_Rect(48, 0, 48, 64),
	SDL_Rect(48, 64, 48, 64),
	
	SDL_Rect(0, 128, 48, 64),
	SDL_Rect(0, 192, 48, 64),
	SDL_Rect(48, 128, 48, 64),
	SDL_Rect(48, 192, 48, 64),
	
	SDL_Rect(96, 0, 48, 64),
	SDL_Rect(96, 64, 48, 64),
	SDL_Rect(144, 0, 48, 64),
	SDL_Rect(144, 64, 48, 64),
	
	SDL_Rect(96, 128, 48, 64),
	SDL_Rect(96, 192, 48, 64),
	SDL_Rect(144, 128, 48, 64),
	SDL_Rect(144, 192, 48, 64),
	
	SDL_Rect(192, 0, 96, 128),
	SDL_Rect(192, 128, 96, 128),
	SDL_Rect(288, 0, 96, 128),
	SDL_Rect(288, 128, 96, 128),
	SDL_Rect(384, 0, 96, 128),
	SDL_Rect(384, 128, 96, 128)
)

public def ConvertTileset(filename as string, outPath as string) as MacroStatement*:
	lFilename = System.IO.Path.GetFileNameWithoutExtension(filename)
	surface = IMG_Load(filename)
	try:
		return null if surface == IntPtr.Zero
		aSurface as SDL_Surface = Marshal.PtrToStructure(surface, SDL_Surface)
		aFormat = aSurface.Format
		return unless aSurface.w == 480 and aSurface.h == 256 and aFormat.BitsPerPixel == 8
		for i in range(TILESET_MAP.Length):
			currentRect = TILESET_MAP[i]
			subSurface = SDL_CreateRGBSurface(0, currentRect.w, currentRect.h, 8, 0, 0, 0, 0)
			try:
				aSubSurface as SDL_Surface = Marshal.PtrToStructure(subSurface, SDL_Surface)
				SDL_SetPaletteColors(aSubSurface.Format.palette, aFormat.Palette.colors, 0, aFormat.Palette.ncolors)
				SDL_BlitSurface(surface, currentRect, subSurface, IntPtr.Zero)
				unless SDL_SavePNG(subSurface, System.IO.Path.Combine(outPath, "$(lFilename)-$(TILESET_NAME[i]).png")) == 0:
					raise SDL_GetError()
				yield CreateNewGroup(lFilename, i)
			ensure:
				SDL_FreeSurface(subSurface)
	ensure:
		SDL_FreeSurface(surface)

private def CreateNewGroup(filename as string, i as int) as MacroStatement:
	groupname = "$(filename)-$(TILESET_NAME[i])"
	result = [|
		TileGroup $groupname:
			Filename $filename
	|]
	if i == 1:
		lf = "$(filename)-$(TILESET_NAME[0])"
		result.Body.Add([|LinkedFilename $lf|])
		result.Body.Add([|Ocean true|])
	elif i in (0, 2):
		lf = "$(filename)-$(TILESET_NAME[1])"
		result.Body.Add([|LinkedFilename $lf|])
		result.Body.Add([|Ocean false|])
	caseOf i:
		case 0, 1, 2: tt = [|TileType Bordered, Animated|]
		case 3: tt = [|TileType Animated|]
		default: tt = ([|TileType Bordered|] if i <= 15 else null)
	isMini = (i < 16) and (i != 3)
	dimSize = (8 if isMini else 16)
	result.Body.Add([|Dimensions $dimSize, $dimSize|])
	result.Body.Add(tt) if tt is not null
	return result