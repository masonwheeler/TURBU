namespace turbu.sprites

import SG.defs
import Pythia.Runtime
import System

struct TSpriteData:

	name as string

	moveMatrix as int

def nextPosition(matrix as ((int)), ref current as TSgPoint) as byte:
	if (current.x > pred(matrix.Length)) or (current.y > pred(matrix[current.x].Length)):
		current = sgPoint(0, 0)
	else:
		current.y = ((current.y + 1) % matrix[current.x].Length)
	return matrix[current.x][current.y]

def nextPosition(matrix as ((int)), currentAnim as int, currentFrame as int) as int:
	if (currentAnim > pred(matrix.Length)) or (currentFrame > pred(matrix[currentAnim].Length)):
		return 0
	else:
		return (currentFrame + 1) % matrix[currentAnim].Length
