namespace turbu.skills

import turbu.operators
import TURBU.RM2K
import Pythia.Runtime
import System
import System.Drawing
import turbu.constants
import turbu.defs
import turbu.classes
import turbu.sounds
import turbu.animations

enum TSkillFuncStyle:
	Bool
	Percent
	Level
	Both

enum TSkillRange:
	Self
	Target
	Area

class TSkillGainInfo(TRpgDatafile):

	[Property(Style)]
	private FStyle as TSkillFuncStyle

	[Property(Skill)]
	private FSkill as int

	[Property(Nums)]
	private FNums as (int)

[TableName('Skills')]
class TSkillTemplate(TRpgDatafile):
	
	def constructor():
		super()

	[Property(Cost)]
	private FCost as int

	[Property(CostAsPercentage)]
	private FCostPercent as bool

	[Property(Desc)]
	private FDescription as string

	[Property(UseString)]
	private FUseString as string

	[Property(UseString2)]
	private FUseString2 as string

	[Property(FailureMessage)]
	private FFailureMessage as ushort

	[Property(UsableWhere)]
	private FUsableWhere as TUsableWhere

	[Property(Range)]
	private FRange as TSkillRange

	[Property(Tag)]
	private FTag as (int)

	protected virtual def GetSound1() as TRpgSound:
		return null

	public FirstSound as TRpgSound:
		get: return GetSound1()

class TNormalSkillTemplate(TSkillTemplate):

	[Property(Offensive)]
	private FOffensive as bool

	[Property(Animation)]
	private FAnim as ushort

	private FSkillPower = array(int, 5)

	[Property(SuccessRate)]
	private FSuccessRate as int

	private FStat = array(bool, STAT_COUNT + 1)

	[Property(Drain)]
	private FVampire as bool

	[Property(Phased)]
	private FPhased as bool

	[Property(Condition)]
	private FCondition = array(int, 0)

	[Property(ResistMod)]
	private FResistMod as bool

	[Property(InflictReversed)]
	private FInflictReversed as bool

	[Property(DisplaySprite)]
	private FDisplaySprite as int

	protected override def GetSound1() as TRpgSound:
		result = null
		anim as TAnimTemplate = GDatabase.value.Anim[self.Animation]
		i as int = 1
		while (i < anim.Effects.Count) and ((anim.Effects[i].Sound == null) or string.IsNullOrEmpty(anim.Effects[i].Sound.Filename)):
			++i
			if i <= anim.Effects.Count:
				result = anim.Effects[i].Sound
		return result

	[Property(Attribute)]
	protected FAttributes as (Point)

	public SkillPower[x as int] as int:
		get:
			assert x in range(1, 5)
			return FSkillPower[x]
		set:
			assert x in range(1, 5)
			FSkillPower[x] = value

	public StrEffect as int:
		get: return SkillPower[1]

	public MindEffect as int:
		get: return SkillPower[2]

	public Variance as int:
		get: return SkillPower[3]

	public Base as int:
		get: return SkillPower[4]

	public Stat[x as int] as bool:
		get:
			assert x in range(1, STAT_COUNT + 1)
			return FStat[x]
		set:
			assert x in range(1, STAT_COUNT + 1)
			FStat[x] = value

	public HP as bool:
		get: return Stat[1]

	public MP as bool:
		get: return Stat[2]

	public Attack as bool:
		get: return Stat[3]

	public Defense as bool:
		get: return Stat[4]

	public mind as bool:
		get: return Stat[5]

	public speed as bool:
		get: return Stat[6]

class TSpecialSkillTemplate(TSkillTemplate):

	[Property(Sfx)]
	private FSfx as TRpgSound

	protected override def GetSound1() as TRpgSound:
		return FSfx

class TTeleportSkillTemplate(TSpecialSkillTemplate):

	[Property(TeleportTarget)]
	private FTarget as byte

class TVariableSkillTemplate(TSpecialSkillTemplate):

	[Property(Which)]
	private FWhich as ushort

	[Property(Magnitude)]
	private FMagnitude as short

	[Property(Style)]
	private FStyle as TVarSets

	[Property(Operation)]
	private FOperation as TBinaryOp

class TScriptSkillTemplate(TSkillTemplate):

	[Property(Event)]
	private FEvent as Action of TRpgObject
