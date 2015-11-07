namespace turbu.RM2K.transitions.graphics

import turbu.defs
import sdl.canvas
import SG.defs
import commons
import timing
import dm.shaders
import sdl.sprite
import Boo.Adt
import Pythia.Runtime
import TURBU.TransitionInterface
import SDL2
import SDL2.SDL2_GPU
import System
import turbu.RM2K.transitions
import turbu.RM2K.sprite.engine
import turbu.RM2K.distortions
import turbu.RM2K.environment
import TURBU.Meta

enum TDivideStyle:
	Vert
	Horiz
	Both

enum TDirectionWipe:
	Random
	Downward
	Upward
	Leftward
	Rightward

class TTransition(TObject, ITransition):

	protected FCurrentTarget as int

	protected FFirstRenderDone as bool

	protected FOnFinished as Action

	protected FShowing as bool

	protected FProgress as int

	virtual def Setup(showing as bool, OnFinished as Action):
		FShowing = showing
		FOnFinished = OnFinished

	protected abstract def InternalDraw() as bool:
		pass

	def Draw() as bool:
		result = InternalDraw()
		if not result:
			FOnFinished
		return result

class TMaskTransition(TTransition):

	private def DrawMask(before as TSdlRenderTarget, after as TSdlRenderTarget, tran as TSdlRenderTarget):
		shaders as TdmShaders
		shaderProgram as int
		GPU_SetShaderImage(before.Image, 0, 0)
		GPU_SetShaderImage(after.Image, 1, 1)
		GPU_SetShaderImage(tran.Image, 2, 2)
		shaders = GSpriteEngine.value.ShaderEngine
		shaderProgram = shaders.ShaderProgram('default', 'MaskF')
		shaders.UseShaderProgram(shaderProgram)
		shaders.SetUniformValue(shaderProgram, 'before', 0)
		shaders.SetUniformValue(shaderProgram, 'after', 1)
		shaders.SetUniformValue(shaderProgram, 'mask', 2)
		before.DrawFull()

	protected abstract def DoDraw() as bool:
		pass

	protected override def InternalDraw() as bool:
		tranTarget as TSdlRenderTarget
		GSpriteEngine.value.Canvas.PushRenderTarget()
		tranTarget = GRenderTargets[RENDERER_TRAN]
		tranTarget.SetRenderer()
		result = DoDraw()
		tranTarget.Parent.PopRenderTarget()
		DrawMask(GRenderTargets[RENDERER_MAIN], GRenderTargets[RENDERER_ALT], tranTarget)
		GPU_DeactivateShaderProgram()
		return result

	public override def Setup(showing as bool, OnFinished as Action):
		tranTarget as TSdlRenderTarget
		super.Setup(showing, OnFinished)
		runThreadsafe(true) def ():
			GSpriteEngine.value.Canvas.PushRenderTarget()
			tranTarget = GRenderTargets[RENDERER_TRAN]
			tranTarget.SetRenderer()
			tranTarget.Parent.Clear(SDL_BLACK)
			tranTarget.Parent.PopRenderTarget()

class TFadeTransition(TMaskTransition):

	protected override def DoDraw() as bool:
		workload as int
		fadeColor as SDL.SDL_Color
		workload = Math.Max((255 / (FADETIME[0] / TRpgTimestamp.FrameLength)), 1)
		FProgress += workload * 2
		FProgress = Math.Min(FProgress, 255)
		fadeColor.r = FProgress
		fadeColor.g = FProgress
		fadeColor.b = FProgress
		GSpriteEngine.value.Canvas.Clear(fadeColor)
		return (FProgress < 255)

class TBlockTransition(TMaskTransition):

	private FBlockArray as (int)
	
	private FRng = Random()

	private def ShuffleBlockArray(direction as TDirectionWipe):
		caseOf direction:
			case TDirectionWipe.Random: ShuffleBlocksRandomly()
			case TDirectionWipe.Downward: ShuffleBlocksDownward()
			case TDirectionWipe.Upward: ShuffleBlocksUpward()
			default: raise Exception('Shuffle style not implemented')

	private def ShuffleBlocksRandomly():
		for i in range(FBlockArray.Length):
			swap(FBlockArray[i], FBlockArray[FRng.Next(FBlockArray.Length)])
		
	let BLOCKSIZE = 4
	
	private def ShuffleBlocksDownward():
		VERTICAL_RANGE = 12
		HALFRANGE = VERTICAL_RANGE / 2
		width as int = GSpriteEngine.value.Canvas.Width / BLOCKSIZE
		freeFloor as int = width * HALFRANGE
		freeCeiling as int = pred(FBlockArray.Length) - freeFloor
		rangeFloor as int = width * VERTICAL_RANGE
		rangeCeiling as int = pred(FBlockArray.Length) - rangeFloor
		for i in range(freeFloor + 1):
			swap(FBlockArray[i], FBlockArray[GEnvironment.value.Random(0, rangeFloor)])
		for i in range(freeFloor + 1, freeCeiling + 1):
			swap(FBlockArray[i], FBlockArray[GEnvironment.value.Random(i - freeFloor, i + freeFloor)])
		for i in range(freeCeiling + 1, FBlockArray.Length):
			swap(FBlockArray[i], FBlockArray[GEnvironment.value.Random(rangeCeiling, pred(FBlockArray.Length))])

	private def ShuffleBlocksUpward():
		ShuffleBlocksDownward()
		for i in range(FBlockArray.Length / 2):
			swap(FBlockArray[i], FBlockArray[FBlockArray.Length - i])

	protected override def DoDraw() as bool:
		workload as int
		width as int
		corner as TSgPoint
		workload = Math.Max((FBlockArray.Length - 1) / (FADETIME[1] / TRpgTimestamp.FrameLength), 1)
		width = GSpriteEngine.value.Canvas.Width / BLOCKSIZE
		for i in range(FProgress, Math.Min(FProgress + workload, FBlockArray.Length)):
			corner = sgPoint((FBlockArray[i] % width) * BLOCKSIZE, (FBlockArray[i] / width) * BLOCKSIZE)
			GSpriteEngine.value.Canvas.FillRect(GPU_MakeRect(corner.x, corner.y, BLOCKSIZE, BLOCKSIZE), SDL_WHITE)
			++FProgress
		return FProgress < FBlockArray.Length - 1

	public def constructor(direction as TDirectionWipe):
		Canvas as TSdlCanvas = GSpriteEngine.value.Canvas
		w as int = Canvas.Width / BLOCKSIZE
		h as int = Canvas.Height / BLOCKSIZE
		++w if Canvas.Width % BLOCKSIZE != 0
		++h if Canvas.Height % BLOCKSIZE != 0
		Array.Resize[of int](FBlockArray, (w * h))
		for i in range(FBlockArray.Length):
			FBlockArray[i] = i
		ShuffleBlockArray(direction)

class TBlindsTransition(TMaskTransition):
	
	let BLINDSIZE = 8
	
	private FTimer as int

	private FInterval as int

	protected override def DoDraw() as bool:
		FTimer += TRpgTimestamp.FrameLength
		if FTimer >= FInterval:
			width as int = GSpriteEngine.value.Canvas.Width
			i as int = FProgress
			repeat :
				GSpriteEngine.value.Canvas.FillRect(GPU_MakeRect(0, i, width, 1), SDL_WHITE)
				i += BLINDSIZE
				until i >= GSpriteEngine.value.Canvas.Height
			if FShowing:
				--FProgress
			else:
				++FProgress
			FTimer -= FInterval
		result = (FProgress >= 0 if FShowing else FProgress < BLINDSIZE)
		return result

	public override def Setup(showing as bool, OnFinished as Action):
		super.Setup(showing, OnFinished)
		FProgress = BLINDSIZE if FShowing

	public def constructor():
		super()
		FInterval = FADETIME[0] / BLINDSIZE
		FTimer = FInterval - TRpgTimestamp.FrameLength

class TStripeTransition(TMaskTransition):

	private FVertical as bool

	private FStripeArray as (int)

	private def setupStripeArray(vertical as bool):
		dimension as int = (GSpriteEngine.value.Canvas.Height if vertical else GSpriteEngine.value.Canvas.Width)
		Array.Resize[of int](FStripeArray, dimension / STRIPESIZE)
		i as int = 0
		j as int = FStripeArray.Length - 1
		--j if (j % 2) == 0
		repeat :
			FStripeArray[i] = i
			FStripeArray[(i + 1)] = j if j >= 0
			i += 2
			j -= 2
			until i >= FStripeArray.Length or j < 0

	protected override def DoDraw() as bool:
		i as int
		workload as int
		corner as TSgPoint
		workload = (FStripeArray.Length - 1) / (FADETIME[1] / TRpgTimestamp.FrameLength)
		for i in range(FProgress, Math.Min(FProgress + workload, FStripeArray.Length - 1) + 1):
			if FVertical:
				corner = sgPoint(FStripeArray[i] * STRIPESIZE, 0)
				GSpriteEngine.value.Canvas.FillRect(
					GPU_MakeRect(corner.x, corner.y, STRIPESIZE, GSpriteEngine.value.Canvas.Height),
					SDL_WHITE)
			else:
				corner = sgPoint(0, (FStripeArray[i] * STRIPESIZE))
				GSpriteEngine.value.Canvas.FillRect(
					GPU_MakeRect(corner.x, corner.y, GSpriteEngine.value.Canvas.Width, STRIPESIZE),
					SDL_WHITE)
			++FProgress
		return (FProgress < FStripeArray.Length - 1)

	public def constructor(vertical as bool):
		super()
		FVertical = vertical
		setupStripeArray(vertical)

class TRectIrisTransition(TMaskTransition):

	private FCenter as TSgPoint

	private FColor as SDL.SDL_Color

	private FEraseColor as SDL.SDL_Color

	private FInOut as bool

	protected override def DoDraw() as bool:
		i as int
		workload as int
		ratio as single
		mask as GPU_Rect
		GSpriteEngine.value.Canvas.Clear(FEraseColor)
		workload = (GSpriteEngine.value.Canvas.Height / 2) / Math.Max(FADETIME[0] / TRpgTimestamp.FrameLength, 1)
		ratio = (GSpriteEngine.value.Canvas.Width cast double) / (GSpriteEngine.value.Canvas.Height cast double)
		i = Math.Min(FProgress + workload, (GSpriteEngine.value.Canvas.Height / 2))
		
		if FInOut:
			mask.x = FCenter.x - round(i * ratio)
			mask.y = FCenter.y - i
			mask.w = FCenter.x + round(i * ratio)
			mask.h = FCenter.y + i
		else:
			mask.x = round(i * ratio)
			mask.y = i
			mask.w = GSpriteEngine.value.Canvas.Width - mask.x
			mask.y = GSpriteEngine.value.Canvas.Height - mask.y
		mask.w -= mask.x
		mask.h -= mask.y
		
		GSpriteEngine.value.Canvas.FillRect(mask, FColor)
		FProgress += workload
		return FProgress < (GSpriteEngine.value.Canvas.Height / 2)

	public def constructor(inOut as bool):
		super()
		FCenter = sgPoint(GSpriteEngine.value.Canvas.Width / 2, GSpriteEngine.value.Canvas.Height / 2)
		FInOut = inOut
		if FInOut:
			FEraseColor = SDL_BLACK
			FColor = SDL_WHITE
		else:
			FEraseColor = SDL_WHITE
			FColor = SDL_BLACK

class TBof2Transition(TMaskTransition):

	protected override def DoDraw() as bool:
		i as int
		j as int
		width as int
		workload as int
		endpoint as int
		width = GSpriteEngine.value.Canvas.Width
		endpoint = (width * 4) + GSpriteEngine.value.Canvas.Height
		workload = endpoint / (FADETIME[1] / TRpgTimestamp.FrameLength)
		FProgress += workload
		j = FProgress / 4
		i = 0
		repeat :
			if j <= width:
				if (i % 2) == 0:
					GSpriteEngine.value.Canvas.FillRect(GPU_MakeRect(0, i, j, 1), SDL_WHITE)
				else:
					GSpriteEngine.value.Canvas.FillRect(GPU_MakeRect(width - j, i, j, 1), SDL_WHITE)
			if ((i % 4) == 0) and (i > 0):
				--j
			++i
			until i > GSpriteEngine.value.Canvas.Height or (j <= 0)
		return FProgress <= endpoint

class TScrollTransition(TTransition):

	private FDirection as TFacing

	private FBoundary as int

	protected override def InternalDraw() as bool:
		workload as int
		timeslice as int
		i as int
		dst as TSgPoint
		dst2 as TSgPoint
		Canvas as TSdlCanvas
		Canvas = GSpriteEngine.value.Canvas
		Canvas.Clear(SDL_BLACK)
		timeslice = Math.Max((FADETIME[0] / TRpgTimestamp.FrameLength), 1)
		caseOf FDirection:
			case TFacing.Up, TFacing.Down:
				workload = (GSpriteEngine.value.Canvas.Height / timeslice)
			case TFacing.Right, TFacing.Left:
				workload = (GSpriteEngine.value.Canvas.Width / timeslice)
			default :
				raise Exception('Invalid direction')
		i = FProgress + workload
		i *= -1 if FDirection in (TFacing.Up, TFacing.Left)
		dst = (sgPoint(0, i) if FDirection in (TFacing.Up, TFacing.Down) else sgPoint(i, 0))
		caseOf FDirection:
			case TFacing.Up:
				i += Canvas.Height
			case TFacing.Left:
				i += Canvas.Width
			case TFacing.Down:
				i -= Canvas.Height
			case TFacing.Right:
				i -= Canvas.Width
		dst2 = (sgPoint(0, i) if FDirection in (TFacing.Up, TFacing.Down) else sgPoint(i, 0))
		Canvas.Draw(GRenderTargets[RENDERER_MAIN], dst)
		Canvas.Draw(GRenderTargets[RENDERER_ALT], dst2)
		FProgress += workload
		return FProgress < FBoundary

	public def constructor(direction as TFacing):
		super()
		FDirection = direction
		caseOf FDirection:
			case TFacing.Up, TFacing.Down:
				FBoundary = GSpriteEngine.value.Canvas.Height
			case TFacing.Right, TFacing.Left:
				FBoundary = GSpriteEngine.value.Canvas.Width
			default :
				raise Exception('Invalid direction')

class TDivideTransition(TTransition):

	private FStyle as TDivideStyle

	private def DivideVert(workload as int, boundary as int):
		Canvas as TSdlCanvas
		Canvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(0, -workload, Canvas.Width, Canvas.Height / 2),
			GPU_MakeRect(0, 0, Canvas.Width, boundary))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(0, boundary + workload, Canvas.Width, Canvas.Height / 2),
			GPU_MakeRect(0, boundary, Canvas.Width, Canvas.Height))

	private def DivideHoriz(workload as int, boundary as int):
		Canvas as TSdlCanvas
		Canvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(-workload, 0, Canvas.Width / 2, Canvas.Height),
			GPU_MakeRect(0, 0, boundary, Canvas.Height))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(boundary + workload, 0, Canvas.Width / 2, Canvas.Height),
			GPU_MakeRect(boundary, 0, Canvas.Width, Canvas.Height))

	private def DivideQuarters(workloadH as int, boundaryH as int, workloadV as int, boundaryV as int):
		Canvas as TSdlCanvas
		Canvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(-workloadH, -workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(0, 0, boundaryH, boundaryV))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(-workloadH, boundaryV + workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(0, boundaryV, boundaryH, Canvas.Height))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(boundaryH + workloadH, -workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(boundaryH, 0, Canvas.Width, boundaryV))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_MAIN],
			GPU_MakeRect(boundaryH + workloadH, boundaryV + workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(boundaryH, boundaryV, Canvas.Width, Canvas.Height))

	protected override def InternalDraw() as bool:
		ratio as single
		workloadH as int
		boundaryH as int
		boundaryV as int
		GRenderTargets[RENDERER_ALT].DrawFull()
		ratio = (GSpriteEngine.value.Canvas.Width cast double) / (GSpriteEngine.value.Canvas.Height cast double)
		boundaryH = GSpriteEngine.value.Canvas.Width / 2
		workloadH = boundaryH / (FADETIME[0] / TRpgTimestamp.FrameLength)
		boundaryV = round((boundaryH cast single) / ratio )
		caseOf FStyle:
			case TDivideStyle.Vert: DivideVert(FProgress, boundaryV)
			case TDivideStyle.Horiz: DivideHoriz(round(FProgress * ratio), boundaryH)
			case TDivideStyle.Both: DivideQuarters(round(FProgress * ratio), boundaryH, FProgress, boundaryV)
		FProgress += workloadH
		return FProgress < boundaryH

	public def constructor(style as TDivideStyle):
		super()
		FStyle = style

class TCombineTransition(TTransition):

	private FStyle as TDivideStyle

	private def CombineVert(workload as int, boundary as int):
		Canvas as TSdlCanvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(0, -(boundary - workload), Canvas.Width, Canvas.Height / 2),
			GPU_MakeRect(0, 0, Canvas.Width, boundary))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(0, Canvas.Height - workload, Canvas.Width, Canvas.Height / 2),
			GPU_MakeRect(0, boundary, Canvas.Width, Canvas.Height))

	private def CombineHoriz(workload as int, boundary as int):
		Canvas as TSdlCanvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(-(boundary - workload), 0, Canvas.Width / 2, Canvas.Height),
			GPU_MakeRect(0, 0, boundary, Canvas.Height))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(Canvas.Width - workload, 0, Canvas.Width / 2, Canvas.Height),
			GPU_MakeRect(boundary, 0, Canvas.Width, Canvas.Height))

	private def CombineQuarters(workloadH as int, boundaryH as int, workloadV as int, boundaryV as int):
		Canvas as TSdlCanvas = GSpriteEngine.value.Canvas
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(-(boundaryH - workloadH), -(boundaryV - workloadV), Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(0, 0, boundaryH, boundaryV))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(-(boundaryH - workloadH), Canvas.Height - workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(0, boundaryV, boundaryH, Canvas.Height))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(Canvas.Width - workloadH, -(boundaryV - workloadV), Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(boundaryH, 0, Canvas.Width, boundaryV))
		Canvas.DrawRectTo(GRenderTargets[RENDERER_ALT],
			GPU_MakeRect(Canvas.Width - workloadH, Canvas.Height - workloadV, Canvas.Width / 2, Canvas.Height / 2),
			GPU_MakeRect(boundaryH, boundaryV, Canvas.Width, Canvas.Height))

	protected override def InternalDraw() as bool:
		workload as int
		boundaryH as int
		boundaryV as int
		ratio as single
		GRenderTargets[RENDERER_MAIN].DrawFull()
		ratio = (GSpriteEngine.value.Canvas.Width cast single) / (GSpriteEngine.value.Canvas.Height cast single)
		boundaryH = GSpriteEngine.value.Canvas.Width / 2
		workload = boundaryH / (FADETIME[1] / TRpgTimestamp.FrameLength)
		boundaryV = round(boundaryH / ratio cast double)
		caseOf FStyle:
			case TDivideStyle.Vert: CombineVert(FProgress, boundaryV)
			case TDivideStyle.Horiz: CombineHoriz(round(FProgress * ratio), boundaryH)
			case TDivideStyle.Both: CombineQuarters(round(FProgress * ratio), boundaryH, FProgress, boundaryV)
		FProgress += workload
		return FProgress < boundaryV

	public def constructor(style as TDivideStyle):
		super()
		FStyle = style

class TZoomTransition(TTransition):

	private FZoomIn as bool

	private FMinimum as int

	private FRatio as single

	private FCenter as TSgPoint

	private FCurrentX as single

	private FCurrentY as single

	private FTarget as int

	protected override def InternalDraw() as bool:
		viewRect as GPU_Rect
		canvas = GSpriteEngine.value.Canvas
		workload as int = GSpriteEngine.value.Canvas.Width / Math.Max((FADETIME[1] / TRpgTimestamp.FrameLength), 1)
		if FZoomIn:
			FProgress = Math.Max(FProgress - workload, FMinimum)
		else:
			FProgress = Math.Min(FProgress + workload, GSpriteEngine.value.Canvas.Width)
		viewRect.w = FProgress
		viewRect.h = round(FProgress / FRatio)
		if FZoomIn:
			FCurrentX = FCurrentX + (((FCenter.x cast double) / (canvas.Width cast double)) * workload)
			FCurrentY = FCurrentY + (((FCenter.y cast double) / (canvas.Height cast double)) * (workload / FRatio))
		else:
			FCurrentX = FCurrentX - (((FCenter.x cast double) / (canvas.Width cast double)) * workload)
			FCurrentY = FCurrentY - (((FCenter.y cast double) / (canvas.Height cast double)) * (workload / FRatio))
		viewRect.x = Math.Max(Math.Round(FCurrentX), 0)
		viewRect.y = Math.Max(Math.Round(FCurrentY), 0)
		canvas.DrawRectTo(GRenderTargets[FTarget], GPU_MakeRect(0, 0, canvas.Width, canvas.Height), viewRect)
		if FZoomIn:
			result = (FProgress > FMinimum)
		else:
			result = (FProgress < canvas.Width)
		return result

	public override def Setup(showing as bool, OnFinished as Action):
		super.Setup(showing, OnFinished)
		if showing:
			FTarget = RENDERER_ALT
		else:
			FTarget = RENDERER_MAIN

	public def constructor(zoomIn as bool):
		base as TSprite
		canvas = GSpriteEngine.value.Canvas
		super()
		FZoomIn = zoomIn
		FMinimum = round(((canvas.Width cast double) / (MAXZOOM cast double)))
		FRatio = (canvas.Width cast double) / (canvas.Height cast double)
		base = GSpriteEngine.value.CurrentParty.BaseTile
		FCenter = sgPoint(Math.Truncate(base.X) + 8, Math.Truncate(base.Y) + 8)
		FCenter.x -= Math.Round(GSpriteEngine.value.WorldX)
		FCenter.y -= Math.Round(GSpriteEngine.value.WorldY)
		if zoomIn:
			FCurrentX = 0
			FCurrentY = 0
			FProgress = canvas.Width
		else:
			FProgress = FMinimum
			FCurrentX = FCenter.x - ((FMinimum cast double) / 2.0)
			FCurrentY = FCenter.y - ((FMinimum / FRatio) / 2.0)

class TMosaicTransition(TTransition):

	public static final MIN_RESOLUTION = 8

	private FBlockSize as single

	private FMaxSize as single

	private FTarget as int

	protected override def InternalDraw() as bool:
		workload as single
		mosaicProg as int
		shaders as TdmShaders
		canvas = GSpriteEngine.value.Canvas
		workload = (canvas.Width cast double) / Math.Max((FADETIME[2] cast double) / (TRpgTimestamp.FrameLength cast double), 1.0)
		FBlockSize = ( (FBlockSize - workload) if FShowing else (FBlockSize + workload) )
		clamp(FBlockSize, 1, FMaxSize)
		shaders = GSpriteEngine.value.ShaderEngine
		mosaicProg = shaders.ShaderProgram('default', 'mosaic')
		shaders.UseShaderProgram(mosaicProg)
		shaders.SetUniformValue(mosaicProg, 'blockSize', FBlockSize)
		GRenderTargets[FTarget].DrawFull()
		GPU_DeactivateShaderProgram()
		result = ( (FBlockSize > 1) if FShowing else (FBlockSize < FMaxSize) )
		return result

	public override def Setup(showing as bool, OnFinished as Action):
		super.Setup(showing, OnFinished)
		FMaxSize = ((GSpriteEngine.value.Canvas.Width cast double) / (MIN_RESOLUTION cast double))
		if showing:
			FBlockSize = FMaxSize
			FTarget = RENDERER_ALT
		else:
			FBlockSize = 1
			FTarget = RENDERER_MAIN

class TWaveTransition(TTransition):

	protected override def InternalDraw() as bool:
		workload as int
		WAVE_PERIOD = 5
		canvas = GSpriteEngine.value.Canvas
		canvas.Clear(SDL_BLACK)
		workload = WAVESIZE / (FADETIME[2] / 64)
		FProgress += workload
		if FShowing:
			drawWave(
				GRenderTargets[RENDERER_ALT],
				GPU_MakeRect(0, 0, canvas.Width, canvas.Height),
				WAVESIZE - FProgress,
				WAVE_PERIOD,
				WAVESIZE - FProgress)
		else:
			drawWave(
				GRenderTargets[RENDERER_MAIN],
				GPU_MakeRect(0, 0, canvas.Width, canvas.Height),
				FProgress,
				WAVE_PERIOD,
				FProgress)
		return (FProgress < WAVESIZE)

def fadeOut() as ITransition:
	return TFadeTransition()

def fadeIn() as ITransition:
	return TFadeTransition()

def blocks(direction as TDirectionWipe) as ITransition:
	return TBlockTransition(direction)

def blinds(vanishing as bool) as ITransition:
	return TBlindsTransition()

def stripes(vanishing as bool, vertical as bool) as ITransition:
	return TStripeTransition(vertical)

def outIn(vanishing as bool) as ITransition:
	return TRectIrisTransition(false)

def inOut(vanishing as bool) as ITransition:
	return TRectIrisTransition(true)

def Scroll(vanishing as bool, direction as TFacing) as ITransition:
	return TScrollTransition(direction)

def divide(style as TDivideStyle) as ITransition:
	return TDivideTransition(style)

def combine(style as TDivideStyle) as ITransition:
	return TCombineTransition(style)

def zoom(vanishing as bool) as ITransition:
	return TZoomTransition(vanishing)

def mosaic(vanishing as bool) as ITransition:
	return TMosaicTransition()

def bof2(vanishing as bool) as ITransition:
	return TBof2Transition()

def wave(vanishing as bool) as ITransition:
	return TWaveTransition()

let GRenderTargets = TSdlRenderTargets()

let RENDERER_MAIN = 0
let RENDERER_ALT = 1
let RENDERER_MAP = 2
let RENDERER_TRAN = 3
let FADETIME = (800, 1200, 5200)