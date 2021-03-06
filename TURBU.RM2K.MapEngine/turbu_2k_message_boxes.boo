namespace TURBU.RM2K.Menus

import sdl.sprite
import turbu.defs
import SDL.ImageManager
import commons
import timing
import Boo.Adt
import Pythia.Runtime
import System
import SDL2.SDL2_GPU
import TURBU.RM2K
import turbu.RM2K.environment
import TURBU.Meta

[Disposable]
class TMessageBox(TGameMenuBox):

	[Getter(Portrait)]
	private FPortrait as TSprite

	private FNextArrow as TSystemTile

	private FRightPortrait as bool

	private def SetRightside(value as bool):
		FRightPortrait = value
		FPortrait.X = (self.Width - 64 if value else 8)

	private FTextRate as single

	private FNextCharTime as Timestamp

	private FImmediate as bool

	private def DrawNextChar():
		if FTextCounter >= FParsedText.Count:
			FNextCharTime = null
			return
		return unless FNextCharTime is null or FNextCharTime.TimeRemaining == 0
		if System.Threading.Monitor.TryEnter(self):
			try:
				while FTextCounter < FParsedText.Count:
					var value = FParsedText[FTextCounter]
					DrawChar(value)
					++FTextCounter
					unless FImmediate:
						SetTimer(FTextRate)
						break
			ensure:
				System.Threading.Monitor.Exit(self)

	private def SetTimer(value as single):
		var remainder = (0 if FNextCharTime is null else FNextCharTime.TimeRemaining)
		var duration = remainder + ((value * 1000) cast int)
		FNextCharTime = Timestamp(duration)

	private def SetTextRate(value as int):
		FTextRate = value * 0.0125

	protected override def NewLine():
		++FTextLine
		FTextPosX = (65 if FPortrait.Visible and not FRightPortrait else 3)
		FTextPosY = (LINE_HEIGHT * FTextLine) + TOP_MARGIN

	protected override def DrawSpecialChar(line as string):
		if line[0] == char('$'):
			super.DrawSpecialChar(line)
		else:
			assert line[0] == char('\\')
			try:
				caseOf line[1]:
					case char('$'): InsertText(GEnvironment.value.Money.ToString())
					case char('!'):
						pass //TODO: implement this
					case char('.'): SetTimer(0.25)
					case char('|'): SetTimer(1)
					case char('>'): FImmediate = true
					case char('<'): FImmediate = false
					case char('^'): EndMessage()
					case char('_'): FTextPosX += HALF_CHAR
					case char('E'):
						Abort //TODO: implement error reporting
					case char('e'):
						Abort //TODO: implement error reporting
					case char('C'): FTextColor = clamp(GetIntegerValue(FParsedText[FTextCounter]), 1, 20)
					case char('S'): SetTextRate(clamp(GetIntegerValue(FParsedText[FTextCounter]), 1, 20))
					case char('N'): InsertText(GetHeroName(GetIntegerValue(FParsedText[FTextCounter])))
					case char('V'): InsertText(GEnvironment.value.Ints[GetIntegerValue(FParsedText[FTextCounter])].ToString())
					case char('T'):
						Abort //TODO: implement string array in Environment
					case char('F'):
						Abort //TODO: implement float array in Environment
					case char('O'):
						Abort //TODO: implement vocab display
			except as EAbort:
				pass

	protected def InsertText(Text as string):
		for i in range(Text.Length):
			FParsedText.Insert(FTextCounter + i + 1, Text[i].ToString())

	protected override def DrawText():
		if FTextCounter == 0:
			FPortrait.Draw()
		DrawNextChar()
		if FTextCounter >= FParsedText.Count:
			DrawingDone()
		else: DrawingInProgress()

	protected override def PostDrawText():
		if FTextCounter >= FParsedText.Count:
			FNextArrow.Draw()

	protected override def ResetText():
		super.ResetText()
		ClearText()
		FImmediate = false
		FNextCharTime = null
		SetTextRate(1)

	protected override def DoButton(input as TButtonCode):
		if assigned(FButtonLock):
			if FButtonLock.TimeRemaining == 0:
				FButtonLock = null
			else: return
		if (input in (TButtonCode.Enter, TButtonCode.Cancel)) and self.DoneWriting:
			EndMessage()
			FButtonLock = Timestamp(180)

	protected override def DoSetPosition(value as TMboxLocation):
		SetY(FNextArrow, ((ord(value) + 1) * 80) - FNextArrow.Height)

	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect, main as TMenuEngine, owner as TMenuPage):
		FNextArrow = TSystemTile(parent, parent.SystemGraphic.Rects[TSystemRects.ArrowD], commons.ORIGIN, 1)
		FNextArrow.ImageName = parent.SystemGraphic.Filename
		FPortrait = TSprite(parent)
		FPortrait.SetSpecialRender()
		FPortrait.Visible = false
		super(parent, coords, main, owner)
		SetTextRate(1)
		Position = TMboxLocation.Top

	public override def MoveTo(coords as GPU_Rect):
		super.MoveTo(coords)
		SetX(FNextArrow, 152 + Math.Truncate(coords.x))
		SetY(FNextArrow, Math.Truncate(coords.y - 8))
		FPortrait.Y = 8
		SetRightside(FRightPortrait)

	public def SetPortrait(filename as string, index as byte):
		image as TSdlImage
		image = Engine.Images.EnsureImage("Portraits\\$filename", filename, GDatabase.value.Layout.PortraitSize)
		FPortrait.Visible = true
		FPortrait.ImageName = image.Name
		FPortrait.ImageIndex = index

	private DoneWriting as bool:
		get: return FTextCounter >= FParsedText.Count

	public Rightside as bool:
		get: return FRightPortrait
		set: SetRightside(value)

class TInputBox(TCustomMessageBox):
	
	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect):
		super(parent, coords)

	[Property(CanCancel)]
	protected FAcceptCancel as bool

	[Property(OnValidate)]
	private FOnValidate as Func[of string, bool]

	protected FTextDrawDone as bool

	protected def Validate(Text as string) as bool:
		return (FOnValidate(Text) if assigned(FOnValidate) else true)

	protected abstract def PrepareText():
		pass

	protected abstract def DrawText():
		pass

	protected override def DoDraw():
		super.DoDraw()
		PrepareText()
		(Engine cast TMenuSpriteEngine).Cursor.Draw()
		DrawText()

	protected def BasicDrawText():
		let TEXTV = 8
		let TEXTH = 8
		dest as GPU_Rect = GetDrawCoords()
		FTextTarget.Parent.Draw(FTextTarget, SG.defs.SgPoint(dest.x + TEXTH, dest.y + TEXTV))

class TChoiceBox(TInputBox):
	
	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect):
		super(parent, coords)

	private FChoices as (string)

	protected override def PrepareText():
		value as string
		return if FTextDrawDone
		
		FTextTarget.Parent.PushRenderTarget()
		FTextTarget.SetRenderer()
		try:
			ResetText()
			for value in FParsedText:
				DrawChar(value)
			if FParsedText.Count > 0:
				NewLine()
			FPromptLines = FTextLine
			for i in range(FChoices.Length):
				value = FChoices[i]
				FOptionEnabled[i] = Validate(value)
				ClearText()
				DoParseText(value, FParsedText)
				for value in FParsedText:
					DrawChar(value)
				NewLine()
		ensure:
			FTextTarget.Parent.PopRenderTarget()
		PlaceCursor(0)
		FTextDrawDone = true

	protected override def DrawText():
		BasicDrawText()

	protected override def ParseText(input as string):
		super.ParseText(input)
		FTextDrawDone = false

	public override def Button(input as TButtonCode):
		caseOf input:
			case TButtonCode.Cancel:
				if FAcceptCancel:
					(Engine cast TMenuSpriteEngine).MenuInt = -1
					EndMessage()
					PlaySound(TSfxTypes.Cancel)
			default :
				super.Button(input)
				if (input == TButtonCode.Enter) and FOptionEnabled[FCursorPosition]:
					EndMessage()

	public def SetChoices(choices as (string)):
		FChoices = choices
		FOptionEnabled = array(bool, choices.Length)

class TValueInputBox(TInputBox):
	
	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect):
		super(parent, coords)

	private FInputResult as (byte)

	private def ComputeInputResult() as int:
		i as int
		result = 0
		for i in range(FInputResult.Length, -1, -1):
			result = (result * 10) + FInputResult[i]
		return result

	protected override def PrepareText():
		value as string
		digit as Byte
		return if FTextDrawDone
		
		FTextTarget.Parent.PushRenderTarget()
		FTextTarget.SetRenderer()
		try:
			ResetText()
			for value in FParsedText:
				DrawChar(value)
			if FParsedText.Count > 0:
				NewLine()
			FPromptLines = FTextLine
			for digit in FInputResult:
				DrawLine(digit.ToString() + ' ')
			PlaceCursor(FCursorPosition)
		ensure:
			FTextTarget.Parent.PopRenderTarget()
		FTextDrawDone = true

	protected override def DrawText():
		BasicDrawText

	public override def Button(input as TButtonCode):
		caseOf input:
			case TButtonCode.Enter:
				(Engine cast TMenuSpriteEngine).MenuInt = ComputeInputResult()
				EndMessage()
				PlaySound(TSfxTypes.Accept)
			case TButtonCode.Down:
				if InputResult[FCursorPosition] == 0:
					InputResult[FCursorPosition] = 9
				else:
					InputResult[FCursorPosition] = (InputResult[FCursorPosition] - 1)
				PlaySound(TSfxTypes.Cursor)
			case TButtonCode.Up:
				if InputResult[FCursorPosition] == 9:
					InputResult[FCursorPosition] = 0
				else:
					InputResult[FCursorPosition] = (InputResult[FCursorPosition] + 1)
				PlaySound(TSfxTypes.Cursor)
			case TButtonCode.Left:
				if FCursorPosition > 0:
					PlaceCursor((FCursorPosition - 1))
				PlaySound(TSfxTypes.Cursor)
			case TButtonCode.Right:
				if FCursorPosition < FInputResult.Length - 1:
					PlaceCursor(FCursorPosition + 1)
				PlaySound(TSfxTypes.Cursor)
			default:
				pass

	public def SetupInput(digits as byte):
		FInputResult = array(byte, digits)

	public override def PlaceCursor(position as short):
		max as short = FInputResult.Length
		width as ushort = SEPARATOR
		assert FInputResult.Length > 0
		position = Math.Min(position, FInputResult.Length - 1)
		coords = GPU_MakeRect(
			8 + (position * (width + SEPARATOR)),
			(((FPromptLines * 15) + FBounds.y) + (ord(FPosition) * 80)) + 11,
			width * 2,
			18)
		coords.h += coords.y
		coords.w += coords.x
		if FCursorPosition > max:
			coords.y += (FCursorPosition / self.Columns) * 15
		FCursorPosition = position
		cursor as TMenuCursor = (FEngine cast TMenuSpriteEngine).Cursor
		cursor.Visible = true
		cursor.Layout(coords)

	public InputResult[x as byte] as byte:
		get:
			assert x < FInputResult.Length
			return FInputResult[x]
		set:
			assert x < FInputResult.Length
			assert value < 10
			return if FInputResult[x] == value
			FInputResult[x] = value
			FTextDrawDone = false

class TPromptBox(TInputBox):
	
	public def constructor(parent as TMenuSpriteEngine, coords as GPU_Rect):
		super(parent, coords)

	public override def Button(input as TButtonCode):
		caseOf input:
			case TButtonCode.Enter:
				if Validate(FParsedText[FCursorPosition]):
					(Engine cast TMenuSpriteEngine).MenuInt = FCursorPosition
					EndMessage()
					PlaySound(TSfxTypes.Accept)
				else: PlaySound(TSfxTypes.Buzzer)
			case TButtonCode.Cancel:
				if FAcceptCancel:
					(Engine cast TMenuSpriteEngine).MenuInt = 3
					EndMessage()
					PlaySound(TSfxTypes.Cancel)
			case TButtonCode.Down, TButtonCode.Up:
				PlaceCursor((3 if FCursorPosition == 2 else 2))
				PlaySound(TSfxTypes.Cursor)
			default :
				pass
	
	protected override def PrepareText():
		raise 'TPromptBox.PrepareText() is not implemented yet'

	protected override def DrawText():
		raise 'TPromptBox.DrawText() is not implemented yet'

initialization :
	TMenuEngine.RegisterMenuBoxClass(classOf(TMessageBox))
