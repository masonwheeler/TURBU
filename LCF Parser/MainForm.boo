namespace LCF_Parser

import System
import System.IO
import System.Windows.Forms
import TURBU.RM2K.Import.LCF

partial class MainForm:
	public def constructor():
		// The InitializeComponent() call is required for Windows Forms designer support.
		InitializeComponent()
		// TODO: Add constructor code after the InitializeComponent() call.

	private def ValidatePaths():
		btnProcess.Enabled = \
			(not string.IsNullOrEmpty(txtRMProject.Text)) and System.IO.File.Exists(txtRMProject.Text)
	
	private def BtnRMProjectClick(sender as object, e as System.EventArgs):
		if dlgRMLocation.ShowDialog() == DialogResult.OK:
			self.txtRMProject.Text = dlgRMLocation.FileName
			projectName = Path.GetFileName(Path.GetDirectoryName(dlgRMLocation.FileName))
			turbuPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), 'TURBU Projects')
			self.txtTurbuProject.Text = Path.Combine(turbuPath, projectName)
		ValidatePaths()
	
	private def BtnProcessClick(sender as object, e as System.EventArgs):
		unless string.IsNullOrEmpty(txtRMProject.Text):
			converter = RMProjectConverterForm()
			converter.Convert(Path.GetDirectoryName(txtRMProject.Text), txtTurbuProject.Text)
	
[STAThread]
public def Main(argv as (string)) as void:
	Application.EnableVisualStyles()
	Application.SetCompatibleTextRenderingDefault(false)
	Application.Run(MainForm())

