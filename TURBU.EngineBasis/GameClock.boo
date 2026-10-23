namespace TURBU.Timing

import System

# The one clock of the game logic. Logic advances in whole ticks of 1/60 s (as in RPG_RT);
# the renderer interpolates between ticks using Alpha.
static class GameClock:
	public final TICK_RATE = 60
	public final TICK_MS = 1000.0 / 60.0

	# Index of the tick being processed. Incremented last in each tick, so a step or wait that
	# starts during tick T has Start == T.
	public static Ticks as long

	# 0..1: how far the display is between the last processed tick and the next one.
	public static Alpha as double

	# When true, Alpha is forced to 1 (output identical to the original at 60 Hz).
	public static PixelPerfect as bool

	# Set the environment variable TURBU_PIXELPERFECT=1 to start with PixelPerfect on.
	static def constructor():
		PixelPerfect = Environment.GetEnvironmentVariable('TURBU_PIXELPERFECT') == '1'

	# The time the renderer should draw, in ticks. One tick behind the logic, so it is never ahead of state:
	# at Alpha == 1 this equals Ticks, i.e. the state after the last processed tick.
	public static RenderTime as double:
		get: return Ticks - 1 + (1.0 if PixelPerfect else Alpha)

	public static def Advance():
		++Ticks

	public static def Reset():
		Ticks = 0
		Alpha = 1.0
