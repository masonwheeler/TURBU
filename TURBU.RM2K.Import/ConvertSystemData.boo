namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF
import turbu.constants
import turbu.defs

static class TSysDataConverter:
	public def Convert(sysData as RMSystemRecord, battleData as RMBattleLayout, is2k3 as bool) as MacroStatement:
		result = [|
			SystemData:
				LogicalSize $(LOGICAL_SIZE.x), $(LOGICAL_SIZE.y)
				WindowSize $(PHYSICAL_SIZE.x), $(PHYSICAL_SIZE.y)
				SpriteSize $(SPRITE_SIZE.x), $(SPRITE_SIZE.y)
				SpriteSheetSize 4, 2, 3, 4
				PortraitSize $(PORTRAIT_SIZE.x), $(PORTRAIT_SIZE.y)
				TileSize $(TILE_SIZE.x), $(TILE_SIZE.y)
				TitleScreen $(sysData.TitleScreen)
				GameOverScreen $(sysData.GameOverScreen)
				SysGraphic $(sysData.SystemGraphic)
				BattleSysGraphic $(sysData.BattleSysGraphic)
				WallpaperStretch $(not sysData.WallpaperTiled)
				FontID $(sysData.WhichFont)
				ReverseGraphics $(sysData.ReverseGraphics)
				EditorCondition $(sysData.EditorCondition)
				EditorHero $(sysData.Hero)
				BattleTestBG $(sysData.EditorBattleTestBG)
				BattleTestTerrain $(sysData.BattleTestTerrain)
				BattleTestFormation $(sysData.BattleTestFormation)
				BattleTestSpecialCondition $(sysData.BattleTestSpecialCondition)
				BattleTestData
				StartingHeroes
				Transitions
				BattleCommands
				MoveMatrix:
					((0, 1, 2, 1), (3, 4, 5, 4), (6, 7, 8, 7), (9, 10, 11, 10))
		|]
		bt = result.SubMacro('BattleTestData')
		for test in sysData.BattleTestData:
			bt.Body.Add(ConvertBattleTestData(test))
		result.SubMacro('StartingHeroes').Arguments.AddRange((sysData.StartingHero cast (int)).Select({e | Expression.Lift(e)}))
		trans = (sysData.MapExitTransition, sysData.MapEnterTransition, sysData.BattleStartEraseTransition, \
					sysData.BattleStartShowTransition, sysData.BattleEndEraseTransition, sysData.BattleEndShowTransition)
		result.SubMacro('Transitions').Arguments.AddRange(trans.Select({t | [|$(ReferenceExpression(Enum.GetName(TTransitions, t)))|]}))
		if is2k3:
			result.SubMacro('BattleCommands').Arguments.AddRange((sysData.Commands cast (int)).Select({e | Expression.Lift(e)}))
			result.Body.Add([|Frame $(sysData.Frame)|]) if sysData.UsesFrame
			result.Body.Add(ConvertBattleLayout(battleData))
		else: result.SubMacro('BattleCommands').Arguments.AddRange(([|1|], [|2|], [|3|], [|4|]))
		return result
	
	private def ConvertBattleTestData(base as RMBattleTest) as MacroStatement:
		result = [|
			Data $(base.ID):
				Hero $(base.HeroID)
				Level $(base.Level)
				Weapon $(base.WeaponID)
				Armor $(base.ArmorID)
				Helmet $(base.HelmetID)
				Relic $(base.RelicID)
		|]
		return result

	private def ConvertBattleLayout(base as RMBattleLayout) as MacroStatement:
		result = [|
			BattleLayout:
				AutoLineup $(base.AutoLineup)
				Row $(base.Row)
				Style $(ReferenceExpression(Enum.GetName(TBattleStyle, base.BattleStyle)))
				Commands
				SmallWindow $(base.SmallWindowSize)
				Translucent $(base.WindowTrans)
		|]
		if base.UsesDeathEventHandler:
			deathEvent = [|
				DeathEvent:
					Handler $(base.DeathEventHandler)
			|]
			if base.TeleportOnDeath:
				deathEvent.Body.Add([|Teleport $(base.EscapeMap), $(base.EscapeX), $(base.EscapeY), $(base.EscapeFacing)|])
			result.Body.Add(deathEvent)
		result.SubMacro('Commands').Body.Statements.AddRange(base.Commands.Select({c | ConvertBattleCommand(c)}))
		return result
	
	private def ConvertBattleCommand(base as BattleCommand) as MacroStatement:
		result = [|
			Command $(base.ID):
				Name $(base.Name)
				Style $(base.Style)
		|]
		return result

static class TSysSoundConverter:
	public def Convert(base as RMSystemRecord) as MacroStatement:
		result = [|
			SystemSounds:
				$(TMusicConverter.Convert(base.CursorSound, 'Cursor'))
				$(TMusicConverter.Convert(base.AcceptSound, 'Accept'))
				$(TMusicConverter.Convert(base.CancelSound, 'Cancel'))
				$(TMusicConverter.Convert(base.BuzzerSound, 'Buzzer'))
				$(TMusicConverter.Convert(base.BattleStartSound, 'BattleStart'))
				$(TMusicConverter.Convert(base.EscapeSound, 'Escape'))
				$(TMusicConverter.Convert(base.EnemyAttackSound, 'EnemyAttack'))
				$(TMusicConverter.Convert(base.EnemyDamageSound, 'EnemyDamage'))
				$(TMusicConverter.Convert(base.AllyDamageSound, 'AllyDamage'))
				$(TMusicConverter.Convert(base.EvadeSound, 'Evade'))
				$(TMusicConverter.Convert(base.EnemyDiesSound, 'EnemyDies'))
				$(TMusicConverter.Convert(base.ItemUsedSound, 'ItemUsed'))
		|]
		return result

static class TSysMusicConverter:
	public def Convert(base as RMSystemRecord) as MacroStatement:
		result = [|
			SystemMusic:
				$(TMusicConverter.Convert(base.TitleMusic, 'Title'))
				$(TMusicConverter.Convert(base.GameOverMusic, 'GameOver'))
				$(TMusicConverter.Convert(base.BattleMusic, 'Battle'))
				$(TMusicConverter.Convert(base.VictoryMusic, 'Victory'))
				$(TMusicConverter.Convert(base.InnMusic, 'Inn'))
				$(TMusicConverter.Convert(base.BattleMusic, 'BossBattle'))
		|]
		return result
