namespace turbu.RM2K.transitions

import turbu.defs
import Boo.Adt
import turbu.RM2K.sprite.engine
import turbu.RM2K.transitions.graphics
import TURBU.RM2K.MapEngine
import TURBU.TransitionInterface
import TURBU.Meta

enum TBlockStyle:
	Random
	FromTop
	FromBottom

def Erase(which as TTransitions):
	tran as ITransition
	if (GSpriteEngine.value.State == TGameState.Fading) or GSpriteEngine.value.Blank:
		return
	caseOf which:
		case TTransitions.Default:
			assert false
		case TTransitions.Fade:
			tran = turbu.RM2K.transitions.graphics.fadeOut()
		case TTransitions.Blocks:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Random)
		case TTransitions.BlockUp:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Downward)
		case TTransitions.BlockDn:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Upward)
		case TTransitions.Blinds:
			tran = turbu.RM2K.transitions.graphics.blinds(true)
		case TTransitions.StripeHiLo:
			tran = turbu.RM2K.transitions.graphics.stripes(true, false)
		case TTransitions.StripeLR:
			tran = turbu.RM2K.transitions.graphics.stripes(true, true)
		case TTransitions.OutIn:
			tran = turbu.RM2K.transitions.graphics.outIn(true)
		case TTransitions.InOut:
			tran = turbu.RM2K.transitions.graphics.inOut(true)
		case TTransitions.ScrollUp:
			tran = turbu.RM2K.transitions.graphics.Scroll(true, TFacing.Up)
		case TTransitions.ScrollDn:
			tran = turbu.RM2K.transitions.graphics.Scroll(true, TFacing.Down)
		case TTransitions.ScrollLeft:
			tran = turbu.RM2K.transitions.graphics.Scroll(true, TFacing.Left)
		case TTransitions.ScrollRight:
			tran = turbu.RM2K.transitions.graphics.Scroll(true, TFacing.Right)
		case TTransitions.DivHiLow:
			tran = turbu.RM2K.transitions.graphics.divide(TDivideStyle.Vert)
		case TTransitions.DivLR:
			tran = turbu.RM2K.transitions.graphics.divide(TDivideStyle.Horiz)
		case TTransitions.DivQuarters:
			tran = turbu.RM2K.transitions.graphics.divide(TDivideStyle.Both)
		case TTransitions.Zoom:
			tran = turbu.RM2K.transitions.graphics.zoom(true)
		case TTransitions.Mosaic:
			tran = mosaic(true)
		case TTransitions.Ripple:
			tran = turbu.RM2K.transitions.graphics.wave(true)
		case TTransitions.None:
			GSpriteEngine.value.EndErase()
			return
		default :
			assert false
	tran.Setup(false, GSpriteEngine.value.EndErase)
	GSpriteEngine.value.BeginTransition(true)
	GGameEngine.value.Transition = tran

def Show(which as TTransitions):
	tran as ITransition
	caseOf which:
		case TTransitions.Default:
			assert false
		case TTransitions.Fade:
			tran = turbu.RM2K.transitions.graphics.fadeIn()
		case TTransitions.Blocks:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Random)
		case TTransitions.BlockUp:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Downward)
		case TTransitions.BlockDn:
			tran = turbu.RM2K.transitions.graphics.blocks(TDirectionWipe.Upward)
		case TTransitions.Blinds:
			tran = turbu.RM2K.transitions.graphics.blinds(false)
		case TTransitions.StripeHiLo:
			tran = turbu.RM2K.transitions.graphics.stripes(false, false)
		case TTransitions.StripeLR:
			tran = turbu.RM2K.transitions.graphics.stripes(false, true)
		case TTransitions.OutIn:
			tran = turbu.RM2K.transitions.graphics.outIn(false)
		case TTransitions.InOut:
			tran = turbu.RM2K.transitions.graphics.inOut(false)
		case TTransitions.ScrollUp:
			tran = turbu.RM2K.transitions.graphics.Scroll(false, TFacing.Up)
		case TTransitions.ScrollDn:
			tran = turbu.RM2K.transitions.graphics.Scroll(false, TFacing.Down)
		case TTransitions.ScrollLeft:
			tran = turbu.RM2K.transitions.graphics.Scroll(false, TFacing.Left)
		case TTransitions.ScrollRight:
			tran = turbu.RM2K.transitions.graphics.Scroll(false, TFacing.Right)
		case TTransitions.DivHiLow:
			tran = turbu.RM2K.transitions.graphics.combine(TDivideStyle.Vert)
		case TTransitions.DivLR:
			tran = turbu.RM2K.transitions.graphics.combine(TDivideStyle.Horiz)
		case TTransitions.DivQuarters:
			tran = turbu.RM2K.transitions.graphics.combine(TDivideStyle.Both)
		case TTransitions.Zoom:
			tran = turbu.RM2K.transitions.graphics.zoom(false)
		case TTransitions.Mosaic:
			tran = mosaic(false)
		case TTransitions.Ripple:
			tran = turbu.RM2K.transitions.graphics.wave(false)
		case TTransitions.None, TTransitions.Instant:
			GSpriteEngine.value.EndShow()
			return
		default :
			assert false
	tran.Setup(true, GSpriteEngine.value.EndShow)
	GSpriteEngine.value.BeginTransition(false)
	GGameEngine.value.Transition = tran

let STRIPESIZE = 4
let WAVESIZE = 100
let MAXZOOM = 13.33333333333
