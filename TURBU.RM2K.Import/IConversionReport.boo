namespace TURBU.RM2K.Import

import System
import Pythia.Runtime

interface IConversionReport:
	def Initialize(thread as TThread, tasks as int)
	def SetCurrentTask(name as string)
	def SetCurrentTask(name as string, steps as int)
	def NewStep(name as string)
	def MakeHint(text as string, group as int)
	def MakeNotice(text as string, group as int)
	def MakeError(text as string, group as int)
	def Fatal(errorMessage as string)
	def Fatal(error as System.Exception)
	def PauseSteps()
	def ResumeSteps()
	def MakeReport(filename as string)