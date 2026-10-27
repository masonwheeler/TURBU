namespace LCF_Parser

import System
import TURBU.RM2K.Import

class CliConverter(IConversionReport):
	def Initialize(taskSource as ITaskSource, tasks as int):
		pass

	private _task = ''
	private _steps = 1
	private _done = 0
	private _printed = -1

	def SetCurrentTask(name as string):
		SetCurrentTask(name, 1)

	def SetCurrentTask(name as string, steps as int):
		_task = name
		_steps = Math.Max(steps, 1)
		_done = -1 //the first step of a task only starts it
		_printed = -1
		print "== $name"

	def NewStep(name as string):
		++_done
		return if _steps < 20
		tenth = (_done * 10) / _steps
		if tenth > _printed and _done >= 0:
			_printed = tenth
			print "   $_task: $(tenth * 10)% ($name)"

	def MakeHint(text as string, group as int):
		print text

	def MakeNotice(text as string, group as int):
		print text

	def MakeError(text as string, group as int):
		print text

	def Fatal(errorMessage as string):
		raise errorMessage

	def Fatal(error as System.Exception):
		raise error

	def PauseSteps():
		pass

	def ResumeSteps():
		pass

	def MakeReport(filename as string):
		pass
