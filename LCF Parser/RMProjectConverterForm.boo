namespace LCF_Parser

import System
import System.IO
import System.Linq.Enumerable
import System.Windows.Forms
import Pythia.Runtime

partial class RMProjectConverterForm(TURBU.RM2K.Import.IConversionReport):
	private _outputPath as string
	private _projectFolder as string
	private _running as bool
	private _taskRunning as bool
	private _paused as bool
	private _finished as bool
	private _conversionReport = Pythia.Runtime.TStringList()
	private _thread as TThread
	
	public def constructor():
		// The InitializeComponent() call is required for Windows Forms designer support.
		InitializeComponent()
		// TODO: Add constructor code after the InitializeComponent() call.
	
	public def Convert(rmProject as string, outputPath as string):
		_projectFolder = rmProject
		_outputPath = outputPath
		self.ShowDialog()
	
	private def RMProjectConverterShown(sender as object, e as System.EventArgs):
		unless ValidateProjectFolder():
			MessageBox.Show("Folder '_projectFolder' does not contain a valid RPG Maker project.",
								 'Invalid project folder', MessageBoxButtons.OK, MessageBoxIcon.Exclamation)
			return
		if Directory.Exists(_outputPath):
			if Directory.EnumerateFiles(_outputPath, '*.*', SearchOption.AllDirectories).Any():
				cont = "Folder '$_outputPath' is not empty.  Converting will delete everything in this folder. Continue conversion?"
				unless MessageBox.Show(cont, 'Folder is not empty', MessageBoxButtons.YesNo, MessageBoxIcon.Warning, 
									 MessageBoxDefaultButton.Button2) == DialogResult.Yes:
					return
			Directory.Delete(_outputPath, true)
			Directory.CreateDirectory(_outputPath)
		Directory.CreateDirectory(_outputPath)
		RMProjectConverter(_projectFolder, _outputPath, self)
	
	private def ValidateProjectFolder() as bool:
	"""Checks that the directory contains a project map tree, database, and at least one map file"""
		return false unless File.Exists(Path.Combine(_projectFolder, 'RPG_RT.LDB'))
		return false unless File.Exists(Path.Combine(_projectFolder, 'RPG_RT.LMT'))
		return Directory.EnumerateFiles(_projectFolder, '*.lmu').Any()

	def SetCurrentTask(name as string, steps as int):
		self.Invoke() do:
			prgConversion.PerformStep() if _running
			_running = true
			_taskRunning = false
			lblStatus.Text = name
			prgSteps.Value = 0
			prgSteps.Maximum = steps
	
	def SetCurrentTask(name as string):
		SetCurrentTask(name, 1)
		NewStep('')
		NewStep(name)
	
	def NewStep(name as string):
		return if _paused
		
		self.Invoke() do:
			prgSteps.PerformStep() if _taskRunning
			_taskRunning = true
			lblSteps.Text = name
	
	def MakeReport(filename as string):
		self.Invoke() do:
			prgConversion.PerformStep() while prgConversion.Value < prgConversion.Maximum
			lblStatus.Font = System.Drawing.Font(lblStatus.Font, System.Drawing.FontStyle.Bold)
			lblStatusLabel.Font = System.Drawing.Font(lblStatusLabel.Font, System.Drawing.FontStyle.Bold)
			if _conversionReport.Count > 0 and not string.IsNullOrEmpty(filename):
				filename = Path.Combine(_outputPath, filename)
				_conversionReport.SaveToFile(filename)
				System.Diagnostics.Process.Start(filename)
			lblStatus.Text = 'Complete'
			btnDone.DialogResult = DialogResult.OK
			btnDone.Text = '&OK'
			btnDone.Visible = true
			btnDone.Focus()
			_finished = true
	
	def PauseSteps():
		_paused = true
	
	def ResumeSteps():
		_paused = false
	
	def Initialize(thread as TThread, tasks as int):
		_thread = thread
		self.Invoke() do:
			prgConversion.Maximum = tasks
			prgConversion.Value = 0
			_running = false
	
	def Fatal(errorMessage as string):
		System.Windows.Forms.MessageBox.Show(errorMessage, 'Fatal error')
	
	def Fatal(error as Exception):
		Fatal("Unhandled conversion exception $(error.GetType().Name):$(Environment.NewLine)$(error.Message)")
	
	def MakeError(text as string, group as int):
		_conversionReport.Add("Error (E$group): $text")
		self.Invoke() do():
			lblErrors.Text = (int.Parse(lblErrors.Text) + 1).ToString()
	
	def MakeHint(text as string, group as int):
		_conversionReport.Add("Hint (H$group): $text")
		self.Invoke() do():
			lblHints.Text = (int.Parse(lblHints.Text) + 1).ToString()
		
	def MakeNotice(text as string, group as int):
		_conversionReport.Add("Hint (H$group): $text")
		self.Invoke() do():
			lblWarnings.Text = (int.Parse(lblWarnings.Text) + 1).ToString()
	
	private def BtnDoneClick(sender as object, e as System.EventArgs):
		_thread.Terminate() if assigned(_thread) and not _finished
	
	override def ToString():
		return 'RM Project Converter'
