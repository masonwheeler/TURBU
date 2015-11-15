namespace TURBU.RM2K.GameData

import System
import System.Collections.Generic
import SG.defs
import turbu.defs
import turbu.classes

[TableName('SystemData')]
class TGameLayout(TRpgDatafile):

	[Property(Width)]
	private FWidth as int

	[Property(Height)]
	private FHeight as int

	[Property(PhysWidth)]
	private FPWidth as int

	[Property(PhysHeight)]
	private FPHeight as int

	[Property(SpriteSize)]
	private FSpriteSize as TSgPoint

	[Property(SpriteSheet)]
	private FSpriteSheet as TSgPoint

	[Property(SpriteSheetFrames)]
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

	[Property(PortraitSize)]
	private FPortraitSize as TSgPoint

	[Property(TileSize)]
	private FTileSize as TSgPoint

	[Property(TitleScreen)]
	private FTitleScreen as string

	[Property(GameOverScreen)]
	private FGameOverScreen as string

	[Property(SysGraphic)]
	private FSysGraphic as string

	[Property(BattleSysGraphic)]
	private FBattleSysGraphic as string

	[Property(BattleTestBG)]
	private FBattleTestBG as string

	[Property(BattleTestTerrain)]
	private FBattleTestTerrain as int

	[Property(BattleTestFormation)]
	private FBattleTestFormation as int

	[Property(BattleTestSpecialCondition)]
	private FBattleTestSpecialCondition as int

	[Property(EditorCondition)]
	private FEditorCondition as int

	[Property(EditorHero)]
	private FEditorHero as int

	[Property(WallpaperStretch)]
	private FWallpaperStretch as bool

	[Property(FontID)]
	private FWhichFont as byte

	[Property(StartingHeroes)]
	private FStartingHero = array(int, 4)

	[Property(Transitions)]
	private FTransition as (TTransitions)

	[Property(BattleCommands)]
	private FCommands as (int)

	[Property(UsesFrame)]
	private FUsesFrame as bool

	[Property(Frame)]
	private FFrame as string

	[Property(ReverseGraphics)]
	private FReverseGraphics as bool

	[Property(TranslucentMessages)]
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

	[Property(MoveMatrix)]
	private FMoveMatrix as List[of ((int))]
