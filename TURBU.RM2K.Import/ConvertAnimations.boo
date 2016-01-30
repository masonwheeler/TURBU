namespace TURBU.RM2K.Import

import System
import System.Linq.Enumerable
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF
import turbu.animations

static class TAnimConverter:
	def Convert(base as RMAnimation) as MacroStatement:
		cellSize = (128 if base.LargeAnim else 96)
		result = [|
			Animation $(base.ID):
				Name $(base.Name)
				Filename $(base.Filename)
				HitsAll $(base.HitsAll)
				YTarget $(ReferenceExpression(Enum.GetName(TAnimYTarget, base.YTarget)))
				CellSize $cellSize, $cellSize
				Frames
				Effects
		|]
		result.SubMacro('Frames').Body.Statements.AddRange(base.Frames.SelectMany({f | ConvertFrame(f)}))
		result.SubMacro('Effects').Body.Statements.AddRange(base.Timing.Select({e | ConvertEffect(e)}))
		return result
	
	private def ConvertFrame(base as AnimFrame) as MacroStatement*:
		id = base.ID
		for cell in base.Cells.Where({c | c.IsNew}):
			yield ConvertCell(cell, id)
	
	private def ConvertCell(cell as AnimCell, frame as int) as MacroStatement:
		result = [|
			Cell $frame, $(cell.ID)
		|]
		result.Body.Add([|ImageIndex $(cell.Index)|]) unless cell.Index == 0
		result.Body.Add([|Position $(cell.X), $(cell.Y)|]) unless cell.X == 0 and cell.Y == 0
		result.Body.Add([|Zoom $(cell.Zoom)|]) unless cell.Zoom == 100
		result.Body.Add([|Color $(cell.Red), $(cell.Green), $(cell.Blue), $(cell.Sat)|]) \
			unless (cell.Red == 100 and cell.Green == 100 and cell.Blue == 100 and cell.Sat== 100)
		result.Body.Add([|Transparency $(cell.Transparency)|]) unless cell.Transparency == 0
		return result
	
	private def ConvertEffect(e as AnimEffects):
		result = [|
			Effect $(e.Frame), $(e.ID)
		|]
		result.Body.Add([|Flash $(ReferenceExpression(Enum.GetName(TFlashTarget, e.FlashWhere)))|]) \
			unless e.FlashWhere == 0
		result.Body.Add([|Color $(e.Red), $(e.Green), $(e.Blue), $(e.Power)|]) \
			unless (e.Red == 31 and e.Green == 31 and e.Blue == 31 and e.Power == 31)
		result.Body.Add([|Shake $(ReferenceExpression(Enum.GetName(TFlashTarget, e.ShakeWhere)))|]) \
			unless e.ShakeWhere == 0
		result.Body.Add(TMusicConverter.Convert(e.Sound, 'Sound')) unless e.Sound.Filename == '(OFF)'
		return result
