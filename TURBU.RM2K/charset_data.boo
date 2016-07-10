namespace charset.data

import SG.defs
import Pythia.Runtime
import turbu.defs
import System

def opposite_facing(whichDir as TDirections) as TDirections:
	return (ord(whichDir) + 2) % 4

def towards(location as TSgPoint, target as TSgPoint) as TDirections:
	dX as int = location.x - target.x
	dY as int = location.y - target.y
	if Math.Abs(dX) > Math.Abs(dY):
		return (TDirections.Left if dX > 0 else TDirections.Right)
	else: return (TDirections.Up if dY > 0 else TDirections.Down)

