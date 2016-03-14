namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
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
				ToHitChange $(base.ToHitChange)
				PhysBlock $(base.PhysBlock)
				MagicReflect $(base.MagBlock)
				PhysCutoff $(base.PhysCutoff)
				MagicCutoff $(base.MagCutoff)
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
		if (base.AttackStat, base.DefenseStat, base.MindStat, base.SpeedStat).Any({b|return b}):
			result.Body.Add([|StatEffect $(ReferenceExpression(Enum.GetName(turbu.resists.TStatEffect, base.StatEffect)))|])
			result.Body.Add([|Attack true|]) if base.AttackStat
			result.Body.Add([|Defense true|]) if base.DefenseStat
			result.Body.Add([|Mind true|]) if base.MindStat
			result.Body.Add([|Speed true|]) if base.SpeedStat
		result.Body.Add([|HpTurnPercent $(base.HpTurnPercent)|]) if base.HpTurnPercent != 0
		result.Body.Add([|HpTurnFixed $(base.HpTurnFixed)|]) if base.HpTurnFixed != 0
		result.Body.Add([|HpStepCount $(base.HpStepCount)|]) if base.HpStepCount != 0
		result.Body.Add([|HpStepQuantity $(base.HpStepQuantity)|]) if base.HpStepQuantity != 0
		result.Body.Add([|MpTurnPercent $(base.MpTurnPercent)|]) if base.MpTurnPercent != 0
		result.Body.Add([|MpTurnFixed $(base.MpTurnFixed)|]) if base.MpTurnFixed != 0
		result.Body.Add([|MpStepCount $(base.MpStepCount)|]) if base.MpStepCount != 0
		result.Body.Add([|MpStepQuantity $(base.MpStepQuantity)|]) if base.MpStepQuantity != 0

		return result
