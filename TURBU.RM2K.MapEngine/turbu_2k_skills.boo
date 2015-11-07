namespace turbu.RM2K.skills

import turbu.classes
import turbu.skills
import turbu.sounds
import turbu.constants
import TURBU.RM2K
import Pythia.Runtime
import System
import turbu.Heroes
import turbu.RM2K.environment

class TRpgSkill(TRpgObject):

	public def constructor(id as ushort):
		super(GDatabase.value.Skill[id])

	public def UseHero(caster as TRpgHero, target as TRpgHero):
		template = self.Template as TNormalSkillTemplate
		if assigned(template):
			if template.HP:
				target.HP += BaseDamage(caster)
			if template.MP:
				target.MP += BaseDamage(caster)

	public def UseParty(caster as TRpgHero):
		for i in range(1, (MAXPARTYSIZE + 1)):
			if GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
				self.UseHero(caster, GEnvironment.value.Party[i])

	public def BaseDamage(caster as TRpgHero) as int:
		deviation as int
		template = self.Template cast TNormalSkillTemplate
		result = commons.round((((caster.Attack * template.StrEffect) cast double) / 20.0) + \
										((caster.Mind * template.MindEffect) cast double) / 40.0) + template.Base
		deviation = Random().Next(((template.Variance * 5) + 1)) - (template.Variance * 5)
		return commons.round(result * (1 + ((deviation cast double) / 100.0)))

	public AreaSkill as bool:
		get: return Template.Range == TSkillRange.Area

	public def UsableParty() as bool:
		return false unless AreaSkill
		result = false
		for i in range(1, MAXPARTYSIZE + 1):
			if GEnvironment.value.Party[i] != GEnvironment.value.Heroes[0]:
				result = result or UsableOn(GEnvironment.value.Party[i].Template.ID)
		return result

	public def UsableOn(id as ushort) as bool:
		hero as TRpgHero = GEnvironment.value.Heroes[id]
		template = self.Template as TNormalSkillTemplate
		if assigned(template):
			result = template.Offensive == false
			if template.HP and template.MP:
				result = result and ((hero.HP < hero.MaxHp) or (hero.MP < hero.MaxMp))
			elif template.HP:
				result = result and (hero.HP < hero.MaxHp)
			elif template.MP:
				result = result and (hero.MP < hero.MaxMp)
			else:
				result = false
		else:
			result = true
		return result

	public Template as TSkillTemplate:
		get: return super.Template cast TSkillTemplate

	public FirstSound as TRpgSound:
		get: return Template.FirstSound
