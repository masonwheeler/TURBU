namespace TURBU.RM2K.BattleEngine

import System
import Pythia.Runtime
import Boo.Adt
import TURBU.Meta
import commons

static class TBattleMath:
	public Rng = Random()

	public def Roll(n as int) as int:
		return Rng.Next(Math.Max(n, 1))

	public def AttackBase(attack as int, targetDefense as int) as int:
		return Math.Max(0, (attack / 2) - (targetDefense / 4))

	public def ScaleByAttributes(damage as int, bestPhysical as int, bestMagical as int) as int:
		damage = (damage * bestPhysical) / 100 if bestPhysical >= 0
		damage = (damage * bestMagical) / 100 if bestMagical >= 0
		return damage

	public def SkillBase(power as int, attack as int, spirit as int, physicalRate as int, magicalRate as int, \
			offensive as bool, ignoreDefense as bool, targetDefense as int, targetSpirit as int) as int:
		result = power + ((attack * physicalRate) / 20) + ((spirit * magicalRate) / 40)
		if offensive and not ignoreDefense:
			result = result - ((targetDefense * physicalRate) / 40) - ((targetSpirit * magicalRate) / 80)
		return Math.Max(result, 0)

	public def SkillSpread(damage as int, variance as int) as int:
		return damage unless damage > 0 and variance > 0
		v = Math.Max(1, (variance * damage) / 10)
		return damage + Rng.Next(v + 1) - (v / 2)

	public def AttackSpread(damage as int) as int:
		return damage unless damage > 0
		spread = Math.Max(1, (damage * 4) / 10)
		return damage + Rng.Next(spread + 1) - (spread / 2)

	// chance of missing, as a percentage
	public def MissChance(hitRate as int, hitRatio as int, attackerAgility as int, targetAgility as int, \
			ignoreEvasion as bool, targetRaisesEvasion as bool, targetCanAct as bool) as double:
		var miss = (100 - ((hitRate * hitRatio) / 100)) cast double
		unless ignoreEvasion:
			if attackerAgility != 0:
				miss = ((((targetAgility cast double) / attackerAgility) - 1.0) / 2.0 + 1.0) * miss
			miss += 25.0 if targetRaisesEvasion
		miss = 0.0 unless targetCanAct
		return miss

	public def RollHit(missChance as double) as bool:
		return missChance <= Rng.NextDouble() * 100.0

	public def RollCritical(chance as double) as bool:
		return chance >= Rng.NextDouble() * 100.0

	public def SkillHitChance(chance as int, hitRatio as int, attackerAgility as int, targetAgility as int, \
			ignoreEvasion as bool, targetRaisesEvasion as bool, targetCanAct as bool) as int:
		chance = (hitRatio * chance) / 100
		miss = (100 - chance) cast double
		unless ignoreEvasion:
			if attackerAgility != 0:
				miss = ((((targetAgility cast double) / attackerAgility) - 1.0) / 2.0 + 1.0) * miss
			miss += 25.0 if targetRaisesEvasion
		miss = 0.0 unless targetCanAct
		return 100 - ((Math.Truncate(miss)) cast int)

	//base chance in percent that the party gets away
	public def EscapeChance(partyAgility as int, monsterAgility as int) as int:
		ratio = 0.0
		ratio = (monsterAgility cast double) / partyAgility unless partyAgility == 0
		return clamp(150 - (Math.Round(100.0 * ratio) cast int), 0, 100)

	public def Initiative(agility as int, preemptive as bool) as int:
		result = agility + Rng.Next((agility / 4) + 3)
		result += 9999 if preemptive
		return result

	public def ChangePerTurn(maximum as int, percent as int, fixedAmount as int) as int:
		return ((maximum * percent) / 100) + fixedAmount

	//how much of the party's strength is gone, in percent
	public def HealthLoss(hp as int, maxHp as int, sp as int, maxSp as int) as int:
		maxHp = 1 if maxHp == 0
		maxSp = 1 if maxSp == 0
		return 100 - ((Math.Truncate(((((hp cast double) / maxHp) * 2.0) + ((sp cast double) / maxSp)) * 100.0 / 3.0)) cast int)

	public def TurnMatches(turn as int, period as int, offset as int) as bool:
		return offset == turn if period == 0
		return turn >= offset and (turn % period) == (offset % period)

	public def DamageAfterDefending(damage as int, superGuard as bool) as int:
		return damage / (4 if superGuard else 2)

	public def ExplosionDamage(attack as int, targetDefense as int) as int:
		return AttackSpread(Math.Max(0, attack - (targetDefense / 2)))

	//the rate in percent for a rank from 0 (A) to 4 (E)
	public def RateAt(rates as (int), rank as int) as int:
		return 0 if rates is null or rank < 0 or rank >= rates.Length
		return rates[rank]

	public def PercentOf(value as int, maximum as int) as int:
		return 0 if maximum <= 0
		return (value * 100) / maximum
