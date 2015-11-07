namespace turbu.RM2K.transitions.graphics

import Pythia.Runtime
import turbu.defs

[Metaclass(TTransition)]
class TTransitionClass(TClass):
	pass

[Metaclass(TMaskTransition)]
class TMaskTransitionClass(TTransitionClass):
	pass

[Metaclass(TFadeTransition)]
class TFadeTransitionClass(TMaskTransitionClass):
	pass

[Metaclass(TBlockTransition)]
class TBlockTransitionClass(TMaskTransitionClass):

	virtual def Create(direction as TDirectionWipe) as turbu.RM2K.transitions.graphics.TBlockTransition:
		return turbu.RM2K.transitions.graphics.TBlockTransition(direction)

[Metaclass(TBlindsTransition)]
class TBlindsTransitionClass(TMaskTransitionClass):

	virtual def Create() as turbu.RM2K.transitions.graphics.TBlindsTransition:
		return turbu.RM2K.transitions.graphics.TBlindsTransition()

[Metaclass(TStripeTransition)]
class TStripeTransitionClass(TMaskTransitionClass):

	virtual def Create(vertical as bool) as turbu.RM2K.transitions.graphics.TStripeTransition:
		return turbu.RM2K.transitions.graphics.TStripeTransition(vertical)

[Metaclass(TRectIrisTransition)]
class TRectIrisTransitionClass(TMaskTransitionClass):

	virtual def Create(inOut as bool) as turbu.RM2K.transitions.graphics.TRectIrisTransition:
		return turbu.RM2K.transitions.graphics.TRectIrisTransition(inOut)

[Metaclass(TBof2Transition)]
class TBof2TransitionClass(TMaskTransitionClass):
	pass

[Metaclass(TScrollTransition)]
class TScrollTransitionClass(TTransitionClass):

	virtual def Create(direction as TFacing) as turbu.RM2K.transitions.graphics.TScrollTransition:
		return turbu.RM2K.transitions.graphics.TScrollTransition(direction)

[Metaclass(TDivideTransition)]
class TDivideTransitionClass(TTransitionClass):

	virtual def Create(style as TDivideStyle) as turbu.RM2K.transitions.graphics.TDivideTransition:
		return turbu.RM2K.transitions.graphics.TDivideTransition(style)

[Metaclass(TCombineTransition)]
class TCombineTransitionClass(TTransitionClass):

	virtual def Create(style as TDivideStyle) as turbu.RM2K.transitions.graphics.TCombineTransition:
		return turbu.RM2K.transitions.graphics.TCombineTransition(style)

[Metaclass(TZoomTransition)]
class TZoomTransitionClass(TTransitionClass):

	virtual def Create(zoomIn as bool) as turbu.RM2K.transitions.graphics.TZoomTransition:
		return turbu.RM2K.transitions.graphics.TZoomTransition(zoomIn)

[Metaclass(TMosaicTransition)]
class TMosaicTransitionClass(TTransitionClass):
	pass

[Metaclass(TWaveTransition)]
class TWaveTransitionClass(TTransitionClass):
	pass

