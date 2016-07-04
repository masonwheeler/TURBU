namespace TURBU.RM2K.GameData

import System
import System.Collections.Generic
import System.Linq.Enumerable

import Newtonsoft.Json.Linq
import SG.defs
import turbu.defs
import turbu.classes

[TableName('SystemData')]
class TGameLayout(TRpgDatafile):

	[Getter(Width)]
	private FWidth as int

	[Getter(Height)]
	private FHeight as int

	[Getter(PhysWidth)]
	private FPWidth as int

	[Getter(PhysHeight)]
	private FPHeight as int

	[Getter(SpriteSize)]
	private FSpriteSize as TSgPoint

	[Getter(SpriteSheet)]
	private FSpriteSheet as TSgPoint

	[Getter(SpriteSheetFrames)]
	private FSpriteSheetFrames as TSgPoint

	private FSpriteRow as int

	public SpriteRow as int:
		get:
			if FSpriteRow == 0:
				FSpriteRow = FSpriteSheetFrames.x * FSpriteSheet.x
			return FSpriteRow

	private FSpriteSheetRow  as int

	public SpriteSheetRow as int:
		get: 
			if FSpriteSheetRow  == 0:
				FSpriteSheetRow = self.SpriteRow * FSpriteSheetFrames.y * 2
			return FSpriteSheetRow 

	[Getter(PortraitSize)]
	private FPortraitSize as TSgPoint

	[Getter(TileSize)]
	private FTileSize as TSgPoint

	[Getter(TitleScreen)]
	private FTitleScreen as string

	[Getter(GameOverScreen)]
	private FGameOverScreen as string

	[Getter(SysGraphic)]
	private FSysGraphic as string

	[Getter(BattleSysGraphic)]
	private FBattleSysGraphic as string

	[Getter(BattleTestBG)]
	private FBattleTestBG as string

	[Getter(BattleTestTerrain)]
	private FBattleTestTerrain as int

	[Getter(BattleTestFormation)]
	private FBattleTestFormation as int

	[Getter(BattleTestSpecialCondition)]
	private FBattleTestSpecialCondition as int

	[Getter(EditorCondition)]
	private FEditorCondition as int

	[Getter(EditorHero)]
	private FEditorHero as int

	[Getter(WallpaperStretch)]
	private FWallpaperStretch as bool

	[Getter(FontID)]
	private FWhichFont as byte

	[Getter(StartingHeroes)]
	private FStartingHero = array(int, 4)

	[Getter(Transitions)]
	private FTransition = array(TTransitions, 6)

	[Getter(BattleCommands)]
	private FCommands = array(int, 4)

	[Getter(UsesFrame)]
	private FUsesFrame as bool

	[Getter(Frame)]
	private FFrame as string

	[Getter(ReverseGraphics)]
	private FReverseGraphics as bool

	[Getter(TranslucentMessages)]
	private FTranslucentMessages as bool

	public Transition[which as TTransitionTypes] as byte:
		get: return FTransition[which]

	public StartingHero[which as ushort] as int:
		get:
			assert which in range(1, 5)
			return FStartingHero[which - 1]

	public DefaultCommands[which as ushort] as ushort:
		get:
			assert which in range(1, 9)
			return FCommands[which]

	[Getter(MoveMatrix)]
	private FMoveMatrix = List[of ((int))]()
	
	def constructor(value as JObject):
		super()
		value.CheckRead('Width', FWidth)
		value.CheckRead('Height', FHeight)
		value.CheckRead('PhysWidth', FPWidth)
		value.CheckRead('PhysHeight', FPHeight)
		value.CheckRead('SpriteSheet', FSpriteSheet)
		value.CheckRead('SpriteSheetFrames', FSpriteSheetFrames)
		value.CheckRead('TitleScreen', FTitleScreen)
		value.CheckRead('GameOverScreen', FGameOverScreen)
		value.CheckRead('SysGraphic', FSysGraphic)
		value.CheckRead('BattleSysGraphic', FBattleSysGraphic)
		value.CheckRead('WallpaperStretch', FWallpaperStretch)
		value.CheckRead('FontID', FWhichFont)
		value.CheckRead('ReverseGraphics', FReverseGraphics)
		value.CheckRead('EditorCondition', FEditorCondition)
		value.CheckRead('EditorHero', FEditorHero)
		value.CheckRead('BattleTestBG', FBattleTestBG)
		value.CheckRead('BattleTestTerrain', FBattleTestTerrain)
		value.CheckRead('BattleTestFormation', FBattleTestFormation)
		value.CheckRead('BattleTestSpecialCondition', FBattleTestSpecialCondition)
		value.CheckRead('SpriteSize', FSpriteSize)
		value.CheckRead('PortraitSize', FPortraitSize)
		value.CheckRead('TileSize', FTileSize)
		ints as (int)
		if value.ReadArray('StartingHeroes', ints):
			for i in range(ints.Length):
				FStartingHero[i] = ints[i]
		strs as (string)
		if value.ReadArray('Transitions', strs):
			for i in range(strs.Length):
				self.FTransition[i] = Enum.Parse(TTransitions, strs[i]) cast TTransitions
		ints = (,)
		if value.ReadArray('BattleCommands', ints):
			for i in range(ints.Length):
				self.FCommands[i] = ints[i]
		
		mm as JArray = value['MoveMatrix']
		value.Remove('MoveMatrix')
		for mat as JArray in mm:
			newMatrix as ((int))
			Array.Resize[of (int)](newMatrix, mat.Count)
			for i in range (mat.Count):
				var elem = mat[i] cast JArray
				var lizt = elem.Select({t | t cast int}).ToArray()
				newMatrix[i] = lizt
			FMoveMatrix.Add(newMatrix)
		value.CheckEmpty()
