namespace charset.data

import SG.defs
import Pythia.Runtime
import turbu.defs
import System

[System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
def opposite_facing(whichDir as TDirections) as TDirections:
	return (ord(whichDir) + 2) % 4

def towards(location as TSgPoint, target as TSgPoint) as TFacing:
	dX as int
	dY as int
	dX = location.x - target.x
	dY = location.y - target.y
	if Math.Abs(dX) > Math.Abs(dY):
		return (TFacing.Left if dX > 0 else TFacing.Right)
	else: return (TFacing.Up if dY > 0 else TFacing.Down)

