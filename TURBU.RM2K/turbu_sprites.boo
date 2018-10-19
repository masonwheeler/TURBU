namespace turbu.sprites

import SG.defs
import System

struct TSpriteData:

	name as string

	moveMatrix as int

def nextPosition(matrix as ((int)), ref current as SgPoint) as byte:
	if (current.x > matrix.Length - 1) or (current.y > matrix[current.x].Length - 1):
		current = SgPoint(0, 0)
	else:
		current.y = (current.y + 1) % matrix[current.x].Length
	return matrix[current.x][current.y]

def nextPosition(matrix as ((int)), currentAnim as int, currentFrame as int) as int:
	if (currentAnim > matrix.Length - 1) or (currentFrame > matrix[currentAnim].Length - 1):
		return 0
	else:
		return (currentFrame + 1) % matrix[currentAnim].Length
