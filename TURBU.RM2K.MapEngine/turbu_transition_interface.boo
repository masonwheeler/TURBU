namespace TURBU.TransitionInterface

interface ITransition:

	def Setup(showing as bool, OnFinished as System.Action)

	def Draw() as bool

