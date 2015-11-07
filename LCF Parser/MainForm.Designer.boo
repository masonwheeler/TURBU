namespace LCF_Parser

partial class MainForm(System.Windows.Forms.Form):
	private components as System.ComponentModel.IContainer = null
	
	protected override def Dispose(disposing as bool) as void:
		if disposing:
			if components is not null:
				components.Dispose()
		super(disposing)
	
	// This method is required for Windows Forms designer support.
	// Do not change the method contents inside the source code editor. The Forms designer might
	// not be able to load this method if it was changed manually.
	private def InitializeComponent():
		self.btnProcess = System.Windows.Forms.Button()
		self.dlgRMLocation = System.Windows.Forms.OpenFileDialog()
		self.txtRMProject = System.Windows.Forms.TextBox()
		self.label1 = System.Windows.Forms.Label()
		self.btnRMProject = System.Windows.Forms.Button()
		self.label2 = System.Windows.Forms.Label()
		self.txtTurbuProject = System.Windows.Forms.TextBox()
		self.SuspendLayout()
		# 
		# btnProcess
		# 
		self.btnProcess.Location = System.Drawing.Point(385, 326)
		self.btnProcess.Name = "btnProcess"
		self.btnProcess.Size = System.Drawing.Size(91, 23)
		self.btnProcess.TabIndex = 2
		self.btnProcess.Text = "Convert"
		self.btnProcess.UseVisualStyleBackColor = true
		self.btnProcess.Click += self.BtnProcessClick as System.EventHandler
		# 
		# dlgRMLocation
		# 
		self.dlgRMLocation.FileName = "RPG_RT.ldb"
		self.dlgRMLocation.Filter = "RPG Maker Database (*.ldb) | *.ldb"
		# 
		# txtRMProject
		# 
		self.txtRMProject.Anchor = cast(System.Windows.Forms.AnchorStyles,(System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right))
		self.txtRMProject.Location = System.Drawing.Point(202, 46)
		self.txtRMProject.Name = "txtRMProject"
		self.txtRMProject.ReadOnly = true
		self.txtRMProject.Size = System.Drawing.Size(356, 22)
		self.txtRMProject.TabIndex = 0
		# 
		# label1
		# 
		self.label1.Location = System.Drawing.Point(12, 49)
		self.label1.Name = "label1"
		self.label1.Size = System.Drawing.Size(143, 23)
		self.label1.TabIndex = 4
		self.label1.Text = "RPG Maker Project:"
		# 
		# btnRMProject
		# 
		self.btnRMProject.Anchor = cast(System.Windows.Forms.AnchorStyles,(System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right))
		self.btnRMProject.Font = System.Drawing.Font("Microsoft Sans Serif", 7.8, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, cast(System.Byte,0))
		self.btnRMProject.Location = System.Drawing.Point(564, 46)
		self.btnRMProject.Name = "btnRMProject"
		self.btnRMProject.Size = System.Drawing.Size(33, 23)
		self.btnRMProject.TabIndex = 1
		self.btnRMProject.Text = "..."
		self.btnRMProject.TextAlign = System.Drawing.ContentAlignment.TopCenter
		self.btnRMProject.UseVisualStyleBackColor = true
		self.btnRMProject.Click += self.BtnRMProjectClick as System.EventHandler
		# 
		# label2
		# 
		self.label2.Location = System.Drawing.Point(12, 178)
		self.label2.Name = "label2"
		self.label2.Size = System.Drawing.Size(174, 23)
		self.label2.TabIndex = 7
		self.label2.Text = "TURBU Project Location:"
		# 
		# txtTurbuProject
		# 
		self.txtTurbuProject.Anchor = cast(System.Windows.Forms.AnchorStyles,(System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right))
		self.txtTurbuProject.Location = System.Drawing.Point(202, 175)
		self.txtTurbuProject.Name = "txtTurbuProject"
		self.txtTurbuProject.ReadOnly = true
		self.txtTurbuProject.Size = System.Drawing.Size(395, 22)
		self.txtTurbuProject.TabIndex = 5
		# 
		# MainForm
		# 
		self.AutoScaleDimensions = System.Drawing.SizeF(8, 16)
		self.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
		self.ClientSize = System.Drawing.Size(609, 377)
		self.Controls.Add(self.label2)
		self.Controls.Add(self.txtTurbuProject)
		self.Controls.Add(self.btnRMProject)
		self.Controls.Add(self.label1)
		self.Controls.Add(self.txtRMProject)
		self.Controls.Add(self.btnProcess)
		self.Name = "MainForm"
		self.Text = "MainForm"
		self.ResumeLayout(false)
		self.PerformLayout()
	private txtTurbuProject as System.Windows.Forms.TextBox
	private label2 as System.Windows.Forms.Label
	private label1 as System.Windows.Forms.Label
	private txtRMProject as System.Windows.Forms.TextBox
	private dlgRMLocation as System.Windows.Forms.OpenFileDialog
	private btnProcess as System.Windows.Forms.Button
	private btnRMProject as System.Windows.Forms.Button
	
