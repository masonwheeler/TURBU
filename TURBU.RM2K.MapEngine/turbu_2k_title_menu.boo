namespace TURBU.RM2K.Menus

import turbu.defs
import turbu.constants
import TURBU.RM2K
import TURBU.TextUtils
import Boo.Adt
import Pythia.Runtime
import System
import TURBU.Meta
import System.Windows.Forms
import TURBU.RM2K.MapEngine
import SDL2.SDL2_GPU

class TTitleMenu(TGameMenuBox):

	protected override def DrawText():
		target = FTextTarget.RenderTarget
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_MENU_NEW], 4, 0, 1)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_MENU_LOAD], 4, 16, 1)
		GFontEngine.DrawText(target, GDatabase.value.Vocab[V_MENU_QUIT], 4, 32, 1)

	protected override def DoCursor(position as short):
		FCursorPosition = position
		if self.Focused:
			coords as GPU_Rect = GPU_MakeRect(FBounds.x + 4, FBounds.y + 6 + (16 * position), 62, 18)
			GMenuEngine.Value.Cursor.Visible = true
			GMenuEngine.Value.Cursor.Layout(coords)

	protected override def DoButton(input as TButtonCode):
		if input != TButtonCode.Cancel:
			super.DoButton(input)
		if input == TButtonCode.Enter:
			caseOf FCursorPosition:
				case 0:
					GGameEngine.value.NewGame()
					self.EndMessage()
				case 1:
					FocusPage('Save', 1)
				case 2:
					Application.Exit()
				default :
					assert false

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		super(parent, coords, main, owner)
		Array.Resize[of bool](FOptionEnabled, 3)
		for i in range(0, FOptionEnabled.Length):
			FOptionEnabled[i] = true

class TTitleMenuPage(TMenuPage):

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, layout as string):
		TITLE_SCREEN = '*TitleScreen'
		filename as string
		super(parent, coords, main, layout)
		filename = "Special Images\\$(GDatabase.value.Layout.TitleScreen).png"
		SetBG(filename, TITLE_SCREEN)

let TITLE_LAYOUT = '[{"Name": "Main", "Class": "TTitleMenu",   "Coords": [130, 148, 200, 212]}]'

initialization :
	TMenuEngine.RegisterMenuBoxClass(classOf(TTitleMenu))
	TMenuEngine.RegisterMenuPageEx(classOf(TTitleMenuPage), 'Title', TITLE_LAYOUT)
