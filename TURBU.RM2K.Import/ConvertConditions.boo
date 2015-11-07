namespace TURBU.RM2K.Import

import System
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF

static class TConditionConverter:
	def Convert(base as RMCondition, is2k3 as bool) as MacroStatement:
		result = [|
			Condition $(base.ID):
				Name $(base.Name)
				Damage $(base.RateA), $(base.RateB), $(base.RateC), $(base.RateD), $(base.RateE)
				OutOfBattle $(base.LastsOutsideBattle)
				Color $(base.Color)
				Priority $(base.Priority)
				AttackLimit $(ReferenceExpression(Enum.GetName(turbu.resists.TAttackLimitation, base.Limitation)))
				HealTurns $(base.HealTurns)
				HealTurnPercent $(base.HealPercent)
				HealShockPercent $(base.HealShock)
				Stats $(ReferenceExpression(Enum.GetName(turbu.resists.TStatEffect, base.StatEffect))), \
						($(base.AttackStat), $(base.DefenseStat), $(base.MindStat), $(base.SpeedStat))
				ToHitChange $(base.ToHitChange)
				PhysBlock $(base.PhysBlock)
				MagicReflect $(base.MagBlock)
				PhysCutoff $(base.PhysCutoff)
				MagicCutoff $(base.MagCutoff)
				HP $(base.HpTurnPercent), $(base.HpTurnFixed), $(base.HpStepCount), $(base.HpStepQuantity)
				MP $(base.MpTurnPercent), $(base.MpTurnFixed), $(base.MpStepCount), $(base.MpStepQuantity)
				Evade $(base.Evade)
				Reflect $(base.Reflect)
				EqLock $(base.EqLock)
				Animation $(base.StatusAnimation)
				HPDot $(ReferenceExpression(Enum.GetName(turbu.resists.TDotEffect, base.HpDot)))
				MPDot $(ReferenceExpression(Enum.GetName(turbu.resists.TDotEffect, base.MpDot)))
		|]
		unless is2k3:
			messages = [|
				UsesMessages true
				AllyMessage $(base.CondMessage1)
				EnemyMessage $(base.CondMessage2)
				AlreadyMessage $(base.CondMessage3)
				NormalMessage $(base.CondMessage4)
				RecoveryMessage $(base.CondMessage5)
			|]
			result.Body.Add(messages)
		return result
