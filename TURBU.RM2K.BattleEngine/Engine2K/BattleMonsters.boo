namespace TURBU.RM2K.BattleEngine

import System
import TURBU.Meta
import commons
import Pythia.Runtime
import Boo.Adt
import TURBU.Timing
import SDL2.SDL2_GPU
import SDL.ImageManager
import SG.defs
import turbu.monsters
import TURBU.RM2K
import TURBU.RM2K.Menus
import TURBU.RM2K.RPGScript

enum MonsterState:
	Normal
	Appearing
	Dying
	Blinking
	Gone

class TBattleMonster(T2kMonster):

	let DEATH_TICKS = 36
	let APPEAR_TICKS = 20
	let BLINK_PERIOD = 3

	[Getter(Center)]
	private _center as SgPoint

	private _image as TSdlImage

	private _state = MonsterState.Normal

	private _stateTicks as int

	private _stateLength as int

	private _hidden as bool

	public Highlighted as bool

	public Unit as TMonsterUnit

	public def constructor(base as TRpgMonster, center as SgPoint, hidden as bool):
		super(base)
		_center = center
		_hidden = hidden
		LoadPicture()
		if hidden:
			_state = MonsterState.Gone

	private def LoadPicture():
		_image = null
		return if string.IsNullOrEmpty(Monster.Filename)
		try:
			_image = GMenuEngine.Value.Images.EnsureImage("Monsters\\$(Monster.Filename).png", 'Monster ' + Monster.Filename)
		except:
			pass

	public Visible as bool:
		get: return _state != MonsterState.Gone

	public Animating as bool:
		get: return _state in (MonsterState.Appearing, MonsterState.Dying, MonsterState.Blinking)

	public Width as int:
		get: return (_image.ImageSize.x if _image is not null else 0)

	public Height as int:
		get: return (_image.ImageSize.y if _image is not null else 0)

	public def DieFade():
		return unless Visible
		SetState(MonsterState.Dying, DEATH_TICKS)

	public def FadeIn():
		SetState(MonsterState.Appearing, APPEAR_TICKS)

	public def Blink(ticks as int):
		return unless Visible
		SetState(MonsterState.Blinking, ticks)

	private def SetState(state as MonsterState, length as int):
		_lastTick = GameClock.Ticks
		_state = state
		_stateTicks = 0
		_stateLength = Math.Max(length, 1)

	private _lastTick as long = -1

	//brings the picture up-to-date with the game timer
	private def Advance():
		now = GameClock.Ticks
		behind = (0 if _lastTick < 0 else Math.Min(now - _lastTick, 120L)) cast int
		_lastTick = now
		for i in range(behind):
			Tick()

	private def Tick():
		return unless Animating
		++_stateTicks
		if _stateTicks >= _stateLength:
			_state = (MonsterState.Gone if _state == MonsterState.Dying else MonsterState.Normal)

	public override def Transform(newBase as TRpgMonster):
		super.Transform(newBase)
		LoadPicture()

	public override def Show():
		FadeIn() unless _state == MonsterState.Normal
		Unit.Present = true if Unit is not null

	public override def Flee(force as bool, ignoreIfSurrounded as bool):
		DieFade()
		Unit.Present = false if Unit is not null

	public override def Position(sign as int) as SgPoint:
		return SgPoint(_center.x, _center.y + ((sign * Height) / 2))

	public override def Flash(r as int, g as int, b as int, power as int, time as int):
		Blink(Math.Max(time * 6, BLINK_PERIOD * 2))

	private def Opacity() as int:
		caseOf _state:
			case MonsterState.Gone: return 0
			case MonsterState.Dying: return 255 - ((255 * _stateTicks) / _stateLength)
			case MonsterState.Appearing: return (255 * _stateTicks) / _stateLength
			case MonsterState.Blinking: return (0 if ((_stateTicks / BLINK_PERIOD) % 2) == 0 else 255)
			default: return 255

	public def Draw():
		Advance()
		return if _image is null or _state == MonsterState.Gone
		alpha = Opacity()
		if Highlighted and _state == MonsterState.Normal and ((GameClock.Ticks / 15) % 2) == 0:
			alpha = 90
		return if alpha <= 0
		GPU_SetRGBA(_image.Surface, 255, 255, 255, alpha cast byte)
		try:
			GPU_Blit(_image.Surface, IntPtr.Zero, sdl.canvas.currentRenderTarget().RenderTarget, _center.x, _center.y)
		ensure:
			GPU_SetRGBA(_image.Surface, 255, 255, 255, 255)
