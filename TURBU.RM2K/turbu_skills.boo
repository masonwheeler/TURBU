namespace turbu.skills

import System
import System.Linq.Enumerable
import Newtonsoft.Json.Linq
import Pythia.Runtime
import SG.defs
import turbu.operators
import TURBU.RM2K
import turbu.constants
import turbu.defs
import turbu.classes
import turbu.sounds
import turbu.animations
import TURBU.Meta

enum TSkillFuncStyle:
	Bool
	Percent
	Level
	Both

enum TSkillRange:
	Self
	Target
	Area

enum TSkillType:
	Normal
	Teleport
	Variable
	Script

class TSkillGainInfo(TRpgDatafile):
	def constructor():
		super()

	def constructor(value as JObject):
		super()
		value.CheckReadEnum('Style', FStyle)
		value.CheckRead('Skill', FSkill)
		value.ReadArray('Nums', FNums)
		value.CheckEmpty()

	[Property(Style)]
	private FStyle as TSkillFuncStyle

	[Property(Skill)]
	private FSkill as int

	[Property(Nums)]
	private FNums as (int)

[TableName('Skills')]
class TSkillTemplate(TRpgDatafile):

	static def Create(value as JObject) as TSkillTemplate:
		st as TSkillType
		value.CheckReadEnum('SkillType', st)
		caseOf st:
			case TSkillType.Normal:
				return TNormalSkillTemplate(value)
			case TSkillType.Teleport:
				return TTeleportSkillTemplate(value)
			case TSkillType.Variable:
				return TVariableSkillTemplate(value)
			case TSkillType.Script:
				return TScriptSkillTemplate(value)
			default: raise "Unknown skill type: $st"

	def constructor():
		super()

	def constructor(value as JObject):
		super(value)
		value.CheckRead('Cost', FCost)
		value.CheckRead('CostAsPercentage', FCostPercent)
		value.CheckRead('Desc', FDescription)
		value.CheckRead('UseString', FUseString)
		value.CheckRead('UseString2', FUseString2)
		value.CheckRead('FailureMessage', FFailureMessage)
		value.CheckReadEnum('Usable', FUsableWhere)
		value.CheckReadEnum('Range', FRange)
		value.ReadArray('Tag', FTag)

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
	private FFailureMessage as int

	[Property(Usable)]
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

	def constructor(value as JObject):
		super(value)
		value.CheckRead('Offensive', FOffensive)
		value.CheckRead('Animation', FAnim)
		value.ReadArray('SkillPower', FSkillPower)
		value.CheckRead('SuccessRate', FSuccessRate)
		value.ReadArray('Stats', FStat)
		value.CheckRead('Drain', FVampire)
		value.CheckRead('Phased', FPhased)
		value.ReadArray('Condition', FCondition)
		value.CheckRead('ResistMod', FResistMod)
		value.CheckRead('InflictReversed', FInflictReversed)
		value.CheckRead('DisplaySprite', FDisplaySprite)
		value.ReadArray('Attributes', FAttributes)
		value.CheckEmpty()
	
	[Property(Offensive)]
	private FOffensive as bool

	[Property(Animation)]
	private FAnim as int

	[Property(SkillPower, value.Length == 5)]
	private FSkillPower = array(int, 5)

	[Property(SuccessRate)]
	private FSuccessRate as int

	[Property(Stats, value.Length == STAT_COUNT + 1)]
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
		anim as TAnimTemplate = GDatabase.value.Anim[self.Animation]
		return anim.Effects.Select({e | e.Sound}).FirstOrDefault({s | (s != null) and not string.IsNullOrEmpty(s.Filename) })

	[Property(Attributes)]
	protected FAttributes as (SgPoint)

	public StrEffect as int:
		get: return SkillPower[1]

	public MindEffect as int:
		get: return SkillPower[2]

	public Variance as int:
		get: return SkillPower[3]

	public Base as int:
		get: return SkillPower[4]

	public HP as bool:
		get: return Stats[1]

	public MP as bool:
		get: return Stats[2]

	public Attack as bool:
		get: return Stats[3]

	public Defense as bool:
		get: return Stats[4]

	public Mind as bool:
		get: return Stats[5]

	public Speed as bool:
		get: return Stats[6]

abstract class TSpecialSkillTemplate(TSkillTemplate):

	def constructor(value as JObject):
		super(value)
		var sfx = value['Sfx'] cast JObject
		if assigned(sfx):
			FSfx = TRpgSound(sfx)

	[Property(Sfx)]
	private FSfx as TRpgSound

	protected override def GetSound1() as TRpgSound:
		return FSfx

class TTeleportSkillTemplate(TSpecialSkillTemplate):

	def constructor(value as JObject):
		super(value)
		value.CheckRead('TeleportTarget', FTarget)
		value.CheckEmpty()

	[Property(TeleportTarget)]
	private FTarget as int

class TVariableSkillTemplate(TSpecialSkillTemplate):

	def constructor(value as JObject):
		super(value)
		value.CheckRead('Which', FWhich)
		value.CheckRead('IsVariable', FIsVar)
		value.CheckRead('Magnitude', FMagnitude)
		value.CheckReadEnum('Style', FStyle)
		value.CheckReadEnum('Operation', FOperation)
		value.CheckEmpty()

	[Property(Which)]
	private FWhich as int

	[Property(IsVariable)]
	private FIsVar as bool

	[Property(Magnitude)]
	private FMagnitude as int

	[Property(Style)]
	private FStyle as TVarSets

	[Property(Operation)]
	private FOperation as TBinaryOp

class TScriptSkillTemplate(TSkillTemplate):

	def constructor(value as JObject):
		raise "Not implemented yet"

	[Property(Event)]
	private FEvent as Action of TRpgObject
