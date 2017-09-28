namespace turbu.defs

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Pythia.Runtime
import System
import TURBU.Meta

callable TExpCalcEvent(level as int, var1 as int, var2 as int, var3 as int, var4 as int) as int

struct TLocation:
	map as int
	x as int
	y as int

	def constructor(map as int, x as int, y as int):
		self.map = map
		self.x = x
		self.y = y

struct TNameType:
	name as string
	flags as ParameterModifiers
	typeVar as int

enum TWeaponStyle:
	Single
	Shield
	Dual
	All

enum TVarSets:
	Switch
	Integer
	Float
	String

enum TUsableWhere:
	None
	Field
	Battle
	Both

enum TColorSet:
	Red
	Green
	Blue
	Sat

enum TSfxTypes:
	Cursor
	Accept
	Cancel
	Buzzer
	BattleStart
	Escape
	EnemyAttack
	EnemyDamage
	AllyDamage
	Evade
	EnemyDies
	ItemUsed

enum TBgmTypes:
	Battle
	Victory
	Inn
	GameOver
	Title
	BossBattle

enum TTransitionTypes:
	MapExit
	MapEnter
	BattleStartErase
	BattleStartShow
	BattleEndErase
	BattleEndShow

enum TTransitions:
	Default
	Fade
	Blocks
	BlockUp
	BlockDn
	Blinds
	StripeHiLo
	StripeLR
	OutIn
	InOut
	ScrollUp
	ScrollDn
	ScrollLeft
	ScrollRight
	DivHiLow
	DivLR
	DivQuarters
	Zoom
	Mosaic
	Ripple
	Instant
	None

enum TShopTypes:
	BuySell
	Buy
	Sell

enum TDirections:
	Up
	Right
	Down
	Left
	Random
	TowardsHero
	FleeHero

[EnumSet]
enum TFacing:
	None = 0
	Up = 1
	Right = 2
	Down = 4
	Left = 8

[Extension]
def op_Implicit(l as TFacing) as TDirections:
	caseOf l:
		case TFacing.Up:
			return TDirections.Up
		case TFacing.Right:
			return TDirections.Right
		case TFacing.Down:
			return TDirections.Down
		case TFacing.Left:
			return TDirections.Left
		default:
			raise "Invalid facing value: $(l.ToString())"

enum TWeatherEffects:
	None
	Rain
	Snow
	Fog
	Sand

enum TImageEffects:
	None
	Rotate
	Wave

[EnumSet]
enum TButtonCode:
	None = 0
	Down = 1
	Left = 2
	Right = 4
	Up = 8
	Enter = 0x10
	Cancel = 0x20
	Dirs = Down | Left | Right | Up
	All = Down | Left | Right | Up | Enter | Cancel

enum TGameState:
	Map
	Message
	Menu
	Battle
	Sleeping
	Fading
	Minigame

enum TBattleFormation:
	Normal
	Initiative
	Surprised
	Surrounded
	Pincer
	FirstStrike

enum TBattleStyle:
	Traditional
	Alternative
	Gauge

enum TConcealmentFactor:
	None
	Low
	Medium
	High

enum TMboxLocation:
	Top
	Middle
	Bottom

enum TSlot:
	Weapon
	Shield
	Armor
	Helmet
	Relic

class NoImportAttribute(System.Attribute):
	pass

class TableNameAttribute(System.Attribute):
	[Getter(Name)]
	private _name as string
	
	def constructor(value as string):
		_name = value